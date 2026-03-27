use crate::config::Config;
use crate::db;
use anyhow::{bail, Context, Result};

/// Arguments for the `clear` command.
pub struct ClearArgs {
    /// If Some, only clear memories of this classification.
    pub memory_type: Option<String>,
}

/// Execute the `clear` command.
///
/// Removes memory records from the database and deletes the corresponding
/// on-disk directory trees. Memories are stored at `<memory-path>/<type>/`,
/// so clearing by type removes that subdirectory; clearing all removes each
/// known type's subdirectory. Prints a summary of what was removed.
pub fn run(cfg: &Config, args: ClearArgs) -> Result<()> {
    if let Some(ref t) = args.memory_type {
        if cfg.memory_type(t).is_none() {
            let valid_types: Vec<&str> = cfg.memory_types.iter().map(|mt| mt.classification.as_str()).collect();
            bail!(
                "invalid --type '{}'; must be one of: {}",
                t,
                valid_types.join(", ")
            );
        }
    }

    let conn = db::open(&cfg.db_path)?;

    let classification = args.memory_type.as_deref();
    let count = db::clear(&conn, classification)
        .context("failed to clear memories from database")?;

    // Remove on-disk files by deleting the type subdirectory/subdirectories.
    let types_to_remove: Vec<&str> = match classification {
        Some(t) => vec![t],
        None => cfg.memory_types.iter().map(|mt| mt.classification.as_str()).collect(),
    };

    for t in &types_to_remove {
        let dir = cfg.memory_path.join(t);
        if dir.exists() {
            std::fs::remove_dir_all(&dir)
                .with_context(|| format!("failed to remove memory directory {}", dir.display()))?;
        }
    }

    match classification {
        Some(t) => println!("cleared {count} {t} memories"),
        None => println!("cleared {count} memories"),
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::MemoryTypeConfig;

    #[test]
    fn test_clear_rejects_invalid_type() {
        // Validation must fail before touching the DB.
        let cfg = make_test_config();
        let result = run_validation(&cfg, Some("invalid"));
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("invalid --type"));
    }

    #[test]
    fn test_clear_accepts_valid_types() {
        let cfg = make_test_config();
        let names: Vec<String> = cfg.memory_types.iter().map(|t| t.classification.clone()).collect();
        for t in &names {
            assert!(run_validation(&cfg, Some(t)).is_ok(), "expected {t} to be valid");
        }
    }

    #[test]
    fn test_clear_accepts_none() {
        let cfg = make_test_config();
        assert!(run_validation(&cfg, None).is_ok());
    }

    /// Runs only the validation portion of `run` without touching the DB.
    fn run_validation(cfg: &Config, memory_type: Option<&str>) -> Result<()> {
        if let Some(t) = memory_type {
            if cfg.memory_type(t).is_none() {
                let valid_types: Vec<&str> = cfg.memory_types.iter().map(|mt| mt.classification.as_str()).collect();
                anyhow::bail!(
                    "invalid --type '{}'; must be one of: {}",
                    t,
                    valid_types.join(", ")
                );
            }
        }
        Ok(())
    }

    /// Create a test config with default memory types.
    fn make_test_config() -> Config {
        Config {
            db_path: std::path::PathBuf::from("/tmp/test.db"),
            memory_path: std::path::PathBuf::from("/tmp/memories"),
            model_path: None,
            query_prefix: None,
            passage_prefix: None,
            indexed_paths: vec![],
            scoring: crate::config::ScoringConfig::default(),
            strength_weights: crate::config::StrengthWeights::default(),
            memory_types: vec![
                MemoryTypeConfig {
                    classification: "episodic".to_string(),
                    description: "Short-lived observations.".to_string(),
                    importance: 0.4,
                    decay_rate: 0.05,
                },
                MemoryTypeConfig {
                    classification: "preference".to_string(),
                    description: "Standing user preferences.".to_string(),
                    importance: 0.8,
                    decay_rate: 0.0,
                },
                MemoryTypeConfig {
                    classification: "fact".to_string(),
                    description: "Stable factual knowledge.".to_string(),
                    importance: 0.7,
                    decay_rate: 0.0,
                },
            ],
        }
    }
}
