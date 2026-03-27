use anyhow::{anyhow, Context, Result};
use candle_core::{DType, Device, Tensor};
use candle_nn::VarBuilder;
use candle_transformers::models::bert::{BertModel, Config};
use std::path::Path;
use std::sync::OnceLock;
use tokenizers::Tokenizer;

/// Maximum number of word-pieces fed to the model per call.
const MAX_TOKENS: usize = 512;

/// HuggingFace model ID of the embedded model, set at compile time by build.rs.
pub const EMBEDDED_MODEL_ID: &str = env!("ENGRAM_EMBEDDED_MODEL");

// Embedded model files, baked in at compile time from the default gte-small model.
const CONFIG_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/config.json"));
const MODEL_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/model.safetensors"));
const TOKENIZER_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/tokenizer.json"));

struct EmbedModel {
    model: BertModel,
    tokenizer: Tokenizer,
    device: Device,
}

// Cache for the active model — initialised once by `init`.
static EMBED: OnceLock<EmbedModel> = OnceLock::new();

/// Initialise the embedding model from a directory of model files.
///
/// Loads config.json, model.safetensors, and tokenizer.json from `model_dir`.
fn load_from_dir(model_dir: &Path) -> Result<EmbedModel> {
    let device = Device::Cpu;

    let config_bytes = std::fs::read(model_dir.join("config.json"))
        .with_context(|| format!("failed to read config.json from {}", model_dir.display()))?;
    let model_bytes = std::fs::read(model_dir.join("model.safetensors"))
        .with_context(|| format!("failed to read model.safetensors from {}", model_dir.display()))?;
    let tokenizer_bytes = std::fs::read(model_dir.join("tokenizer.json"))
        .with_context(|| format!("failed to read tokenizer.json from {}", model_dir.display()))?;

    let config: Config = serde_json::from_slice(&config_bytes)
        .map_err(|e| anyhow!("failed to parse config.json: {}", e))?;
    let vb = VarBuilder::from_buffered_safetensors(model_bytes, DType::F32, &device)
        .map_err(|e| anyhow!("failed to load model weights: {}", e))?;
    let model = BertModel::load(vb, &config)
        .map_err(|e| anyhow!("failed to create BERT model: {}", e))?;
    let tokenizer = Tokenizer::from_bytes(&tokenizer_bytes)
        .map_err(|e| anyhow!("failed to parse tokenizer.json: {}", e))?;

    Ok(EmbedModel { model, tokenizer, device })
}

/// Initialise the embedding model from the embedded (compiled-in) gte-small files.
fn load_embedded() -> Result<EmbedModel> {
    let device = Device::Cpu;

    let config: Config = serde_json::from_slice(CONFIG_BYTES)
        .map_err(|e| anyhow!("failed to parse embedded config.json: {}", e))?;
    let vb = VarBuilder::from_buffered_safetensors(MODEL_BYTES.to_vec(), DType::F32, &device)
        .map_err(|e| anyhow!("failed to load embedded model weights: {}", e))?;
    let model = BertModel::load(vb, &config)
        .map_err(|e| anyhow!("failed to create BERT model: {}", e))?;
    let tokenizer = Tokenizer::from_bytes(TOKENIZER_BYTES)
        .map_err(|e| anyhow!("failed to parse embedded tokenizer.json: {}", e))?;

    Ok(EmbedModel { model, tokenizer, device })
}

/// Initialise the embedding model.
///
/// Must be called once at startup before any call to `embed`. When `model_path`
/// is `Some`, the model is loaded from that directory; otherwise the embedded
/// gte-small model is used. Calling `init` more than once is a no-op — the first
/// call wins.
pub fn init(model_path: Option<&Path>) -> Result<()> {
    if EMBED.get().is_some() {
        return Ok(());
    }

    let em = match model_path {
        Some(dir) => load_from_dir(dir)
            .with_context(|| format!("failed to load custom model from {}", dir.display()))?,
        None => load_embedded().context("failed to load embedded model")?,
    };

    let _ = EMBED.set(em);
    Ok(())
}

fn get_embed() -> Result<&'static EmbedModel> {
    EMBED.get().ok_or_else(|| anyhow!("embedding model not initialised — call embed::init first"))
}

/// Embed a search query, prepending `query_prefix` if non-empty.
pub fn embed_query(text: &str, query_prefix: &str) -> Result<Vec<f32>> {
    if query_prefix.is_empty() {
        embed(text)
    } else {
        embed(&format!("{}{}", query_prefix, text))
    }
}

/// Embed a passage for storage, prepending `passage_prefix` if non-empty.
pub fn embed_passage(text: &str, passage_prefix: &str) -> Result<Vec<f32>> {
    if passage_prefix.is_empty() {
        embed(text)
    } else {
        embed(&format!("{}{}", passage_prefix, text))
    }
}

/// Embed title and body separately, then combine as a weighted average (L2-normalized).
/// title_weight=0.3, body_weight=0.7
pub fn embed_passage_with_title(title: &str, body: &str, passage_prefix: &str) -> Result<Vec<f32>> {
    let title_vec = embed_passage(title, passage_prefix)?;
    let body_vec = embed_passage(body, passage_prefix)?;
    
    // Weighted average
    let combined: Vec<f32> = title_vec.iter().zip(body_vec.iter())
        .map(|(t, b)| 0.3 * t + 0.7 * b)
        .collect();
    
    // L2 normalize
    let norm: f32 = combined.iter().map(|x| x * x).sum::<f32>().sqrt();
    Ok(combined.iter().map(|x| x / norm.max(1e-8)).collect())
}

/// Returns the output dimension of the active model.
///
/// Embeds a single token and returns the vector length. Used to detect
/// dimension mismatches when switching models.
pub fn embedding_dim() -> Result<usize> {
    Ok(embed(".")?.len())
}

/// Embed text into a float32 vector using the active model.
///
/// The vector is L2-normalized. The model must be initialised via `init` before
/// the first call. Subsequent calls reuse the cached model.
pub fn embed(text: &str) -> Result<Vec<f32>> {
    let em = get_embed()?;

    // Tokenize and truncate to MAX_TOKENS.
    let encoding = em
        .tokenizer
        .encode(text, true)
        .map_err(|e| anyhow!("tokenization failed: {}", e))?;

    let ids: Vec<u32> = encoding.get_ids().iter().take(MAX_TOKENS).copied().collect();
    let mask: Vec<u32> = encoding
        .get_attention_mask()
        .iter()
        .take(MAX_TOKENS)
        .copied()
        .collect();

    let ids_tensor = Tensor::new(ids.as_slice(), &em.device)
        .map_err(|e| anyhow!("failed to create token IDs tensor: {}", e))?
        .unsqueeze(0)
        .map_err(|e| anyhow!("failed to unsqueeze ids: {}", e))?;

    let mask_tensor = Tensor::new(mask.as_slice(), &em.device)
        .map_err(|e| anyhow!("failed to create attention mask tensor: {}", e))?
        .unsqueeze(0)
        .map_err(|e| anyhow!("failed to unsqueeze mask: {}", e))?;

    // BERT forward pass — produces [batch=1, seq_len, hidden].
    let embeddings = em
        .model
        .forward(&ids_tensor, &mask_tensor, None)
        .map_err(|e| anyhow!("BERT inference failed: {}", e))?;

    // Mean pooling weighted by attention mask, then L2-normalize.
    let pooled = mean_pooling(&embeddings, &mask_tensor)?;
    let normalized = l2_normalize(&pooled)?;

    normalized
        .flatten_all()
        .map_err(|e| anyhow!("failed to flatten tensor: {}", e))?
        .to_vec1::<f32>()
        .map_err(|e| anyhow!("failed to convert tensor to Vec<f32>: {}", e))
}

/// Average token embeddings weighted by the attention mask, excluding padding.
fn mean_pooling(embeddings: &Tensor, attention_mask: &Tensor) -> Result<Tensor> {
    // Expand mask from [batch, seq] to [batch, seq, hidden].
    let mask_f32 = attention_mask
        .to_dtype(DType::F32)
        .map_err(|e| anyhow!("failed to cast mask to f32: {}", e))?;

    let mask_expanded = mask_f32
        .unsqueeze(2)
        .map_err(|e| anyhow!("failed to unsqueeze mask: {}", e))?
        .broadcast_as(embeddings.shape())
        .map_err(|e| anyhow!("failed to broadcast mask: {}", e))?;

    let masked = (embeddings * &mask_expanded)
        .map_err(|e| anyhow!("failed to apply mask to embeddings: {}", e))?;

    let sum = masked
        .sum(1)
        .map_err(|e| anyhow!("failed to sum masked embeddings: {}", e))?;

    let count = mask_expanded
        .sum(1)
        .map_err(|e| anyhow!("failed to sum mask: {}", e))?;

    (sum / count).map_err(|e| anyhow!("failed to compute mean: {}", e))
}

/// L2-normalize a tensor along its last dimension.
fn l2_normalize(tensor: &Tensor) -> Result<Tensor> {
    let norm = tensor
        .sqr()
        .map_err(|e| anyhow!("failed to square tensor: {}", e))?
        .sum_keepdim(candle_core::D::Minus1)
        .map_err(|e| anyhow!("failed to sum squares: {}", e))?
        .sqrt()
        .map_err(|e| anyhow!("failed to compute sqrt: {}", e))?;

    tensor
        .broadcast_div(&norm)
        .map_err(|e| anyhow!("failed to divide by norm: {}", e))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ensure_init() {
        let _ = init(None);
    }

    #[test]
    fn test_embed_returns_correct_dimension() {
        ensure_init();
        let embedding = embed("Hello, world!").expect("embed failed");
        assert_eq!(embedding.len(), 384);
    }

    #[test]
    fn test_embed_is_normalized() {
        ensure_init();
        let embedding = embed("Test text").expect("embed failed");
        let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 0.01, "L2 norm was {}", norm);
    }

    #[test]
    fn test_embed_handles_long_text() {
        ensure_init();
        let long_text = "word ".repeat(300);
        let embedding = embed(&long_text).expect("embed failed on long text");
        assert_eq!(embedding.len(), 384);
    }
}
