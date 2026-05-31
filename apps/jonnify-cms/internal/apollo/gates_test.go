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
	ok, detail := gateContainers(`<main><section><p>x</p></main>`)
	if ok {
		t.Fatalf("expected unbalanced detection, got pass: %s", detail)
	}
}
