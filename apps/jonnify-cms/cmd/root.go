// Package cmd wires the jonnify-cms Cobra command tree.
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "cms",
	Short: "jonnify-cms — content toolchain for the Functional Programming in Elixir course",
	Long: `jonnify-cms manages the static /elixir course.

It reconciles three sources of truth — the in-code manifest (declared status),
the filesystem (which pages exist), and the nine Apollo A+ gates (quality) — to
answer which pages are ready, which links are broken, and where the manifest has
drifted from reality.`,
	SilenceUsage:  true,
	SilenceErrors: false,
}

// Execute runs the root command.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(
		newManifestCmd(),
		newRoutesCmd(),
		newStampCmd(),
		newCheckCmd(),
		newGraphCmd(),
		newAuditCmd(),
		newReadinessCmd(),
		newBuildCmd(),
	)
}

// defaultRoot finds the /elixir content root from common run locations.
func defaultRoot() string {
	for _, c := range []string{os.Getenv("CMS_ELIXIR_DIR"), "elixir", "../../elixir"} {
		if c == "" {
			continue
		}
		if st, err := os.Stat(c); err == nil && st.IsDir() {
			return c
		}
	}
	return "elixir"
}
