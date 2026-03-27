use crate::config::Config;
use crate::db;
use anyhow::{Context, Result};

/// Arguments for the `maintain` command.
pub struct MaintainArgs;

/// Execute the `maintain` command.
///
/// Applies Ebbinghaus forgetting curve decay to all memories whose type has a
/// non-zero decay rate. Memories whose strength drops below the configured
/// threshold are deleted. Then updates the corpus mean. Prints a summary of how
/// many memories were decayed.
pub fn run(cfg: &Config, _args: MaintainArgs) -> Result<()> {
    let conn = db::open(&cfg.db_path)?;

    let decayable = db::all_decayable(&conn).context("failed to load decayable memories")?;

    let now = now_unix();
    let mut decayed = 0usize;

    for (id, path, strength, decay_rate, last_accessed) in decayable {
        let hours_since = hours_elapsed(last_accessed, now);
        let new_strength = apply_decay(strength, decay_rate, hours_since);

        if new_strength < cfg.scoring.decay_threshold {
            db::delete_by_id(&conn, id)
                .with_context(|| format!("failed to delete decayed memory {path}"))?;
            // Remove the file from disk if it lives under memory_path, so it
            // isn't resurrected on the next ingest.
            let file_path = std::path::Path::new(&path);
            if file_path.starts_with(&cfg.memory_path) && file_path.exists() {
                std::fs::remove_file(file_path).with_context(|| {
                    format!("failed to delete decayed memory file {path}")
                })?;
            }
        } else {
            db::update_strength(&conn, id, new_strength)
                .with_context(|| format!("failed to update strength for {path}"))?;
        }

        decayed += 1;
    }

    println!("decayed {decayed} memories");

    db::update_corpus_mean(&conn).context("failed to update corpus mean")?;

    Ok(())
}

/// Apply Ebbinghaus forgetting curve: `strength * exp(-decay_rate * hours)`.
pub fn apply_decay(strength: f64, decay_rate: f64, hours: f64) -> f64 {
    strength * (-decay_rate * hours).exp()
}

/// Compute elapsed hours between a Unix timestamp and now.
fn hours_elapsed(last_accessed: i64, now: i64) -> f64 {
    let secs = (now - last_accessed).max(0) as f64;
    secs / 3600.0
}

/// Current Unix timestamp in seconds.
fn now_unix() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_apply_decay_zero_rate() {
        // Zero decay rate means no decay.
        assert!((apply_decay(0.8, 0.0, 100.0) - 0.8).abs() < 1e-9);
    }

    #[test]
    fn test_apply_decay_reduces_strength() {
        let new = apply_decay(1.0, 0.05, 24.0);
        assert!(new < 1.0);
        assert!(new > 0.0);
    }

    #[test]
    fn test_apply_decay_below_threshold() {
        // After enough time, strength should drop below threshold (0.05).
        let new = apply_decay(0.06, 0.05, 1000.0);
        assert!(new < 0.05);
    }

    #[test]
    fn test_hours_elapsed() {
        let elapsed = hours_elapsed(0, 7200);
        assert!((elapsed - 2.0).abs() < 1e-9);
    }
}
