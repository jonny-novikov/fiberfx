package stale

import (
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

// testRef is the fixed injected REVIEW-DUE reference date the stale tests use —
// the rule never reads the wall clock (msh2.2 §3.5), so a fixed ref keeps every
// expectation byte-stable forever.
var testRef = time.Date(2026, 7, 2, 0, 0, 0, 0, time.UTC)

func TestRuleReviewDueStories(t *testing.T) {
	cases := []struct {
		name         string
		reviewAfter  string
		status       graph.Status
		wantCount    int
		wantSeverity string
	}{
		{"due fires", "2026-06-01", graph.StatusActive, 1, SeverityWarn},
		{"not yet due yields nothing", "2027-01-01", graph.StatusActive, 0, ""},
		{"boundary fires on the named day", "2026-07-02", graph.StatusActive, 1, SeverityWarn},
		{"invalid date is an error", "soon", graph.StatusActive, 1, SeverityError},
		{"superseded is skipped", "2020-01-01", graph.StatusSuperseded, 0, ""},
		{"keyless yields nothing", "", graph.StatusActive, 0, ""},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			g := graph.New("/root")
			_ = g.AddNode(&graph.Node{Path: "note.md", Type: graph.NodeFeedback, Status: c.status, ReviewAfter: c.reviewAfter})
			got := ruleReviewDue(g, config.Defaults(), newFake(), testRef)
			if len(got) != c.wantCount {
				t.Fatalf("findings=%d want %d: %+v", len(got), c.wantCount, got)
			}
			if c.wantCount == 0 {
				return
			}
			f := got[0]
			if f.Rule != RuleReviewDue {
				t.Errorf("rule=%s want %s", f.Rule, RuleReviewDue)
			}
			if f.Severity != c.wantSeverity {
				t.Errorf("severity=%s want %s", f.Severity, c.wantSeverity)
			}
			if f.File != "note.md" || f.Line != 1 {
				t.Errorf("file=%s line=%d want note.md line 1", f.File, f.Line)
			}
			if f.Target != c.reviewAfter {
				t.Errorf("target=%q want %q", f.Target, c.reviewAfter)
			}
			// The warn message names both the date and the ref (spec §3.5);
			// the error message names the invalid value.
			if !strings.Contains(f.Message, c.reviewAfter) {
				t.Errorf("message %q does not name the value %q", f.Message, c.reviewAfter)
			}
			if c.wantSeverity == SeverityWarn && !strings.Contains(f.Message, "2026-07-02") {
				t.Errorf("message %q does not name the reference date", f.Message)
			}
			if c.wantSeverity == SeverityError && !strings.Contains(f.Message, "invalid review_after") {
				t.Errorf("message %q missing 'invalid review_after'", f.Message)
			}
		})
	}
}

func TestRuleReviewDueDeterministicUnderFixedRef(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "due.md", Type: graph.NodeFeedback, Status: graph.StatusActive, ReviewAfter: "2026-01-01"})
	_ = g.AddNode(&graph.Node{Path: "bad.md", Type: graph.NodeFeedback, Status: graph.StatusActive, ReviewAfter: "not-a-date"})
	cfg := config.Defaults()
	src := newFake()
	first := ruleReviewDue(g, cfg, src, testRef)
	second := ruleReviewDue(g, cfg, src, testRef)
	if !reflect.DeepEqual(first, second) {
		t.Errorf("same corpus + same ref must be identical:\nfirst:  %+v\nsecond: %+v", first, second)
	}
}

func TestRunSelectsReviewDueByName(t *testing.T) {
	g := graph.New("/root")
	_ = g.AddNode(&graph.Node{Path: "due.md", Type: graph.NodeFeedback, Status: graph.StatusActive, ReviewAfter: "2026-01-01"})
	got := Run(g, config.Defaults(), newFake(), []string{"REVIEW-DUE"}, testRef)
	if len(got) != 1 {
		t.Fatalf("findings=%d want 1: %+v", len(got), got)
	}
	if got[0].Rule != RuleReviewDue {
		t.Errorf("rule=%s want %s", got[0].Rule, RuleReviewDue)
	}
}
