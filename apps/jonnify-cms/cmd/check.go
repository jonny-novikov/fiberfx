package cmd

import (
	"fmt"
	"os"

	"github.com/jonny-novikov/jonnify-cms/internal/apollo"
	"github.com/spf13/cobra"
)

func newCheckCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "check FILES...",
		Short: "Run the nine Apollo A+ gates on built HTML files",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			allPass := true
			for _, f := range args {
				doc, err := os.ReadFile(f)
				if err != nil {
					return err
				}
				res, passed := apollo.Run(string(doc))
				fmt.Println(f)
				for _, r := range res {
					mark := "PASS"
					if !r.OK {
						mark = "FAIL"
					}
					fmt.Printf("  [%s] %-11s %s\n", mark, r.Name, r.Detail)
				}
				grade, status := "—", "FAIL"
				if passed {
					grade, status = "A+", "PASS"
				}
				fmt.Printf("  grade: %s\n  STATUS: %s\n", grade, status)
				if !passed {
					allPass = false
				}
			}
			if !allPass {
				return fmt.Errorf("one or more files failed the gates")
			}
			return nil
		},
	}
}
