use anyhow::{Context, Result};
use directories::BaseDirs;
use std::path::{Path, PathBuf};

/// Chunking configuration for document splitting.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct ChunkingConfig {
    pub enabled: bool,
    pub chunk_size: usize,
    pub chunk_stride: usize,
    pub chunk_min_words: usize,
}

impl Default for ChunkingConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            chunk_size: 128,
            chunk_stride: 64,
            chunk_min_words: 20,
        }
    }
}

/// Title boosting configuration.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct TitleBoostingConfig {
    pub enabled: bool,
}

impl Default for TitleBoostingConfig {
    fn default() -> Self {
        Self { enabled: true }
    }
}

/// Corpus centering configuration.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct CorpusCenteringConfig {
    pub enabled: bool,
}

impl Default for CorpusCenteringConfig {
    fn default() -> Self {
        Self { enabled: false }
    }
}

/// MMR (Maximal Marginal Relevance) configuration.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct MmrConfig {
    pub enabled: bool,
    pub lambda: f64,
}

impl Default for MmrConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            lambda: 0.7,
        }
    }
}

/// BM25 hybrid search configuration.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct Bm25Config {
    pub enabled: bool,
    pub weight: f64,
    pub dense_weight: f64,
    pub rrf_k: f64,
}

impl Default for Bm25Config {
    fn default() -> Self {
        Self {
            enabled: true,
            weight: 0.5,
            dense_weight: 0.5,
            rrf_k: 60.0,
        }
    }
}

/// Scoring configuration from TOML.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct ScoringConfig {
    pub semantic_weight: f64,
    pub strength_weight: f64,
    pub decay_threshold: f64,
    /// Minimum cosine similarity for a document to appear in search results.
    /// Documents below this threshold are excluded regardless of limit.
    pub semantic_threshold: f64,
    /// Chunking configuration.
    #[serde(default)]
    pub chunking: ChunkingConfig,
    /// Title boosting configuration.
    #[serde(default)]
    pub title_boosting: TitleBoostingConfig,
    /// Corpus centering configuration.
    #[serde(default)]
    pub corpus_centering: CorpusCenteringConfig,
    /// MMR configuration.
    #[serde(default)]
    pub mmr: MmrConfig,
    /// BM25 configuration.
    #[serde(default)]
    pub bm25: Bm25Config,
}

impl Default for ScoringConfig {
    fn default() -> Self {
        Self {
            semantic_weight: 0.5,
            strength_weight: 0.5,
            decay_threshold: 0.05,
            semantic_threshold: 0.25,
            chunking: ChunkingConfig::default(),
            title_boosting: TitleBoostingConfig::default(),
            corpus_centering: CorpusCenteringConfig::default(),
            mmr: MmrConfig::default(),
            bm25: Bm25Config::default(),
        }
    }
}

/// Strength weights configuration from TOML.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
#[serde(default)]
pub struct StrengthWeights {
    pub recency: f64,
    pub frequency: f64,
    pub importance: f64,
    pub utility: f64,
    pub novelty: f64,
    pub confidence: f64,
    pub interference: f64,
}

impl Default for StrengthWeights {
    fn default() -> Self {
        Self {
            recency: 0.20,
            frequency: 0.15,
            importance: 0.25,
            utility: 0.20,
            novelty: 0.10,
            confidence: 0.10,
            interference: 0.10,
        }
    }
}

/// Memory type configuration from TOML.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct MemoryTypeConfig {
    pub classification: String,
    pub description: String,
    pub importance: f64,
    pub decay_rate: f64,
}

/// Configuration for a single indexed path.
///
/// Indexed paths are external directories whose contents are searchable but not
/// managed as memories. Documents ingested from these paths receive a reserved
/// classification (default: `"indexed"`) that excludes them from `engram list`
/// and from use with `engram add`.
#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct IndexedPathConfig {
    /// The directory to index.
    pub path: String,
    /// Classification assigned to documents from this path.
    /// Defaults to `"indexed"`. Must not be a name in `memory_types`.
    #[serde(default = "default_indexed_classification")]
    pub classification: String,
    /// Strength score for documents from this path (0.0–1.0).
    /// Defaults to 0.8 — manually curated content warrants high strength.
    #[serde(default = "default_indexed_strength")]
    pub strength: f64,
}

fn default_indexed_classification() -> String {
    "indexed".to_string()
}

fn default_indexed_strength() -> f64 {
    0.8
}

/// Allows `indexed_paths` in TOML to be either a bare string or a full config table.
///
/// ```toml
/// # Simple form (classification="indexed", strength=0.8)
/// indexed_paths = ["/path/to/notes"]
///
/// # Full form
/// [[indexed_paths]]
/// path = "/path/to/notes"
/// classification = "reference"
/// strength = 0.9
/// ```
#[derive(Debug, Clone, serde::Deserialize)]
#[serde(untagged)]
pub enum IndexedPathEntry {
    Simple(String),
    Config(IndexedPathConfig),
}

impl IndexedPathEntry {
    /// Convert to a resolved `IndexedPathConfig`.
    pub fn into_config(self) -> IndexedPathConfig {
        match self {
            IndexedPathEntry::Simple(path) => IndexedPathConfig {
                path,
                classification: default_indexed_classification(),
                strength: default_indexed_strength(),
            },
            IndexedPathEntry::Config(c) => c,
        }
    }
}

/// Configuration loaded from a TOML file.
#[derive(Debug, Default, serde::Deserialize)]
pub struct FileConfig {
    pub db: Option<String>,
    pub memory_path: Option<String>,
    /// Path to a directory containing a custom embedding model.
    /// Must contain config.json, model.safetensors, and tokenizer.json.
    /// When unset, the embedded gte-small model is used.
    pub model_path: Option<String>,
    /// Prefix prepended to search queries before embedding.
    /// Required by some models (e.g. E5: "query: ", BGE: "Represent this sentence for searching relevant passages: ").
    /// Defaults to None.
    #[serde(default)]
    pub query_prefix: Option<String>,
    /// Prefix prepended to stored passages before embedding.
    /// Required by some models (e.g. E5: "passage: ").
    /// Defaults to None.
    #[serde(default)]
    pub passage_prefix: Option<String>,
    #[serde(default)]
    pub indexed_paths: Vec<IndexedPathEntry>,
    #[serde(default)]
    pub scoring: ScoringConfig,
    #[serde(default)]
    pub strength_weights: StrengthWeights,
    #[serde(default = "default_memory_types")]
    pub memory_types: Vec<MemoryTypeConfig>,
}

/// Default memory types matching the hardcoded values.
fn default_memory_types() -> Vec<MemoryTypeConfig> {
    vec![
        MemoryTypeConfig {
            classification: "episodic".to_string(),
            description: "Short-lived observations, session events, and what happened.".to_string(),
            importance: 0.4,
            decay_rate: 0.05,
        },
        MemoryTypeConfig {
            classification: "preference".to_string(),
            description: "Standing user preferences, constraints, and workflow rules.".to_string(),
            importance: 0.8,
            decay_rate: 0.0,
        },
        MemoryTypeConfig {
            classification: "fact".to_string(),
            description: "Decisions made, things learned, and stable factual knowledge.".to_string(),
            importance: 0.7,
            decay_rate: 0.0,
        },
    ]
}

/// Global configuration derived from CLI flags and file config.
#[derive(Debug, Clone)]
pub struct Config {
    /// Path to the SQLite database file.
    pub db_path: PathBuf,
    /// Directory where memory markdown files are stored.
    pub memory_path: PathBuf,
    /// Path to a directory containing a custom embedding model.
    /// When None, the embedded gte-small model is used.
    pub model_path: Option<PathBuf>,
    /// Prefix prepended to search queries before embedding.
    pub query_prefix: Option<String>,
    /// Prefix prepended to stored passages before embedding.
    pub passage_prefix: Option<String>,
    /// Additional directories to index alongside memory_path, with per-path settings.
    pub indexed_paths: Vec<IndexedPathConfig>,
    /// Scoring configuration.
    pub scoring: ScoringConfig,
    /// Strength weights configuration.
    pub strength_weights: StrengthWeights,
    /// Memory type configurations.
    pub memory_types: Vec<MemoryTypeConfig>,
}

impl Config {
    /// Construct a Config, expanding all paths.
    /// Configuration is loaded from the file config, with defaults for missing values.
    pub fn new(
        config_path: Option<String>,
    ) -> Result<Self> {
        let default_data_dir = BaseDirs::new()
            .map(|b| b.data_dir().join("engram"))
            .context("could not determine XDG data directory")?;

        // Load file config
        let file_cfg = if let Some(path) = config_path {
            load_file_config(Path::new(&path))
                .context("failed to load config file")?
        } else {
            let default_path = default_config_path()?;
            load_file_config(&default_path)?
        };

        // Merge with priority: file config > defaults
        let db_path = if let Some(p) = file_cfg.db {
            expand_path(&p).context("failed to expand db path from config file")?
        } else {
            default_data_dir.join("engram.db")
        };

        let memory_path = if let Some(p) = file_cfg.memory_path {
            expand_path(&p).context("failed to expand memory-path from config file")?
        } else {
            default_data_dir.join("memories")
        };

        // Use indexed_paths from file config only.
        let all_entries: Vec<IndexedPathEntry> = file_cfg.indexed_paths;

        let resolved_indexed: Vec<IndexedPathConfig> = all_entries
            .into_iter()
            .map(|e| {
                let mut cfg = e.into_config();
                cfg.path = expand_path(&cfg.path)
                    .context("failed to expand indexed-path")
                    .map(|p| p.to_string_lossy().into_owned())
                    .unwrap_or(cfg.path);
                cfg
            })
            .collect();

        let model_path = if let Some(p) = file_cfg.model_path {
            Some(expand_path(&p).context("failed to expand model_path from config file")?)
        } else {
            None
        };

        Ok(Self {
            db_path,
            memory_path,
            model_path,
            query_prefix: file_cfg.query_prefix,
            passage_prefix: file_cfg.passage_prefix,
            indexed_paths: resolved_indexed,
            scoring: file_cfg.scoring,
            strength_weights: file_cfg.strength_weights,
            memory_types: file_cfg.memory_types,
        })
    }

    /// Look up a memory type by name.
    pub fn memory_type(&self, name: &str) -> Option<&MemoryTypeConfig> {
        self.memory_types.iter().find(|t| t.classification == name)
    }
}

/// Load config from a TOML file. Returns default FileConfig if the file doesn't exist.
pub fn load_file_config(path: &Path) -> Result<FileConfig> {
    if !path.exists() {
        return Ok(FileConfig::default());
    }

    let content = std::fs::read_to_string(path)
        .context("failed to read config file")?;
    let cfg = toml::from_str(&content)
        .context("failed to parse TOML config file")?;
    Ok(cfg)
}

/// Returns $XDG_CONFIG_HOME/engram/engram.toml
pub fn default_config_path() -> Result<PathBuf> {
    let config_dir = BaseDirs::new()
        .map(|b| b.config_dir().join("engram/engram.toml"))
        .context("could not determine XDG config directory")?;
    Ok(config_dir)
}

/// Expand `~` and `$VAR` / `${VAR}` in a path string.
pub fn expand_path(path: &str) -> Result<PathBuf> {
    let with_home = if path.starts_with("~/") || path == "~" {
        let home = std::env::var("HOME").context("HOME environment variable not set")?;
        path.replacen('~', &home, 1)
    } else {
        path.to_string()
    };

    // Expand $VAR and ${VAR} references.
    let expanded = expand_env_vars(&with_home)?;

    Ok(PathBuf::from(expanded))
}

/// Replace `$VAR` and `${VAR}` occurrences with their environment values.
fn expand_env_vars(s: &str) -> Result<String> {
    let mut result = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();

    while let Some(ch) = chars.next() {
        if ch != '$' {
            result.push(ch);
            continue;
        }

        // Determine variable name.
        let var_name: String = if chars.peek() == Some(&'{') {
            chars.next(); // consume '{'
            let name: String = chars.by_ref().take_while(|&c| c != '}').collect();
            name
        } else {
            chars
                .by_ref()
                .take_while(|c| c.is_alphanumeric() || *c == '_')
                .collect()
        };

        if var_name.is_empty() {
            result.push('$');
        } else {
            let value = std::env::var(&var_name)
                .with_context(|| format!("environment variable ${var_name} not set"))?;
            result.push_str(&value);
        }
    }

    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_tilde() {
        std::env::set_var("HOME", "/home/testuser");
        let p = expand_path("~/foo/bar").unwrap();
        assert_eq!(p, PathBuf::from("/home/testuser/foo/bar"));
    }

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_env_var() {
        std::env::set_var("MY_TEST_VAR", "/some/path");
        let p = expand_path("$MY_TEST_VAR/sub").unwrap();
        assert_eq!(p, PathBuf::from("/some/path/sub"));
    }

    #[test]
    #[ignore = "relies on env mutation which is unreliable in sandboxed builds"]
    fn test_expand_braced_env_var() {
        std::env::set_var("MY_TEST_VAR2", "/braced");
        let p = expand_path("${MY_TEST_VAR2}/sub").unwrap();
        assert_eq!(p, PathBuf::from("/braced/sub"));
    }

    #[test]
    fn test_no_expansion_needed() {
        let p = expand_path("/absolute/path").unwrap();
        assert_eq!(p, PathBuf::from("/absolute/path"));
    }

    #[test]
    fn test_indexed_path_entry_simple_defaults() {
        let entry = IndexedPathEntry::Simple("/some/path".to_string());
        let cfg = entry.into_config();
        assert_eq!(cfg.path, "/some/path");
        assert_eq!(cfg.classification, "indexed");
        assert_eq!(cfg.strength, 0.8);
    }

    #[test]
    fn test_indexed_path_entry_config_preserved() {
        let entry = IndexedPathEntry::Config(IndexedPathConfig {
            path: "/notes".to_string(),
            classification: "reference".to_string(),
            strength: 0.95,
        });
        let cfg = entry.into_config();
        assert_eq!(cfg.classification, "reference");
        assert_eq!(cfg.strength, 0.95);
    }

    #[test]
    fn test_indexed_path_simple_toml() {
        let toml = r#"indexed_paths = ["/a/path"]"#;
        let fc: FileConfig = toml::from_str(toml).unwrap();
        assert_eq!(fc.indexed_paths.len(), 1);
        let cfg = fc.indexed_paths.into_iter().next().unwrap().into_config();
        assert_eq!(cfg.path, "/a/path");
        assert_eq!(cfg.classification, "indexed");
    }

    #[test]
    fn test_indexed_path_table_toml() {
        let toml = r#"
[[indexed_paths]]
path = "/b/path"
classification = "reference"
strength = 0.85
"#;
        let fc: FileConfig = toml::from_str(toml).unwrap();
        let cfg = fc.indexed_paths.into_iter().next().unwrap().into_config();
        assert_eq!(cfg.path, "/b/path");
        assert_eq!(cfg.classification, "reference");
        assert_eq!(cfg.strength, 0.85);
    }


}
