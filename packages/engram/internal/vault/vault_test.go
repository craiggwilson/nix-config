package vault_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/craiggwilson/engram/internal/vault"
)

// writeFile creates a file at path with the given content.
func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("MkdirAll: %v", err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("WriteFile: %v", err)
	}
}

func TestWalkFindsMarkdownFiles(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello\n\ncontent")
	writeFile(t, filepath.Join(dir, "sub/nested.md"), "# Nested\n\ncontent")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 2 {
		t.Errorf("expected 2 files, got %d", len(files))
	}
}

func TestWalkSkipsNonMarkdown(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello")
	writeFile(t, filepath.Join(dir, "image.png"), "binary")
	writeFile(t, filepath.Join(dir, "data.json"), "{}")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 1 {
		t.Errorf("expected 1 file, got %d", len(files))
	}
}

func TestWalkSkipsHiddenDirectories(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello")
	writeFile(t, filepath.Join(dir, ".obsidian/config.md"), "hidden")
	writeFile(t, filepath.Join(dir, ".trash/deleted.md"), "deleted")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 1 {
		t.Errorf("expected 1 file (hidden dirs skipped), got %d", len(files))
	}
	if files[0].Path != filepath.Join(dir, "note.md") {
		t.Errorf("unexpected file: %q", files[0].Path)
	}
}

func TestWalkRespectsGitignore(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello")
	writeFile(t, filepath.Join(dir, "tmp/scratch.md"), "# Scratch")
	writeFile(t, filepath.Join(dir, "archive/old.md"), "# Old")
	writeFile(t, filepath.Join(dir, "keep/important.md"), "# Important")
	writeFile(t, filepath.Join(dir, ".gitignore"), "tmp/\narchive/\n")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}

	paths := make(map[string]bool)
	for _, f := range files {
		paths[f.Path] = true
	}

	if !paths[filepath.Join(dir, "note.md")] {
		t.Error("expected note.md to be included")
	}
	if !paths[filepath.Join(dir, "keep/important.md")] {
		t.Error("expected keep/important.md to be included")
	}
	if paths[filepath.Join(dir, "tmp/scratch.md")] {
		t.Error("expected tmp/scratch.md to be excluded by .gitignore")
	}
	if paths[filepath.Join(dir, "archive/old.md")] {
		t.Error("expected archive/old.md to be excluded by .gitignore")
	}
}

func TestWalkNoGitignore(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello")
	writeFile(t, filepath.Join(dir, "tmp/scratch.md"), "# Scratch")
	// No .gitignore — tmp/ should be included.

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 2 {
		t.Errorf("expected 2 files without .gitignore, got %d", len(files))
	}
}

func TestWalkParsesTitle(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# My Title\n\nsome content here")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	if files[0].Title != "My Title" {
		t.Errorf("got title %q, want %q", files[0].Title, "My Title")
	}
}

func TestWalkParsesFrontmatter(t *testing.T) {
	dir := t.TempDir()
	content := `---
title: Frontmatter Title
tags:
  - foo
  - bar
---

Body content here.
`
	writeFile(t, filepath.Join(dir, "note.md"), content)

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	f := files[0]
	if f.Title != "Frontmatter Title" {
		t.Errorf("got title %q, want %q", f.Title, "Frontmatter Title")
	}
	if len(f.Tags) != 2 {
		t.Errorf("expected 2 tags, got %d: %v", len(f.Tags), f.Tags)
	}
}

func TestWalkEmptyDir(t *testing.T) {
	dir := t.TempDir()

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if len(files) != 0 {
		t.Errorf("expected 0 files, got %d", len(files))
	}
}

func TestWalkPopulatesMtime(t *testing.T) {
	dir := t.TempDir()
	writeFile(t, filepath.Join(dir, "note.md"), "# Hello")

	files, err := vault.Walk(dir)
	if err != nil {
		t.Fatalf("Walk: %v", err)
	}
	if files[0].Mtime == 0 {
		t.Error("expected non-zero mtime")
	}
}
