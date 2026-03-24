use crate::commands::add::{compute_strength, metadata_for_type};
use crate::config::Config;
use crate::db::{self, UpsertOptions};
use crate::embed;
use crate::walker;
use anyhow::{Context, Result};
use std::collections::HashSet;
use std::path::Path;

/// Arguments for the `ingest` command.
pub struct IngestArgs {
    /// When true, re-embed all files even if mtime is unchanged.
    pub full: bool,
}

/// Execute the `ingest` command.
///
/// Walks memory-path and all indexed-paths, upserts changed files, and removes
/// DB records for files that no longer exist on disk.
pub fn run(cfg: &Config, args: IngestArgs) -> Result<()> {
    let mut roots = vec![cfg.memory_path.clone()];
    roots.extend(cfg.indexed_paths.iter().cloned());

    let files = walker::walk_all(&roots).context("failed to walk vault directories")?;

    let conn = db::open(&cfg.db_path)?;

    // Build a set of all on-disk paths for deletion detection.
    let on_disk: HashSet<String> = files
        .iter()
        .map(|f| f.path.to_string_lossy().to_string())
        .collect();

    // Determine which DB records no longer have a corresponding file.
    let db_paths = db::all_paths(&conn).context("failed to load db paths")?;
    let mut deleted = 0usize;
    for (db_path, _) in &db_paths {
        if !on_disk.contains(db_path.as_str()) {
            db::delete(&conn, db_path).context("failed to delete stale record")?;
            deleted += 1;
        }
    }

    let mut ingested = 0usize;
    let mut skipped = 0usize;

    for file in &files {
        let path_str = file.path.to_string_lossy().to_string();

        // Skip unchanged files unless --full is set.
        if !args.full {
            if let Some(stored_mtime) = db::get_mtime(&conn, &path_str)
                .context("failed to query mtime")?
            {
                if stored_mtime == file.mtime {
                    skipped += 1;
                    continue;
                }
            }
        }

        let classification = detect_classification(&file.path, &cfg.memory_path);
        let (importance, decay_rate) = metadata_for_type(&classification);

        // Embed title + "\n\n" + content, or just content if no title.
        let text_to_embed = format!("{}\n\n{}", file.title, file.content);
        let embedding = embed::embed(&text_to_embed)
            .with_context(|| format!("failed to embed {}", file.path.display()))?;

        let strength = compute_strength(importance, 1, 0.5, 0.5);

        db::upsert(
            &conn,
            &path_str,
            Some(&file.title),
            &file.content,
            file.mtime,
            file.doc_type.as_deref(),
            file.tags.as_deref(),
            &classification,
            importance,
            0.5,
            decay_rate,
            strength,
            &embedding,
            &UpsertOptions { force_metadata: false },
        )
        .with_context(|| format!("failed to upsert {}", file.path.display()))?;

        ingested += 1;
    }

    println!("ingested {ingested} files, skipped {skipped} unchanged, deleted {deleted} removed");

    Ok(())
}

/// Detect the classification of a file based on its path relative to memory_path.
///
/// Files under `<memory_path>/episodic/` → "episodic"
/// Files under `<memory_path>/preference/` → "preference"
/// Files under `<memory_path>/fact/` → "fact"
/// Everything else → ""
fn detect_classification(file_path: &Path, memory_path: &Path) -> String {
    if let Ok(rel) = file_path.strip_prefix(memory_path) {
        if let Some(first) = rel.components().next() {
            let name = first.as_os_str().to_string_lossy();
            match name.as_ref() {
                "episodic" | "preference" | "fact" => return name.to_string(),
                _ => {}
            }
        }
    }
    String::new()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn test_detect_classification_episodic() {
        let memory = PathBuf::from("/memories");
        let file = PathBuf::from("/memories/episodic/2026-01-01.md");
        assert_eq!(detect_classification(&file, &memory), "episodic");
    }

    #[test]
    fn test_detect_classification_fact() {
        let memory = PathBuf::from("/memories");
        let file = PathBuf::from("/memories/fact/something.md");
        assert_eq!(detect_classification(&file, &memory), "fact");
    }

    #[test]
    fn test_detect_classification_unknown() {
        let memory = PathBuf::from("/memories");
        let file = PathBuf::from("/other/path/file.md");
        assert_eq!(detect_classification(&file, &memory), "");
    }
}
