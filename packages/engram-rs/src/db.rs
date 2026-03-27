use anyhow::{anyhow, Context, Result};
use rusqlite::{params, Connection};
use std::path::Path;

/// A single document record stored in the database.
#[derive(Debug, Clone)]
pub struct Document {
    pub id: i64,
    pub path: String,
    pub title: Option<String>,
    pub content: String,
    pub mtime: i64,
    pub doc_type: Option<String>,
    pub tags: Option<String>,
    pub classification: String,
    /// True if this record is a user-managed memory (vs. an indexed external document).
    pub is_memory: bool,
    pub frequency: i64,
    pub last_accessed: i64,
    pub decay_rate: f64,
    pub importance: f64,
    pub confidence: f64,
    pub strength: f64,
    pub embedding: Vec<u8>,
}

/// A lightweight record used for search results.
#[derive(Debug, Clone)]
pub struct SearchResult {
    pub path: String,
    pub classification: String,
    pub strength: f64,
    pub content: String,
    pub embedding: Vec<f32>,
}

/// Options controlling how an upsert behaves on conflict.
pub struct UpsertOptions {
    /// When true, always overwrite metadata fields (type, tags, classification,
    /// importance, decay_rate, strength). When false, preserve existing values.
    pub force_metadata: bool,
}

/// Open (or create) the SQLite database at `path`, creating the schema if needed.
pub fn open(path: &Path) -> Result<Connection> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("failed to create db directory {}", parent.display()))?;
    }

    let conn = Connection::open(path)
        .with_context(|| format!("failed to open database at {}", path.display()))?;

    create_schema(&conn).context("failed to create database schema")?;

    Ok(conn)
}

/// Create the database schema. Safe to call on an existing database — all
/// statements use CREATE TABLE IF NOT EXISTS.
pub fn create_schema(conn: &Connection) -> Result<()> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS documents (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            path           TEXT    NOT NULL UNIQUE,
            title          TEXT,
            content        TEXT    NOT NULL,
            mtime          INTEGER NOT NULL,
            type           TEXT,
            tags           TEXT,
            classification TEXT    NOT NULL DEFAULT '',
            is_memory      INTEGER NOT NULL DEFAULT 0,
            frequency      INTEGER NOT NULL DEFAULT 1,
            last_accessed  INTEGER NOT NULL DEFAULT 0,
            decay_rate     REAL    NOT NULL DEFAULT 0.0,
            importance     REAL    NOT NULL DEFAULT 0.5,
            confidence     REAL    NOT NULL DEFAULT 0.5,
            strength       REAL    NOT NULL DEFAULT 0.0,
            embedding      BLOB    NOT NULL DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS chunks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            doc_id      INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
            chunk_index INTEGER NOT NULL,
            content     TEXT    NOT NULL,
            embedding   BLOB    NOT NULL,
            UNIQUE(doc_id, chunk_index)
        );
        CREATE TABLE IF NOT EXISTS kv (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS docs_fts USING fts5(
            path UNINDEXED,
            content,
            content='documents',
            content_rowid='id'
        );",
    )
    .context("failed to create schema")?;

    Ok(())
}

/// Read a value from the key-value metadata table.
pub fn kv_get(conn: &Connection, key: &str) -> Result<Option<String>> {
    let mut stmt = conn
        .prepare("SELECT value FROM kv WHERE key = ?1")
        .context("failed to prepare kv_get")?;
    let mut rows = stmt.query([key]).context("failed to query kv")?;
    if let Some(row) = rows.next().context("failed to read kv row")? {
        Ok(Some(row.get(0).context("failed to read kv value")?))
    } else {
        Ok(None)
    }
}

/// Write a value to the key-value metadata table.
pub fn kv_set(conn: &Connection, key: &str, value: &str) -> Result<()> {
    conn.execute(
        "INSERT INTO kv (key, value) VALUES (?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value",
        [key, value],
    )
    .context("failed to write kv entry")?;
    Ok(())
}

/// Compute the mean embedding vector across all documents and store in kv.
pub fn update_corpus_mean(conn: &Connection) -> Result<()> {
    // Fetch all document embeddings (not chunks)
    let mut stmt = conn
        .prepare("SELECT embedding FROM documents WHERE length(embedding) > 0")
        .context("failed to prepare corpus_mean query")?;
    
    let embeddings: Vec<Vec<f32>> = stmt
        .query_map([], |row| {
            let blob: Vec<u8> = row.get(0)?;
            Ok(deserialize_embedding(&blob))
        })
        .context("failed to execute corpus_mean query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect corpus_mean embeddings")?;
    
    if embeddings.is_empty() {
        // No documents yet, store empty mean
        kv_set(conn, "corpus_mean", "[]")?;
        return Ok(());
    }
    
    let embedding_dim = embeddings[0].len();
    
    // Check all embeddings have the same dimension
    if !embeddings.iter().all(|e| e.len() == embedding_dim) {
        return Err(anyhow::anyhow!("inconsistent embedding dimensions in corpus"));
    }
    
    // Compute sum across all embeddings
    let mut sum = vec![0.0f32; embedding_dim];
    for embedding in &embeddings {
        for (i, &val) in embedding.iter().enumerate() {
            sum[i] += val;
        }
    }
    
    // Divide by count to get mean
    let count = embeddings.len() as f32;
    let mean: Vec<f32> = sum.iter().map(|&x| x / count).collect();
    
    // Serialize and store
    let json_str = serde_json::to_string(&mean)
        .context("failed to serialize corpus_mean")?;
    kv_set(conn, "corpus_mean", &json_str)?;
    
    Ok(())
}

/// Load the corpus mean embedding from kv, or None if not computed yet.
pub fn get_corpus_mean(conn: &Connection) -> Result<Option<Vec<f32>>> {
    if let Some(json_str) = kv_get(conn, "corpus_mean")? {
        let mean = serde_json::from_str(&json_str)
            .context("failed to deserialize corpus_mean")?;
        Ok(Some(mean))
    } else {
        Ok(None)
    }
}

/// Insert or update a document record.
///
/// When `opts.force_metadata` is false and the row already exists, metadata
/// fields (classification, importance, decay_rate, strength, type, tags) are
/// preserved from the existing row.
pub fn upsert(
    conn: &Connection,
    path: &str,
    title: Option<&str>,
    content: &str,
    mtime: i64,
    doc_type: Option<&str>,
    tags: Option<&str>,
    classification: &str,
    is_memory: bool,
    importance: f64,
    confidence: f64,
    decay_rate: f64,
    strength: f64,
    embedding: &[f32],
    opts: &UpsertOptions,
) -> Result<()> {
    let embedding_blob = serialize_embedding(embedding);
    let is_memory_int = is_memory as i64;

    if opts.force_metadata {
        conn.execute(
            "INSERT INTO documents
                (path, title, content, mtime, type, tags, classification, is_memory,
                 frequency, last_accessed, decay_rate, importance, confidence, strength, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 1, 0, ?9, ?10, ?11, ?12, ?13)
             ON CONFLICT(path) DO UPDATE SET
                title          = excluded.title,
                content        = excluded.content,
                mtime          = excluded.mtime,
                type           = excluded.type,
                tags           = excluded.tags,
                classification = excluded.classification,
                is_memory      = excluded.is_memory,
                decay_rate     = excluded.decay_rate,
                importance     = excluded.importance,
                confidence     = excluded.confidence,
                strength       = excluded.strength,
                embedding      = excluded.embedding",
            params![
                path,
                title,
                content,
                mtime,
                doc_type,
                tags,
                classification,
                is_memory_int,
                decay_rate,
                importance,
                confidence,
                strength,
                embedding_blob,
            ],
        )
        .context("failed to upsert document (force_metadata=true)")?;
    } else {
        // Preserve existing metadata on conflict; only update content/mtime/embedding.
        conn.execute(
            "INSERT INTO documents
                (path, title, content, mtime, type, tags, classification, is_memory,
                 frequency, last_accessed, decay_rate, importance, confidence, strength, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 1, 0, ?9, ?10, ?11, ?12, ?13)
             ON CONFLICT(path) DO UPDATE SET
                title     = excluded.title,
                content   = excluded.content,
                mtime     = excluded.mtime,
                embedding = excluded.embedding",
            params![
                path,
                title,
                content,
                mtime,
                doc_type,
                tags,
                classification,
                is_memory_int,
                decay_rate,
                importance,
                confidence,
                strength,
                embedding_blob,
            ],
        )
        .context("failed to upsert document (force_metadata=false)")?;
    }

    // Update FTS index — delete old entry then insert new one.
    let doc_id = conn.query_row("SELECT id FROM documents WHERE path = ?1", [path], |r| r.get::<_, i64>(0))
        .context("failed to get document id after upsert")?;

    conn.execute(
        "INSERT INTO docs_fts(docs_fts, rowid, path, content) VALUES('delete', ?1, ?2, ?3)",
        params![doc_id, path, content],
    ).ok(); // ignore error if row didn't exist yet

    conn.execute(
        "INSERT INTO docs_fts(rowid, path, content) VALUES(?1, ?2, ?3)",
        params![doc_id, path, content],
    ).context("failed to update FTS index")?;

    Ok(())
}

/// Return all (path, mtime) pairs stored in the database.
pub fn all_paths(conn: &Connection) -> Result<Vec<(String, i64)>> {
    let mut stmt = conn
        .prepare("SELECT path, mtime FROM documents")
        .context("failed to prepare all_paths query")?;

    let rows = stmt
        .query_map([], |row| Ok((row.get::<_, String>(0)?, row.get::<_, i64>(1)?)))
        .context("failed to execute all_paths query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect all_paths rows")?;

    Ok(rows)
}

/// Return all memory records, optionally filtered by a specific classification.
///
/// Only rows with `is_memory = 1` are returned, which unambiguously excludes
/// indexed-path documents regardless of their classification name.
/// Results are ordered by strength descending.
pub fn list_all(
    conn: &Connection,
    classification: Option<&str>,
) -> Result<Vec<Document>> {
    let mut stmt = conn
        .prepare(
            "SELECT id, path, title, content, mtime, type, tags, classification, is_memory,
                    frequency, last_accessed, decay_rate, importance, confidence, strength, embedding
             FROM documents
             WHERE is_memory = 1
               AND (?1 IS NULL OR classification = ?1)
             ORDER BY strength DESC",
        )
        .context("failed to prepare list_all query")?;

    let rows = stmt
        .query_map(params![classification], |row| {
            Ok(Document {
                id: row.get(0)?,
                path: row.get(1)?,
                title: row.get(2)?,
                content: row.get(3)?,
                mtime: row.get(4)?,
                doc_type: row.get(5)?,
                tags: row.get(6)?,
                classification: row.get(7)?,
                is_memory: row.get::<_, i64>(8)? != 0,
                frequency: row.get(9)?,
                last_accessed: row.get(10)?,
                decay_rate: row.get(11)?,
                importance: row.get(12)?,
                confidence: row.get(13)?,
                strength: row.get(14)?,
                embedding: vec![],
            })
        })
        .context("failed to execute list_all query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect list_all rows")?;

    Ok(rows)
}

/// Look up a document by its integer ID. Returns None if not found.
pub fn get_by_id(conn: &Connection, id: i64) -> Result<Option<Document>> {
    let mut stmt = conn
        .prepare(
            "SELECT id, path, title, content, mtime, type, tags, classification, is_memory,
                    frequency, last_accessed, decay_rate, importance, confidence, strength, embedding
             FROM documents WHERE id = ?1",
        )
        .context("failed to prepare get_by_id query")?;

    let result = stmt
        .query_row(params![id], |row| {
            Ok(Document {
                id: row.get(0)?,
                path: row.get(1)?,
                title: row.get(2)?,
                content: row.get(3)?,
                mtime: row.get(4)?,
                doc_type: row.get(5)?,
                tags: row.get(6)?,
                classification: row.get(7)?,
                is_memory: row.get::<_, i64>(8)? != 0,
                frequency: row.get(9)?,
                last_accessed: row.get(10)?,
                decay_rate: row.get(11)?,
                importance: row.get(12)?,
                confidence: row.get(13)?,
                strength: row.get(14)?,
                embedding: vec![],
            })
        })
        .optional()
        .context("failed to execute get_by_id query")?;

    Ok(result)
}

/// Return the stored mtime for a path, or None if not found.
///
/// Only considers memory records (`is_memory = 1`). Indexed documents are
/// invisible to callers that use this to check whether a path is manageable.
pub fn get_mtime(conn: &Connection, path: &str) -> Result<Option<i64>> {
    let mut stmt = conn
        .prepare("SELECT mtime FROM documents WHERE path = ?1 AND is_memory = 1")
        .context("failed to prepare get_mtime query")?;

    let result = stmt
        .query_row(params![path], |row| row.get::<_, i64>(0))
        .optional()
        .context("failed to execute get_mtime query")?;

    Ok(result)
}

/// Get the document ID by path.
pub fn get_id_by_path(conn: &Connection, path: &str) -> Result<Option<i64>> {
    let mut stmt = conn
        .prepare("SELECT id FROM documents WHERE path = ?1")
        .context("failed to prepare get_id_by_path query")?;

    let result = stmt
        .query_row(params![path], |row| row.get::<_, i64>(0))
        .optional()
        .context("failed to execute get_id_by_path query")?;

    Ok(result)
}

/// Increment the access frequency counter for a document.
pub fn increment_frequency(conn: &Connection, path: &str) -> Result<()> {
    conn.execute(
        "UPDATE documents SET frequency = frequency + 1, last_accessed = ?1 WHERE path = ?2",
        params![now_unix(), path],
    )
    .context("failed to increment frequency")?;
    Ok(())
}

/// Delete a document by path.
pub fn delete(conn: &Connection, path: &str) -> Result<()> {
    conn.execute("DELETE FROM documents WHERE path = ?1", params![path])
        .context("failed to delete document")?;
    Ok(())
}

/// Load all memories that have a non-zero decay rate, for decay processing.
///
/// Not restricted to any particular classification — any memory type with
/// `decay_rate > 0` will be included.
pub fn all_decayable(conn: &Connection) -> Result<Vec<(i64, String, f64, f64, i64)>> {
    let mut stmt = conn
        .prepare(
            "SELECT id, path, strength, decay_rate, last_accessed
             FROM documents
             WHERE is_memory = 1 AND decay_rate > 0",
        )
        .context("failed to prepare all_decayable query")?;

    let rows = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, i64>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, f64>(2)?,
                row.get::<_, f64>(3)?,
                row.get::<_, i64>(4)?,
            ))
        })
        .context("failed to execute all_decayable query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect decayable rows")?;

    Ok(rows)
}

/// Update the strength of a document by id.
pub fn update_strength(conn: &Connection, id: i64, strength: f64) -> Result<()> {
    conn.execute(
        "UPDATE documents SET strength = ?1 WHERE id = ?2",
        params![strength, id],
    )
    .context("failed to update strength")?;
    Ok(())
}

/// A single row in the by-type breakdown.
#[derive(Debug)]
pub struct TypeCount {
    pub classification: String,
    pub is_memory: bool,
    pub count: i64,
}

/// A single row in the file type distribution breakdown.
#[derive(Debug)]
pub struct FileTypeCount {
    pub doc_type: String,
    pub count: i64,
}

/// Statistics about the dataset.
#[derive(Debug)]
pub struct Stats {
    /// Total number of memory records (is_memory = 1).
    pub total_memories: i64,
    /// Count per classification across both memories and indexed docs,
    /// sorted by source then classification.
    pub by_type: Vec<TypeCount>,
    /// Total number of indexed (non-memory) documents.
    pub total_indexed: i64,
    /// Strength statistics across all memories (None if no memories).
    pub strength: Option<StrengthStats>,
    /// Strength statistics across all indexed documents (None if no indexed docs).
    pub indexed_strength: Option<StrengthStats>,
    /// Number of memories with decay_rate > 0.
    pub decayable_count: i64,
    /// Number of decayable memories whose strength is within 2× the decay threshold.
    pub near_threshold_count: i64,
    /// Size of the database file on disk in bytes (None if path unavailable).
    pub db_size_bytes: Option<u64>,
    /// Size and mtime statistics for memories (None if no memories).
    pub memory_size: Option<SizeStats>,
    /// Size and mtime statistics for indexed documents (None if no indexed docs).
    pub indexed_size: Option<SizeStats>,
    /// File type distribution for indexed documents (by doc_type field).
    pub indexed_file_types: Vec<FileTypeCount>,
}

/// Strength distribution statistics.
#[derive(Debug)]
pub struct StrengthStats {
    pub min: f64,
    pub max: f64,
    pub mean: f64,
    pub median: f64,
}

/// Size and mtime statistics for a set of documents.
#[derive(Debug)]
pub struct SizeStats {
    pub total_bytes: i64,
    pub oldest_mtime: i64,
    pub newest_mtime: i64,
}

/// Gather dataset statistics.
pub fn stats(conn: &Connection, db_path: &Path, decay_threshold: f64) -> Result<Stats> {
    // Total memories and indexed docs.
    let total_memories: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM documents WHERE is_memory = 1",
            [],
            |r| r.get(0),
        )
        .context("failed to count memories")?;

    let total_indexed: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM documents WHERE is_memory = 0",
            [],
            |r| r.get(0),
        )
        .context("failed to count indexed docs")?;

    // Count by classification across all documents, with is_memory flag.
    let mut by_type_stmt = conn
        .prepare(
            "SELECT classification, is_memory, COUNT(*)
             FROM documents
             GROUP BY classification, is_memory
             ORDER BY classification",
        )
        .context("failed to prepare by_type query")?;

    let by_type = by_type_stmt
        .query_map([], |row| {
            Ok(TypeCount {
                classification: row.get(0)?,
                is_memory: row.get::<_, i64>(1)? != 0,
                count: row.get(2)?,
            })
        })
        .context("failed to execute by_type query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect by_type rows")?;

    // Decay stats.
    let decayable_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM documents WHERE is_memory = 1 AND decay_rate > 0",
            [],
            |r| r.get(0),
        )
        .context("failed to count decayable memories")?;

    let near_threshold_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM documents
             WHERE is_memory = 1 AND decay_rate > 0 AND strength < ?1",
            params![decay_threshold * 2.0],
            |r| r.get(0),
        )
        .context("failed to count near-threshold memories")?;

    // Strength distribution — fetch all values sorted for median.
    let strength = if total_memories > 0 {
        let mut s_stmt = conn
            .prepare(
                "SELECT strength FROM documents WHERE is_memory = 1 ORDER BY strength ASC",
            )
            .context("failed to prepare strength query")?;

        let values: Vec<f64> = s_stmt
            .query_map([], |r| r.get(0))
            .context("failed to execute strength query")?
            .collect::<rusqlite::Result<Vec<_>>>()
            .context("failed to collect strength values")?;

        let min = values.first().copied().unwrap_or(0.0);
        let max = values.last().copied().unwrap_or(0.0);
        let mean = values.iter().sum::<f64>() / values.len() as f64;
        let median = if values.len() % 2 == 0 {
            (values[values.len() / 2 - 1] + values[values.len() / 2]) / 2.0
        } else {
            values[values.len() / 2]
        };

        Some(StrengthStats { min, max, mean, median })
    } else {
        None
    };

    // DB file size.
    let db_size_bytes = std::fs::metadata(db_path).ok().map(|m| m.len());

    // Memory size and mtime stats.
    let memory_size = if total_memories > 0 {
        let mut size_stmt = conn
            .prepare(
                "SELECT SUM(length(content)), MIN(mtime), MAX(mtime)
                 FROM documents WHERE is_memory = 1",
            )
            .context("failed to prepare memory size query")?;

        let (total_bytes, oldest_mtime, newest_mtime) = size_stmt
            .query_row([], |row| {
                Ok((row.get::<_, i64>(0)?, row.get::<_, i64>(1)?, row.get::<_, i64>(2)?))
            })
            .context("failed to execute memory size query")?;

        Some(SizeStats {
            total_bytes,
            oldest_mtime,
            newest_mtime,
        })
    } else {
        None
    };

    // Indexed size and mtime stats.
    let indexed_size = if total_indexed > 0 {
        let mut idx_size_stmt = conn
            .prepare(
                "SELECT SUM(length(content)), MIN(mtime), MAX(mtime)
                 FROM documents WHERE is_memory = 0",
            )
            .context("failed to prepare indexed size query")?;

        let (total_bytes, oldest_mtime, newest_mtime) = idx_size_stmt
            .query_row([], |row| {
                Ok((row.get::<_, i64>(0)?, row.get::<_, i64>(1)?, row.get::<_, i64>(2)?))
            })
            .context("failed to execute indexed size query")?;

        Some(SizeStats {
            total_bytes,
            oldest_mtime,
            newest_mtime,
        })
    } else {
        None
    };

    // Strength stats for indexed documents.
    let indexed_strength = if total_indexed > 0 {
        let mut s_stmt = conn
            .prepare(
                "SELECT strength FROM documents WHERE is_memory = 0 ORDER BY strength ASC",
            )
            .context("failed to prepare indexed strength query")?;

        let values: Vec<f64> = s_stmt
            .query_map([], |r| r.get(0))
            .context("failed to execute indexed strength query")?
            .collect::<rusqlite::Result<Vec<_>>>()
            .context("failed to collect indexed strength values")?;

        let min = values.first().copied().unwrap_or(0.0);
        let max = values.last().copied().unwrap_or(0.0);
        let mean = values.iter().sum::<f64>() / values.len() as f64;
        let median = if values.len() % 2 == 0 {
            (values[values.len() / 2 - 1] + values[values.len() / 2]) / 2.0
        } else {
            values[values.len() / 2]
        };

        Some(StrengthStats { min, max, mean, median })
    } else {
        None
    };

    // File type distribution for indexed documents.
    let mut file_type_stmt = conn
        .prepare(
            "SELECT COALESCE(type, 'unknown'), COUNT(*)
             FROM documents
             WHERE is_memory = 0
             GROUP BY type
             ORDER BY COUNT(*) DESC",
        )
        .context("failed to prepare indexed file type query")?;

    let indexed_file_types = file_type_stmt
        .query_map([], |row| {
            Ok(FileTypeCount {
                doc_type: row.get(0)?,
                count: row.get(1)?,
            })
        })
        .context("failed to execute indexed file type query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect indexed file type rows")?;

    Ok(Stats {
        total_memories,
        by_type,
        total_indexed,
        strength,
        indexed_strength,
        decayable_count,
        near_threshold_count,
        db_size_bytes,
        memory_size,
        indexed_size,
        indexed_file_types,
    })
}

/// Delete a document by id.
pub fn delete_by_id(conn: &Connection, id: i64) -> Result<()> {
    // Remove from FTS before deleting document
    conn.execute(
        "INSERT INTO docs_fts(docs_fts, rowid, path, content) VALUES('delete', ?1, '', '')",
        params![id],
    ).ok();
    
    conn.execute("DELETE FROM documents WHERE id = ?1", params![id])
        .context("failed to delete document by id")?;
    Ok(())
}

/// Delete all chunks for a document and insert fresh ones.
///
/// Takes ownership of chunks with their content and embeddings, deletes any
/// existing chunks for the document, and batch-inserts new ones.
pub fn upsert_chunks(
    conn: &Connection,
    doc_id: i64,
    chunks: &[(usize, String, Vec<f32>)],
) -> Result<()> {
    // Delete existing chunks for this document
    conn.execute("DELETE FROM chunks WHERE doc_id = ?1", params![doc_id])
        .context("failed to delete existing chunks")?;

    // Batch insert new chunks
    let mut stmt = conn
        .prepare(
            "INSERT INTO chunks (doc_id, chunk_index, content, embedding)
             VALUES (?1, ?2, ?3, ?4)",
        )
        .context("failed to prepare insert chunks statement")?;

    for (chunk_index, content, embedding_vec) in chunks {
        let embedding_blob = serialize_embedding(embedding_vec);
        stmt.execute(params![
            doc_id,
            *chunk_index as i64,
            content,
            embedding_blob
        ])
        .context("failed to insert chunk")?;
    }

    Ok(())
}

/// Delete memory records, or only those matching a classification if provided.
///
/// Only affects rows with `is_memory = 1`; indexed documents are never cleared.
/// Returns the number of rows deleted.
pub fn clear(conn: &Connection, classification: Option<&str>) -> Result<usize> {
    let count = match classification {
        Some(cls) => conn
            .execute(
                "DELETE FROM documents WHERE is_memory = 1 AND classification = ?1",
                params![cls],
            )
            .context("failed to clear memories by classification")?,
        None => conn
            .execute("DELETE FROM documents WHERE is_memory = 1", [])
            .context("failed to clear all memories")?,
    };
    Ok(count)
}

/// Center a vector by subtracting the mean, or return unchanged if dimensions don't match.
fn center(v: &[f32], mean: &[f32]) -> Vec<f32> {
    if mean.is_empty() || mean.len() != v.len() {
        return v.to_vec();
    }
    v.iter().zip(mean.iter()).map(|(x, m)| x - m).collect()
}

/// Run BM25 keyword search using FTS5. Returns doc paths ordered by BM25 score.
fn bm25_search(conn: &Connection, query: &str) -> Result<Vec<String>> {
    let mut stmt = conn.prepare(
        "SELECT path FROM docs_fts
         WHERE docs_fts MATCH ?1
         ORDER BY bm25(docs_fts) ASC
         LIMIT 100"
    ).context("failed to prepare BM25 query")?;
    // Note: bm25() returns negative values in FTS5 (more negative = better match)
    // ORDER BY ASC gives best matches first

    let paths = stmt.query_map([query], |row| row.get(0))
        .context("failed to execute BM25 query")?
        .filter_map(|r| r.ok())
        .collect();
    Ok(paths)
}

/// Rerank search results using Maximal Marginal Relevance (MMR).
///
/// After initial ranking by combined score, MMR iteratively selects results that balance
/// relevance (high combined score) with diversity (low similarity to already-selected results).
///
/// Formula: mmr_score = λ * combined_score - (1 - λ) * max_sim_to_selected
///
/// When λ >= 1.0, returns candidates unchanged (pure relevance, no diversity constraint).
fn mmr_rerank(
    candidates: Vec<(SearchResult, f64)>,
    limit: usize,
    lambda: f64,
) -> Vec<(SearchResult, f64)> {
    if lambda >= 1.0 || candidates.len() <= 1 {
        return candidates.into_iter().take(limit).collect();
    }

    let mut selected: Vec<(SearchResult, f64)> = Vec::with_capacity(limit);
    let mut remaining = candidates;

    // Always take the top result first
    if !remaining.is_empty() {
        selected.push(remaining.remove(0));
    }

    while selected.len() < limit && !remaining.is_empty() {
        let mut best_idx = 0;
        let mut best_mmr = f64::NEG_INFINITY;

        for (i, (candidate, score)) in remaining.iter().enumerate() {
            // Max similarity to any already-selected result
            let max_sim = selected
                .iter()
                .map(|(sel, _)| cosine_similarity(&candidate.embedding, &sel.embedding) as f64)
                .fold(f64::NEG_INFINITY, f64::max);

            let mmr_score = lambda * score - (1.0 - lambda) * max_sim;
            if mmr_score > best_mmr {
                best_mmr = mmr_score;
                best_idx = i;
            }
        }

        selected.push(remaining.remove(best_idx));
    }

    selected
}

/// Brute-force cosine similarity search with optional BM25 hybrid fusion via RRF.
///
/// Searches both document-level embeddings and chunk embeddings. For each document,
/// the semantic score is the maximum of its document embedding score and the best
/// chunk embedding score. Documents whose score falls below `semantic_threshold`
/// are excluded entirely.
///
/// If BM25 is enabled, performs a keyword search and fuses results using Reciprocal
/// Rank Fusion (RRF) with configurable dense and BM25 weights.
///
/// Returns up to `limit` results sorted by combined score descending, then reranked
/// by MMR (Maximal Marginal Relevance) for diversity.
/// Combined score = semantic_score * semantic_weight * (1 + strength * strength_weight),
/// normalised to 0–1. Strength acts as a multiplicative boost so it can amplify
/// relevant results but cannot rescue semantically irrelevant ones.
pub fn search(
    conn: &Connection,
    query_embedding: &[f32],
    limit: usize,
    semantic_weight: f64,
    strength_weight: f64,
    semantic_threshold: f64,
    use_chunking: bool,
    use_corpus_centering: bool,
    use_mmr: bool,
    mmr_lambda: f64,
    use_bm25: bool,
    bm25_weight: f64,
    dense_weight: f64,
    rrf_k: f64,
    query_text: &str,
) -> Result<Vec<(SearchResult, f64)>> {
    // Load corpus mean for centering only if enabled
    let corpus_mean = if use_corpus_centering {
        get_corpus_mean(conn)?.unwrap_or_default()
    } else {
        vec![]
    };
    let centered_query = center(query_embedding, &corpus_mean);
    
    // Only load chunk scores if chunking is enabled
    let mut chunk_scores: std::collections::HashMap<i64, f64> =
        std::collections::HashMap::new();

    if use_chunking {
        let mut chunk_stmt = conn
            .prepare("SELECT doc_id, embedding FROM chunks WHERE length(embedding) > 0")
            .context("failed to prepare chunk search query")?;

        chunk_stmt
            .query_map([], |row| {
                let doc_id: i64 = row.get(0)?;
                let blob: Vec<u8> = row.get(1)?;
                Ok((doc_id, blob))
            })
            .context("failed to execute chunk search query")?
            .filter_map(|r| r.ok())
            .for_each(|(doc_id, blob)| {
                let chunk_embedding = deserialize_embedding(&blob);
                if !chunk_embedding.is_empty() {
                    let centered_chunk = center(&chunk_embedding, &corpus_mean);
                    let score = cosine_similarity(&centered_query, &centered_chunk) as f64;
                    chunk_scores
                        .entry(doc_id)
                        .and_modify(|best| *best = best.max(score))
                        .or_insert(score);
                }
            });
    }

    // Load all documents and compute their semantic scores
    let mut stmt = conn
        .prepare(
            "SELECT id, path, classification, strength, content, embedding
             FROM documents
             WHERE length(embedding) > 0",
        )
        .context("failed to prepare search query")?;

    let mut results: Vec<(SearchResult, f64)> = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, i64>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, f64>(3)?,
                row.get::<_, String>(4)?,
                row.get::<_, Vec<u8>>(5)?,
            ))
        })
        .context("failed to execute search query")?
        .filter_map(|r| r.ok())
        .filter_map(|(doc_id, path, classification, strength, content, blob)| {
            let doc_embedding = deserialize_embedding(&blob);
            if doc_embedding.is_empty() {
                return None;
            }

            // Compute document-level semantic score using centered embeddings
            let centered_doc = center(&doc_embedding, &corpus_mean);
            let doc_score = cosine_similarity(&centered_query, &centered_doc) as f64;

            // Use the max of document score and best chunk score (if any chunks exist)
            let semantic_score = if let Some(&chunk_score) = chunk_scores.get(&doc_id) {
                doc_score.max(chunk_score)
            } else {
                doc_score
            };

            if semantic_score < semantic_threshold {
                return None;
            }

            // Strength acts as a multiplicative boost to semantic relevance so it
            // cannot rescue semantically irrelevant documents. Normalised to 0–1
            // by dividing by the maximum possible value.
            let max_score = semantic_weight * (1.0 + strength_weight);
            let combined = (semantic_score * semantic_weight * (1.0 + strength * strength_weight))
                / max_score;
            Some((
                SearchResult {
                    path,
                    classification,
                    strength,
                    content,
                    embedding: doc_embedding,
                },
                combined,
            ))
        })
        .collect();

    results.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    // Apply RRF fusion if BM25 is enabled
    if use_bm25 {
        let bm25_paths = bm25_search(conn, query_text).unwrap_or_default();
        
        // Build rank maps using owned Strings to avoid lifetime issues (1-indexed)
        let dense_ranks: std::collections::HashMap<String, usize> = results.iter()
            .enumerate()
            .map(|(i, (r, _))| (r.path.clone(), i + 1))
            .collect();
        
        let bm25_ranks: std::collections::HashMap<String, usize> = bm25_paths.iter()
            .enumerate()
            .map(|(i, p)| (p.clone(), i + 1))
            .collect();
        
        // Compute RRF scores (owned version)
        let mut rrf_scores: std::collections::HashMap<String, f64> = std::collections::HashMap::new();
        for (path, rank) in &dense_ranks {
            let dense_rrf = 1.0 / (rrf_k + *rank as f64);
            let bm25_rrf = bm25_ranks.get(path)
                .map(|&r| 1.0 / (rrf_k + r as f64))
                .unwrap_or(0.0);
            rrf_scores.insert(path.clone(), dense_weight * dense_rrf + bm25_weight * bm25_rrf);
        }
        for (path, rank) in &bm25_ranks {
            if !rrf_scores.contains_key(path) {
                let bm25_rrf = 1.0 / (rrf_k + *rank as f64);
                rrf_scores.insert(path.clone(), bm25_weight * bm25_rrf);
            }
        }
        
        // Re-sort results by RRF score, keeping only those in dense results
        results.sort_by(|a, b| {
            let sa = rrf_scores.get(&a.0.path).copied().unwrap_or(0.0);
            let sb = rrf_scores.get(&b.0.path).copied().unwrap_or(0.0);
            sb.partial_cmp(&sa).unwrap_or(std::cmp::Ordering::Equal)
        });

        // Min-max normalize RRF scores back to 0–1 so displayed scores remain meaningful.
        let rrf_min = results.iter()
            .map(|(r, _)| rrf_scores.get(&r.path).copied().unwrap_or(0.0))
            .fold(f64::INFINITY, f64::min);
        let rrf_max = results.iter()
            .map(|(r, _)| rrf_scores.get(&r.path).copied().unwrap_or(0.0))
            .fold(f64::NEG_INFINITY, f64::max);
        let rrf_range = (rrf_max - rrf_min).max(1e-10);

        results = results.into_iter()
            .map(|(r, _)| {
                let rrf = rrf_scores.get(&r.path).copied().unwrap_or(0.0);
                let normalized = (rrf - rrf_min) / rrf_range;
                (r, normalized)
            })
            .collect();
    }

    // Apply MMR reranking for diversity only if enabled
    let reranked = if use_mmr {
        mmr_rerank(results, limit, mmr_lambda)
    } else {
        results.into_iter().take(limit).collect()
    };

    // Increment frequency for returned results.
    for (result, _) in &reranked {
        let _ = increment_frequency(conn, &result.path);
    }

    Ok(reranked)
}

/// Serialize a float32 slice to little-endian bytes.
pub fn serialize_embedding(v: &[f32]) -> Vec<u8> {
    v.iter().flat_map(|f| f.to_le_bytes()).collect()
}

/// Deserialize little-endian bytes back to a float32 vector.
pub fn deserialize_embedding(b: &[u8]) -> Vec<f32> {
    b.chunks_exact(4)
        .map(|c| f32::from_le_bytes(c.try_into().unwrap()))
        .collect()
}

/// Compute cosine similarity between two equal-length vectors.
///
/// Returns 0.0 if either vector has zero magnitude.
fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let mag_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let mag_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    if mag_a == 0.0 || mag_b == 0.0 {
        0.0
    } else {
        dot / (mag_a * mag_b)
    }
}

/// Current Unix timestamp in seconds.
fn now_unix() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64
}

/// Extension trait to add `.optional()` to rusqlite query results.
trait OptionalExt<T> {
    fn optional(self) -> rusqlite::Result<Option<T>>;
}

impl<T> OptionalExt<T> for rusqlite::Result<T> {
    fn optional(self) -> rusqlite::Result<Option<T>> {
        match self {
            Ok(v) => Ok(Some(v)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn in_memory_db() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        create_schema(&conn).unwrap();
        conn
    }

    #[test]
    fn test_upsert_and_get_mtime() {
        let conn = in_memory_db();
        upsert(
            &conn,
            "/test/path.md",
            Some("Title"),
            "content",
            12345,
            Some("fact"),
            None,
            "fact",
            true,
            0.7,
            0.5,
            0.0,
            0.5,
            &[0.1, 0.2, 0.3],
            &UpsertOptions { force_metadata: true },
        )
        .unwrap();

        let mtime = get_mtime(&conn, "/test/path.md").unwrap();
        assert_eq!(mtime, Some(12345));
    }

    #[test]
    fn test_delete() {
        let conn = in_memory_db();
        upsert(
            &conn,
            "/test/del.md",
            None,
            "content",
            1,
            None,
            None,
            "fact",
            true,
            0.7,
            0.5,
            0.0,
            0.5,
            &[],
            &UpsertOptions { force_metadata: true },
        )
        .unwrap();
        delete(&conn, "/test/del.md").unwrap();
        assert_eq!(get_mtime(&conn, "/test/del.md").unwrap(), None);
    }

    #[test]
    fn test_indexed_doc_invisible_to_get_mtime() {
        let conn = in_memory_db();
        upsert(
            &conn,
            "/indexed/doc.md",
            None,
            "content",
            999,
            None,
            None,
            "reference",
            false,
            0.75,
            0.8,
            0.0,
            0.5,
            &[],
            &UpsertOptions { force_metadata: true },
        )
        .unwrap();
        // get_mtime only sees is_memory=1 records.
        assert_eq!(get_mtime(&conn, "/indexed/doc.md").unwrap(), None);
    }

    #[test]
    fn test_clear_only_affects_memories() {
        let conn = in_memory_db();
        upsert(&conn, "/mem.md", None, "c", 1, None, None, "fact", true,
               0.7, 0.5, 0.0, 0.5, &[], &UpsertOptions { force_metadata: true }).unwrap();
        upsert(&conn, "/idx.md", None, "c", 1, None, None, "fact", false,
               0.75, 0.8, 0.0, 0.5, &[], &UpsertOptions { force_metadata: true }).unwrap();
        let deleted = clear(&conn, None).unwrap();
        assert_eq!(deleted, 1);
        // Indexed doc survives.
        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM documents", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 1);
    }

    #[test]
    fn test_list_all_excludes_indexed() {
        let conn = in_memory_db();
        upsert(&conn, "/mem.md", None, "memory content", 1, None, None, "fact", true,
               0.7, 0.5, 0.0, 0.5, &[], &UpsertOptions { force_metadata: true }).unwrap();
        upsert(&conn, "/idx.md", None, "indexed content", 1, None, None, "fact", false,
               0.75, 0.8, 0.0, 0.5, &[], &UpsertOptions { force_metadata: true }).unwrap();
        let memories = list_all(&conn, None).unwrap();
        assert_eq!(memories.len(), 1);
        assert_eq!(memories[0].path, "/mem.md");
    }

    #[test]
    fn test_serialize_deserialize_embedding() {
        let v = vec![1.0f32, 2.0, 3.0];
        let blob = serialize_embedding(&v);
        let back = deserialize_embedding(&blob);
        assert_eq!(v, back);
    }

    #[test]
    fn test_cosine_similarity_identical() {
        let v = vec![1.0f32, 0.0, 0.0];
        assert!((cosine_similarity(&v, &v) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn test_cosine_similarity_orthogonal() {
        let a = vec![1.0f32, 0.0];
        let b = vec![0.0f32, 1.0];
        assert!((cosine_similarity(&a, &b)).abs() < 1e-6);
    }
}
