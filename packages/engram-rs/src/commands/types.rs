use crate::config::Config;
use anyhow::{Context, Result};
use serde::Serialize;

/// Arguments for the `types` command.
pub struct TypesArgs {
    pub json: bool,
}

/// A single memory type entry for JSON serialization.
#[derive(Serialize)]
pub struct JsonType {
    pub name: String,
    pub description: String,
}

/// Execute the `types` command.
///
/// Prints the configured memory types and their descriptions, either as a
/// human-readable list or as a JSON array suitable for use by a classifier.
pub fn run(cfg: &Config, args: TypesArgs) -> Result<()> {
    if args.json {
        let entries: Vec<JsonType> = cfg
            .memory_types
            .iter()
            .map(|t| JsonType {
                name: t.classification.clone(),
                description: t.description.clone(),
            })
            .collect();

        let output =
            serde_json::to_string_pretty(&entries).context("failed to serialize types to JSON")?;
        println!("{output}");
    } else {
        let use_color = crate::color_enabled();

        for (idx, t) in cfg.memory_types.iter().enumerate() {
            if use_color {
                let cls_str = format!("[{}]", t.classification);
                println!(
                    "{} {}",
                    super::list::classification_label(&cls_str, idx),
                    t.description
                );
            } else {
                println!("{}: {}", t.classification, t.description);
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{MemoryTypeConfig, ScoringConfig, StrengthWeights};

    fn test_cfg() -> Config {
        Config {
            db_path: std::path::PathBuf::from("/tmp/test.db"),
            memory_path: std::path::PathBuf::from("/tmp/memories"),
            model_path: None,
            query_prefix: None,
            passage_prefix: None,
            indexed_paths: vec![],
            scoring: ScoringConfig::default(),
            strength_weights: StrengthWeights::default(),
            memory_types: vec![
                MemoryTypeConfig {
                    classification: "episodic".to_string(),
                    description: "Short-lived observations.".to_string(),
                    importance: 0.4,
                    decay_rate: 0.05,
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

    #[test]
    fn test_json_output_excludes_scoring_fields() {
        let cfg = test_cfg();
        let entries: Vec<JsonType> = cfg
            .memory_types
            .iter()
            .map(|t| JsonType {
                name: t.classification.clone(),
                description: t.description.clone(),
            })
            .collect();

        let json = serde_json::to_string(&entries).unwrap();
        assert!(json.contains("episodic"));
        assert!(json.contains("Short-lived observations."));
        assert!(!json.contains("importance"));
        assert!(!json.contains("decay_rate"));
    }

    #[test]
    fn test_run_human() {
        let cfg = test_cfg();
        assert!(run(&cfg, TypesArgs { json: false }).is_ok());
    }

    #[test]
    fn test_run_json() {
        let cfg = test_cfg();
        assert!(run(&cfg, TypesArgs { json: true }).is_ok());
    }
}
