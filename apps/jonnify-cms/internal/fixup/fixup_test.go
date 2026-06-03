package fixup

import "testing"

const (
	root  = "/x/html/agile-agent-workflow"
	file  = "/x/html/agile-agent-workflow/why/four-artifacts.html"
	mount = "/course/agile-agent-workflow"
)

func allowedSet() map[string]bool {
	return map[string]bool{
		"/course/agile-agent-workflow":                     true,
		"/course/agile-agent-workflow/why":                 true,
		"/course/agile-agent-workflow/why/four-artifacts":  true,
		"/course/agile-agent-workflow/why/two-layer-model": true,
		"/elixir":        true,
		"/elixir/course": true,
	}
}

// sample mixes the author scheme (/course/.../a1/...), an already-canonical link,
// a shortened-prefix link (the wrong-direction form an earlier pass produced),
// a foreign route, and a section link with no valid repair.
const sample = `<style>h1{font-size:clamp(2.7rem,1.9rem+4.2vw,5.1rem)}</style>
<span class="route-tag">/course/agile-agent-workflow/a1/four-artifacts</span>
<a href="/course/agile-agent-workflow">course</a>
<a href="/course/agile-agent-workflow/a1">chapter</a>
<a href="/course/agile-agent-workflow/a1/two-layer-model">sibling</a>
<a href="/agile-agent-workflow/why/two-layer-model">short-prefix sibling</a>
<a href="/elixir/course">companion</a>
<a href="/agile-agent-workflow/why/ghost">dead</a>
<a href="https://example.com">ext</a>`

func TestApplyRepairs(t *testing.T) {
	// No aliases: a1->why resolves via the page's own chapter dir (swapChapter).
	out, r := Apply(sample, file, root, mount, nil, allowedSet())

	if r.Clamps != 1 {
		t.Errorf("clamps = %d, want 1", r.Clamps)
	}
	if r.Relinks != 3 {
		t.Errorf("relinks = %d, want 3; changes=%v", r.Relinks, r.Changes)
	}
	if !r.RouteTag {
		t.Error("route-tag not corrected")
	}
	for _, want := range []string{
		"clamp(2.7rem,1.9rem + 4.2vw,5.1rem)",
		`href="/course/agile-agent-workflow/why"`,
		`href="/course/agile-agent-workflow/why/two-layer-model"`,
		`route-tag">/course/agile-agent-workflow/why/four-artifacts`,
	} {
		if !contains(out, want) {
			t.Errorf("output missing %q", want)
		}
	}
	if !contains(out, `href="/agile-agent-workflow/why/ghost"`) {
		t.Error("ghost link should be untouched (no valid repair)")
	}
	if !contains(out, `href="/course/agile-agent-workflow"`) {
		t.Error("already-valid /course hub link should be untouched")
	}
	if !contains(out, `href="/elixir/course"`) {
		t.Error("already-valid /elixir/course link should be untouched")
	}
}

// TestApplyAliasesAndFlatten exercises the A0 chapter: a0->intro / a1->why and a
// nested deep-dive reference collapsing to its flat hyphenated file.
func TestApplyAliasesAndFlatten(t *testing.T) {
	introRoot := "/x/html/agile-agent-workflow"
	introFile := "/x/html/agile-agent-workflow/intro/index.html"
	aliases := map[string]string{"a0": "intro", "a1": "why"}
	allowed := map[string]bool{
		"/course/agile-agent-workflow/intro":                                 true,
		"/course/agile-agent-workflow/intro/two-layer-model":                 true,
		"/course/agile-agent-workflow/intro/two-layer-model-roadmap-anatomy": true,
		"/course/agile-agent-workflow/intro/four-artifacts":                  true,
		"/course/agile-agent-workflow/why":                                   true,
	}
	doc := `<a href="/course/agile-agent-workflow/a0">chap</a>
<a href="/course/agile-agent-workflow/a0/four-artifacts">leaf</a>
<a href="/course/agile-agent-workflow/a0/two-layer-model/roadmap-anatomy">deep dive</a>
<a href="/course/agile-agent-workflow/a1">next chapter</a>`

	out, r := Apply(doc, introFile, introRoot, mount, aliases, allowed)
	if r.Relinks != 4 {
		t.Fatalf("relinks = %d, want 4; changes=%v", r.Relinks, r.Changes)
	}
	for _, want := range []string{
		`href="/course/agile-agent-workflow/intro"`,
		`href="/course/agile-agent-workflow/intro/four-artifacts"`,
		`href="/course/agile-agent-workflow/intro/two-layer-model-roadmap-anatomy"`,
		`href="/course/agile-agent-workflow/why"`,
	} {
		if !contains(out, want) {
			t.Errorf("output missing %q; got %s", want, out)
		}
	}
}

func TestApplyIdempotent(t *testing.T) {
	once, _ := Apply(sample, file, root, mount, nil, allowedSet())
	twice, r := Apply(once, file, root, mount, nil, allowedSet())
	if r.Changed() {
		t.Errorf("second Apply changed the doc: clamps=%d relinks=%d routeTag=%v", r.Clamps, r.Relinks, r.RouteTag)
	}
	if once != twice {
		t.Error("Apply is not idempotent")
	}
}

func TestClampOnlyWithoutSection(t *testing.T) {
	in := `<style>h1{font-size:clamp(2.7rem,1.9rem+4.2vw,5.1rem)}</style><a href="/course/x/a1">x</a>`
	out, r := Apply(in, file, "", "", nil, nil)
	if r.Clamps != 1 {
		t.Errorf("clamps = %d, want 1", r.Clamps)
	}
	if r.Relinks != 0 {
		t.Errorf("relinks = %d, want 0 (no section context)", r.Relinks)
	}
	if !contains(out, `href="/course/x/a1"`) {
		t.Error("link must be untouched without a section")
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
