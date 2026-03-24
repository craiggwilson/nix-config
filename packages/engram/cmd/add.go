package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/craiggwilson/engram/internal/db"
	"github.com/craiggwilson/engram/internal/embed"
	"github.com/spf13/cobra"
)

var addType string
var correlationID string

var addCmd = &cobra.Command{
	Use:   "add --type episodic|preference|fact <content>",
	Short: "Add a new memory file to the vault",
	Long: `Write a new markdown file to the memory subdirectory of the vault,
then embed and index it immediately. The --type flag controls whether the
memory is stored under episodic/, preference/, or fact/.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := cfg.ValidateMemoryPath(); err != nil {
			return err
		}

		content := args[0]

		if addType != "episodic" && addType != "preference" && addType != "fact" {
			return fmt.Errorf("--type must be 'episodic', 'preference', or 'fact', got %q", addType)
		}

		now := time.Now()
		filename := now.Format("2006-01-02-150405") + ".md"
		dir := filepath.Join(cfg.MemoryPath, addType)

		if err := os.MkdirAll(dir, 0o755); err != nil {
			return fmt.Errorf("creating memory directory %s: %w", dir, err)
		}

		path := filepath.Join(dir, filename)
		fileContent := buildMemoryFile(now, addType, content, correlationID)

		if err := os.WriteFile(path, []byte(fileContent), 0o644); err != nil {
			return fmt.Errorf("writing memory file %s: %w", path, err)
		}

		// Embed and index immediately.
		database, err := db.Open(cfg.DBPath)
		if err != nil {
			return fmt.Errorf("opening database: %w", err)
		}
		defer database.Close()

		embedText := content
		embedding, err := embed.Embed(embedText, "")
		if err != nil {
			return fmt.Errorf("embedding memory: %w", err)
		}

		info, err := os.Stat(path)
		if err != nil {
			return fmt.Errorf("stat %s: %w", path, err)
		}

		// Calculate initial strength and decay rate
		strength := db.CalculateStrength(addType, 1, 0.8)
		decayRate := db.DecayRate(addType)

		// Determine importance based on classification
		var importance float64
		switch addType {
		case "preference":
			importance = 0.8
		case "fact":
			importance = 0.7
		case "episodic":
			importance = 0.4
		default:
			importance = 0.5
		}

		tags := []string{"memory", addType}
		if correlationID != "" {
			tags = append(tags, "correlation:"+correlationID)
		}

		doc := db.Document{
			Path:           path,
			Title:          "",
			Content:        content,
			Mtime:          info.ModTime().Unix(),
			Type:           "memory",
			Tags:           tags,
			Embedding:      embedding,
			Classification: addType,
			Frequency:      1,
			LastAccessed:   time.Now().Unix(),
			DecayRate:      decayRate,
			Importance:     importance,
			Confidence:     0.8,
			Strength:       strength,
		}
		if err := database.UpsertDocument(doc, true); err != nil {
			return fmt.Errorf("indexing memory: %w", err)
		}

		fmt.Println(path)
		return nil
	},
}

func init() {
	addCmd.Flags().StringVar(&addType, "type", "",
		"memory type: episodic, preference, or fact (required)")
	_ = addCmd.MarkFlagRequired("type")
	addCmd.Flags().StringVar(&correlationID, "correlation-id", "",
		"optional correlation ID for tracking related memories")
}

// buildMemoryFile constructs the markdown content for a new memory file.
func buildMemoryFile(t time.Time, memType, content, correlationID string) string {
	var sb strings.Builder
	sb.WriteString("---\n")
	sb.WriteString("created: " + t.Format("2006-01-02") + "\n")
	if correlationID != "" {
		sb.WriteString("correlation_id: " + correlationID + "\n")
	}
	sb.WriteString("tags:\n")
	sb.WriteString("  - memory\n")
	sb.WriteString("  - " + memType + "\n")
	sb.WriteString("type: memory\n")
	sb.WriteString("---\n\n")
	sb.WriteString(content)
	sb.WriteString("\n")
	return sb.String()
}
