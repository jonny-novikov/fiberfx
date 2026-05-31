package cmd

import (
	"fmt"

	"github.com/jonny-novikov/jonnify-cms/internal/audit"
	"github.com/spf13/cobra"
)

func newAuditCmd() *cobra.Command {
	var root string
	var fix bool
	c := &cobra.Command{
		Use:   "audit",
		Short: "Find broken internal links; --fix renames slug-mismatch orphans",
		RunE: func(cmd *cobra.Command, args []string) error {
			rep, err := audit.Run(root)
			if err != nil {
				return err
			}
			fmt.Printf("scanned %d pages, %d internal /elixir links under %s\n\n", rep.Pages, rep.RefCount, rep.Root)

			if len(rep.BrokenLinks) == 0 {
				fmt.Println("no broken in-page links")
			}
			for _, b := range rep.BrokenLinks {
				fmt.Printf("BROKEN  %s  (%d refs)\n", b.Route, len(b.Refs))
				for _, r := range b.Refs {
					fmt.Printf("        %s:%d\n", r.File, r.Line)
				}
				if b.Orphan != "" {
					fmt.Printf("        orphan: %s  ->  %s\n", b.Orphan, b.Canonical)
					if fix {
						msg, err := audit.ApplyFix(b)
						if err != nil {
							fmt.Printf("        fix failed: %v\n", err)
						} else {
							fmt.Printf("        FIXED: %s\n", msg)
						}
					}
				} else {
					fmt.Println("        (no orphan auto-fix; needs a human decision)")
				}
			}

			if len(rep.UnresolvedRoutes) > 0 {
				fmt.Println("\ndeclared-linkable routes that do not resolve:")
				for _, u := range rep.UnresolvedRoutes {
					fmt.Printf("  %s — %s\n", u.Route, u.Note)
				}
			}

			if !fix && len(rep.BrokenLinks) > 0 {
				fmt.Println("\nre-run with --fix to rename slug-mismatch orphans to their canonical filename")
			}
			return nil
		},
	}
	c.Flags().StringVar(&root, "root", defaultRoot(), "the /elixir content root")
	c.Flags().BoolVar(&fix, "fix", false, "rename slug-mismatch orphan files to their canonical name")
	return c
}
