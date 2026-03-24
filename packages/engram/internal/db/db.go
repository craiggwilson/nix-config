// Package db manages the sqlite database and vector search index for engram.
package db

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"time"

	sqlite_vec "github.com/asg017/sqlite-vec-go-bindings/cgo"
	_ "github.com/mattn/go-sqlite3"
)

// Document represents a markdown file stored in the database.
type Document struct {
	// Path is the absolute path to the file.
	Path string

	// Title is the document title.
	Title string

	// Content is the body text (frontmatter stripped).
	Content string

	// Mtime is the file modification time as a Unix timestamp.
	Mtime int64

	// Type is the document type from frontmatter.
	Type string

	// Tags is the list of tags from frontmatter.
	Tags []string

	// Embedding is the vector embedding for the document.
	Embedding []float32

	// Classification is the memory type: episodic, preference, fact, or empty for KB docs.
	Classification string

	// Frequency is the number of times this document has been accessed.
	Frequency int

	// LastAccessed is the Unix timestamp of the last access.
	LastAccessed int64

	// DecayRate is the exponential decay rate for episodic memories.
	DecayRate float64

	// Importance is the importance score (0-1).
	Importance float64

	// Confidence is the confidence score (0-1).
	Confidence float64

	// Strength is the overall memory strength (0-1).
	Strength float64
}

// SearchResult is a document returned from a KNN vector search.
type SearchResult struct {
	// Path is the absolute path to the file.
	Path string

	// Title is the document title.
	Title string

	// Snippet is the first 200 characters of the content.
	Snippet string

	// Distance is the vector distance from the query embedding.
	Distance float64

	// Classification is the memory type (episodic, preference, fact, or empty for KB docs).
	Classification string

	// Strength is the memory strength score (0-1).
	Strength float64

	// Score is the combined ranking score (0-1).
	Score float64
}

// DB wraps a sqlite database with vector search capabilities.
type DB struct {
	conn *sql.DB
}

// Open opens (or creates) the engram sqlite database at dbPath.
// It loads the sqlite-vec extension and runs schema migrations.
func Open(dbPath string) (*DB, error) {
	sqlite_vec.Auto()

	if err := os.MkdirAll(filepath.Dir(dbPath), 0o755); err != nil {
		return nil, fmt.Errorf("creating db directory: %w", err)
	}

	conn, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("opening sqlite db: %w", err)
	}

	if _, err := conn.Exec(`
		PRAGMA journal_mode=WAL;
		PRAGMA busy_timeout=5000;
	`); err != nil {
		conn.Close()
		return nil, fmt.Errorf("configuring sqlite pragmas: %w", err)
	}

	db := &DB{conn: conn}
	if err := db.migrate(); err != nil {
		conn.Close()
		return nil, fmt.Errorf("running migrations: %w", err)
	}

	return db, nil
}

// Close closes the underlying database connection.
func (db *DB) Close() error {
	return db.conn.Close()
}

// migrate creates the required tables if they do not already exist.
func (db *DB) migrate() error {
	_, err := db.conn.Exec(`
		CREATE TABLE IF NOT EXISTS documents (
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
			strength       REAL    NOT NULL DEFAULT 0.0
		);

		CREATE VIRTUAL TABLE IF NOT EXISTS vec_documents USING vec0(
			document_id INTEGER PRIMARY KEY,
			embedding   float[384]
		);
	`)
	if err != nil {
		return fmt.Errorf("creating schema: %w", err)
	}
	return nil
}

// UpsertDocument inserts or replaces a document and its embedding in the database.
// When forceMetadata is false, existing memory metadata columns are preserved on conflict.
// When forceMetadata is true, all columns including metadata are updated on conflict.
func (db *DB) UpsertDocument(doc Document, forceMetadata bool) error {
	tagsJSON, err := json.Marshal(doc.Tags)
	if err != nil {
		return fmt.Errorf("marshalling tags: %w", err)
	}

	tx, err := db.conn.Begin()
	if err != nil {
		return fmt.Errorf("beginning transaction: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	var docID int64
	var query string
	if forceMetadata {
		// Update all columns including metadata
		query = `
			INSERT INTO documents (path, title, content, mtime, type, tags, classification, frequency, last_accessed, decay_rate, importance, confidence, strength)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(path) DO UPDATE SET
				title          = excluded.title,
				content        = excluded.content,
				mtime          = excluded.mtime,
				type           = excluded.type,
				tags           = excluded.tags,
				classification = excluded.classification,
				frequency      = excluded.frequency,
				last_accessed  = excluded.last_accessed,
				decay_rate     = excluded.decay_rate,
				importance     = excluded.importance,
				confidence     = excluded.confidence,
				strength       = excluded.strength
			RETURNING id
		`
	} else {
		// Preserve existing memory metadata columns
		query = `
			INSERT INTO documents (path, title, content, mtime, type, tags, classification, frequency, last_accessed, decay_rate, importance, confidence, strength)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(path) DO UPDATE SET
				title          = excluded.title,
				content        = excluded.content,
				mtime          = excluded.mtime,
				type           = excluded.type,
				tags           = excluded.tags
			RETURNING id
		`
	}

	err = tx.QueryRow(query, doc.Path, doc.Title, doc.Content, doc.Mtime, doc.Type, string(tagsJSON), doc.Classification, doc.Frequency, doc.LastAccessed, doc.DecayRate, doc.Importance, doc.Confidence, doc.Strength).Scan(&docID)
	if err != nil {
		return fmt.Errorf("upserting document: %w", err)
	}

	embeddingBytes, err := sqlite_vec.SerializeFloat32(doc.Embedding)
	if err != nil {
		return fmt.Errorf("serializing embedding: %w", err)
	}

	// sqlite-vec virtual tables do not support ON CONFLICT upsert syntax —
	// delete the existing row first, then insert.
	if _, err = tx.Exec(`DELETE FROM vec_documents WHERE document_id = ?`, docID); err != nil {
		return fmt.Errorf("deleting old embedding: %w", err)
	}
	if _, err = tx.Exec(`INSERT INTO vec_documents (document_id, embedding) VALUES (?, ?)`, docID, embeddingBytes); err != nil {
		return fmt.Errorf("inserting embedding: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("committing transaction: %w", err)
	}

	return nil
}

// GetMtime returns the stored modification time for the given path.
// Returns (0, false) if the path is not in the database.
func (db *DB) GetMtime(path string) (int64, bool) {
	var mtime int64
	err := db.conn.QueryRow(`SELECT mtime FROM documents WHERE path = ?`, path).Scan(&mtime)
	if err != nil {
		return 0, false
	}
	return mtime, true
}

// Search performs a KNN vector search and returns the top limit results.
func (db *DB) Search(embedding []float32, limit int) ([]SearchResult, error) {
	embeddingBytes, err := sqlite_vec.SerializeFloat32(embedding)
	if err != nil {
		return nil, fmt.Errorf("serializing query embedding: %w", err)
	}

	rows, err := db.conn.Query(`
		SELECT d.path, d.title, d.content, v.distance, d.classification, d.strength
		FROM vec_documents v
		JOIN documents d ON d.id = v.document_id
		WHERE v.embedding MATCH ?
		  AND k = ?
		ORDER BY v.distance
	`, embeddingBytes, limit)
	if err != nil {
		return nil, fmt.Errorf("executing vector search: %w", err)
	}
	defer rows.Close()

	var results []SearchResult
	for rows.Next() {
		var r SearchResult
		var content string
		if err := rows.Scan(&r.Path, &r.Title, &content, &r.Distance, &r.Classification, &r.Strength); err != nil {
			return nil, fmt.Errorf("scanning search result: %w", err)
		}
		r.Snippet = snippet(content, 200)
		// sqlite-vec cosine distance is in [0, 2]; normalize to [0, 1] then
		// invert so that 1.0 = identical, 0.0 = opposite.
		semanticScore := 1.0 - (r.Distance / 2.0)
		r.Score = semanticScore*0.5 + r.Strength*0.5
		results = append(results, r)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating search results: %w", err)
	}

	// Sort by score descending
	for i := 0; i < len(results); i++ {
		for j := i + 1; j < len(results); j++ {
			if results[j].Score > results[i].Score {
				results[i], results[j] = results[j], results[i]
			}
		}
	}

	return results, nil
}

// DeleteDocument removes a document and its embedding from the database.
func (db *DB) DeleteDocument(path string) error {
	tx, err := db.conn.Begin()
	if err != nil {
		return fmt.Errorf("beginning transaction: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	var docID int64
	err = tx.QueryRow(`SELECT id FROM documents WHERE path = ?`, path).Scan(&docID)
	if err == sql.ErrNoRows {
		return tx.Commit()
	}
	if err != nil {
		return fmt.Errorf("looking up document: %w", err)
	}

	if _, err := tx.Exec(`DELETE FROM vec_documents WHERE document_id = ?`, docID); err != nil {
		return fmt.Errorf("deleting embedding: %w", err)
	}
	if _, err := tx.Exec(`DELETE FROM documents WHERE id = ?`, docID); err != nil {
		return fmt.Errorf("deleting document: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("committing transaction: %w", err)
	}

	return nil
}

// AllPaths returns all document paths currently stored in the database.
func (db *DB) AllPaths() ([]string, error) {
	rows, err := db.conn.Query(`SELECT path FROM documents`)
	if err != nil {
		return nil, fmt.Errorf("querying paths: %w", err)
	}
	defer rows.Close()

	var paths []string
	for rows.Next() {
		var p string
		if err := rows.Scan(&p); err != nil {
			return nil, fmt.Errorf("scanning path: %w", err)
		}
		paths = append(paths, p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating paths: %w", err)
	}

	return paths, nil
}

// IncrementFrequency increments the frequency counter and updates last_accessed for a document.
func (db *DB) IncrementFrequency(path string) error {
	_, err := db.conn.Exec(`
		UPDATE documents
		SET frequency = frequency + 1, last_accessed = ?
		WHERE path = ?
	`, time.Now().Unix(), path)
	if err != nil {
		return fmt.Errorf("incrementing frequency: %w", err)
	}
	return nil
}

// episodicMemory holds the data needed to apply decay to a single episodic memory.
type episodicMemory struct {
	id           int64
	strength     float64
	decayRate    float64
	lastAccessed int64
}

// ApplyDecay applies Ebbinghaus decay to episodic memories and removes faded ones.
// Returns the count of episodic memories processed.
func (db *DB) ApplyDecay() (int, error) {
	// Collect all episodic memories first (before opening a write transaction)
	// to avoid holding a read cursor open during writes.
	rows, err := db.conn.Query(`
		SELECT id, strength, decay_rate, last_accessed
		FROM documents
		WHERE classification = 'episodic'
	`)
	if err != nil {
		return 0, fmt.Errorf("querying episodic memories: %w", err)
	}

	var memories []episodicMemory
	for rows.Next() {
		var m episodicMemory
		if err := rows.Scan(&m.id, &m.strength, &m.decayRate, &m.lastAccessed); err != nil {
			rows.Close()
			return 0, fmt.Errorf("scanning memory: %w", err)
		}
		memories = append(memories, m)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, fmt.Errorf("iterating memories: %w", err)
	}

	if len(memories) == 0 {
		return 0, nil
	}

	now := time.Now().Unix()

	tx, err := db.conn.Begin()
	if err != nil {
		return 0, fmt.Errorf("beginning transaction: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	for _, m := range memories {
		hoursSince := float64(now-m.lastAccessed) / 3600.0
		if hoursSince < 0 {
			hoursSince = 0
		}

		// Apply Ebbinghaus decay: new_strength = strength * exp(-decay_rate * hours)
		newStrength := m.strength * math.Exp(-m.decayRate*hoursSince)

		if newStrength < 0.05 {
			if _, err := tx.Exec(`DELETE FROM vec_documents WHERE document_id = ?`, m.id); err != nil {
				return 0, fmt.Errorf("deleting embedding: %w", err)
			}
			if _, err := tx.Exec(`DELETE FROM documents WHERE id = ?`, m.id); err != nil {
				return 0, fmt.Errorf("deleting document: %w", err)
			}
		} else {
			if _, err := tx.Exec(`UPDATE documents SET strength = ? WHERE id = ?`, newStrength, m.id); err != nil {
				return 0, fmt.Errorf("updating strength: %w", err)
			}
		}
	}

	if err := tx.Commit(); err != nil {
		return 0, fmt.Errorf("committing transaction: %w", err)
	}

	return len(memories), nil
}

// CalculateStrength computes the memory strength using a 7-feature model.
func CalculateStrength(classification string, frequency int, confidence float64) float64 {
	// KB documents have no strength
	if classification == "" {
		return 0.0
	}

	// 7-feature model with weights
	recency := 0.0 // Always fresh on add
	frequencyScore := math.Min(1.0, math.Log(float64(frequency)+1)/math.Log(10))

	// Importance varies by classification
	var importance float64
	switch classification {
	case "preference":
		importance = 0.8
	case "fact":
		importance = 0.7
	case "episodic":
		importance = 0.4
	default:
		importance = 0.0
	}

	utility := 0.5
	novelty := 0.5
	interference := 0.0

	// Weights
	weights := map[string]float64{
		"recency":      0.20,
		"frequency":    0.15,
		"importance":   0.25,
		"utility":      0.20,
		"novelty":      0.10,
		"confidence":   0.10,
		"interference": -0.10,
	}

	strength := weights["recency"]*recency +
		weights["frequency"]*frequencyScore +
		weights["importance"]*importance +
		weights["utility"]*utility +
		weights["novelty"]*novelty +
		weights["confidence"]*confidence +
		weights["interference"]*interference

	// Clamp to [0, 1]
	return math.Max(0, math.Min(1, strength))
}

// DecayRate returns the decay rate for a given classification.
func DecayRate(classification string) float64 {
	if classification == "episodic" {
		return 0.05 // Decays to ~5% in ~60 hours
	}
	return 0.0
}

// snippet returns up to maxLen characters of text.
func snippet(text string, maxLen int) string {
	runes := []rune(text)
	if len(runes) <= maxLen {
		return text
	}
	return string(runes[:maxLen]) + "…"
}
