package command

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestStaleSeverityInvalid(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"stale", "--severity", "garbage", "--root", testdataRoot(t)})
	err := root.Execute()
	if err == nil {
		t.Fatal("expected invalid severity error")
	}
}

func TestScanFormatPretty(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"scan", "--format", "pretty", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("scan exec: %v", err)
	}
	out := buf.String()
	if !strings.Contains(out, "PATH") {
		t.Errorf("expected PATH header, got: %s", out)
	}
	if !strings.Contains(out, "MEMORY.md") {
		t.Errorf("expected MEMORY.md row, got: %s", out)
	}
}

func TestStaleFormatPretty(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"stale", "--format", "pretty", "--severity", "info", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("stale pretty exec: %v", err)
	}
	if !strings.Contains(buf.String(), "SEVERITY") && !strings.Contains(buf.String(), "no findings") {
		t.Errorf("unexpected pretty output: %s", buf.String())
	}
}

func TestGraphFormatInvalid(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"graph", "--format", "yaml", "--root", testdataRoot(t)})
	if err := root.Execute(); err == nil {
		t.Fatal("expected error for unknown graph format")
	}
}

func TestGraphOutToFile(t *testing.T) {
	out := filepath.Join(t.TempDir(), "graph.json")
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"graph", "--format", "json", "--out", out, "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("graph out exec: %v", err)
	}
	data, err := os.ReadFile(out)
	if err != nil {
		t.Fatalf("read out: %v", err)
	}
	if !bytes.Contains(data, []byte(`"nodes"`)) {
		t.Errorf("output file missing nodes: %s", data)
	}
}

func TestAuditExitCodeDisabled(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"audit", "--exit-code=false", "--root", testdataRoot(t)})
	if err := root.Execute(); err != nil {
		t.Fatalf("audit with exit-code disabled should succeed, got: %v", err)
	}
}

func TestAuditMaxWarn(t *testing.T) {
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs([]string{"audit", "--max-warn", "0", "--root", testdataRoot(t)})
	err := root.Execute()
	if err == nil {
		t.Fatal("synthetic corpus has warns; --max-warn 0 should fail")
	}
}

func TestParseRulesList(t *testing.T) {
	cases := []struct {
		in   string
		want int
	}{
		{"", 1},
		{"all", 1},
		{"DEAD-TARGET,REMOVED-TOOL", 2},
		{"  DEAD-TARGET  ", 1},
	}
	for _, c := range cases {
		got := parseRulesList(c.in)
		if len(got) != c.want {
			t.Errorf("parseRulesList(%q) len=%d want %d", c.in, len(got), c.want)
		}
	}
}

func TestNormalizeFormatEmpty(t *testing.T) {
	if normalizeFormat("") != "pretty" {
		t.Error("empty format should default pretty")
	}
}

func TestParseLogLevel(t *testing.T) {
	if _, err := parseLogLevel("debug"); err != nil {
		t.Errorf("debug: %v", err)
	}
	if _, err := parseLogLevel("garbage"); err == nil {
		t.Error("garbage should error")
	}
}

func TestBuildLoggerJSON(t *testing.T) {
	var buf bytes.Buffer
	flags := &globalFlags{LogLevel: "info", LogFormat: "json"}
	if _, err := buildLogger(&buf, flags); err != nil {
		t.Fatal(err)
	}
}

func TestBuildLoggerInvalidFormat(t *testing.T) {
	var buf bytes.Buffer
	flags := &globalFlags{LogLevel: "info", LogFormat: "yaml"}
	if _, err := buildLogger(&buf, flags); err == nil {
		t.Fatal("yaml format should error")
	}
}

func TestBuildLoggerInvalidLevel(t *testing.T) {
	var buf bytes.Buffer
	flags := &globalFlags{LogLevel: "garbage", LogFormat: "text"}
	if _, err := buildLogger(&buf, flags); err == nil {
		t.Fatal("garbage level should error")
	}
}

func TestClassifyTypeFallbacks(t *testing.T) {
	cases := []struct {
		raw, path string
		want      string
	}{
		{"feedback", "x.md", "feedback"},
		{"", "MEMORY.md", "index"},
		{"", "completed-projects.md", "index"},
		{"", "law3_foo.md", "law"},
		{"", "session_pause_x.md", "session_pause"},
		{"", "feedback_y.md", "feedback"},
		{"", "project_z.md", "project"},
		{"", "reference_q.md", "reference"},
		{"", "topics/feedback-index.md", "index"},
		{"", "uncategorized.md", "unknown"},
	}
	for _, c := range cases {
		got := classifyType(c.raw, c.path)
		if string(got) != c.want {
			t.Errorf("classifyType(%q,%q)=%s want %s", c.raw, c.path, got, c.want)
		}
	}
}

func TestIsSupersededByText(t *testing.T) {
	cases := []struct {
		body string
		want bool
	}{
		{"# Title\n\n> **Superseded** by foo.md\n", true},
		{"# Title\n\n(superseded — see foo.md)\n", true},
		{"# Title\n\nactive content here.\n", false},
	}
	for _, c := range cases {
		body := []byte(c.body)
		got := isSupersededByText(body, 0)
		if got != c.want {
			t.Errorf("isSupersededByText(%q)=%v want %v", c.body, got, c.want)
		}
	}
}

func TestCorpusSourceExistsRelative(t *testing.T) {
	root := testdataRoot(t)
	c := &corpusSource{root: root, bodies: map[string][]byte{}, headings: map[string][]string{}}
	if !c.Exists("MEMORY.md") {
		t.Error("expected MEMORY.md to exist")
	}
	if c.Exists("nope.md") {
		t.Error("nope.md should not exist")
	}
}

func TestCorpusBodyMissingErrors(t *testing.T) {
	c := &corpusSource{bodies: map[string][]byte{}, headings: map[string][]string{}}
	if _, err := c.Body("missing"); err == nil {
		t.Error("expected error")
	}
	if _, err := c.HeadingSlugs("missing"); err == nil {
		t.Error("expected error")
	}
}
