package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newVersionCmd(cfg *rootConfig) *cobra.Command {
	return &cobra.Command{
		Use:          "version",
		Short:        "Print binary version.",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			_, err := fmt.Fprintf(cfg.Stdout, "hugot-memory %s (commit %s, built %s)\n", version, commit, buildDate)
			return err
		},
	}
}
