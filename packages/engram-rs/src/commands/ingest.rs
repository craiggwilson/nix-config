use crate::chunk;
use crate::commands::add::compute_strength;
use crate::config::{Config, IndexedPathConfig};
use crate::db::{self, UpsertOptions};
use crate::embed;
use crate::walker;
use anyhow::{Context, Result};
use std::collections::HashSet;
use std::path::{Path, PathBuf};

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
    let conn = db::open(&cfg.db_path)?;

    // Collect all on-disk file paths across all roots for deletion detection.
    let mut all_files: Vec<(walker::File, FileSource)> = vec![];

    // Walk memory_path — classification comes from subdirectory name.
    let memory_roots = vec![cfg.memory_path.clone()];
    for file in walker::walk_all(&memory_roots).context("failed to walk memory-path")? {
        all_files.push((file, FileSource::Memory));
    }

    // Walk each indexed path with its per-path config.
    for indexed in &cfg.indexed_paths {
        let root = PathBuf::from(&indexed.path);
        let roots = vec![root];
        for file in walker::walk_all(&roots)
            .with_context(|| format!("failed to walk indexed-path {}", indexed.path))?
        {
            all_files.push((file, FileSource::Indexed(indexed.clone())));
        }
    }

    // Build on-disk path set for deletion detection.
    let on_disk: HashSet<String> = all_files
        .iter()
        .map(|(f, _)| f.path.to_string_lossy().to_string())
        .collect();

    // Remove DB records for files no longer on disk.
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

    for (file, source) in &all_files {
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

        let (classification, is_memory, importance, confidence, decay_rate, strength) = match source {
            FileSource::Memory => {
                let cls = detect_memory_classification(&file.path, &cfg.memory_path);
                let (imp, dr) = cfg
                    .memory_type(&cls)
                    .map(|t| (t.importance, t.decay_rate))
                    .unwrap_or((0.5, 0.0));
                let strength = compute_strength(imp, 1, 0.5, &cfg.strength_weights);
                (cls, true, imp, 0.5, dr, strength)
            }
            FileSource::Indexed(idx_cfg) => (
                idx_cfg.classification.clone(),
                false,
                0.5,
                0.5,
                0.0,
                idx_cfg.strength,
            ),
        };

        // Embed title and body separately if title is non-empty, otherwise embed content directly.
        let embedding = if !file.title.is_empty() {
            embed::embed_passage_with_title(&file.title, &file.content, cfg.passage_prefix.as_deref().unwrap_or(""))
                .with_context(|| format!("failed to embed {}", file.path.display()))?
        } else {
            embed::embed_passage(&file.content, cfg.passage_prefix.as_deref().unwrap_or(""))
                .with_context(|| format!("failed to embed {}", file.path.display()))?
        };

        db::upsert(
            &conn,
            &path_str,
            Some(&file.title),
            &file.content,
            file.mtime,
            file.doc_type.as_deref(),
            file.tags.as_deref(),
            &classification,
            is_memory,
            importance,
            confidence,
            decay_rate,
            strength,
            &embedding,
            &UpsertOptions { force_metadata: args.full },
        )
        .with_context(|| format!("failed to upsert {}", file.path.display()))?;

        // Get the document ID for chunking
        if let Some(doc_id) = db::get_id_by_path(&conn, &path_str)
            .with_context(|| format!("failed to get doc_id for {}", file.path.display()))?
        {
            // Chunk the document and embed each chunk
            let chunks = chunk::chunk_text(
                &file.title,
                &file.content,
                cfg.scoring.chunking.chunk_size,
                cfg.scoring.chunking.chunk_stride,
                cfg.scoring.chunking.chunk_min_words,
            );

            let mut chunk_embeddings: Vec<(usize, String, Vec<f32>)> = vec![];
            for c in chunks {
                let embedding = embed::embed_passage(&c.content, cfg.passage_prefix.as_deref().unwrap_or(""))
                    .with_context(|| {
                        format!("failed to embed chunk {} for {}", c.index, file.path.display())
                    })?;
                chunk_embeddings.push((c.index, c.content, embedding));
            }

            if !chunk_embeddings.is_empty() {
                db::upsert_chunks(&conn, doc_id, &chunk_embeddings)
                    .with_context(|| format!("failed to upsert chunks for {}", file.path.display()))?;
            }
        }

        ingested += 1;
    }

    // Update the corpus mean for centering in search
    db::update_corpus_mean(&conn).context("failed to update corpus mean")?;

    println!("ingested {ingested} files, skipped {skipped} unchanged, deleted {deleted} removed");

    Ok(())
}

/// Whether a file came from the memory path or an indexed path.
enum FileSource {
    Memory,
    Indexed(IndexedPathConfig),
}

/// Detect the classification of a memory file based on its subdirectory under memory_path.
///
/// Files under `<memory_path>/<type_name>/` → type_name
/// Everything else → ""
fn detect_memory_classification(file_path: &Path, memory_path: &Path) -> String {
    if let Ok(rel) = file_path.strip_prefix(memory_path) {
        if let Some(first) = rel.components().next() {
            let name = first.as_os_str().to_string_lossy();
            return name.to_string();
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
        assert_eq!(detect_memory_classification(&file, &memory), "episodic");
    }

    #[test]
    fn test_detect_classification_fact() {
        let memory = PathBuf::from("/memories");
        let file = PathBuf::from("/memories/fact/something.md");
        assert_eq!(detect_memory_classification(&file, &memory), "fact");
    }

    #[test]
    fn test_detect_classification_unknown() {
        let memory = PathBuf::from("/memories");
        let file = PathBuf::from("/other/path/file.md");
        assert_eq!(detect_memory_classification(&file, &memory), "");
    }
}
