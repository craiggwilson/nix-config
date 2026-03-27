use crate::commands::list::classification_label;
use crate::config::{Config, IndexedPathConfig, MemoryTypeConfig, ScoringConfig, StrengthWeights};
use anyhow::{Context, Result};
use owo_colors::OwoColorize;
use serde::Serialize;
use std::collections::HashMap;
use toml;

/// Arguments for the `config` command.
pub struct ConfigArgs {
    pub json: bool,
}

/// Full configuration view for display.
#[derive(Serialize)]
struct ConfigView<'a> {
    db_path: String,
    memory_path: String,
    model_path: Option<String>,
    query_prefix: Option<String>,
    passage_prefix: Option<String>,
    indexed_paths: Vec<IndexedPathView>,
    scoring: &'a ScoringConfig,
    strength_weights: &'a StrengthWeights,
    memory_types: Vec<MemoryTypeView<'a>>,
}

/// Serializable view of an indexed path entry.
#[derive(Serialize)]
struct IndexedPathView {
    path: String,
    classification: String,
    strength: f64,
}

impl From<&IndexedPathConfig> for IndexedPathView {
    fn from(c: &IndexedPathConfig) -> Self {
        Self {
            path: c.path.clone(),
            classification: c.classification.clone(),
            strength: c.strength,
        }
    }
}

/// Per-type view including all fields.
#[derive(Serialize)]
struct MemoryTypeView<'a> {
    classification: &'a str,
    description: &'a str,
    importance: f64,
    decay_rate: f64,
}

impl<'a> MemoryTypeView<'a> {
    fn from(t: &'a MemoryTypeConfig) -> Self {
        Self {
            classification: &t.classification,
            description: &t.description,
            importance: t.importance,
            decay_rate: t.decay_rate,
        }
    }
}

/// Post-process the top-level toml::Value for display special cases.
/// Since Option::None serializes as absent in TOML, no cleanup is needed.
fn post_process_toml(_value: &mut toml::Value) {
    // No-op: None values serialize as absent automatically.
}

/// Emit a toml::Value tree as colored TOML text.
/// `path` is the dotted key path to the current node (for table headers).
fn emit_toml(value: &toml::Value, path: &[String], use_color: bool, classification_index: &HashMap<String, usize>) {
    match value {
        toml::Value::Table(table) => {
            if !path.is_empty() {
                // Emit table header for non-root tables
                let path_str = path.join(".");
                let header = format!("[{}]", path_str);
                let header_str = if use_color {
                    header.bold().to_string()
                } else {
                    header
                };
                println!("{}", header_str);
            }

            // Collect and sort: scalars first, then tables/arrays
            let mut scalars: Vec<(&String, &toml::Value)> = table
                .iter()
                .filter(|(_, v)| !v.is_table() && !v.is_array())
                .collect();
            let mut tables: Vec<(&String, &toml::Value)> = table
                .iter()
                .filter(|(_, v)| v.is_table())
                .collect();
            let mut arrays: Vec<(&String, &toml::Value)> = table
                .iter()
                .filter(|(_, v)| v.is_array())
                .collect();
            scalars.sort_by_key(|(k, _)| k.as_str());
            tables.sort_by_key(|(k, _)| k.as_str());
            arrays.sort_by_key(|(k, _)| k.as_str());

            // Emit scalar key-value pairs
            for (k, v) in scalars.iter() {
                emit_scalar(k, v, use_color, classification_index);
            }

            // Emit arrays — one blank line before if there were scalars
            for (i, (k, v)) in arrays.iter().enumerate() {
                if i == 0 && !scalars.is_empty() {
                    println!();
                } else if i > 0 {
                    println!();
                }
                emit_array(k, v, path, use_color, classification_index);
            }

            // Emit nested tables — exactly one blank line before each
            for (k, v) in tables.iter() {
                println!();
                let mut new_path = path.to_vec();
                new_path.push((*k).clone());
                emit_toml(v, &new_path, use_color, classification_index);
            }
        }
        _ => {
            // Leaf node at root (shouldn't happen in normal TOML)
        }
    }
}

/// Emit an array (array of tables or simple array).
fn emit_array(key: &str, value: &toml::Value, path: &[String], use_color: bool, classification_index: &HashMap<String, usize>) {
    if let toml::Value::Array(arr) = value {
        // Check if array contains tables (array of tables)
        if !arr.is_empty() && arr[0].is_table() {
            // Array of tables: emit as [[key]]
            for (idx, item) in arr.iter().enumerate() {
                let mut new_path = path.to_vec();
                new_path.push(key.to_string());
                
                let path_str = new_path.join(".");
                let header = format!("[[{}]]", path_str);
                let header_str = if use_color {
                    header.bold().to_string()
                } else {
                    header
                };
                println!("{}", header_str);
                
                if let toml::Value::Table(table) = item {
                    let mut keys: Vec<_> = table.keys().collect();
                    keys.sort();
                    for k in keys {
                        if let Some(v) = table.get(k) {
                            emit_scalar(k, v, use_color, classification_index);
                        }
                    }
                }
                
                if idx < arr.len() - 1 {
                    println!();
                }
            }
        } else {
            // Simple array: print as key = [...]
            let key_str = if use_color {
                format!("{} =", key).dimmed().to_string()
            } else {
                format!("{} =", key)
            };
            
            let val_str = format!(
                "[{}]",
                arr.iter()
                    .map(|v| match v {
                        toml::Value::String(s) => format!("\"{}\"", s),
                        toml::Value::Boolean(b) => b.to_string(),
                        toml::Value::Integer(i) => i.to_string(),
                        toml::Value::Float(f) => f.to_string(),
                        _ => "(unknown)".to_string(),
                    })
                    .collect::<Vec<_>>()
                    .join(", ")
            );
            
            println!("{} {}", key_str, val_str);
        }
    }
}

/// Emit a single scalar key-value pair.
fn emit_scalar(key: &str, value: &toml::Value, use_color: bool, classification_index: &HashMap<String, usize>) {
    let key_str = if use_color {
        format!("{} =", key).dimmed().to_string()
    } else {
        format!("{} =", key)
    };

    let val_str = match value {
        toml::Value::Boolean(b) => {
            if use_color {
                b.to_string().cyan().to_string()
            } else {
                b.to_string()
            }
        }
        toml::Value::Integer(i) => {
            if use_color {
                i.to_string().yellow().to_string()
            } else {
                i.to_string()
            }
        }
        toml::Value::Float(f) => {
            if use_color {
                f.to_string().yellow().to_string()
            } else {
                f.to_string()
            }
        }
        toml::Value::String(s) => {
            if key == "classification" {
                let idx = classification_index.get(s.as_str()).copied()
                    .unwrap_or_else(|| s.bytes().fold(0usize, |a, b| a.wrapping_add(b as usize)) % 6);
                if use_color {
                    classification_label(&format!("\"{}\"", s), idx)
                } else {
                    format!("\"{}\"", s)
                }
            } else {
                format!("\"{}\"", s)
            }
        }
        _ => "(unknown)".to_string(),
    };

    println!("{} {}", key_str, val_str);
}

/// Execute the `config` command.
///
/// Prints the active configuration (merging file config, CLI flags, and
/// built-in defaults), either as JSON or in a human-readable format.
/// Useful for inspecting effective defaults and sharing them with other tools.
pub fn run(cfg: &Config, args: ConfigArgs) -> Result<()> {
    let view = ConfigView {
        db_path: cfg.db_path.to_string_lossy().into_owned(),
        memory_path: cfg.memory_path.to_string_lossy().into_owned(),
        model_path: cfg.model_path.as_ref().map(|p| p.to_string_lossy().into_owned()),
        query_prefix: cfg.query_prefix.clone(),
        passage_prefix: cfg.passage_prefix.clone(),
        indexed_paths: cfg.indexed_paths.iter().map(IndexedPathView::from).collect(),
        scoring: &cfg.scoring,
        strength_weights: &cfg.strength_weights,
        memory_types: cfg.memory_types.iter().map(MemoryTypeView::from).collect(),
    };

    if args.json {
        let output =
            serde_json::to_string_pretty(&view).context("failed to serialize config to JSON")?;
        println!("{output}");
    } else {
        let use_color = crate::color_enabled();

        // Build classification index from both memory types and indexed paths
        let mut classification_index: HashMap<String, usize> = HashMap::new();
        for (i, t) in cfg.memory_types.iter().enumerate() {
            classification_index.insert(t.classification.clone(), i);
        }
        for (i, p) in cfg.indexed_paths.iter().enumerate() {
            classification_index.insert(p.classification.clone(), i);
        }

        // Serialize entire config view to TOML
        let mut toml_value = toml::Value::try_from(&view)
            .context("failed to serialize config to TOML")?;
        
        // Post-process to handle special cases
        post_process_toml(&mut toml_value);
        
        // Emit the colored TOML
        emit_toml(&toml_value, &[], use_color, &classification_index);
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
            indexed_paths: vec![IndexedPathConfig {
                path: "/tmp/notes".to_string(),
                classification: "indexed".to_string(),
                strength: 0.8,
            }],
            scoring: ScoringConfig::default(),
            strength_weights: StrengthWeights::default(),
            memory_types: vec![MemoryTypeConfig {
                classification: "episodic".to_string(),
                description: "Short-lived observations.".to_string(),
                importance: 0.4,
                decay_rate: 0.05,
            }],
        }
    }

    #[test]
    fn test_run_human() {
        assert!(run(&test_cfg(), ConfigArgs { json: false }).is_ok());
    }

    #[test]
    fn test_run_json() {
        assert!(run(&test_cfg(), ConfigArgs { json: true }).is_ok());
    }

    #[test]
    fn test_json_contains_all_sections() {
        let cfg = test_cfg();
        let view = ConfigView {
            db_path: cfg.db_path.to_string_lossy().into_owned(),
            memory_path: cfg.memory_path.to_string_lossy().into_owned(),
            model_path: cfg.model_path.as_ref().map(|p| p.to_string_lossy().into_owned()),
            query_prefix: cfg.query_prefix.clone(),
            passage_prefix: cfg.passage_prefix.clone(),
            indexed_paths: cfg.indexed_paths.iter().map(IndexedPathView::from).collect(),
            scoring: &cfg.scoring,
            strength_weights: &cfg.strength_weights,
            memory_types: cfg.memory_types.iter().map(MemoryTypeView::from).collect(),
        };

        let json = serde_json::to_string(&view).unwrap();
        assert!(json.contains("db_path"));
        assert!(json.contains("model_path"));
        // query_prefix and passage_prefix will be null since they're None
        assert!(json.contains("query_prefix"));
        assert!(json.contains("passage_prefix"));
        assert!(json.contains("scoring"));
        assert!(json.contains("strength_weights"));
        assert!(json.contains("memory_types"));
        assert!(json.contains("episodic"));
        assert!(json.contains("indexed_paths"));
        assert!(json.contains("classification"));
        assert!(json.contains("strength"));
    }
}
