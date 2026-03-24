use anyhow::{anyhow, Result};
use candle_core::{DType, Device, Tensor};
use candle_nn::VarBuilder;
use candle_transformers::models::bert::{BertModel, Config};
use std::sync::OnceLock;
use tokenizers::Tokenizer;

/// Maximum number of word-pieces fed to the model per call.
const MAX_TOKENS: usize = 256;

// Model files are downloaded at build time into OUT_DIR and embedded here.
const CONFIG_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/config.json"));
const MODEL_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/model.safetensors"));
const TOKENIZER_BYTES: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/tokenizer.json"));

struct EmbedModel {
    model: BertModel,
    tokenizer: Tokenizer,
    device: Device,
}

static EMBED: OnceLock<EmbedModel> = OnceLock::new();

fn get_embed() -> Result<&'static EmbedModel> {
    if let Some(e) = EMBED.get() {
        return Ok(e);
    }

    let device = Device::Cpu;

    let config: Config = serde_json::from_slice(CONFIG_BYTES)
        .map_err(|e| anyhow!("Failed to parse config.json: {}", e))?;

    let vb = VarBuilder::from_buffered_safetensors(MODEL_BYTES.to_vec(), DType::F32, &device)
        .map_err(|e| anyhow!("Failed to load model weights: {}", e))?;

    let model = BertModel::load(vb, &config)
        .map_err(|e| anyhow!("Failed to create BERT model: {}", e))?;

    let tokenizer = Tokenizer::from_bytes(TOKENIZER_BYTES)
        .map_err(|e| anyhow!("Failed to parse tokenizer.json: {}", e))?;

    // OnceLock::set returns Err if already set — ignore the race, just get the winner.
    let _ = EMBED.set(EmbedModel { model, tokenizer, device });
    Ok(EMBED.get().unwrap())
}

/// Embed text into a 384-dimensional float32 vector using all-MiniLM-L6-v2.
///
/// The vector is L2-normalized. The model and tokenizer are lazy-initialized on
/// the first call and reused for all subsequent calls.
pub fn embed(text: &str) -> Result<Vec<f32>> {
    let em = get_embed()?;

    // Tokenize and truncate to MAX_TOKENS.
    let encoding = em
        .tokenizer
        .encode(text, true)
        .map_err(|e| anyhow!("Tokenization failed: {}", e))?;

    let ids: Vec<u32> = encoding.get_ids().iter().take(MAX_TOKENS).copied().collect();
    let mask: Vec<u32> = encoding
        .get_attention_mask()
        .iter()
        .take(MAX_TOKENS)
        .copied()
        .collect();

    let ids_tensor = Tensor::new(ids.as_slice(), &em.device)
        .map_err(|e| anyhow!("Failed to create token IDs tensor: {}", e))?
        .unsqueeze(0)
        .map_err(|e| anyhow!("Failed to unsqueeze ids: {}", e))?;

    let mask_tensor = Tensor::new(mask.as_slice(), &em.device)
        .map_err(|e| anyhow!("Failed to create attention mask tensor: {}", e))?
        .unsqueeze(0)
        .map_err(|e| anyhow!("Failed to unsqueeze mask: {}", e))?;

    // BERT forward pass — produces [batch=1, seq_len, hidden=384].
    let embeddings = em
        .model
        .forward(&ids_tensor, &mask_tensor, None)
        .map_err(|e| anyhow!("BERT inference failed: {}", e))?;

    // Mean pooling weighted by attention mask, then L2-normalize.
    let pooled = mean_pooling(&embeddings, &mask_tensor)?;
    let normalized = l2_normalize(&pooled)?;

    normalized
        .flatten_all()
        .map_err(|e| anyhow!("Failed to flatten tensor: {}", e))?
        .to_vec1::<f32>()
        .map_err(|e| anyhow!("Failed to convert tensor to Vec<f32>: {}", e))
}

/// Average token embeddings weighted by the attention mask, excluding padding.
fn mean_pooling(embeddings: &Tensor, attention_mask: &Tensor) -> Result<Tensor> {
    // Expand mask from [batch, seq] to [batch, seq, hidden].
    let mask_f32 = attention_mask
        .to_dtype(DType::F32)
        .map_err(|e| anyhow!("Failed to cast mask to f32: {}", e))?;

    let mask_expanded = mask_f32
        .unsqueeze(2)
        .map_err(|e| anyhow!("Failed to unsqueeze mask: {}", e))?
        .broadcast_as(embeddings.shape())
        .map_err(|e| anyhow!("Failed to broadcast mask: {}", e))?;

    let masked = (embeddings * &mask_expanded)
        .map_err(|e| anyhow!("Failed to apply mask to embeddings: {}", e))?;

    let sum = masked
        .sum(1)
        .map_err(|e| anyhow!("Failed to sum masked embeddings: {}", e))?;

    let count = mask_expanded
        .sum(1)
        .map_err(|e| anyhow!("Failed to sum mask: {}", e))?;

    (sum / count).map_err(|e| anyhow!("Failed to compute mean: {}", e))
}

/// L2-normalize a tensor along its last dimension.
fn l2_normalize(tensor: &Tensor) -> Result<Tensor> {
    let norm = tensor
        .sqr()
        .map_err(|e| anyhow!("Failed to square tensor: {}", e))?
        .sum_keepdim(candle_core::D::Minus1)
        .map_err(|e| anyhow!("Failed to sum squares: {}", e))?
        .sqrt()
        .map_err(|e| anyhow!("Failed to compute sqrt: {}", e))?;

    tensor
        .broadcast_div(&norm)
        .map_err(|e| anyhow!("Failed to divide by norm: {}", e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embed_returns_correct_dimension() {
        let embedding = embed("Hello, world!").expect("embed failed");
        assert_eq!(embedding.len(), 384);
    }

    #[test]
    fn test_embed_is_normalized() {
        let embedding = embed("Test text").expect("embed failed");
        let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 0.01, "L2 norm was {}", norm);
    }

    #[test]
    fn test_embed_handles_long_text() {
        let long_text = "word ".repeat(300);
        let embedding = embed(&long_text).expect("embed failed on long text");
        assert_eq!(embedding.len(), 384);
    }
}
