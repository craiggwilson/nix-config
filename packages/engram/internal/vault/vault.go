// Package vault provides utilities for walking and parsing markdown files.
package vault

import (
	"bufio"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	gitignore "github.com/sabhiram/go-gitignore"
	"gopkg.in/yaml.v3"
)

// File represents a parsed markdown file from the vault.
type File struct {
	// Path is the absolute path to the file.
	Path string

	// Title is extracted from frontmatter or the first H1 heading.
	Title string

	// Content is the body of the file with frontmatter stripped.
	Content string

	// Mtime is the file modification time as a Unix timestamp.
	Mtime int64

	// Type is the document type from frontmatter.
	Type string

	// Tags is the list of tags from frontmatter.
	Tags []string
}

// frontmatter holds the YAML fields we care about.
type frontmatter struct {
	Title string   `yaml:"title"`
	Type  string   `yaml:"type"`
	Tags  []string `yaml:"tags"`
}

// Walk recursively walks dir and returns all parsed markdown files.
// It respects a .gitignore file at the directory root if one exists.
func Walk(dir string) ([]File, error) {
	var files []File

	// Load .gitignore from the directory root if present. Errors are ignored —
	// a missing or malformed .gitignore simply means nothing is excluded.
	ignore, _ := gitignore.CompileIgnoreFile(filepath.Join(dir, ".gitignore"))

	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return fmt.Errorf("walking %s: %w", path, err)
		}

		// Compute the path relative to the directory root for gitignore matching.
		rel, relErr := filepath.Rel(dir, path)
		if relErr != nil {
			return fmt.Errorf("computing relative path for %s: %w", path, relErr)
		}

		if d.IsDir() {
			// Always skip hidden directories (covers .obsidian, .trash, etc.).
			if strings.HasPrefix(d.Name(), ".") {
				return filepath.SkipDir
			}
			// Skip directories matched by .gitignore.
			if ignore != nil && ignore.MatchesPath(rel) {
				return filepath.SkipDir
			}
			return nil
		}

		// Skip files matched by .gitignore.
		if ignore != nil && ignore.MatchesPath(rel) {
			return nil
		}

		if !strings.HasSuffix(path, ".md") {
			return nil
		}

		info, err := d.Info()
		if err != nil {
			return fmt.Errorf("stat %s: %w", path, err)
		}

		raw, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("reading %s: %w", path, err)
		}

		fm, body := parseFrontmatter(string(raw))

		title := fm.Title
		if title == "" {
			title = extractH1(body)
		}
		if title == "" {
			title = strings.TrimSuffix(filepath.Base(path), ".md")
		}

		files = append(files, File{
			Path:    path,
			Title:   title,
			Content: body,
			Mtime:   info.ModTime().Unix(),
			Type:    fm.Type,
			Tags:    fm.Tags,
		})
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("walking %s: %w", dir, err)
	}

	return files, nil
}

// parseFrontmatter splits YAML frontmatter from the body of a markdown document.
// Returns the parsed frontmatter and the remaining body text.
func parseFrontmatter(content string) (frontmatter, string) {
	var fm frontmatter

	if !strings.HasPrefix(content, "---") {
		return fm, content
	}

	// Find the closing ---
	rest := content[3:]
	idx := strings.Index(rest, "\n---")
	if idx == -1 {
		return fm, content
	}

	yamlBlock := rest[:idx]
	body := rest[idx+4:] // skip "\n---"
	if strings.HasPrefix(body, "\n") {
		body = body[1:]
	}

	_ = yaml.Unmarshal([]byte(yamlBlock), &fm)
	return fm, body
}

// extractH1 returns the text of the first H1 heading in the markdown body.
func extractH1(body string) string {
	scanner := bufio.NewScanner(strings.NewReader(body))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "# ") {
			return strings.TrimPrefix(line, "# ")
		}
	}
	return ""
}
