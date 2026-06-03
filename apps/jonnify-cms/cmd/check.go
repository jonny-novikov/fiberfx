package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/apollo"
	"github.com/jonny-novikov/jonnify-cms/internal/fixup"
	"github.com/jonny-novikov/jonnify-cms/internal/site"
	"github.com/spf13/cobra"
)

// checkSection pairs a --routes-from section's on-disk root with its URL mount.
type checkSection struct{ root, mount string }

func newCheckCmd() *cobra.Command {
	var routesFrom []string
	var fix bool
	var chapterAlias string
	var requireRefs bool

	cmd := &cobra.Command{
		Use:   "check FILES...",
		Short: "Run the nine Apollo A+ gates on built HTML files",
		Long: "Run the nine Apollo A+ gates on built HTML files.\n\n" +
			"By default internal links resolve against the elixir manifest only. For a\n" +
			"folder-routed section (e.g. the agile-agent-workflow course) pass --routes-from\n" +
			"<dir> to also accept that section's filesystem-derived routes — the same clean\n" +
			"URLs the server serves — so its pages can reach a true A+. With --fix, apply the\n" +
			"deterministic, route-verified repairs (clamp spacing + relink) before checking.",
		Args: cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			// Build the extra resolvable-route set + remember each section's
			// (root, mount) so --fix can place a file within its section.
			extra := map[string]bool{}
			var sections []checkSection
			for _, spec := range routesFrom {
				mount, clean := parseRoutesFrom(spec)
				routes, err := site.SectionRoutes(clean, mount)
				if err != nil {
					return fmt.Errorf("routes-from %s: %w", spec, err)
				}
				for r := range routes {
					extra[r] = true
				}
				sections = append(sections, checkSection{clean, mount})
				fmt.Printf("routes-from %s -> mount %s (%d routes)\n", clean, mount, len(routes))
			}

			aliases := parseAliases(chapterAlias)

			allPass := true
			for _, f := range args {
				doc, err := os.ReadFile(f)
				if err != nil {
					return err
				}
				s := string(doc)

				if fix {
					root, mount := sectionOf(f, sections)
					fixed, r := fixup.Apply(s, f, root, mount, aliases, extra)
					if r.Changed() {
						if err := os.WriteFile(f, []byte(fixed), 0o644); err != nil {
							return err
						}
						s = fixed
						fmt.Printf("%s\n  FIXED: clamps=%d relinks=%d route-tag=%v\n", f, r.Clamps, r.Relinks, r.RouteTag)
						for _, c := range r.Changes {
							fmt.Printf("    - %s\n", c)
						}
					}
				}

				res, passed := apollo.RunWithOpts(s, extra, apollo.Opts{RequireRefs: requireRefs})
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

	cmd.Flags().StringArrayVar(&routesFrom, "routes-from", nil,
		"folder-routed section whose filesystem routes also count as resolvable: \"<mount>=<dir>\" or bare \"<dir>\" (mount from base name); repeatable")
	cmd.Flags().BoolVar(&fix, "fix", false,
		"apply deterministic, route-verified repairs (clamp spacing + relink) before checking")
	cmd.Flags().StringVar(&chapterAlias, "chapter-alias", "",
		"comma-separated positional-slug=dir map for relink, e.g. \"a0=intro,a1=why\" (used with --fix)")
	cmd.Flags().BoolVar(&requireRefs, "require-refs", false,
		"also require a References section (a .refs block) on every page (the agile-agent-workflow mandate)")
	return cmd
}

// parseAliases turns "a0=intro,a1=why" into a map. Malformed entries are skipped.
func parseAliases(spec string) map[string]string {
	if strings.TrimSpace(spec) == "" {
		return nil
	}
	m := map[string]string{}
	for _, pair := range strings.Split(spec, ",") {
		if i := strings.IndexByte(pair, '='); i > 0 {
			k := strings.TrimSpace(pair[:i])
			v := strings.TrimSpace(pair[i+1:])
			if k != "" && v != "" {
				m[k] = v
			}
		}
	}
	return m
}

// parseRoutesFrom splits a --routes-from value. The explicit "mount=dir" form
// (e.g. "/course/agile-agent-workflow=html/agile-agent-workflow") pins the URL
// mount when it differs from the directory name; a bare "dir" derives the mount
// from the directory's base name (the elixir-style default).
func parseRoutesFrom(spec string) (mount, dir string) {
	if i := strings.IndexByte(spec, '='); i >= 0 {
		mount = "/" + strings.Trim(spec[:i], "/")
		dir = filepath.Clean(spec[i+1:])
		return mount, dir
	}
	dir = filepath.Clean(spec)
	return "/" + filepath.Base(dir), dir
}

// sectionOf returns the (root, mount) of the first --routes-from section that
// contains file, so --fix can derive the page's chapter and canonical route.
// Empty strings mean "no section matched" — Apply then does clamp repair only.
func sectionOf(file string, sections []checkSection) (string, string) {
	abs, err := filepath.Abs(file)
	if err != nil {
		abs = file
	}
	for _, s := range sections {
		rootAbs, err := filepath.Abs(s.root)
		if err != nil {
			continue
		}
		rel, err := filepath.Rel(rootAbs, abs)
		if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
			continue
		}
		return s.root, s.mount
	}
	return "", ""
}
