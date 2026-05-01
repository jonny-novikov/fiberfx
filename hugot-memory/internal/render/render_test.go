package render

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"github.com/fiberfx/hugot-memory/internal/graph"
	"github.com/fiberfx/hugot-memory/internal/stale"
)

func TestPrettyScan(t *testing.T) {
	var buf bytes.Buffer
	nodes := []*graph.Node{
		{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusActive, SizeBytes: 100, Name: "Sample"},
	}
	if err := PrettyScan(&buf, nodes); err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, "a.md") {
		t.Errorf("missing path: %s", out)
	}
	if !strings.Contains(out, "PATH") {
		t.Errorf("missing header: %s", out)
	}
}

func TestPrettyFindingsEmpty(t *testing.T) {
	var buf bytes.Buffer
	if err := PrettyFindings(&buf, stale.Findings{}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "no findings") {
		t.Errorf("expected 'no findings', got %q", buf.String())
	}
}

func TestPrettyFindingsHasRows(t *testing.T) {
	var buf bytes.Buffer
	f := stale.Findings{
		{Severity: stale.SeverityError, Rule: "DEAD-TARGET", File: "a.md", Line: 5, Target: "x.md", Message: "missing"},
	}
	if err := PrettyFindings(&buf, f); err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, "DEAD-TARGET") || !strings.Contains(out, "a.md") {
		t.Errorf("unexpected output: %s", out)
	}
}

func TestNDJSONNodes(t *testing.T) {
	var buf bytes.Buffer
	nodes := []*graph.Node{
		{Path: "a.md", Type: graph.NodeFeedback, Status: graph.StatusActive},
		{Path: "b.md", Type: graph.NodeFeedback, Status: graph.StatusActive},
	}
	if err := NDJSONNodes(&buf, nodes); err != nil {
		t.Fatal(err)
	}
	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	if len(lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(lines))
	}
	for _, line := range lines {
		var got graph.Node
		if err := json.Unmarshal([]byte(line), &got); err != nil {
			t.Errorf("decode: %v", err)
		}
	}
}

func TestNDJSONFindings(t *testing.T) {
	var buf bytes.Buffer
	f := stale.Findings{
		{Severity: stale.SeverityError, Rule: "DEAD-TARGET", File: "a.md"},
		{Severity: stale.SeverityWarn, Rule: "REMOVED-TOOL", File: "b.md"},
	}
	if err := NDJSONFindings(&buf, f); err != nil {
		t.Fatal(err)
	}
	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	if len(lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(lines))
	}
}

func TestPrettyAuditSummary(t *testing.T) {
	var buf bytes.Buffer
	counts := map[string]int{
		stale.SeverityError: 1,
		stale.SeverityWarn:  2,
		stale.SeverityInfo:  3,
	}
	if err := PrettyAuditSummary(&buf, counts, 84); err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, "84 files") {
		t.Errorf("missing file count: %s", out)
	}
	if !strings.Contains(out, "error=1") {
		t.Errorf("missing error count: %s", out)
	}
}
