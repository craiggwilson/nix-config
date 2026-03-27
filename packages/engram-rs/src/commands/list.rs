use crate::config::Config;
use crate::db;
use anyhow::{bail, Result};
use owo_colors::OwoColorize;
use serde::Serialize;
use std::collections::HashMap;

/// Arguments for the `list` command.
pub struct ListArgs {
    /// If Some, only list memories of this classification.
    pub memory_type: Option<String>,
    /// Output as JSON array.
    pub json: bool,
}

#[derive(Serialize)]
struct JsonRecord {
    id: i64,
    path: String,
    classification: String,
    is_memory: bool,
    strength: f64,
    snippet: String,
}

/// Execute the `list` command.
///
/// Displays all memories in the database, optionally filtered by classification.
/// Results are ordered by strength descending. Output can be formatted as
/// human-readable text or JSON.
pub fn run(cfg: &Config, args: ListArgs) -> Result<()> {
    if let Some(ref t) = args.memory_type {
        if cfg.memory_type(t).is_none() {
            let valid: Vec<&str> = cfg.memory_types.iter().map(|mt| mt.classification.as_str()).collect();
            bail!("invalid --type '{}'; must be one of: {}", t, valid.join(", "));
        }
    }

    let conn = db::open(&cfg.db_path)?;
    let records = db::list_all(&conn, args.memory_type.as_deref())?;

    if args.json {
        let out: Vec<JsonRecord> = records
            .iter()
            .map(|r| JsonRecord {
                id: r.id,
                path: r.path.clone(),
                classification: r.classification.clone(),
                is_memory: r.is_memory,
                strength: r.strength,
                snippet: truncate(&r.content, 200),
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&out)?);
    } else {
        if records.is_empty() {
            println!("No memories found.");
            return Ok(());
        }
        let use_color = crate::color_enabled();
        // Map each configured type name to its palette index.
        let type_index: HashMap<&str, usize> = cfg
            .memory_types
            .iter()
            .enumerate()
            .map(|(i, t)| (t.classification.as_str(), i))
            .collect();

        for r in records.iter() {
            let id_str = format!("{}.", r.id);
            let cls_str = format!("[{}]", r.classification);
            let strength_str = format!("(strength: {:.3})", r.strength);
            let snippet = truncate(&r.content, 200);

            if use_color {
                // Unknown types (not in config) get the last palette slot.
                let idx = type_index
                    .get(r.classification.as_str())
                    .copied()
                    .unwrap_or(5);
                println!(
                    "{} {} {} {}",
                    id_str.dimmed(),
                    classification_label(&cls_str, idx),
                    r.path,
                    strength_label(&strength_str, r.strength),
                );
                println!("   {}", snippet.dimmed());
            } else {
                println!("{} {} {} {}", id_str, cls_str, r.path, strength_str);
                println!("   {}", snippet);
            }
            println!();
        }
    }

    Ok(())
}

/// Apply a palette color by index to a bold string.
pub fn classification_label(s: &str, index: usize) -> String {
    // Palette cycles if there are more types than entries.
    match index % 6 {
        0 => s.bold().cyan().to_string(),
        1 => s.bold().green().to_string(),
        2 => s.bold().yellow().to_string(),
        3 => s.bold().magenta().to_string(),
        4 => s.bold().blue().to_string(),
        _ => s.bold().red().to_string(),
    }
}

/// Colored strength annotation: green ≥ 0.7, yellow ≥ 0.4, red below.
pub fn strength_label(s: &str, strength: f64) -> String {
    if strength >= 0.7 {
        s.green().to_string()
    } else if strength >= 0.4 {
        s.yellow().to_string()
    } else {
        s.red().to_string()
    }
}

/// Truncate text to max_chars, adding ellipsis if needed.
pub fn truncate(text: &str, max_chars: usize) -> String {
    let trimmed = text.trim();
    if trimmed.chars().count() <= max_chars {
        trimmed.to_string()
    } else {
        let s: String = trimmed.chars().take(max_chars).collect();
        format!("{s}…")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::MemoryTypeConfig;

    #[test]
    fn test_list_rejects_invalid_type() {
        let cfg = make_test_config();
        let result = run_validation(&cfg, Some("invalid"));
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("invalid --type"));
    }

    #[test]
    fn test_list_accepts_valid_types() {
        let cfg = make_test_config();
        let names: Vec<String> = cfg.memory_types.iter().map(|t| t.classification.clone()).collect();
        for t in &names {
            assert!(run_validation(&cfg, Some(t)).is_ok(), "expected {t} to be valid");
        }
    }

    #[test]
    fn test_list_accepts_none() {
        let cfg = make_test_config();
        assert!(run_validation(&cfg, None).is_ok());
    }

    #[test]
    fn test_truncate_short_text() {
        let text = "short";
        assert_eq!(truncate(text, 200), "short");
    }

    #[test]
    fn test_truncate_long_text() {
        let text = "a".repeat(250);
        let truncated = truncate(&text, 200);
        assert!(truncated.ends_with('…'));
        assert_eq!(truncated.chars().count(), 201); // 200 chars + ellipsis
    }

    /// Runs only the validation portion of `run` without touching the DB.
    fn run_validation(cfg: &Config, memory_type: Option<&str>) -> Result<()> {
        if let Some(t) = memory_type {
            if cfg.memory_type(t).is_none() {
                let valid: Vec<&str> = cfg.memory_types.iter().map(|mt| mt.classification.as_str()).collect();
                anyhow::bail!("invalid --type '{}'; must be one of: {}", t, valid.join(", "));
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
