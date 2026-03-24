package cmd

import (
	"fmt"

	"github.com/craiggwilson/engram/internal/db"
	"github.com/spf13/cobra"
)

var decayCmd = &cobra.Command{
	Use:   "decay",
	Short: "Apply Ebbinghaus decay to episodic memories",
	Long:  `Decays episodic memory strength over time and removes memories that have faded below threshold.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		database, err := db.Open(cfg.DBPath)
		if err != nil {
			return fmt.Errorf("opening database: %w", err)
		}
		defer database.Close()

		n, err := database.ApplyDecay()
		if err != nil {
			return fmt.Errorf("applying decay: %w", err)
		}

		fmt.Printf("decayed %d episodic memories\n", n)
		return nil
	},
}
