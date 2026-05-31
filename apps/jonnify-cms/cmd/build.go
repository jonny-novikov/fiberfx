package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newBuildCmd() *cobra.Command {
	var page string
	var all bool
	c := &cobra.Command{
		Use:   "build",
		Short: "Assemble pages from content fragments (port of build_page.py)",
		Long: `Port of build_page.py's assemble pipeline. This command is spec-complete
(see docs/specs/05-build-validate.md) but inert in this repository: the content/
fragments build_page.py consumes are not committed here, only the already-built
pages under /elixir. Use 'cms check' to validate built pages today.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("build: no content/ fragments are committed to this repo yet.")
			fmt.Println("       this command is spec-complete; see docs/specs/05-build-validate.md.")
			fmt.Println("       to validate already-built pages, use: cms check <files...>")
			_ = page
			_ = all
			return nil
		},
	}
	c.Flags().StringVar(&page, "page", "landing", "page key to build")
	c.Flags().BoolVar(&all, "all", false, "build every page")
	return c
}
