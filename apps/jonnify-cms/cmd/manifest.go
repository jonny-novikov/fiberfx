package cmd

import (
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/jonny-novikov/jonnify-cms/internal/manifest"
	"github.com/spf13/cobra"
)

func newManifestCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "manifest",
		Short: "Print the course manifest (chapters, modules, dives)",
		RunE: func(cmd *cobra.Command, args []string) error {
			w := tabwriter.NewWriter(os.Stdout, 0, 2, 2, ' ', 0)
			fmt.Fprintln(w, "ID\tSTATUS\tTITLE")
			for _, c := range manifest.Chapters {
				fmt.Fprintf(w, "%s\t%s\t%s  [%s]\n", c.ID, c.Status, c.Title, c.Route)
				for _, m := range manifest.Modules[c.ID] {
					lab := ""
					if m.Lab {
						lab = "  (lab)"
					}
					fmt.Fprintf(w, "%s\t%s\t  %s%s\n", m.N, m.Status, m.Title, lab)
					for _, d := range m.Dives {
						fmt.Fprintf(w, "%s\t%s\t    %s\n", d.N, d.Status, d.Title)
					}
				}
			}
			fmt.Fprintf(w, "\t\ttotal spine modules: %d\n", manifest.ModuleCount())
			return w.Flush()
		},
	}
}

func newRoutesCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "routes",
		Short: "Print every route with its link/card state",
		RunE: func(cmd *cobra.Command, args []string) error {
			kind := func(s string) string {
				if manifest.Linkable(s) {
					return "link"
				}
				return "card"
			}
			w := tabwriter.NewWriter(os.Stdout, 0, 2, 2, ' ', 0)
			fmt.Fprintln(w, "ID\tSTATUS\tKIND\tROUTE")
			fmt.Fprintf(w, "ROOT\tlive\tlink\t%s\n", manifest.RootRoute)
			for _, c := range manifest.Chapters {
				fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", c.ID, c.Status, kind(c.Status), c.Route)
				for _, m := range manifest.Modules[c.ID] {
					route := c.Route + "/" + m.Slug
					fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", m.N, m.Status, kind(m.Status), route)
					for _, s := range manifest.SubpagesOf(m.N) {
						fmt.Fprintf(w, "\t%s\t%s\t%s\n", m.Status, kind(m.Status), s.Route)
					}
				}
			}
			return w.Flush()
		},
	}
}
