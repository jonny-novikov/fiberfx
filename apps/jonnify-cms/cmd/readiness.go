package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/jonny-novikov/jonnify-cms/internal/readiness"
	"github.com/spf13/cobra"
)

func newReadinessCmd() *cobra.Command {
	var root string
	var asJSON bool
	c := &cobra.Command{
		Use:   "readiness",
		Short: "Reconcile manifest vs filesystem vs gates (ready|drift|broken)",
		RunE: func(cmd *cobra.Command, args []string) error {
			rows, err := readiness.Assess(root)
			if err != nil {
				return err
			}
			if asJSON {
				b, _ := json.MarshalIndent(rows, "", "  ")
				fmt.Println(string(b))
				return nil
			}
			w := tabwriter.NewWriter(os.Stdout, 0, 2, 2, ' ', 0)
			fmt.Fprintln(w, "MODULE\tDECLARED\tFILE\tGATES\tCLASS\tNOTE")
			counts := map[readiness.Class]int{}
			for _, r := range rows {
				counts[r.Class]++
				file := "—"
				gates := "—"
				if r.FileExists {
					file = "yes"
					if r.GatesPass {
						gates = "pass"
					} else {
						gates = "FAIL:" + strings.Join(r.GateFails, ",")
					}
				}
				fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\n", r.N, r.Declared, file, gates, r.Class, r.Note)
			}
			w.Flush()
			fmt.Print("\nsummary: ")
			for _, cl := range []readiness.Class{readiness.Ready, readiness.DriftPromote, readiness.InProgress, readiness.Regression, readiness.Broken, readiness.Planned} {
				if counts[cl] > 0 {
					fmt.Printf("%s=%d  ", cl, counts[cl])
				}
			}
			fmt.Println()
			return nil
		},
	}
	c.Flags().StringVar(&root, "root", defaultRoot(), "the /elixir content root")
	c.Flags().BoolVar(&asJSON, "json", false, "emit JSON instead of a table")
	return c
}
