// Package config defines the shared configuration struct for engram commands.
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/adrg/xdg"
)

// Config holds all runtime configuration for engram, populated from cobra flags.
type Config struct {
	// DBPath is the path to the sqlite database file.
	DBPath string

	// IndexedPaths is the list of directories to index during ingestion.
	IndexedPaths []string

	// MemoryPath is the absolute path to the memory directory.
	MemoryPath string
}

// ExpandPath expands ~ and environment variables in a path, then cleans it.
func ExpandPath(p string) (string, error) {
	// Expand environment variables first.
	p = os.ExpandEnv(p)

	// Expand leading ~ to the home directory.
	if p == "~" || strings.HasPrefix(p, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("expanding ~: %w", err)
		}
		p = home + p[1:]
	}

	return filepath.Clean(p), nil
}

// ExpandPaths expands all paths in the config in place.
// If MemoryPath is empty, it defaults to $XDG_DATA_HOME/engram/memories.
func (c *Config) ExpandPaths() error {
	// Apply default memory path if not provided.
	if c.MemoryPath == "" {
		defaultPath, err := DefaultMemoryPath()
		if err != nil {
			return fmt.Errorf("determining default memory path: %w", err)
		}
		c.MemoryPath = defaultPath
	} else {
		expanded, err := ExpandPath(c.MemoryPath)
		if err != nil {
			return fmt.Errorf("--memory-path: %w", err)
		}
		c.MemoryPath = expanded
	}

	for i, p := range c.IndexedPaths {
		expanded, err := ExpandPath(p)
		if err != nil {
			return fmt.Errorf("--indexed-path %q: %w", p, err)
		}
		c.IndexedPaths[i] = expanded
	}

	return nil
}

// ValidateMemoryPath returns an error if MemoryPath is not absolute.
// MemoryPath should be set by ExpandPaths() before this is called.
func (c *Config) ValidateMemoryPath() error {
	if !filepath.IsAbs(c.MemoryPath) {
		return fmt.Errorf("--memory-path must be an absolute path, got %q", c.MemoryPath)
	}
	return nil
}

// DefaultMemoryPath returns the default path for the engram memory directory.
// It respects XDG_DATA_HOME on Linux/Unix and uses platform-appropriate defaults on macOS/Windows.
func DefaultMemoryPath() (string, error) {
	if xdg.DataHome == "" {
		return "", fmt.Errorf("could not determine XDG data home")
	}
	return filepath.Join(xdg.DataHome, "engram", "memories"), nil
}

// DefaultDBPath returns the default path for the engram sqlite database.
// It respects XDG_DATA_HOME on Linux/Unix and uses platform-appropriate defaults on macOS/Windows.
func DefaultDBPath() (string, error) {
	if xdg.DataHome == "" {
		return "", fmt.Errorf("could not determine XDG data home")
	}
	return filepath.Join(xdg.DataHome, "engram", "engram.db"), nil
}
