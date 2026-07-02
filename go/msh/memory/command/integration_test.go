package command

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/stale"
)

func TestAuditAgainstSyntheticCorpus(t *testing.T) {
	root := testdataRoot(t)
	g, src, err := loadCorpus(root)
	if err != nil {
		t.Fatalf("load corpus: %v", err)
	}
	if g.NodeCount() != 12 {
		t.Errorf("expected 12 nodes in synthetic corpus, got %d", g.NodeCount())
	}

	cfg := config.Defaults()
	findings := stale.Run(g, cfg, src, []string{"all"}, fixedRef)

	expectFinding(t, findings, stale.RuleDeadTarget, "feedback_dead.md", stale.SeverityError)
	expectFinding(t, findings, stale.RuleBrokenAnchor, "feedback_anchor.md", stale.SeverityWarn)
	expectFinding(t, findings, stale.RuleRemovedTool, "feedback_removed_tool.md", stale.SeverityWarn)
	expectFinding(t, findings, stale.RuleRemovedTool, "feedback_removed_tool_whitelist.md", stale.SeverityInfo)
	expectFinding(t, findings, stale.RuleStaleExternal, "feedback_external.md", stale.SeverityWarn)
	expectFinding(t, findings, stale.RuleOrphan, "feedback_orphan.md", stale.SeverityInfo)

	expectNoFindingFor(t, findings, stale.RuleOrphan, "completed-projects.md")
	expectNoFindingFor(t, findings, stale.RuleOrphan, "MEMORY.md")
}

func TestSyntheticCorpusMemoryReferenceWhitelisted(t *testing.T) {
	root := testdataRoot(t)
	g, src, err := loadCorpus(root)
	if err != nil {
		t.Fatal(err)
	}
	cfg := config.Defaults()
	findings := stale.Run(g, cfg, src, []string{stale.RuleDeletedPath}, fixedRef)
	for _, f := range findings {
		if f.File == "MEMORY.md" && f.Severity == stale.SeverityError {
			t.Errorf("MEMORY.md apps/mcp reference should not be ERROR (deletion-context whitelisted)")
		}
	}
}

func TestScanCommandNDJSON(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"scan", "--format", "ndjson", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("scan exec: %v", err)
	}
	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	if len(lines) != 12 {
		t.Errorf("expected 12 NDJSON lines, got %d", len(lines))
	}
	for i, line := range lines {
		var node map[string]any
		if err := json.Unmarshal([]byte(line), &node); err != nil {
			t.Errorf("line %d not valid json: %v", i, err)
		}
		if _, ok := node["path"]; !ok {
			t.Errorf("line %d missing path", i)
		}
	}
}

func TestGraphCommandJSON(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"graph", "--format", "json", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("graph exec: %v", err)
	}
	var parsed struct {
		Nodes []map[string]any `json:"nodes"`
		Edges []map[string]any `json:"edges"`
	}
	if err := json.Unmarshal(buf.Bytes(), &parsed); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(parsed.Nodes) != 12 {
		t.Errorf("expected 12 nodes, got %d", len(parsed.Nodes))
	}
	if len(parsed.Edges) == 0 {
		t.Errorf("expected non-zero edges")
	}
}

func TestGraphCommandDot(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"graph", "--format", "dot", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("graph exec: %v", err)
	}
	if !strings.HasPrefix(strings.TrimSpace(buf.String()), "digraph memory") {
		t.Errorf("expected digraph header, got: %.100s", buf.String())
	}
}

func TestStaleCommandRespectsRulesFlag(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"stale", "--rules", "ORPHAN", "--severity", "info", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("stale exec: %v", err)
	}
	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	for i, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		var f map[string]any
		if err := json.Unmarshal([]byte(line), &f); err != nil {
			t.Errorf("line %d not json: %v", i, err)
			continue
		}
		if f["rule"] != "ORPHAN" {
			t.Errorf("line %d rule=%v want ORPHAN", i, f["rule"])
		}
	}
}

func TestAuditCommandSummaryFailsOnDeadTarget(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"audit", "--root", testdataRoot(t)})
	err := root.Execute()
	if err == nil {
		t.Errorf("expected non-zero exit (synthetic corpus has DEAD-TARGET)")
	}
	if !strings.Contains(buf.String(), "audit summary") {
		t.Errorf("expected summary header, got: %s", buf.String())
	}
}

func TestVersionCommand(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"version"})
	if err := root.Execute(); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "msh-memory") {
		t.Errorf("missing version output: %s", buf.String())
	}
}

func TestRunWrapperOK(t *testing.T) {
	cwd, _ := os.Getwd()
	defer os.Chdir(cwd)
	if err := os.Chdir(testdataRoot(t)); err != nil {
		t.Fatal(err)
	}
	code := run([]string{"version"})
	if code != exitOK {
		t.Errorf("run version exit=%d want 0", code)
	}
}

func TestRunWrapperUsageError(t *testing.T) {
	code := run([]string{"scan", "--format", "garbage"})
	if code != exitUsage {
		t.Errorf("garbage format should produce exit=%d want %d", code, exitUsage)
	}
}

func TestResolveRootExplicit(t *testing.T) {
	dir := testdataRoot(t)
	got, err := resolveRoot(dir)
	if err != nil {
		t.Fatal(err)
	}
	abs, _ := filepath.Abs(dir)
	if got != abs {
		t.Errorf("resolveRoot=%s want %s", got, abs)
	}
}

func TestResolveRootMissing(t *testing.T) {
	if _, err := resolveRoot(filepath.Join(t.TempDir(), "nope")); err == nil {
		t.Fatal("expected error")
	}
}

func TestStaleSeverityFiltering(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"stale", "--severity", "error", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("stale exec: %v", err)
	}
	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		if !strings.Contains(line, `"error"`) {
			t.Errorf("non-error line at error severity: %s", line)
		}
	}
}

func expectFinding(t *testing.T, findings stale.Findings, rule, file, severity string) {
	t.Helper()
	for _, f := range findings {
		if f.Rule == rule && f.File == file && f.Severity == severity {
			return
		}
	}
	t.Errorf("missing expected finding: rule=%s file=%s severity=%s. all findings: %+v", rule, file, severity, findings)
}

func expectNoFindingFor(t *testing.T, findings stale.Findings, rule, file string) {
	t.Helper()
	for _, f := range findings {
		if f.Rule == rule && f.File == file {
			t.Errorf("unexpected finding: rule=%s file=%s severity=%s", rule, file, f.Severity)
			return
		}
	}
}

func testdataRoot(t *testing.T) string {
	t.Helper()
	wd, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(wd, "..", "testdata", "memory")
	abs, err := filepath.Abs(root)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(abs); err != nil {
		t.Fatalf("testdata missing: %v", err)
	}
	return abs
}
