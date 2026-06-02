package builder

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/jonny-novikov/jonnify-cms/internal/snowflake"
	"github.com/jonny-novikov/jonnify-cms/internal/store"
)

// findElixirRoot locates the published /elixir content tree so the parity tests
// are portable. The CMS_ELIXIR_DIR environment variable wins when set; otherwise
// the search walks up from this test file's directory looking for an elixir/
// subdirectory that holds the course's index.html. When the tree is absent the
// caller skips, so the suite stays runnable in a checkout without the content.
func findElixirRoot(t *testing.T) string {
	t.Helper()
	if env := os.Getenv("CMS_ELIXIR_DIR"); env != "" {
		if isElixirRoot(env) {
			return env
		}
		t.Skipf("CMS_ELIXIR_DIR=%q does not look like the /elixir content root", env)
	}
	_, self, _, ok := runtime.Caller(0)
	if !ok {
		t.Skip("cannot determine the test file location to find the elixir tree")
	}
	dir := filepath.Dir(self)
	for {
		cand := filepath.Join(dir, "elixir")
		if isElixirRoot(cand) {
			return cand
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Skip("no elixir/ content tree found walking up from the test directory; set CMS_ELIXIR_DIR")
		}
		dir = parent
	}
}

// isElixirRoot reports whether dir is the published course root (a directory
// holding the course landing index.html).
func isElixirRoot(dir string) bool {
	st, err := os.Stat(filepath.Join(dir, "index.html"))
	if err != nil || st.IsDir() {
		return false
	}
	di, err := os.Stat(dir)
	return err == nil && di.IsDir()
}

// loadStore opens an in-memory store and loads the published tree into it,
// returning the store and the load report.
func loadStore(t *testing.T, root string) (*store.Store, store.LoadReport) {
	t.Helper()
	s, err := store.Open(":memory:")
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { s.Close() })
	rep, err := s.LoadFromTree(root)
	if err != nil {
		t.Fatalf("load tree %s: %v", root, err)
	}
	return s, rep
}

// TestPublishedPagesRoundTripByteIdentical decomposes every published page into
// the store and asserts the builder recomposes byte-identical output. It also
// asserts the full published count loaded with no skips, so a page that fails to
// conform surfaces as a failure rather than a silent omission.
func TestPublishedPagesRoundTripByteIdentical(t *testing.T) {
	root := findElixirRoot(t)
	s, rep := loadStore(t, root)

	if len(rep.Skips) != 0 {
		for _, sk := range rep.Skips {
			t.Errorf("skipped non-conforming file %s: %s", sk.Path, sk.Reason)
		}
		t.Fatalf("%d file(s) did not conform to the decomposition; expected zero", len(rep.Skips))
	}

	// Cross-check the loaded count against the *.html files on disk so a missed
	// page (one walked but not inserted) cannot pass unnoticed.
	onDisk := countHTMLFiles(t, root)
	if rep.Pages != onDisk {
		t.Fatalf("loaded %d pages but %d *.html files exist under %s", rep.Pages, onDisk, root)
	}

	routes, err := s.Routes()
	if err != nil {
		t.Fatalf("routes: %v", err)
	}
	if len(routes) != rep.Pages {
		t.Fatalf("store holds %d routes but report counted %d pages", len(routes), rep.Pages)
	}

	for _, route := range routes {
		p, head, err := s.Get(route)
		if err != nil {
			t.Fatalf("get %s: %v", route, err)
		}
		got := Assemble(head, p)
		want, err := os.ReadFile(filepath.Join(root, p.OutputPath))
		if err != nil {
			t.Fatalf("read published %s: %v", p.OutputPath, err)
		}
		if string(got) != string(want) {
			off, gw, ww := firstDiff(got, want)
			t.Errorf("route %s (%s) does not reproduce byte-for-byte: first diff at offset %d\n  built published lengths: %d vs %d\n  built : %q\n  publshd: %q",
				route, p.OutputPath, off, len(got), len(want), gw, ww)
		}
	}
}

// TestStampRoundTrip asserts each page's pinned build id is internally
// consistent: the timestamp the branded id decodes to equals the timestamp
// printed beside it in the footer.
func TestStampRoundTrip(t *testing.T) {
	root := findElixirRoot(t)
	s, _ := loadStore(t, root)
	routes, err := s.Routes()
	if err != nil {
		t.Fatalf("routes: %v", err)
	}
	checked := 0
	for _, route := range routes {
		p, _, err := s.Get(route)
		if err != nil {
			t.Fatalf("get %s: %v", route, err)
		}
		if p.BuildID == "" {
			continue
		}
		dec, err := snowflake.Decode(p.BuildID)
		if err != nil {
			t.Errorf("route %s: decode %q: %v", route, p.BuildID, err)
			continue
		}
		if dec.Timestamp != p.BuildTS {
			t.Errorf("route %s: stamp %q decodes to %q but footer shows %q",
				route, p.BuildID, dec.Timestamp, p.BuildTS)
		}
		checked++
	}
	if checked == 0 {
		t.Fatal("no page carried a non-empty build id; expected the published pages to be stamped")
	}
	t.Logf("verified %d stamped pages decode to their printed timestamp", checked)
}

// TestDistinctHeadCount reports how many distinct head templates the published
// pages dedup into. It asserts only that at least one head exists; the count is
// logged for visibility.
func TestDistinctHeadCount(t *testing.T) {
	root := findElixirRoot(t)
	_, rep := loadStore(t, root)
	if rep.DistinctHeads < 1 {
		t.Fatalf("expected at least one distinct head template, got %d", rep.DistinctHeads)
	}
	t.Logf("%d published pages dedup into %d distinct head templates", rep.Pages, rep.DistinctHeads)
}

// countHTMLFiles counts *.html files under root, matching the loader's walk.
func countHTMLFiles(t *testing.T, root string) int {
	t.Helper()
	n := 0
	err := filepath.WalkDir(root, func(p string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && filepath.Ext(p) == ".html" {
			n++
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walk %s: %v", root, err)
	}
	return n
}

// firstDiff returns the first differing byte offset between got and want and an
// up-to-80-character window from each side starting at that offset.
func firstDiff(got, want []byte) (offset int, gotWin, wantWin string) {
	n := len(got)
	if len(want) < n {
		n = len(want)
	}
	i := 0
	for i < n && got[i] == want[i] {
		i++
	}
	return i, window(got, i), window(want, i)
}

func window(b []byte, start int) string {
	if start > len(b) {
		start = len(b)
	}
	end := start + 80
	if end > len(b) {
		end = len(b)
	}
	return string(b[start:end])
}
