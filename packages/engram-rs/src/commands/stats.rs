use crate::commands::list::classification_label;
use crate::config::Config;
use crate::db;
use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use owo_colors::OwoColorize;
use serde::Serialize;
use std::collections::HashMap;

/// Arguments for the `stats` command.
pub struct StatsArgs {
    /// Output as JSON.
    pub json: bool,
}

#[derive(Serialize)]
struct JsonStrengthStats {
    min: f64,
    max: f64,
    mean: f64,
    median: f64,
}

#[derive(Serialize)]
struct JsonTypeCount {
    classification: String,
    count: i64,
}

#[derive(Serialize)]
struct JsonFileTypeCount {
    doc_type: String,
    count: i64,
}

#[derive(Serialize)]
struct JsonStats {
    model: JsonModel,
    memories: JsonMemorySection,
    indexed: JsonIndexedSection,
    aggregates: JsonAggregates,
}

#[derive(Serialize)]
struct JsonMemorySection {
    total: i64,
    by_type: Vec<JsonTypeCount>,
    strength: Option<JsonStrengthStats>,
    decayable: i64,
    near_threshold: i64,
    total_bytes: Option<i64>,
    oldest: Option<String>,
    newest: Option<String>,
}

#[derive(Serialize)]
struct JsonIndexedSection {
    total: i64,
    by_type: Vec<JsonTypeCount>,
    file_types: Vec<JsonFileTypeCount>,
    strength: Option<JsonStrengthStats>,
    total_bytes: Option<i64>,
    oldest: Option<String>,
    newest: Option<String>,
}

#[derive(Serialize)]
struct JsonAggregates {
    total_documents: i64,
    db_size_bytes: Option<u64>,
}

#[derive(Serialize)]
struct JsonModel {
    model: String,
    dimensions: usize,
}

/// Represents a value in the stats output tree.
enum StatValue {
    Count(i64),
    Bytes(u64),
    Date(String),
    Text(String),
    LabeledWithCount(String, usize, i64), // classification + idx + count
    Strength(f64, f64, f64, f64), // min, max, mean, median
    Section(Vec<(String, StatValue)>), // named sub-section
}

/// A top-level section in the stats output.
struct StatSection {
    label: String,
    total: Option<StatValue>,           // shown on the header line
    entries: Vec<(String, StatValue)>,  // key → value pairs
}

/// Execute the `stats` command.
///
/// Prints statistics in three sections: memories, indexed documents, and
/// overall aggregates.
pub fn run(cfg: &Config, args: StatsArgs) -> Result<()> {
    let conn = db::open(&cfg.db_path)?;
    let s = db::stats(&conn, &cfg.db_path, cfg.scoring.decay_threshold)
        .context("failed to gather statistics")?;

    let model_name = db::kv_get(&conn, "embedding_model")
        .context("failed to read embedding model from db")?
        .unwrap_or_else(|| "unknown".to_string());
    let model_dim: usize = db::kv_get(&conn, "embedding_dim")
        .context("failed to read embedding dim from db")?
        .and_then(|v| v.parse().ok())
        .unwrap_or(0);

    let memory_types: Vec<&db::TypeCount> =
        s.by_type.iter().filter(|t| t.is_memory).collect();
    let indexed_types: Vec<&db::TypeCount> =
        s.by_type.iter().filter(|t| !t.is_memory).collect();

    if args.json {
        let out = JsonStats {
            model: JsonModel { model: model_name, dimensions: model_dim },
            memories: JsonMemorySection {
                total: s.total_memories,
                by_type: memory_types
                    .iter()
                    .map(|t| JsonTypeCount {
                        classification: t.classification.clone(),
                        count: t.count,
                    })
                    .collect(),
                strength: s.strength.as_ref().map(|st| JsonStrengthStats {
                    min: st.min,
                    max: st.max,
                    mean: st.mean,
                    median: st.median,
                }),
                decayable: s.decayable_count,
                near_threshold: s.near_threshold_count,
                total_bytes: s.memory_size.as_ref().map(|sz| sz.total_bytes),
                oldest: s.memory_size.as_ref().map(|sz| {
                    DateTime::<Utc>::from_timestamp(sz.oldest_mtime, 0)
                        .map(|dt| dt.format("%Y-%m-%d").to_string())
                        .unwrap_or_else(|| "unknown".to_string())
                }),
                newest: s.memory_size.as_ref().map(|sz| {
                    DateTime::<Utc>::from_timestamp(sz.newest_mtime, 0)
                        .map(|dt| dt.format("%Y-%m-%d").to_string())
                        .unwrap_or_else(|| "unknown".to_string())
                }),
            },
            indexed: JsonIndexedSection {
                total: s.total_indexed,
                by_type: indexed_types
                    .iter()
                    .map(|t| JsonTypeCount {
                        classification: t.classification.clone(),
                        count: t.count,
                    })
                    .collect(),
                file_types: s.indexed_file_types
                    .iter()
                    .map(|ft| JsonFileTypeCount {
                        doc_type: ft.doc_type.clone(),
                        count: ft.count,
                    })
                    .collect(),
                strength: s.indexed_strength.as_ref().map(|st| JsonStrengthStats {
                    min: st.min,
                    max: st.max,
                    mean: st.mean,
                    median: st.median,
                }),
                total_bytes: s.indexed_size.as_ref().map(|sz| sz.total_bytes),
                oldest: s.indexed_size.as_ref().map(|sz| {
                    DateTime::<Utc>::from_timestamp(sz.oldest_mtime, 0)
                        .map(|dt| dt.format("%Y-%m-%d").to_string())
                        .unwrap_or_else(|| "unknown".to_string())
                }),
                newest: s.indexed_size.as_ref().map(|sz| {
                    DateTime::<Utc>::from_timestamp(sz.newest_mtime, 0)
                        .map(|dt| dt.format("%Y-%m-%d").to_string())
                        .unwrap_or_else(|| "unknown".to_string())
                }),
            },
            aggregates: JsonAggregates {
                total_documents: s.total_memories + s.total_indexed,
                db_size_bytes: s.db_size_bytes,
            },
        };
        println!(
            "{}",
            serde_json::to_string_pretty(&out).context("failed to serialize stats")?
        );
    } else {
        let use_color = crate::color_enabled();

        // Map each configured memory type name to its palette index (same as list).
        let type_index: HashMap<&str, usize> = cfg
            .memory_types
            .iter()
            .enumerate()
            .map(|(i, t)| (t.classification.as_str(), i))
            .collect();

        // Map each configured indexed path classification to its palette index.
        let indexed_type_index: HashMap<&str, usize> = cfg
            .indexed_paths
            .iter()
            .enumerate()
            .map(|(i, p)| (p.classification.as_str(), i))
            .collect();

        // Build the stats tree
        let mut sections = Vec::new();

        // Model section
        sections.push(StatSection {
            label: "model".to_string(),
            total: None,
            entries: vec![
                ("name".to_string(), StatValue::Text(model_name.clone())),
                ("dimensions".to_string(), StatValue::Count(model_dim as i64)),
            ],
        });

        // Memories section
        let mut memory_entries = Vec::new();

        if !memory_types.is_empty() {
            // Create types subsection with classification + index + count
            let type_subsection: Vec<(String, StatValue)> = memory_types
                .iter()
                .map(|t| {
                    let idx = type_index.get(t.classification.as_str()).copied().unwrap_or(5);
                    (
                        t.classification.clone(),
                        StatValue::LabeledWithCount(t.classification.clone(), idx, t.count),
                    )
                })
                .collect();

            memory_entries.push(("types".to_string(), StatValue::Section(type_subsection)));
        }

        if let Some(sz) = &s.memory_size {
            memory_entries.push(("size".to_string(), StatValue::Bytes(sz.total_bytes as u64)));
            let oldest_date = DateTime::<Utc>::from_timestamp(sz.oldest_mtime, 0)
                .map(|dt| dt.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "unknown".to_string());
            let newest_date = DateTime::<Utc>::from_timestamp(sz.newest_mtime, 0)
                .map(|dt| dt.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "unknown".to_string());
            memory_entries.push(("oldest".to_string(), StatValue::Date(oldest_date)));
            memory_entries.push(("newest".to_string(), StatValue::Date(newest_date)));
        }

        if let Some(st) = &s.strength {
            memory_entries.push(("strength".to_string(), StatValue::Strength(st.min, st.max, st.mean, st.median)));
        }

        memory_entries.push((
            "decayable".to_string(),
            StatValue::Text(format!("{} ({} near threshold)", s.decayable_count, s.near_threshold_count)),
        ));

        sections.push(StatSection {
            label: "memories".to_string(),
            total: Some(StatValue::Count(s.total_memories)),
            entries: memory_entries,
        });

        // Indexed section
        let mut indexed_entries = Vec::new();

        if !indexed_types.is_empty() {
            indexed_entries.push((
                "types".to_string(),
                StatValue::Section(
                    indexed_types
                        .iter()
                        .map(|t| {
                            let idx = indexed_type_index
                                .get(t.classification.as_str())
                                .copied()
                                .unwrap_or(5);
                            (
                                t.classification.clone(),
                                StatValue::LabeledWithCount(t.classification.clone(), idx, t.count),
                            )
                        })
                        .collect(),
                ),
            ));
        }

        if !s.indexed_file_types.is_empty() {
            indexed_entries.push((
                "file types".to_string(),
                StatValue::Section(
                    s.indexed_file_types
                        .iter()
                        .map(|ft| (ft.doc_type.clone(), StatValue::Count(ft.count)))
                        .collect(),
                ),
            ));
        }

        if let Some(sz) = &s.indexed_size {
            indexed_entries.push(("size".to_string(), StatValue::Bytes(sz.total_bytes as u64)));
            let oldest_date = DateTime::<Utc>::from_timestamp(sz.oldest_mtime, 0)
                .map(|dt| dt.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "unknown".to_string());
            let newest_date = DateTime::<Utc>::from_timestamp(sz.newest_mtime, 0)
                .map(|dt| dt.format("%Y-%m-%d").to_string())
                .unwrap_or_else(|| "unknown".to_string());
            indexed_entries.push(("oldest".to_string(), StatValue::Date(oldest_date)));
            indexed_entries.push(("newest".to_string(), StatValue::Date(newest_date)));
        }

        if let Some(st) = &s.indexed_strength {
            indexed_entries.push(("strength".to_string(), StatValue::Strength(st.min, st.max, st.mean, st.median)));
        }

        sections.push(StatSection {
            label: "indexed".to_string(),
            total: Some(StatValue::Count(s.total_indexed)),
            entries: indexed_entries,
        });

        // Totals section
        let mut totals_entries = Vec::new();
        totals_entries.push(("documents".to_string(), StatValue::Count(s.total_memories + s.total_indexed)));
        if let Some(bytes) = s.db_size_bytes {
            totals_entries.push(("db size".to_string(), StatValue::Bytes(bytes)));
        }

        sections.push(StatSection {
            label: "totals".to_string(),
            total: None,
            entries: totals_entries,
        });

        // Render all sections
        render_stats(&sections, use_color);
    }

    Ok(())
}

/// Format a byte count as a human-readable string.
fn format_bytes(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;
    if bytes >= GB {
        format!("{:.1} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.1} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.1} KB", bytes as f64 / KB as f64)
    } else {
        format!("{bytes} B")
    }
}

/// Render a StatValue with appropriate formatting and coloring.
fn format_stat_value(
    value: &StatValue,
    use_color: bool,
) -> String {
    match value {
        StatValue::Count(n) => {
            if use_color {
                n.to_string().cyan().to_string()
            } else {
                n.to_string()
            }
        }
        StatValue::Bytes(bytes) => {
            let formatted = format_bytes(*bytes);
            if use_color {
                formatted.dimmed().to_string()
            } else {
                formatted
            }
        }
        StatValue::Date(date) => {
            if use_color {
                date.dimmed().to_string()
            } else {
                date.clone()
            }
        }
        StatValue::Text(text) => text.clone(),
        StatValue::LabeledWithCount(classification, idx, _count) => {
            if use_color {
                classification_label(&format!("{}:", classification), *idx)
            } else {
                format!("{}:", classification)
            }
        }
        StatValue::Strength(min, max, mean, median) => {
            let formatted = format!(
                "min={:.3}  max={:.3}  mean={:.3}  median={:.3}",
                min, max, mean, median
            );
            if use_color {
                formatted.cyan().to_string()
            } else {
                formatted
            }
        }
        StatValue::Section(_) => String::new(), // handled separately
    }
}

/// Render stats sections with proper indentation and formatting.
fn render_stats(
    sections: &[StatSection],
    use_color: bool,
) {
    for (section_idx, section) in sections.iter().enumerate() {
        // Section header: bold label + optional total
        let header = if use_color {
            format!("{}:", section.label).bold().to_string()
        } else {
            format!("{}:", section.label)
        };

        if let Some(ref total) = section.total {
            let total_str = format_stat_value(total, use_color);
            println!("{} {}", header, total_str);
        } else {
            println!("{}", header);
        }

        // Entries
        for (key, value) in &section.entries {
            match value {
                StatValue::Section(subsection) => {
                    // Subsection header: indent 2, dimmed
                    let header = if use_color {
                        format!("{}:", key).dimmed().to_string()
                    } else {
                        format!("{}:", key)
                    };
                    println!("  {}", header);

                    // Subsection entries: indent 4
                    for (subkey, subvalue) in subsection {
                        match subvalue {
                            StatValue::LabeledWithCount(classification, idx, count) => {
                                // Render labeled type with its count
                                let label = if use_color {
                                    classification_label(&format!("{}:", classification), *idx)
                                } else {
                                    format!("{}:", classification)
                                };
                                let count_str = if use_color {
                                    count.to_string().cyan().to_string()
                                } else {
                                    count.to_string()
                                };
                                println!("    {}  {}", label, count_str);
                            }
                            _ => {
                                let formatted = format_stat_value(subvalue, use_color);
                                println!("    {}  {}", subkey, formatted);
                            }
                        }
                    }
                }
                _ => {
                    // Regular entry: indent 2
                    let formatted = format_stat_value(value, use_color);
                    let key_str = if use_color {
                        format!("{}:", key).dimmed().to_string()
                    } else {
                        format!("{}:", key)
                    };
                    println!("  {}  {}", key_str, formatted);
                }
            }
        }

        // Blank line between sections (but not after the last one)
        if section_idx < sections.len() - 1 {
            println!();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_bytes_b() {
        assert_eq!(format_bytes(512), "512 B");
    }

    #[test]
    fn test_format_bytes_kb() {
        assert_eq!(format_bytes(2048), "2.0 KB");
    }

    #[test]
    fn test_format_bytes_mb() {
        assert_eq!(format_bytes(3 * 1024 * 1024), "3.0 MB");
    }

    #[test]
    fn test_format_bytes_gb() {
        assert_eq!(format_bytes(2 * 1024 * 1024 * 1024), "2.0 GB");
    }
}
