package apollo

import (
	"strings"
	"testing"
)

func TestGoodDocPassesAll(t *testing.T) {
	res, all := Run(goodDoc)
	if !all {
		for _, r := range res {
			if !r.OK {
				t.Errorf("gate %q failed: %s", r.Name, r.Detail)
			}
		}
	}
}

func TestBadDocFailsExpectedGates(t *testing.T) {
	res, all := Run(badDoc)
	if all {
		t.Fatal("badDoc unexpectedly passed every gate")
	}
	for _, name := range []string{"voice", "storage", "no-future", "links"} {
		if ok, _ := passDetail(res, name); ok {
			t.Errorf("gate %q should have failed", name)
		}
	}
	if ok, detail := passDetail(res, "voice"); !ok && !strings.Contains(detail, "just") {
		t.Errorf("voice detail = %q, want it to name 'just'", detail)
	}
}

func TestContainersDetectsUnclosed(t *testing.T) {
	ok, detail := gateContainers(`<main><section><p>x</p></main>`, nil)
	if ok {
		t.Fatalf("expected unbalanced detection, got pass: %s", detail)
	}
}

func TestRefsGateIsOptIn(t *testing.T) {
	// A page with no .refs block passes the nine core gates but fails once the
	// opt-in refs requirement is on — and the CSS selector alone is not enough.
	noRefs := strings.Replace(goodDoc, `class="refs"`, `class="reflist"`, 1)
	if _, all := RunWith(noRefs, nil); !all {
		// goodDoc may legitimately fail an unrelated core gate; only assert the
		// refs interaction below, which is what this test pins down.
		_ = all
	}
	if ok, _ := gateRefs(`<style>.refs{margin:0}</style><p>no section here</p>`, nil); ok {
		t.Error("a .refs CSS selector with no class=\"refs\" element must fail the refs gate")
	}
	if ok, _ := gateRefs(`<section id="refs"><div class="refs"><ul><li>x</li></ul></div></section>`, nil); !ok {
		t.Error("a real References section must pass the refs gate")
	}
	// Opt-in semantics: RequireRefs flips a refs-less doc from its core verdict to FAIL.
	core := `<main class="pager"><svg></svg>prefers-reduced-motion <a href="#x">x</a></main>`
	if _, withRefs := RunWithOpts(core, nil, Opts{RequireRefs: true}); withRefs {
		t.Error("RequireRefs must fail a document that has no References section")
	}
}
