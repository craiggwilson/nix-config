// Package cmd implements the engram CLI commands.
package cmd

import (
	"fmt"
	"os"

	"github.com/craiggwilson/engram/internal/config"
	"github.com/spf13/cobra"
)

var cfg config.Config

var rootCmd = &cobra.Command{
	Use:   "engram",
	Short: "A local memory and search tool for markdown directories",
	Long: `engram indexes markdown files into a sqlite-vec database
and provides semantic search and memory management capabilities.`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return cfg.ExpandPaths()
	},
}

// Execute runs the root command and exits on error.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	defaultDB, err := config.DefaultDBPath()
	if err != nil {
		// Non-fatal: user can supply --db flag
		defaultDB = ""
	}

	rootCmd.PersistentFlags().StringArrayVar(
		&cfg.IndexedPaths, "indexed-path", nil,
		"directory to index (repeatable; memory-path is always indexed)",
	)
	rootCmd.PersistentFlags().StringVar(
		&cfg.DBPath, "db", defaultDB,
		"path to the sqlite database file",
	)

	rootCmd.AddCommand(ingestCmd)
	rootCmd.AddCommand(searchCmd)
	rootCmd.AddCommand(addCmd)
	rootCmd.AddCommand(decayCmd)
}
