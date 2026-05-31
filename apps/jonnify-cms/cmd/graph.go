package cmd

import (
	"fmt"
	"os"

	"github.com/jonny-novikov/jonnify-cms/internal/graph"
	"github.com/spf13/cobra"
)

func newGraphCmd() *cobra.Command {
	var format, root, out string
	c := &cobra.Command{
		Use:   "graph",
		Short: "Emit the structural navigation graph (dot|mermaid|json)",
		RunE: func(cmd *cobra.Command, args []string) error {
			g := graph.Build(root)
			var s string
			switch format {
			case "dot":
				s = g.DOT()
			case "mermaid":
				s = g.Mermaid()
			case "json":
				s = g.JSON()
			default:
				return fmt.Errorf("unknown format %q (want dot|mermaid|json)", format)
			}
			if out == "" {
				fmt.Println(s)
				return nil
			}
			return os.WriteFile(out, []byte(s), 0o644)
		},
	}
	c.Flags().StringVar(&format, "format", "mermaid", "output format: dot|mermaid|json")
	c.Flags().StringVar(&root, "root", defaultRoot(), "the /elixir content root")
	c.Flags().StringVar(&out, "out", "", "write to file instead of stdout")
	return c
}
