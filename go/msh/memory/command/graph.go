package command

import (
	"fmt"
	"io"
	"os"

	"github.com/spf13/cobra"

	"github.com/jonny-novikov/msh/memory/internal/graph"
)

func newGraphCmd(cfg *rootConfig, flags *globalFlags) *cobra.Command {
	var format string
	var out string
	var includeExternal bool
	cmd := &cobra.Command{
		Use:          "graph",
		Short:        "Build node+edge graph; emit JSON or dot.",
		Long:         "Builds the in-memory cross-reference graph for the memory root and emits it. --format=json produces a single JSON document with nodes[] + edges[]; --format=dot produces GraphViz output.",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			format = normalizeFormat(format)
			if err := validateGraphFormat(format); err != nil {
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
			sink, closer, err := openSink(out, cfg.Stdout)
			if err != nil {
				return &exitError{code: exitGeneric, err: err}
			}
			if closer != nil {
				defer closer.Close()
			}
			switch format {
			case "json":
				return graph.RenderJSON(sink, g, includeExternal)
			case "dot":
				return graph.RenderDOT(sink, g, includeExternal)
			default:
				return &exitError{code: exitUsage, err: fmt.Errorf("%q: %w", format, errInvalidFormat)}
			}
		},
	}
	cmd.Flags().StringVar(&format, "format", "json", "Output format: json | dot")
	cmd.Flags().StringVar(&out, "out", "", "Output file path (default stdout)")
	cmd.Flags().BoolVar(&includeExternal, "include-external", false, "Include external_rel edges in output")
	return cmd
}

func validateGraphFormat(f string) error {
	switch f {
	case "json", "dot":
		return nil
	default:
		return &exitError{code: exitUsage, err: fmt.Errorf("%q: %w", f, errInvalidFormat)}
	}
}

func openSink(path string, fallback io.Writer) (io.Writer, io.Closer, error) {
	if path == "" {
		return fallback, nil, nil
	}
	f, err := os.Create(path)
	if err != nil {
		return nil, nil, fmt.Errorf("open --out %q: %w", path, err)
	}
	return f, f, nil
}
