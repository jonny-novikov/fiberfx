package cmd

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/jonny-novikov/jonnify-cms/internal/builder"
	"github.com/jonny-novikov/jonnify-cms/internal/store"
	"github.com/spf13/cobra"
)

// newBuildCmd wires `cms build`, the store-backed page assembler. It operates in
// one of three modes, selected by a flag:
//
//   - --load DB        decompose the published /elixir tree into the SQLite
//     content store at DB and print the load report.
//   - --route /elixir/… assemble that route from the store (or from an in-memory
//     store loaded from --root) and print it (or write --out).
//   - --verify         assemble every stored page and compare it against the
//     published file, reporting how many reproduce byte-for-byte.
//
// Exit codes follow the tool convention: 0 success, 1 mismatch/gate failure,
// 2 usage error.
func newBuildCmd() *cobra.Command {
	var (
		load   string
		route  string
		verify bool
		db     string
		root   string
		out    string
	)
	c := &cobra.Command{
		Use:   "build",
		Short: "Assemble pages from the SQLite content store (store-backed port of build_page.py)",
		Long: `Build recomposes published /elixir pages from a filesystem-mirrored SQLite
content store. The store decomposes each page into a head template, a body-fragment
template, and per-page data (title, description, build stamp); build fills those
templates back to byte-identical output.

Modes (choose one):
  --load DB             build the content store from the /elixir tree and report
  --route /elixir/PATH  assemble that route from the store and print (or --out FILE)
  --verify              assemble every stored page and compare to the published file

The content root is taken from --root, then $CMS_ELIXIR_DIR, then default discovery.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			modes := 0
			for _, on := range []bool{load != "", route != "", verify} {
				if on {
					modes++
				}
			}
			if modes == 0 {
				usageError(cmd, "choose a mode: --load DB | --route /elixir/PATH | --verify")
			}
			if modes > 1 {
				usageError(cmd, "--load, --route, and --verify are mutually exclusive")
			}

			switch {
			case load != "":
				return runLoad(cmd, load, root)
			case route != "":
				return runRoute(cmd, route, db, root, out)
			default:
				return runVerify(cmd, db, root)
			}
		},
	}
	c.Flags().StringVar(&load, "load", "", "build the SQLite content store at this path from the /elixir tree")
	c.Flags().StringVar(&route, "route", "", "assemble this clean route from the store")
	c.Flags().BoolVar(&verify, "verify", false, "verify every stored page reproduces its published file byte-for-byte")
	c.Flags().StringVar(&db, "db", "", "SQLite content store to read (for --route/--verify); absent, an in-memory store is built from --root")
	c.Flags().StringVar(&root, "root", "", "the /elixir content root (default: $CMS_ELIXIR_DIR or discovery)")
	c.Flags().StringVar(&out, "out", "", "write the assembled route to this file instead of stdout")
	return c
}

// usageError prints a usage error and exits with code 2.
func usageError(cmd *cobra.Command, msg string) {
	fmt.Fprintln(os.Stderr, "error:", msg)
	cmd.Usage()
	os.Exit(2)
}

// resolveRoot returns the content root: the --root flag if set, else
// defaultRoot() (which honors CMS_ELIXIR_DIR).
func resolveRoot(root string) string {
	if root != "" {
		return root
	}
	return defaultRoot()
}

// openLoaded returns a store ready to read: the on-disk db when dbPath is set,
// otherwise an in-memory store freshly loaded from the content root. When it
// loads from the tree it also returns the load report (empty for an on-disk db).
func openLoaded(dbPath, root string) (*store.Store, store.LoadReport, error) {
	if dbPath != "" {
		s, err := store.Open(dbPath)
		return s, store.LoadReport{}, err
	}
	s, err := store.Open(":memory:")
	if err != nil {
		return nil, store.LoadReport{}, err
	}
	rep, err := s.LoadFromTree(resolveRoot(root))
	if err != nil {
		s.Close()
		return nil, store.LoadReport{}, err
	}
	return s, rep, nil
}

// runLoad builds the content store from the tree and prints the report.
func runLoad(cmd *cobra.Command, dbPath, root string) error {
	r := resolveRoot(root)
	s, err := store.Open(dbPath)
	if err != nil {
		return err
	}
	defer s.Close()
	rep, err := s.LoadFromTree(r)
	if err != nil {
		return err
	}
	printReport(cmd, dbPath, r, rep)
	return nil
}

// printReport writes a load report to the command's output.
func printReport(cmd *cobra.Command, dbPath, root string, rep store.LoadReport) {
	w := cmd.OutOrStdout()
	fmt.Fprintf(w, "loaded %s from %s\n", dbPath, root)
	fmt.Fprintf(w, "  pages:         %d\n", rep.Pages)
	fmt.Fprintf(w, "  distinct heads: %d\n", rep.DistinctHeads)
	fmt.Fprintf(w, "  skipped:       %d\n", len(rep.Skips))
	for _, sk := range rep.Skips {
		fmt.Fprintf(w, "    - %s: %s\n", sk.Path, sk.Reason)
	}
}

// runRoute assembles one route and prints it or writes it to --out.
func runRoute(cmd *cobra.Command, route, dbPath, root, out string) error {
	s, _, err := openLoaded(dbPath, root)
	if err != nil {
		return err
	}
	defer s.Close()
	doc, err := builder.BuildFromStore(s, route)
	if err != nil {
		return err
	}
	if out != "" {
		if err := os.WriteFile(out, doc, 0o644); err != nil {
			return err
		}
		fmt.Fprintf(cmd.OutOrStdout(), "wrote %s (%d bytes) for %s\n", out, len(doc), route)
		return nil
	}
	_, err = cmd.OutOrStdout().Write(doc)
	return err
}

// runVerify assembles every stored page and compares it to the published file.
//
// Two store sources are possible. With --db the store is a frozen snapshot; a
// page that has stopped conforming in the live tree surfaces as a byte mismatch
// (the snapshot still holds the old conforming bytes), so that path needs no
// extra gate. Without --db the store is built from the live tree itself, so a
// now-non-conforming page is silently skipped at load — it would never reach the
// per-page comparison. To match the parity test's rigor, the tree-built path
// additionally fails on any load skip and on a loaded-vs-on-disk count mismatch,
// so a dropped page yields a non-zero exit with the reason rather than a false
// OK N/N.
func runVerify(cmd *cobra.Command, dbPath, root string) error {
	r := resolveRoot(root)
	w := cmd.OutOrStdout()

	var s *store.Store
	if dbPath != "" {
		var err error
		s, err = store.Open(dbPath)
		if err != nil {
			return err
		}
	} else {
		var err error
		s, err = store.Open(":memory:")
		if err != nil {
			return err
		}
		rep, err := s.LoadFromTree(r)
		if err != nil {
			s.Close()
			return err
		}
		if gerr := treeLoadGate(w, r, rep); gerr != nil {
			s.Close()
			return gerr
		}
	}
	defer s.Close()

	routes, err := s.Routes()
	if err != nil {
		return err
	}
	var mismatches []string
	for _, route := range routes {
		p, head, err := s.Get(route)
		if err != nil {
			return err
		}
		got := builder.Assemble(head, p)
		want, err := os.ReadFile(filepath.Join(r, p.OutputPath))
		if err != nil {
			mismatches = append(mismatches, fmt.Sprintf("%s: cannot read published %s: %v", route, p.OutputPath, err))
			continue
		}
		if string(got) != string(want) {
			off := firstDiffOffset(got, want)
			mismatches = append(mismatches, fmt.Sprintf("%s (%s): differs at offset %d (built %d bytes, published %d bytes)",
				route, p.OutputPath, off, len(got), len(want)))
		}
	}
	ok := len(routes) - len(mismatches)
	fmt.Fprintf(w, "OK %d/%d pages reproduce byte-for-byte\n", ok, len(routes))
	for _, m := range mismatches {
		fmt.Fprintln(w, "  MISMATCH "+m)
	}
	if len(mismatches) > 0 {
		return fmt.Errorf("%d page(s) did not reproduce byte-for-byte", len(mismatches))
	}
	return nil
}

// treeLoadGate enforces, for the tree-built verify store, the same load
// invariants the parity test asserts: zero non-conforming skips, and a loaded
// page count equal to the on-disk *.html count under root. A violation prints the
// reason to w and returns a non-nil error so the command exits non-zero rather
// than reporting a false OK over the pages that happened to load.
func treeLoadGate(w io.Writer, root string, rep store.LoadReport) error {
	if len(rep.Skips) > 0 {
		for _, sk := range rep.Skips {
			fmt.Fprintf(w, "  SKIP %s: %s\n", sk.Path, sk.Reason)
		}
		return fmt.Errorf("%d file(s) did not conform to the decomposition and were skipped", len(rep.Skips))
	}
	onDisk, err := countHTMLFiles(root)
	if err != nil {
		return err
	}
	if rep.Pages != onDisk {
		fmt.Fprintf(w, "  COUNT loaded %d pages but %d *.html files exist under %s\n", rep.Pages, onDisk, root)
		return fmt.Errorf("loaded page count %d does not match the on-disk *.html count %d", rep.Pages, onDisk)
	}
	return nil
}

// countHTMLFiles counts *.html files under root, walking the same way the store
// loader does, so the count cross-check uses the same population.
func countHTMLFiles(root string) (int, error) {
	n := 0
	err := filepath.WalkDir(root, func(p string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && strings.EqualFold(filepath.Ext(p), ".html") {
			n++
		}
		return nil
	})
	return n, err
}

// firstDiffOffset returns the first byte offset at which a and b differ, or the
// length of the shorter slice when one is a prefix of the other.
func firstDiffOffset(a, b []byte) int {
	n := len(a)
	if len(b) < n {
		n = len(b)
	}
	i := 0
	for i < n && a[i] == b[i] {
		i++
	}
	return i
}
