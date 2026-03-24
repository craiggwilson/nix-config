package cmd

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/craiggwilson/engram/internal/db"
	"github.com/craiggwilson/engram/internal/embed"
	"github.com/spf13/cobra"
)

var (
	searchLimit int
	searchJSON  bool
)

var searchCmd = &cobra.Command{
	Use:   "search <query>",
	Short: "Semantically search the indexed vault",
	Long: `Embed the query and perform a KNN vector search against the indexed documents.
Results are printed as a human-readable list by default, or as JSON with --json.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		query := args[0]

		database, err := db.Open(cfg.DBPath)
		if err != nil {
			return fmt.Errorf("opening database: %w", err)
		}
		defer database.Close()

		embedding, err := embed.Embed(query, "")
		if err != nil {
			return fmt.Errorf("embedding query: %w", err)
		}

		results, err := database.Search(embedding, searchLimit)
		if err != nil {
			return fmt.Errorf("searching: %w", err)
		}

		if searchJSON {
			return printJSON(results)
		}

		printHuman(results)
		return nil
	},
}

func init() {
	searchCmd.Flags().IntVarP(&searchLimit, "limit", "n", 5,
		"maximum number of results to return")
	searchCmd.Flags().BoolVar(&searchJSON, "json", false,
		"output results as a JSON array")
}

// printJSON writes results as a JSON array to stdout.
func printJSON(results []db.SearchResult) error {
	out, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return fmt.Errorf("marshalling results: %w", err)
	}
	fmt.Println(string(out))
	return nil
}

// printHuman writes results in a human-readable format to stdout.
func printHuman(results []db.SearchResult) {
	if len(results) == 0 {
		fmt.Println("no results found")
		return
	}
	for i, r := range results {
		fmt.Printf("%d. %s\n", i+1, r.Title)
		fmt.Printf("   path:           %s\n", r.Path)
		if r.Classification != "" {
			fmt.Printf("   classification: %s\n", r.Classification)
			fmt.Printf("   strength:       %.4f\n", r.Strength)
		}
		fmt.Printf("   score:          %.4f\n", r.Score)
		snippet := strings.ReplaceAll(r.Snippet, "\n", " ")
		fmt.Printf("   snippet:        %s\n", snippet)
		fmt.Println()
	}
}
