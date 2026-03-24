use crate::config::Config;
use crate::db;
use anyhow::{Context, Result};

/// Minimum strength below which a memory is deleted.
const STRENGTH_THRESHOLD: f64 = 0.05;

/// Arguments for the `decay` command.
pub struct DecayArgs;

/// Execute the `decay` command.
///
/// Applies Ebbinghaus forgetting curve decay to all episodic memories.
/// Memories whose strength drops below the threshold are deleted.
/// Prints a summary of how many memories were decayed.
pub fn run(cfg: &Config, _args: DecayArgs) -> Result<()> {
    let conn = db::open(&cfg.db_path)?;

    let episodic = db::all_episodic(&conn).context("failed to load episodic memories")?;

    let now = now_unix();
    let mut decayed = 0usize;

    for (id, path, strength, decay_rate, last_accessed) in episodic {
        let hours_since = hours_elapsed(last_accessed, now);
        let new_strength = apply_decay(strength, decay_rate, hours_since);

        if new_strength < STRENGTH_THRESHOLD {
            db::delete_by_id(&conn, id)
                .with_context(|| format!("failed to delete decayed memory {path}"))?;
        } else {
            db::update_strength(&conn, id, new_strength)
                .with_context(|| format!("failed to update strength for {path}"))?;
        }

        decayed += 1;
    }

    println!("decayed {decayed} episodic memories");

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
        // After enough time, strength should drop below threshold.
        let new = apply_decay(0.06, 0.05, 1000.0);
        assert!(new < STRENGTH_THRESHOLD);
    }

    #[test]
    fn test_hours_elapsed() {
        let elapsed = hours_elapsed(0, 7200);
        assert!((elapsed - 2.0).abs() < 1e-9);
    }
}
