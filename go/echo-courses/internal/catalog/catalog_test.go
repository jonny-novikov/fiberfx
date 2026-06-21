package catalog_test

import (
	"reflect"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/fiberfx/echo-courses/content"
	"github.com/fiberfx/echo-courses/internal/catalog"
)

// AC1: the seeded content/ tree loads to exactly five courses in published order,
// with the exact slug, title, tracks, facet, and path of each — verified against
// the embedded corpus (content.FS), the same FS the server boots on.
func TestLoad_SeededCatalog(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("Load(content.FS): %v", err)
	}

	want := []struct {
		slug   string
		title  string
		tracks []string
		facet  string
		path   string
	}{
		{"elixir", "Functional Programming", []string{"Elixir", "BEAM"}, "Elixir", "/elixir"},
		{"redis-patterns", "Redis Patterns Applied", []string{"Redis", "EchoMQ"}, "Redis", "/redis-patterns"},
		{"echomq", "EchoMQ in Depth", []string{"EchoMQ", "protocol"}, "EchoMQ", "/echomq"},
		{"agile-agent-workflow", "Agile Agent Workflow", []string{"Claude Agents", "Portal"}, "Agents", "/course/agile-agent-workflow"},
		{"bcs", "Branded Component System", []string{"Identity", "five runtimes"}, "BCS", "/bcs"},
	}

	if len(cat.Courses) != len(want) {
		t.Fatalf("course count = %d, want %d", len(cat.Courses), len(want))
	}
	for i, w := range want {
		got := cat.Courses[i]
		if got.Order != i+1 {
			t.Errorf("course[%d] %q: Order = %d, want %d (published order)", i, got.Slug, got.Order, i+1)
		}
		if got.Slug != w.slug {
			t.Errorf("course[%d]: Slug = %q, want %q (published order)", i, got.Slug, w.slug)
		}
		if got.Title != w.title {
			t.Errorf("course[%d] %q: Title = %q, want %q", i, got.Slug, got.Title, w.title)
		}
		if !reflect.DeepEqual(got.Tracks, w.tracks) {
			t.Errorf("course[%d] %q: Tracks = %v, want %v", i, got.Slug, got.Tracks, w.tracks)
		}
		if got.Facet != w.facet {
			t.Errorf("course[%d] %q: Facet = %q, want %q", i, got.Slug, got.Facet, w.facet)
		}
		if got.Path != w.path {
			t.Errorf("course[%d] %q: Path = %q, want %q", i, got.Slug, got.Path, w.path)
		}
	}
}

// AC1 (ordering): an out-of-published-order content tree still loads ordered by
// Order, proving the sort rather than filesystem/glob order. fs.Glob returns
// lexical order, so naming the later course "a-*" would put it first on disk; the
// Order field must override that.
func TestLoad_SortsByOrder(t *testing.T) {
	fsys := fstest.MapFS{
		"a-second.html": {Data: courseFile(2, "Second", "Beta", "/second")},
		"z-first.html":  {Data: courseFile(1, "First", "Alpha", "/first")},
	}
	cat, err := catalog.Load(fsys)
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cat.Courses[0].Order != 1 || cat.Courses[1].Order != 2 {
		t.Fatalf("orders = [%d, %d], want [1, 2] (sorted by Order, not glob order)",
			cat.Courses[0].Order, cat.Courses[1].Order)
	}
	if cat.Courses[0].Slug != "z-first" {
		t.Fatalf("first course slug = %q, want %q (the Order:1 file, despite lexical glob order)",
			cat.Courses[0].Slug, "z-first")
	}
}

// AC2: a course file missing a required front-matter field makes Load return a
// named error that cites the file and the missing field — the boot-aborting
// failure run() relies on.
func TestLoad_MissingFieldNamedError(t *testing.T) {
	cases := map[string]struct {
		front       string
		wantInError string
	}{
		"missing title": {
			front:       "order: 1\nfacet_order: 1\ntracks: [A]\nfacet: F\nsummary: s\npath: /p\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "title",
		},
		"missing facet": {
			front:       "order: 1\nfacet_order: 1\ntitle: T\ntracks: [A]\nsummary: s\npath: /p\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "facet",
		},
		"missing path": {
			front:       "order: 1\nfacet_order: 1\ntitle: T\ntracks: [A]\nfacet: F\nsummary: s\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "path",
		},
		"missing tracks": {
			front:       "order: 1\nfacet_order: 1\ntitle: T\nfacet: F\nsummary: s\npath: /p\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "tracks",
		},
		"missing accent": {
			front:       "order: 1\nfacet_order: 1\ntitle: T\ntracks: [A]\nfacet: F\nsummary: s\npath: /p\nicon: <svg/>",
			wantInError: "accent",
		},
		"missing icon": {
			front:       "order: 1\nfacet_order: 1\ntitle: T\ntracks: [A]\nfacet: F\nsummary: s\npath: /p\naccent: \"#fff\"",
			wantInError: "icon",
		},
		"missing order": {
			front:       "facet_order: 1\ntitle: T\ntracks: [A]\nfacet: F\nsummary: s\npath: /p\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "order",
		},
		"missing facet_order": {
			front:       "order: 1\ntitle: T\ntracks: [A]\nfacet: F\nsummary: s\npath: /p\naccent: \"#fff\"\nicon: <svg/>",
			wantInError: "facet_order",
		},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			fsys := fstest.MapFS{
				"broken.html": {Data: []byte("---\n" + tc.front + "\n---\n<h1>x</h1>\n")},
			}
			_, err := catalog.Load(fsys)
			if err == nil {
				t.Fatal("Load over a course missing a required field returned nil error; want fail-fast")
			}
			if !strings.HasPrefix(err.Error(), "catalog: ") {
				t.Fatalf("error %q is not a named catalog error (want a 'catalog: …' prefix)", err)
			}
			if !strings.Contains(err.Error(), tc.wantInError) {
				t.Fatalf("error %q does not name the missing field %q", err, tc.wantInError)
			}
			if !strings.Contains(err.Error(), "broken.html") {
				t.Fatalf("error %q does not name the offending file (broken.html)", err)
			}
		})
	}
}

// AC2 (no front-matter): a file with no --- fence is also a named error, not a
// course with empty metadata.
func TestLoad_NoFrontMatter(t *testing.T) {
	fsys := fstest.MapFS{
		"plain.html": {Data: []byte("<h1>just a body, no front-matter</h1>\n")},
	}
	_, err := catalog.Load(fsys)
	if err == nil {
		t.Fatal("Load over a front-matter-less file returned nil error; want a named error")
	}
	if !strings.HasPrefix(err.Error(), "catalog: ") {
		t.Fatalf("error %q is not a named catalog error", err)
	}
}

// AC3: two files reducing to the same slug make Load return a duplicate-slug
// error. fstest.MapFS keys are unique, so a literal same-name pair is impossible;
// the collision is a top-level file and a nested file whose base names match
// ("dup.html" and "sub/dup.html" both → slug "dup"), which Load's recursive walk
// surfaces.
func TestLoad_DuplicateSlug(t *testing.T) {
	fsys := fstest.MapFS{
		"dup.html":     {Data: courseFile(1, "First Dup", "F", "/dup-a")},
		"sub/dup.html": {Data: courseFile(2, "Second Dup", "G", "/dup-b")},
	}
	_, err := catalog.Load(fsys)
	if err == nil {
		t.Fatal("Load over two files with the same slug returned nil error; want a duplicate-slug error")
	}
	if !strings.HasPrefix(err.Error(), "catalog: ") {
		t.Fatalf("error %q is not a named catalog error", err)
	}
	if !strings.Contains(err.Error(), "duplicate slug") {
		t.Fatalf("error %q is not a duplicate-slug error", err)
	}
	if !strings.Contains(err.Error(), `"dup"`) {
		t.Fatalf("error %q does not name the duplicated slug", err)
	}
}

// AC4: the facet index over the seeded catalog is All 5 / Elixir 1 / Agents 1 /
// Redis 1 / EchoMQ 1 / BCS 1, with All first and the Key lower-cased.
func TestLoad_FacetCounts(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("Load(content.FS): %v", err)
	}

	got := map[string]int{}
	keyOf := map[string]string{}
	for _, f := range cat.Facets {
		got[f.Label] = f.Count
		keyOf[f.Label] = f.Key
	}

	want := map[string]int{"All": 5, "Elixir": 1, "Agents": 1, "Redis": 1, "EchoMQ": 1, "BCS": 1}
	if len(cat.Facets) != len(want) {
		t.Fatalf("facet count = %d (%v), want %d", len(cat.Facets), cat.Facets, len(want))
	}
	for label, count := range want {
		if got[label] != count {
			t.Errorf("facet %q count = %d, want %d", label, got[label], count)
		}
	}

	if cat.Facets[0].Label != "All" || cat.Facets[0].Key != "all" {
		t.Errorf("facet[0] = {%q, %q}, want the All facet {All, all} first", cat.Facets[0].Label, cat.Facets[0].Key)
	}
	// Key must be the lower-cased facet label (the ec.4 filter matches on it).
	for label, key := range keyOf {
		if want := strings.ToLower(label); key != want {
			t.Errorf("facet %q Key = %q, want %q (lower-cased)", label, key, want)
		}
	}
}

// AC4 (ordering): the non-All facets follow the PUBLISHED chip order carried by
// each course's facet_order (ec.4 D-1) — All · Elixir · Agents · Redis · EchoMQ ·
// BCS — which is distinct from the grid Course.Order (where Agents is 4th). This
// is the pin that proves buildFacets sorts by FacetOrder, not first-seen Order.
func TestLoad_FacetPublishedOrder(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("Load(content.FS): %v", err)
	}
	wantLabels := []string{"All", "Elixir", "Agents", "Redis", "EchoMQ", "BCS"}
	if len(cat.Facets) != len(wantLabels) {
		t.Fatalf("facet count = %d, want %d", len(cat.Facets), len(wantLabels))
	}
	for i, label := range wantLabels {
		if cat.Facets[i].Label != label {
			t.Errorf("facet[%d] = %q, want %q (published chip order)", i, cat.Facets[i].Label, label)
		}
	}
}

// AC5: a course body in the source format is available as non-empty
// template.HTML (the markup after the front-matter block), ready for the ec.4
// detail template.
func TestLoad_BodyAvailableAsHTML(t *testing.T) {
	cat, err := catalog.Load(content.FS)
	if err != nil {
		t.Fatalf("Load(content.FS): %v", err)
	}
	for _, c := range cat.Courses {
		if strings.TrimSpace(string(c.Body)) == "" {
			t.Errorf("course %q: Body is empty; want the rendered HTML available to the detail template", c.Slug)
		}
		// The body carries real markup (the migrated starter heading), not the
		// front-matter — proving the split kept the body, not the metadata.
		if !strings.Contains(string(c.Body), "<h1>") {
			t.Errorf("course %q: Body = %q, want HTML markup (an <h1> heading)", c.Slug, c.Body)
		}
		if strings.Contains(string(c.Body), "facet:") {
			t.Errorf("course %q: Body leaked front-matter (%q)", c.Slug, c.Body)
		}
	}
}

// --- helpers ---

// courseFile builds a minimal valid content file (all required fields present,
// incl. ec.4's facet_order — mirrored to order for the fixtures) for the
// failure/ordering fixtures.
func courseFile(order int, title, facet, path string) []byte {
	var b strings.Builder
	b.WriteString("---\n")
	b.WriteString("order: ")
	b.WriteByte(byte('0' + order))
	b.WriteString("\nfacet_order: ")
	b.WriteByte(byte('0' + order))
	b.WriteString("\ntitle: ")
	b.WriteString(title)
	b.WriteString("\ntracks: [A, B]\nfacet: ")
	b.WriteString(facet)
	b.WriteString("\nsummary: a summary\npath: ")
	b.WriteString(path)
	b.WriteString("\naccent: \"#ffffff\"\nicon: <svg/>\n---\n<h1>")
	b.WriteString(title)
	b.WriteString("</h1>\n")
	return []byte(b.String())
}
