package main

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/msh/memory/command"
)

// newSpecsCmd builds `msh specs [AREA]` — check a docs/specs tree for stale
// (broken) markdown links and missing heading anchors. The check is the whole
// job of the command, so AREA is a positional (no --stale flag): `msh specs
// echo_mq`. Logic lives in memory/command so the CLI and the MCP tool share one
// implementation (cmd/ cannot import the memory internals it relies on).
func newSpecsCmd() *cobra.Command {
	var base, format, severity string
	cmd := &cobra.Command{
		Use:   "specs [AREA]",
		Short: "Check a docs/specs tree for stale (broken) markdown links + anchors.",
		Long: "Walks a docs/specs tree and resolves every relative markdown link against the filesystem, " +
			"reporting dead file targets (error) and missing heading anchors (warn) — cross-area links " +
			"(../aaw/x.md, ../../echo/...) are validated wherever they point.\n\n" +
			"AREA is an existing directory path, or a name resolved to <repo>/<base>/<AREA> (base defaults " +
			"to docs); with no AREA the active project from .msh-memory.json is used.\n\n" +
			"  msh specs echo_mq                 # check docs/echo_mq\n" +
			"  msh specs echo_mq --severity error  # only dead targets\n" +
			"  msh specs --format ndjson echo_mq   # machine-readable",
		Args:         cobra.MaximumNArgs(1),
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			var area string
			if len(args) == 1 {
				area = args[0]
			}
			out, err := command.SpecsLinks(area, base, format, severity)
			if err != nil {
				return err
			}
			fmt.Fprint(cmd.OutOrStdout(), out)
			return nil
		},
	}
	cmd.Flags().StringVar(&base, "base", "docs", "Base directory an AREA name resolves under: <repo>/<base>/<AREA>")
	cmd.Flags().StringVar(&format, "format", "pretty", "Output format: pretty | ndjson | audit")
	cmd.Flags().StringVar(&severity, "severity", "warn", "Minimum severity: error | warn | info")
	return cmd
}

// specsToolArgs is the input schema for the mcp__msh__specs tool.
type specsToolArgs struct {
	Area     string `json:"area,omitempty" jsonschema:"specs area: an existing path, a name resolved to <repo>/<base>/<area>, or empty for the active project from .msh-memory.json"`
	Base     string `json:"base,omitempty" jsonschema:"base directory an area NAME resolves under (default: docs)"`
	Format   string `json:"format,omitempty" jsonschema:"ndjson (default) | pretty | audit"`
	Severity string `json:"severity,omitempty" jsonschema:"minimum severity: error | warn (default) | info"`
}

// registerSpecsTool binds `msh specs` as the mcp__msh__specs tool.
func registerSpecsTool(s *mcp.Server) {
	mcp.AddTool(s, &mcp.Tool{
		Name: "specs",
		Description: "Check a docs/specs tree for stale (broken) markdown links: dead relative file targets (error) " +
			"and missing heading anchors (warn), resolved against the real filesystem so cross-area links are " +
			"validated wherever they point. 'area' selects the tree (an existing path, a name under <repo>/docs/, " +
			"or empty for the active .msh-memory.json project). Returns Finding[] as ndjson (default) | pretty | audit.",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in specsToolArgs) (*mcp.CallToolResult, any, error) {
		format := in.Format
		if format == "" {
			format = "ndjson" // machine-readable default for the MCP surface
		}
		out, err := command.SpecsLinks(in.Area, in.Base, format, in.Severity)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})
}
