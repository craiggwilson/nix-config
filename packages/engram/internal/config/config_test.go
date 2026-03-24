package config_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/adrg/xdg"
	"github.com/craiggwilson/engram/internal/config"
)

func TestValidateMemoryPathEmpty(t *testing.T) {
	cfg := &config.Config{}
	if err := cfg.ValidateMemoryPath(); err == nil {
		t.Error("expected error for empty MemoryPath, got nil")
	}
}

func TestDefaultMemoryPath(t *testing.T) {
	got, err := config.DefaultMemoryPath()
	if err != nil {
		t.Fatalf("DefaultMemoryPath: %v", err)
	}

	// The expected path should be $XDG_DATA_HOME/engram/memories
	// On Linux, if XDG_DATA_HOME is not set, xdg library defaults to ~/.local/share
	want := filepath.Join(xdg.DataHome, "engram", "memories")
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestExpandPathsAppliesDefaultMemoryPath(t *testing.T) {
	cfg := &config.Config{
		MemoryPath:   "",
		IndexedPaths: []string{},
	}

	if err := cfg.ExpandPaths(); err != nil {
		t.Fatalf("ExpandPaths: %v", err)
	}

	// The expected path should be $XDG_DATA_HOME/engram/memories
	want := filepath.Join(xdg.DataHome, "engram", "memories")
	if cfg.MemoryPath != want {
		t.Errorf("MemoryPath: got %q, want %q", cfg.MemoryPath, want)
	}
}

func TestValidateMemoryPathRelative(t *testing.T) {
	cfg := &config.Config{MemoryPath: "relative/path"}
	if err := cfg.ValidateMemoryPath(); err == nil {
		t.Error("expected error for relative MemoryPath, got nil")
	}
}

func TestValidateMemoryPathAbsolute(t *testing.T) {
	cfg := &config.Config{MemoryPath: "/absolute/path/to/memory"}
	if err := cfg.ValidateMemoryPath(); err != nil {
		t.Errorf("expected no error for absolute MemoryPath, got: %v", err)
	}
}

func TestExpandPathTilde(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("UserHomeDir: %v", err)
	}

	got, err := config.ExpandPath("~/foo/bar")
	if err != nil {
		t.Fatalf("ExpandPath: %v", err)
	}
	want := filepath.Join(home, "foo", "bar")
	if got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestExpandPathTildeOnly(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("UserHomeDir: %v", err)
	}

	got, err := config.ExpandPath("~")
	if err != nil {
		t.Fatalf("ExpandPath: %v", err)
	}
	if got != home {
		t.Errorf("got %q, want %q", got, home)
	}
}

func TestExpandPathEnvVar(t *testing.T) {
	t.Setenv("ENGRAM_TEST_DIR", "/tmp/testdir")

	got, err := config.ExpandPath("$ENGRAM_TEST_DIR/memory")
	if err != nil {
		t.Fatalf("ExpandPath: %v", err)
	}
	if got != "/tmp/testdir/memory" {
		t.Errorf("got %q, want %q", got, "/tmp/testdir/memory")
	}
}

func TestExpandPathAbsoluteUnchanged(t *testing.T) {
	got, err := config.ExpandPath("/absolute/path")
	if err != nil {
		t.Fatalf("ExpandPath: %v", err)
	}
	if got != "/absolute/path" {
		t.Errorf("got %q, want %q", got, "/absolute/path")
	}
}

func TestExpandPathsExpandsAll(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("UserHomeDir: %v", err)
	}
	t.Setenv("ENGRAM_TEST_INDEXED", "/tmp/indexed")

	cfg := &config.Config{
		MemoryPath:   "~/memory",
		IndexedPaths: []string{"$ENGRAM_TEST_INDEXED", "~/notes"},
	}

	if err := cfg.ExpandPaths(); err != nil {
		t.Fatalf("ExpandPaths: %v", err)
	}

	wantMemory := filepath.Join(home, "memory")
	if cfg.MemoryPath != wantMemory {
		t.Errorf("MemoryPath: got %q, want %q", cfg.MemoryPath, wantMemory)
	}
	if cfg.IndexedPaths[0] != "/tmp/indexed" {
		t.Errorf("IndexedPaths[0]: got %q, want %q", cfg.IndexedPaths[0], "/tmp/indexed")
	}
	wantNotes := filepath.Join(home, "notes")
	if cfg.IndexedPaths[1] != wantNotes {
		t.Errorf("IndexedPaths[1]: got %q, want %q", cfg.IndexedPaths[1], wantNotes)
	}
}
