package command

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/render"
	"github.com/jonny-novikov/msh/memory/internal/stale"
)

// fixedRef is the injected REVIEW-DUE reference date for fixtures + goldens —
// the production callers inject the UTC day instead; the rule itself never
// reads the clock (msh2.2 §3.5), so these bytes stay stable forever.
var fixedRef = time.Date(2026, 7, 2, 0, 0, 0, 0, time.UTC)

func reviewDueFixtureRoot(t *testing.T) string {
	t.Helper()
	wd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	abs, err := filepath.Abs(filepath.Join(wd, "..", "testdata", "review_due"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(abs); err != nil {
		t.Fatalf("review_due fixture missing: %v", err)
	}
	return abs
}

// G-6: the REVIEW-DUE golden fixture — due / not-yet / boundary (ref == date) /
// invalid date / superseded-skip — byte-stable across runs under the fixed
// injected reference date.
func TestReviewDueGoldenByteStable(t *testing.T) {
	root := reviewDueFixtureRoot(t)
	g, src, err := loadCorpus(root)
	if err != nil {
		t.Fatal(err)
	}
	cfg := config.Defaults()

	emit := func() []byte {
		t.Helper()
		findings := stale.Run(g, cfg, src, []string{stale.RuleReviewDue}, fixedRef)
		var buf bytes.Buffer
		if err := render.NDJSONFindings(&buf, findings); err != nil {
			t.Fatal(err)
		}
		return buf.Bytes()
	}

	first := emit()
	second := emit()
	if !bytes.Equal(first, second) {
		t.Fatalf("two runs at the same ref differ:\nfirst:  %s\nsecond: %s", first, second)
	}

	golden, err := os.ReadFile(filepath.Join(root, "..", "review_due.golden.ndjson"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(first, golden) {
		t.Errorf("golden drift:\ngot:  %s\nwant: %s", first, golden)
	}
}

// G-7: the audit exit honors ANY error-severity finding (msh2.2 D6) — an
// invalid review_after (error, not a DEAD-TARGET) now exits non-zero.
func TestAuditExitsOnAnyErrorSeverity(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "bad.md", "---\nname: bad\ndescription: malformed review date\ntype: feedback\nreview_after: soon\n---\n\nbody.\n")

	out, err := runCLI(t, "audit", "--root", dir)
	if err == nil {
		t.Fatal("expected non-zero exit: an invalid review_after is error-severity")
	}
	if !strings.Contains(err.Error(), "error-severity") {
		t.Errorf("exit error should name the trigger, got %q", err.Error())
	}
	if !strings.Contains(out, "audit summary") {
		t.Errorf("summary still prints before the exit: %q", out)
	}
}

func TestAuditPassesCleanCorpus(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "good.md", "---\nname: good\ndescription: healthy note\ntype: feedback\nreview_after: 2999-01-01\n---\n\nbody.\n")

	if _, err := runCLI(t, "audit", "--root", dir); err != nil {
		t.Errorf("clean corpus must pass audit, got: %v", err)
	}
}
