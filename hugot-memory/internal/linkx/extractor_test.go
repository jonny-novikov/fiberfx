package linkx

import (
	"testing"

	"github.com/fiberfx/hugot-memory/internal/graph"
)

func TestExtractMDLinkPlain(t *testing.T) {
	body := []byte(`# Title

See [Sample](feedback_alpha.md) for details.
`)
	got := Extract("MEMORY.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge, got %d: %+v", len(got.Edges), got.Edges)
	}
	e := got.Edges[0]
	if e.Kind != graph.EdgeMDLink {
		t.Errorf("Kind=%s want md_link", e.Kind)
	}
	if e.To != "feedback_alpha.md" {
		t.Errorf("To=%s", e.To)
	}
	if e.SourceLine != 3 {
		t.Errorf("SourceLine=%d want 3", e.SourceLine)
	}
}

func TestExtractMDLinkAnchor(t *testing.T) {
	body := []byte(`See [X](feedback_alpha.md#nope).
`)
	got := Extract("a.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge, got %d", len(got.Edges))
	}
	e := got.Edges[0]
	if e.Kind != graph.EdgeMDLinkAnchor {
		t.Errorf("Kind=%s", e.Kind)
	}
	if e.Anchor != "nope" {
		t.Errorf("Anchor=%q", e.Anchor)
	}
}

func TestExtractExternalRel(t *testing.T) {
	body := []byte(`See [docs](../../dev/foo.md).
`)
	got := Extract("a.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge")
	}
	if got.Edges[0].Kind != graph.EdgeExternalRel {
		t.Errorf("Kind=%s want external_rel", got.Edges[0].Kind)
	}
}

func TestExtractCrossSubdir(t *testing.T) {
	body := []byte(`See [t](topics/cclin/topologies.md) for details.
`)
	got := Extract("MEMORY.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge")
	}
	if got.Edges[0].Kind != graph.EdgeCrossSubdir {
		t.Errorf("Kind=%s", got.Edges[0].Kind)
	}
}

func TestExtractCodePath(t *testing.T) {
	body := []byte("Path is `apps/cclin-server/internal/router/resolver.go` for the resolver.\n")
	got := Extract("a.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge, got %d", len(got.Edges))
	}
	e := got.Edges[0]
	if e.Kind != graph.EdgeCodePath {
		t.Errorf("Kind=%s want code_path", e.Kind)
	}
	if e.To != "apps/cclin-server/internal/router/resolver.go" {
		t.Errorf("To=%q", e.To)
	}
}

func TestExtractBareMention(t *testing.T) {
	body := []byte(`See feedback_alpha.md and feedback_beta.md for context.
`)
	got := Extract("a.md", body)
	if len(got.Edges) != 2 {
		t.Fatalf("expected 2 edges, got %d", len(got.Edges))
	}
	for _, e := range got.Edges {
		if e.Kind != graph.EdgeBareMention {
			t.Errorf("Kind=%s want bare_mention", e.Kind)
		}
	}
}

func TestExtractAnchorOnly(t *testing.T) {
	body := []byte(`Per §Clause 3.6 the rule applies.
`)
	got := Extract("a.md", body)
	if len(got.Edges) != 1 {
		t.Fatalf("expected 1 edge")
	}
	if got.Edges[0].Kind != graph.EdgeAnchorOnly {
		t.Errorf("Kind=%s", got.Edges[0].Kind)
	}
}

func TestCodeBlockMaskingFenced(t *testing.T) {
	body := []byte("Outside [link](outside.md).\n\n```bash\nfeedback_inside.md\napps/foo/bar.go\n```\n\nAfter [link2](after.md).\n")
	got := Extract("a.md", body)
	hasInside := false
	hasOutside := false
	hasAfter := false
	hasFenced := false
	for _, e := range got.Edges {
		if e.To == "outside.md" {
			hasOutside = true
		}
		if e.To == "after.md" {
			hasAfter = true
		}
		if e.To == "feedback_inside.md" {
			hasInside = true
		}
		if e.To == "apps/foo/bar.go" {
			hasFenced = true
		}
	}
	if !hasOutside {
		t.Error("expected outside.md edge")
	}
	if !hasAfter {
		t.Error("expected after.md edge")
	}
	if hasInside {
		t.Error("fenced bare-mention should be masked")
	}
	if hasFenced {
		t.Error("fenced code-path should be masked")
	}
}

func TestCodeBlockMaskingInline(t *testing.T) {
	body := []byte("Token `feedback_inside.md` should not match. But feedback_real.md should.\n")
	got := Extract("a.md", body)
	for _, e := range got.Edges {
		if e.To == "feedback_inside.md" && e.Kind == graph.EdgeBareMention {
			t.Error("inline-code masked bare-mention should not be extracted")
		}
	}
	hasReal := false
	for _, e := range got.Edges {
		if e.To == "feedback_real.md" {
			hasReal = true
		}
	}
	if !hasReal {
		t.Error("real bare mention missing")
	}
}

func TestExtractHeadingsAndSlugs(t *testing.T) {
	body := []byte(`# Top-Level Heading

## Section One

### Sub Section
`)
	got := Extract("a.md", body)
	if len(got.Headings) != 3 {
		t.Fatalf("expected 3 headings, got %d", len(got.Headings))
	}
	want := []struct {
		level int
		slug  string
	}{
		{1, "top-level-heading"},
		{2, "section-one"},
		{3, "sub-section"},
	}
	for i, w := range want {
		if got.Headings[i].Level != w.level {
			t.Errorf("heading %d level=%d want %d", i, got.Headings[i].Level, w.level)
		}
		if got.Headings[i].Slug != w.slug {
			t.Errorf("heading %d slug=%q want %q", i, got.Headings[i].Slug, w.slug)
		}
	}
}

func TestSlugifyDashCollapse(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"Hello World", "hello-world"},
		{"Multi   Spaces", "multi-spaces"},
		{"Punctuation!@#", "punctuation"},
		{"  Leading and Trailing  ", "leading-and-trailing"},
		{"Already-Hyphenated", "already-hyphenated"},
	}
	for _, c := range cases {
		got := Slugify(c.in)
		if got != c.want {
			t.Errorf("Slugify(%q)=%q want %q", c.in, got, c.want)
		}
	}
}

func TestClassifyMDLinkVariants(t *testing.T) {
	cases := map[string]graph.EdgeKind{
		"feedback_alpha.md":             graph.EdgeMDLink,
		"feedback_alpha.md#anchor":      graph.EdgeMDLinkAnchor,
		"#section":                      graph.EdgeAnchorOnly,
		"../../dev/foo.md":              graph.EdgeExternalRel,
		"http://example.com/x.md":       graph.EdgeExternalRel,
		"topics/cclin/topologies.md":    graph.EdgeCrossSubdir,
	}
	for in, want := range cases {
		got := ClassifyMDLink(in)
		if got != want {
			t.Errorf("Classify(%q)=%s want %s", in, got, want)
		}
	}
}

func TestOffsetLineCol(t *testing.T) {
	body := []byte("line1\nline2\nline3")
	line, col := offsetLineCol(body, 0)
	if line != 1 || col != 1 {
		t.Errorf("offset 0: line=%d col=%d", line, col)
	}
	line, col = offsetLineCol(body, 6)
	if line != 2 || col != 1 {
		t.Errorf("offset 6: line=%d col=%d", line, col)
	}
	line, col = offsetLineCol(body, 8)
	if line != 2 || col != 3 {
		t.Errorf("offset 8: line=%d col=%d", line, col)
	}
}
