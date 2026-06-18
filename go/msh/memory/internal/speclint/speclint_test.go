package speclint

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/jonny-novikov/msh/memory/internal/stale"
)

// writeFile is a tiny fixture helper.
func writeFile(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func TestCheck(t *testing.T) {
	root := t.TempDir()
	area := filepath.Join(root, "area")

	// Cross-area target that exists OUTSIDE the walked area — must resolve.
	writeFile(t, filepath.Join(root, "outside.md"), "# Outside\n")
	// Link target inside the area with a known heading.
	writeFile(t, filepath.Join(area, "b.md"), "# B\n\n## Real Section\n")
	// The file under test.
	writeFile(t, filepath.Join(area, "a.md"), `# A

[ok file](b.md)
[ok anchor](b.md#real-section)
[bad anchor](b.md#missing)
[dead file](c.md)
[self bad](#nope)
[web route](/redis-patterns)
[external](https://example.com)
[mail](mailto:x@y.z)
[cross ok](../outside.md)
[cross dead](../nope.md)
`)

	res, err := Check(area, root)
	if err != nil {
		t.Fatalf("Check: %v", err)
	}

	// a.md + b.md are under area; outside.md is not walked.
	if res.Files != 2 {
		t.Errorf("Files=%d want 2", res.Files)
	}

	byRule := map[string]int{}
	for _, f := range res.Findings {
		byRule[f.Rule]++
		if f.File == "" || f.Line == 0 {
			t.Errorf("finding missing file/line: %+v", f)
		}
	}
	// dead file (c.md) + cross dead (../nope.md) = 2 dead targets.
	if byRule[stale.RuleDeadTarget] != 2 {
		t.Errorf("DEAD-TARGET=%d want 2 (%+v)", byRule[stale.RuleDeadTarget], res.Findings)
	}
	// bad anchor (b.md#missing) + self bad (#nope) = 2 broken anchors.
	if byRule[stale.RuleBrokenAnchor] != 2 {
		t.Errorf("BROKEN-ANCHOR=%d want 2 (%+v)", byRule[stale.RuleBrokenAnchor], res.Findings)
	}
	// Total: nothing else (ok file/anchor, web route, external, mail, cross ok are clean/skipped).
	if len(res.Findings) != 4 {
		t.Errorf("findings=%d want 4: %+v", len(res.Findings), res.Findings)
	}

	// Severity mapping: dead target = error, broken anchor = warn.
	for _, f := range res.Findings {
		switch f.Rule {
		case stale.RuleDeadTarget:
			if f.Severity != stale.SeverityError {
				t.Errorf("dead target severity=%s want error", f.Severity)
			}
		case stale.RuleBrokenAnchor:
			if f.Severity != stale.SeverityWarn {
				t.Errorf("broken anchor severity=%s want warn", f.Severity)
			}
		}
	}
}

func TestCheckDisplayPathRelativeToRoot(t *testing.T) {
	root := t.TempDir()
	area := filepath.Join(root, "docs", "x")
	writeFile(t, filepath.Join(area, "a.md"), "[dead](missing.md)\n")

	res, err := Check(area, root)
	if err != nil {
		t.Fatalf("Check: %v", err)
	}
	if len(res.Findings) != 1 {
		t.Fatalf("findings=%d want 1", len(res.Findings))
	}
	if got, want := res.Findings[0].File, "docs/x/a.md"; got != want {
		t.Errorf("File=%q want %q (repo-relative, slash-separated)", got, want)
	}
}

func TestOffsiteTargetsSkipped(t *testing.T) {
	root := t.TempDir()
	writeFile(t, filepath.Join(root, "a.md"), `
[a](/site/route)
[b](https://example.com/x)
[c](http://example.com)
[d](mailto:x@y.z)
[e](tel:+1)
`)
	res, err := Check(root, root)
	if err != nil {
		t.Fatalf("Check: %v", err)
	}
	if len(res.Findings) != 0 {
		t.Errorf("offsite links should be skipped, got %+v", res.Findings)
	}
}
