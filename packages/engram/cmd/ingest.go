package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/craiggwilson/engram/internal/db"
	"github.com/craiggwilson/engram/internal/embed"
	"github.com/craiggwilson/engram/internal/vault"
	"github.com/spf13/cobra"
)

var ingestFull bool

var ingestCmd = &cobra.Command{
	Use:   "ingest",
	Short: "Index markdown files into the database",
	Long: `Walk the memory directory and any configured indexed paths, embedding all
markdown files into the sqlite-vec database. Skips files whose modification
time has not changed unless --full is set.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := cfg.ValidateMemoryPath(); err != nil {
			return err
		}

		database, err := db.Open(cfg.DBPath)
		if err != nil {
			return fmt.Errorf("opening database: %w", err)
		}
		defer database.Close()

		// Collect all directories to walk: memory-path is always included.
		dirs := make([]string, 0, 1+len(cfg.IndexedPaths))
		dirs = append(dirs, cfg.MemoryPath)
		dirs = append(dirs, cfg.IndexedPaths...)

		// Walk all directories and merge files, deduplicating by path.
		seen := make(map[string]struct{})
		var files []vault.File
		for _, dir := range dirs {
			walked, err := vault.Walk(dir)
			if err != nil {
				return fmt.Errorf("walking %s: %w", dir, err)
			}
			for _, f := range walked {
				if _, ok := seen[f.Path]; ok {
					continue
				}
				seen[f.Path] = struct{}{}
				files = append(files, f)
			}
		}

		// Build a set of current paths for deletion detection.
		currentPaths := make(map[string]struct{}, len(files))
		for _, f := range files {
			currentPaths[f.Path] = struct{}{}
		}

		// Delete records for files that no longer exist.
		storedPaths, err := database.AllPaths()
		if err != nil {
			return fmt.Errorf("listing stored paths: %w", err)
		}
		deleted := 0
		for _, p := range storedPaths {
			if _, ok := currentPaths[p]; !ok {
				if err := database.DeleteDocument(p); err != nil {
					return fmt.Errorf("deleting removed document %s: %w", p, err)
				}
				deleted++
			}
		}

		ingested := 0
		skipped := 0

		episodicPrefix := cfg.MemoryPath + "/episodic/"
		preferencePrefix := cfg.MemoryPath + "/preference/"
		factPrefix := cfg.MemoryPath + "/fact/"

		for _, f := range files {
			if !ingestFull {
				storedMtime, found := database.GetMtime(f.Path)
				if found && storedMtime == f.Mtime {
					skipped++
					continue
				}
			}

			embedText := buildEmbedText(f)
			embedding, err := embed.Embed(embedText, "")
			if err != nil {
				fmt.Fprintf(os.Stderr, "warning: embedding %s: %v\n", f.Path, err)
				continue
			}

			// Detect if this is a memory file and extract classification.
			// Use cfg.MemoryPath as the prefix so memory can live outside indexed paths.
			var classification string
			var importance float64
			var decayRate float64

			if strings.HasPrefix(f.Path, episodicPrefix) {
				classification = "episodic"
				importance = 0.4
				decayRate = db.DecayRate("episodic")
			} else if strings.HasPrefix(f.Path, preferencePrefix) {
				classification = "preference"
				importance = 0.8
				decayRate = db.DecayRate("preference")
			} else if strings.HasPrefix(f.Path, factPrefix) {
				classification = "fact"
				importance = 0.7
				decayRate = db.DecayRate("fact")
			} else {
				classification = ""
				importance = 0.5
				decayRate = 0.0
			}

			var strength float64
			if classification != "" {
				strength = db.CalculateStrength(classification, 1, 0.8)
			}

			doc := db.Document{
				Path:           f.Path,
				Title:          f.Title,
				Content:        f.Content,
				Mtime:          f.Mtime,
				Type:           f.Type,
				Tags:           f.Tags,
				Embedding:      embedding,
				Classification: classification,
				Frequency:      1,
				LastAccessed:   f.Mtime,
				DecayRate:      decayRate,
				Importance:     importance,
				Confidence:     0.8,
				Strength:       strength,
			}
			if err := database.UpsertDocument(doc, ingestFull); err != nil {
				return fmt.Errorf("upserting %s: %w", f.Path, err)
			}
			ingested++
		}

		fmt.Printf("ingested %d files, skipped %d unchanged, deleted %d removed\n",
			ingested, skipped, deleted)
		return nil
	},
}

func init() {
	ingestCmd.Flags().BoolVar(&ingestFull, "full", false,
		"re-embed all files regardless of modification time")
}

// buildEmbedText combines the title and content for embedding.
func buildEmbedText(f vault.File) string {
	if f.Title != "" {
		return f.Title + "\n\n" + f.Content
	}
	return f.Content
}
