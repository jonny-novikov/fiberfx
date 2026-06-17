package command

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/jonny-novikov/msh/memory/internal/render"
)

func newScanCmd(cfg *rootConfig, flags *globalFlags) *cobra.Command {
	var format string
	cmd := &cobra.Command{
		Use:          "scan",
		Short:        "Walk memory, parse frontmatter, dump per-file metadata.",
		Long:         "Walks the memory root, parses YAML frontmatter on each .md file, and emits one record per node. --format=ndjson produces one JSON object per line; --format=pretty produces a tabwriter table.",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			format = normalizeFormat(format)
			if err := validateScanFormat(format); err != nil {
				return err
			}
			root, err := resolveRoot(flags.Root)
			if err != nil {
				return err
			}
			g, _, err := loadCorpus(root)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			nodes := g.Nodes()
			switch format {
			case "ndjson":
				return render.NDJSONNodes(cfg.Stdout, nodes)
			default:
				return render.PrettyScan(cfg.Stdout, nodes)
			}
		},
	}
	cmd.Flags().StringVar(&format, "format", "pretty", "Output format: pretty | ndjson")
	return cmd
}

func validateScanFormat(f string) error {
	switch f {
	case "pretty", "ndjson":
		return nil
	default:
		return &exitError{code: exitUsage, err: fmt.Errorf("%q: %w", f, errInvalidFormat)}
	}
}

func normalizeFormat(s string) string {
	if s == "" {
		return "pretty"
	}
	return s
}
