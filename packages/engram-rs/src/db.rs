use anyhow::{Context, Result};
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

/// Open (or create) the SQLite database at `path`, running migrations.
pub fn open(path: &Path) -> Result<Connection> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("failed to create db directory {}", parent.display()))?;
    }

    let conn = Connection::open(path)
        .with_context(|| format!("failed to open database at {}", path.display()))?;

    migrate(&conn).context("database migration failed")?;

    Ok(conn)
}

/// Apply the schema migration (idempotent).
fn migrate(conn: &Connection) -> Result<()> {
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
            frequency      INTEGER NOT NULL DEFAULT 1,
            last_accessed  INTEGER NOT NULL DEFAULT 0,
            decay_rate     REAL    NOT NULL DEFAULT 0.0,
            importance     REAL    NOT NULL DEFAULT 0.5,
            confidence     REAL    NOT NULL DEFAULT 0.5,
            strength       REAL    NOT NULL DEFAULT 0.0,
            embedding      BLOB    NOT NULL DEFAULT ''
        );",
    )
    .context("failed to create documents table")
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
    importance: f64,
    confidence: f64,
    decay_rate: f64,
    strength: f64,
    embedding: &[f32],
    opts: &UpsertOptions,
) -> Result<()> {
    let embedding_blob = serialize_embedding(embedding);

    if opts.force_metadata {
        conn.execute(
            "INSERT INTO documents
                (path, title, content, mtime, type, tags, classification,
                 frequency, last_accessed, decay_rate, importance, confidence, strength, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 1, 0, ?8, ?9, ?10, ?11, ?12)
             ON CONFLICT(path) DO UPDATE SET
                title          = excluded.title,
                content        = excluded.content,
                mtime          = excluded.mtime,
                type           = excluded.type,
                tags           = excluded.tags,
                classification = excluded.classification,
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
                (path, title, content, mtime, type, tags, classification,
                 frequency, last_accessed, decay_rate, importance, confidence, strength, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 1, 0, ?8, ?9, ?10, ?11, ?12)
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
                decay_rate,
                importance,
                confidence,
                strength,
                embedding_blob,
            ],
        )
        .context("failed to upsert document (force_metadata=false)")?;
    }

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

/// Return the stored mtime for a path, or None if not found.
pub fn get_mtime(conn: &Connection, path: &str) -> Result<Option<i64>> {
    let mut stmt = conn
        .prepare("SELECT mtime FROM documents WHERE path = ?1")
        .context("failed to prepare get_mtime query")?;

    let result = stmt
        .query_row(params![path], |row| row.get::<_, i64>(0))
        .optional()
        .context("failed to execute get_mtime query")?;

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

/// Load all episodic memories for decay processing.
pub fn all_episodic(conn: &Connection) -> Result<Vec<(i64, String, f64, f64, i64)>> {
    let mut stmt = conn
        .prepare(
            "SELECT id, path, strength, decay_rate, last_accessed
             FROM documents
             WHERE classification = 'episodic'",
        )
        .context("failed to prepare all_episodic query")?;

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
        .context("failed to execute all_episodic query")?
        .collect::<rusqlite::Result<Vec<_>>>()
        .context("failed to collect episodic rows")?;

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

/// Delete a document by id.
pub fn delete_by_id(conn: &Connection, id: i64) -> Result<()> {
    conn.execute("DELETE FROM documents WHERE id = ?1", params![id])
        .context("failed to delete document by id")?;
    Ok(())
}

/// Brute-force cosine similarity search.
///
/// Returns up to `limit` results sorted by combined score descending.
/// Combined score = semantic_score * 0.5 + strength * 0.5.
pub fn search(conn: &Connection, query_embedding: &[f32], limit: usize) -> Result<Vec<(SearchResult, f64)>> {
    let mut stmt = conn
        .prepare(
            "SELECT path, classification, strength, content, embedding
             FROM documents
             WHERE length(embedding) > 0",
        )
        .context("failed to prepare search query")?;

    let mut results: Vec<(SearchResult, f64)> = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, f64>(2)?,
                row.get::<_, String>(3)?,
                row.get::<_, Vec<u8>>(4)?,
            ))
        })
        .context("failed to execute search query")?
        .filter_map(|r| r.ok())
        .filter_map(|(path, classification, strength, content, blob)| {
            let doc_embedding = deserialize_embedding(&blob);
            if doc_embedding.is_empty() {
                return None;
            }
            let semantic_score = cosine_similarity(query_embedding, &doc_embedding) as f64;
            let combined = semantic_score * 0.5 + strength * 0.5;
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
    results.truncate(limit);

    // Increment frequency for returned results.
    for (result, _) in &results {
        let _ = increment_frequency(conn, &result.path);
    }

    Ok(results)
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
        migrate(&conn).unwrap();
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
