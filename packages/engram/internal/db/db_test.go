package db_test

import (
	"path/filepath"
	"testing"
	"time"

	"github.com/craiggwilson/engram/internal/db"
)

// openTestDB opens a fresh database in t.TempDir() and registers cleanup.
func openTestDB(t *testing.T) *db.DB {
	t.Helper()
	path := filepath.Join(t.TempDir(), "test.db")
	d, err := db.Open(path)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	t.Cleanup(func() { d.Close() })
	return d
}

// makeEmbedding returns a normalised 384-dim vector with value v at index 0.
func makeEmbedding(v float32) []float32 {
	e := make([]float32, 384)
	e[0] = v
	return e
}

func TestUpsertAndSearch(t *testing.T) {
	d := openTestDB(t)

	doc := db.Document{
		Path:           "/vault/note.md",
		Title:          "Test Note",
		Content:        "hello world",
		Mtime:          time.Now().Unix(),
		Embedding:      makeEmbedding(1.0),
		Classification: "fact",
		Frequency:      1,
		LastAccessed:   time.Now().Unix(),
		Strength:       db.CalculateStrength("fact", 1, 0.8),
		DecayRate:      db.DecayRate("fact"),
		Importance:     0.7,
		Confidence:     0.8,
	}

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}

	results, err := d.Search(makeEmbedding(1.0), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}
	if results[0].Path != doc.Path {
		t.Errorf("got path %q, want %q", results[0].Path, doc.Path)
	}
	if results[0].Classification != "fact" {
		t.Errorf("got classification %q, want %q", results[0].Classification, "fact")
	}
	if results[0].Strength <= 0 {
		t.Errorf("expected positive strength, got %f", results[0].Strength)
	}
	if results[0].Score < 0 || results[0].Score > 1 {
		t.Errorf("score %f out of range [0, 1]", results[0].Score)
	}
}

func TestSearchScoreInRange(t *testing.T) {
	d := openTestDB(t)

	// KB doc — no strength, score should be in [0, 0.5].
	kb := db.Document{
		Path:         "/vault/kb.md",
		Title:        "KB Doc",
		Content:      "some content",
		Mtime:        time.Now().Unix(),
		Embedding:    makeEmbedding(1.0),
		Frequency:    1,
		LastAccessed: time.Now().Unix(),
	}
	if err := d.UpsertDocument(kb, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}

	results, err := d.Search(makeEmbedding(1.0), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) == 0 {
		t.Fatal("expected results")
	}
	for _, r := range results {
		if r.Score < 0 || r.Score > 1 {
			t.Errorf("score %f out of range [0, 1] for %q", r.Score, r.Path)
		}
	}
}

func TestUpsertIsIdempotent(t *testing.T) {
	d := openTestDB(t)

	doc := db.Document{
		Path:         "/vault/note.md",
		Title:        "Original",
		Content:      "original content",
		Mtime:        time.Now().Unix(),
		Embedding:    makeEmbedding(0.5),
		Frequency:    1,
		LastAccessed: time.Now().Unix(),
	}

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("first UpsertDocument: %v", err)
	}

	// Update the same path with new content.
	doc.Title = "Updated"
	doc.Content = "updated content"
	doc.Embedding = makeEmbedding(0.9)

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("second UpsertDocument: %v", err)
	}

	results, err := d.Search(makeEmbedding(0.9), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) != 1 {
		t.Fatalf("expected 1 result, got %d", len(results))
	}
	if results[0].Title != "Updated" {
		t.Errorf("got title %q, want %q", results[0].Title, "Updated")
	}
}

func TestSearchRanksMemoriesAboveKBDocs(t *testing.T) {
	d := openTestDB(t)

	// KB document — no strength.
	kb := db.Document{
		Path:         "/vault/notes/kb.md",
		Title:        "KB Doc",
		Content:      "some knowledge",
		Mtime:        time.Now().Unix(),
		Embedding:    makeEmbedding(1.0),
		Frequency:    1,
		LastAccessed: time.Now().Unix(),
	}

	// Memory with strength — same embedding direction.
	mem := db.Document{
		Path:           "/vault/memory/fact/decision.md",
		Title:          "Decision",
		Content:        "some knowledge",
		Mtime:          time.Now().Unix(),
		Embedding:      makeEmbedding(1.0),
		Classification: "fact",
		Frequency:      5,
		LastAccessed:   time.Now().Unix(),
		Strength:       db.CalculateStrength("fact", 5, 0.9),
		DecayRate:      db.DecayRate("fact"),
		Importance:     0.7,
		Confidence:     0.9,
	}

	if err := d.UpsertDocument(kb, false); err != nil {
		t.Fatalf("UpsertDocument kb: %v", err)
	}
	if err := d.UpsertDocument(mem, false); err != nil {
		t.Fatalf("UpsertDocument mem: %v", err)
	}

	results, err := d.Search(makeEmbedding(1.0), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) < 2 {
		t.Fatalf("expected 2 results, got %d", len(results))
	}
	if results[0].Path != mem.Path {
		t.Errorf("expected memory to rank first, got %q", results[0].Path)
	}
}

func TestApplyDecayRemovesFadedMemories(t *testing.T) {
	d := openTestDB(t)

	// Episodic memory with last_accessed far in the past so it decays below threshold.
	old := db.Document{
		Path:           "/vault/memory/episodic/old.md",
		Title:          "Old Memory",
		Content:        "something that happened",
		Mtime:          time.Now().Unix(),
		Embedding:      makeEmbedding(0.5),
		Classification: "episodic",
		Frequency:      1,
		LastAccessed:   time.Now().Add(-30 * 24 * time.Hour).Unix(), // 30 days ago
		Strength:       0.06,                                        // just above threshold before decay
		DecayRate:      db.DecayRate("episodic"),
		Importance:     0.4,
		Confidence:     0.5,
	}

	if err := d.UpsertDocument(old, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}

	n, err := d.ApplyDecay()
	if err != nil {
		t.Fatalf("ApplyDecay: %v", err)
	}
	if n == 0 {
		t.Fatal("expected at least one memory to be processed")
	}

	// The memory should be gone from search results.
	results, err := d.Search(makeEmbedding(0.5), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	for _, r := range results {
		if r.Path == old.Path {
			t.Errorf("expected faded memory to be deleted, but found it in results")
		}
	}
}

func TestApplyDecayPreservesStrongMemories(t *testing.T) {
	d := openTestDB(t)

	recent := db.Document{
		Path:           "/vault/memory/episodic/recent.md",
		Title:          "Recent Memory",
		Content:        "something that just happened",
		Mtime:          time.Now().Unix(),
		Embedding:      makeEmbedding(0.7),
		Classification: "episodic",
		Frequency:      1,
		LastAccessed:   time.Now().Add(-1 * time.Hour).Unix(), // 1 hour ago
		Strength:       0.9,
		DecayRate:      db.DecayRate("episodic"),
		Importance:     0.4,
		Confidence:     0.8,
	}

	if err := d.UpsertDocument(recent, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}

	if _, err := d.ApplyDecay(); err != nil {
		t.Fatalf("ApplyDecay: %v", err)
	}

	results, err := d.Search(makeEmbedding(0.7), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	found := false
	for _, r := range results {
		if r.Path == recent.Path {
			found = true
		}
	}
	if !found {
		t.Error("expected recent memory to survive decay")
	}
}

func TestApplyDecayIgnoresNonEpisodic(t *testing.T) {
	d := openTestDB(t)

	pref := db.Document{
		Path:           "/vault/memory/preference/style.md",
		Title:          "Style Preference",
		Content:        "always use tabs",
		Mtime:          time.Now().Unix(),
		Embedding:      makeEmbedding(0.3),
		Classification: "preference",
		Frequency:      1,
		LastAccessed:   time.Now().Add(-365 * 24 * time.Hour).Unix(), // 1 year ago
		Strength:       0.8,
		DecayRate:      db.DecayRate("preference"),
		Importance:     0.8,
		Confidence:     0.9,
	}

	if err := d.UpsertDocument(pref, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}

	if _, err := d.ApplyDecay(); err != nil {
		t.Fatalf("ApplyDecay: %v", err)
	}

	results, err := d.Search(makeEmbedding(0.3), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	found := false
	for _, r := range results {
		if r.Path == pref.Path {
			found = true
		}
	}
	if !found {
		t.Error("expected preference memory to survive decay (non-episodic)")
	}
}

func TestCalculateStrength(t *testing.T) {
	cases := []struct {
		classification string
		frequency      int
		confidence     float64
		wantPositive   bool
		wantZero       bool
	}{
		{"fact", 1, 0.8, true, false},
		{"preference", 1, 0.8, true, false},
		{"episodic", 1, 0.8, true, false},
		{"", 1, 0.8, false, true}, // KB doc — always 0
		{"fact", 10, 0.9, true, false},
	}

	for _, tc := range cases {
		s := db.CalculateStrength(tc.classification, tc.frequency, tc.confidence)
		if tc.wantZero && s != 0 {
			t.Errorf("CalculateStrength(%q, %d, %f) = %f, want 0", tc.classification, tc.frequency, tc.confidence, s)
		}
		if tc.wantPositive && s <= 0 {
			t.Errorf("CalculateStrength(%q, %d, %f) = %f, want > 0", tc.classification, tc.frequency, tc.confidence, s)
		}
		if s < 0 || s > 1 {
			t.Errorf("CalculateStrength(%q, %d, %f) = %f, want in [0,1]", tc.classification, tc.frequency, tc.confidence, s)
		}
	}
}

func TestDecayRate(t *testing.T) {
	if db.DecayRate("episodic") <= 0 {
		t.Error("episodic decay rate should be positive")
	}
	if db.DecayRate("fact") != 0 {
		t.Error("fact decay rate should be zero")
	}
	if db.DecayRate("preference") != 0 {
		t.Error("preference decay rate should be zero")
	}
	if db.DecayRate("") != 0 {
		t.Error("KB doc decay rate should be zero")
	}
}

func TestIncrementFrequency(t *testing.T) {
	d := openTestDB(t)

	doc := db.Document{
		Path:         "/vault/note.md",
		Title:        "Note",
		Content:      "content",
		Mtime:        time.Now().Unix(),
		Embedding:    makeEmbedding(0.5),
		Frequency:    1,
		LastAccessed: time.Now().Unix(),
	}

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("UpsertDocument: %v", err)
	}
	if err := d.IncrementFrequency(doc.Path); err != nil {
		t.Fatalf("IncrementFrequency: %v", err)
	}
}

func TestUpsertPreservesMetadataOnConflict(t *testing.T) {
	d := openTestDB(t)

	// Insert a document with forceMetadata=false and specific metadata values.
	doc := db.Document{
		Path:           "/vault/memory/fact/decision.md",
		Title:          "Original Title",
		Content:        "original content",
		Mtime:          time.Now().Unix(),
		Type:           "memory",
		Tags:           []string{"memory", "fact"},
		Embedding:      makeEmbedding(0.5),
		Classification: "fact",
		Frequency:      5,
		LastAccessed:   time.Now().Unix(),
		DecayRate:      db.DecayRate("fact"),
		Importance:     0.7,
		Confidence:     0.8,
		Strength:       0.6,
	}

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("first UpsertDocument: %v", err)
	}

	// Upsert again with forceMetadata=false, updating content and changing strength/frequency.
	doc.Title = "Updated Title"
	doc.Content = "updated content"
	doc.Embedding = makeEmbedding(0.7)
	doc.Strength = 0.9 // Different strength
	doc.Frequency = 10 // Different frequency

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("second UpsertDocument: %v", err)
	}

	// Search to verify the document was updated.
	results, err := d.Search(makeEmbedding(0.7), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}

	found := false
	for _, r := range results {
		if r.Path == doc.Path {
			found = true
			// Content should be updated
			if r.Title != "Updated Title" {
				t.Errorf("expected title to be updated to 'Updated Title', got %q", r.Title)
			}
			// Strength should be preserved from first insert (0.6), not updated to 0.9
			if r.Strength != 0.6 {
				t.Errorf("expected strength to be preserved at 0.6, got %f", r.Strength)
			}
			break
		}
	}
	if !found {
		t.Fatal("expected to find the document in search results")
	}
}

func TestUpsertForceMetadataOverwrites(t *testing.T) {
	d := openTestDB(t)

	// Insert a document with forceMetadata=false.
	doc := db.Document{
		Path:           "/vault/memory/preference/style.md",
		Title:          "Original Title",
		Content:        "original content",
		Mtime:          time.Now().Unix(),
		Type:           "memory",
		Tags:           []string{"memory", "preference"},
		Embedding:      makeEmbedding(0.3),
		Classification: "preference",
		Frequency:      2,
		LastAccessed:   time.Now().Unix(),
		DecayRate:      db.DecayRate("preference"),
		Importance:     0.8,
		Confidence:     0.7,
		Strength:       0.5,
	}

	if err := d.UpsertDocument(doc, false); err != nil {
		t.Fatalf("first UpsertDocument: %v", err)
	}

	// Upsert again with forceMetadata=true, changing metadata values.
	doc.Title = "Updated Title"
	doc.Content = "updated content"
	doc.Embedding = makeEmbedding(0.4)
	doc.Strength = 0.8 // Different strength
	doc.Frequency = 15 // Different frequency
	doc.Importance = 0.9
	doc.Confidence = 0.95

	if err := d.UpsertDocument(doc, true); err != nil {
		t.Fatalf("second UpsertDocument with forceMetadata=true: %v", err)
	}

	// Search to verify the document was updated.
	results, err := d.Search(makeEmbedding(0.4), 5)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}

	found := false
	for _, r := range results {
		if r.Path == doc.Path {
			found = true
			// Content should be updated
			if r.Title != "Updated Title" {
				t.Errorf("expected title to be updated to 'Updated Title', got %q", r.Title)
			}
			// Strength should be overwritten to 0.8 (from forceMetadata=true)
			if r.Strength != 0.8 {
				t.Errorf("expected strength to be overwritten to 0.8, got %f", r.Strength)
			}
			break
		}
	}
	if !found {
		t.Fatal("expected to find the document in search results")
	}
}
