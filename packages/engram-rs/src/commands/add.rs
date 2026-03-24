use crate::config::Config;
use crate::db::{self, UpsertOptions};
use crate::embed;
use anyhow::{bail, Context, Result};
use chrono::Utc;
use std::path::PathBuf;

/// Valid memory classification types.
const VALID_TYPES: &[&str] = &["episodic", "preference", "fact"];

/// Arguments for the `add` command.
pub struct AddArgs {
    pub memory_type: String,
    pub correlation_id: Option<String>,
    pub content: String,
}

/// Execute the `add` command.
///
/// Creates a markdown file under `<memory-path>/<type>/YYYY-MM-DD-HHmmss.md`,
/// embeds the content, and upserts the record into the database.
/// Prints the created file path to stdout.
pub fn run(cfg: &Config, args: AddArgs) -> Result<()> {
    if !VALID_TYPES.contains(&args.memory_type.as_str()) {
        bail!(
            "invalid --type '{}'; must be one of: {}",
            args.memory_type,
            VALID_TYPES.join(", ")
        );
    }

    let now = Utc::now();
    let timestamp = now.format("%Y-%m-%d-%H%M%S").to_string();
    let date_str = now.format("%Y-%m-%d").to_string();

    let dir = cfg.memory_path.join(&args.memory_type);
    std::fs::create_dir_all(&dir)
        .with_context(|| format!("failed to create directory {}", dir.display()))?;

    let filename = format!("{timestamp}.md");
    let file_path = dir.join(&filename);

    let frontmatter = build_frontmatter(&date_str, &args.memory_type, args.correlation_id.as_deref());
    let file_content = format!("{frontmatter}\n{}", args.content);

    std::fs::write(&file_path, &file_content)
        .with_context(|| format!("failed to write {}", file_path.display()))?;

    let mtime = file_path
        .metadata()
        .context("failed to stat new file")?
        .modified()
        .context("failed to get mtime")?
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;

    let embedding = embed::embed(&args.content).context("failed to embed content")?;

    let (importance, decay_rate) = metadata_for_type(&args.memory_type);
    let strength = compute_strength(importance, 1, 0.5, 0.5);

    let tags_json = format!(r#"["memory","{}"]"#, args.memory_type);

    let conn = db::open(&cfg.db_path)?;
    db::upsert(
        &conn,
        &file_path.to_string_lossy(),
        None,
        &args.content,
        mtime,
        Some("memory"),
        Some(&tags_json),
        &args.memory_type,
        importance,
        0.5,
        decay_rate,
        strength,
        &embedding,
        &UpsertOptions { force_metadata: true },
    )
    .context("failed to upsert memory into database")?;

    println!("{}", file_path.display());

    Ok(())
}

/// Build the YAML frontmatter block for a new memory file.
fn build_frontmatter(date: &str, memory_type: &str, correlation_id: Option<&str>) -> String {
    let mut fm = format!("---\ncreated: {date}\n");
    if let Some(cid) = correlation_id {
        fm.push_str(&format!("correlation_id: {cid}\n"));
    }
    fm.push_str(&format!(
        "tags:\n  - memory\n  - {memory_type}\ntype: memory\n---\n"
    ));
    fm
}

/// Return (importance, decay_rate) for a given memory type.
pub fn metadata_for_type(memory_type: &str) -> (f64, f64) {
    match memory_type {
        "preference" => (0.8, 0.0),
        "fact" => (0.7, 0.0),
        _ => (0.4, 0.05), // episodic
    }
}

/// Compute memory strength using the 7-feature model.
///
/// - recency: 0.0 (always fresh on add)
/// - frequency_score: min(1.0, ln(frequency + 1) / ln(10))
/// - importance: per type
/// - utility: 0.5
/// - novelty: 0.5
/// - confidence: 0.5
/// - interference: 0.0
pub fn compute_strength(importance: f64, frequency: u64, confidence: f64, _utility: f64) -> f64 {
    let recency = 0.0_f64;
    let frequency_score = (1.0_f64).min(((frequency as f64 + 1.0).ln()) / (10.0_f64).ln());
    let utility = 0.5_f64;
    let novelty = 0.5_f64;
    let interference = 0.0_f64;

    let strength = recency * 0.20
        + frequency_score * 0.15
        + importance * 0.25
        + utility * 0.20
        + novelty * 0.10
        + confidence * 0.10
        + interference * (-0.10);

    strength.clamp(0.0, 1.0)
}

/// Resolve the file path that `add` would create, without creating it.
/// Useful for testing.
#[allow(dead_code)]
pub fn preview_path(memory_path: &PathBuf, memory_type: &str) -> PathBuf {
    let now = Utc::now();
    let timestamp = now.format("%Y-%m-%d-%H%M%S").to_string();
    memory_path.join(memory_type).join(format!("{timestamp}.md"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_build_frontmatter_without_correlation() {
        let fm = build_frontmatter("2026-01-01", "episodic", None);
        assert!(fm.contains("created: 2026-01-01"));
        assert!(fm.contains("- episodic"));
        assert!(!fm.contains("correlation_id"));
    }

    #[test]
    fn test_build_frontmatter_with_correlation() {
        let fm = build_frontmatter("2026-01-01", "fact", Some("session-42"));
        assert!(fm.contains("correlation_id: session-42"));
    }

    #[test]
    fn test_metadata_for_type() {
        let (imp, decay) = metadata_for_type("preference");
        assert_eq!(imp, 0.8);
        assert_eq!(decay, 0.0);

        let (imp, decay) = metadata_for_type("fact");
        assert_eq!(imp, 0.7);
        assert_eq!(decay, 0.0);

        let (imp, decay) = metadata_for_type("episodic");
        assert_eq!(imp, 0.4);
        assert_eq!(decay, 0.05);
    }

    #[test]
    fn test_compute_strength_clamped() {
        let s = compute_strength(1.0, 100, 1.0, 1.0);
        assert!(s <= 1.0);
        assert!(s >= 0.0);
    }
}
