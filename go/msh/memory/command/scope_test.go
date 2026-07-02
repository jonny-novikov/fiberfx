package command

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/jonny-novikov/msh/memory/internal/graph"
)

// writeNote drops a fixture note at rel (slash-separated) under root.
func writeNote(t *testing.T, root, rel, content string) {
	t.Helper()
	abs := filepath.Join(root, filepath.FromSlash(rel))
	if err := os.MkdirAll(filepath.Dir(abs), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(abs, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

// runCLI executes the cobra command tree with args and returns stdout.
func runCLI(t *testing.T, args ...string) (string, error) {
	t.Helper()
	var buf bytes.Buffer
	cfg := rootConfig{Stdout: &buf, Stderr: &bytes.Buffer{}}
	root := newRootCmd(cfg)
	root.SetArgs(args)
	err := root.Execute()
	return buf.String(), err
}

func ndjsonLines(s string) []string {
	trimmed := strings.TrimRight(s, "\n")
	if trimmed == "" {
		return nil
	}
	return strings.Split(trimmed, "\n")
}

// G-2: scoped scan counts — unfiltered = N, --project P returns exactly the P
// subset, unscoped notes match no filter, and the ops path (the MCP handler's
// implementation) returns the same rows as the CLI.
func TestScopedScanCounts(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "a.md", "---\nname: a\ndescription: mercury note\ntype: feedback\nproject: mercury\n---\n\nalpha body.\n")
	writeNote(t, dir, "b.md", "---\nname: b\ndescription: msh note\ntype: feedback\nproject: msh\n---\n\nbeta body.\n")
	writeNote(t, dir, "c.md", "---\nname: c\ndescription: keyless flat note\ntype: feedback\n---\n\ngamma body.\n")
	writeNote(t, dir, "d.md", "---\nname: d\ndescription: v2 key nested only\ntype: feedback\nmetadata:\n  project: mercury\n---\n\ndelta body.\n")

	unfiltered, err := runCLI(t, "scan", "--format", "ndjson", "--root", dir)
	if err != nil {
		t.Fatalf("unfiltered scan: %v", err)
	}
	if got := len(ndjsonLines(unfiltered)); got != 4 {
		t.Errorf("unfiltered rows=%d want 4", got)
	}

	scoped, err := runCLI(t, "scan", "--format", "ndjson", "--project", "mercury", "--root", dir)
	if err != nil {
		t.Fatalf("scoped scan: %v", err)
	}
	lines := ndjsonLines(scoped)
	if len(lines) != 1 {
		t.Fatalf("mercury rows=%d want 1: %q", len(lines), scoped)
	}
	if !strings.Contains(lines[0], `"a.md"`) || !strings.Contains(lines[0], `"project":"mercury"`) {
		t.Errorf("mercury row wrong: %s", lines[0])
	}
	// d.md declares project only under metadata: — top-level only (§3.1), so
	// it does NOT match the declared value.
	if strings.Contains(scoped, "d.md") {
		t.Errorf("nested metadata.project must not scope d.md: %q", scoped)
	}
	// The unscoped flat note c.md appears in no filtered output.
	if strings.Contains(scoped, "c.md") {
		t.Errorf("unscoped note leaked into the mercury filter: %q", scoped)
	}

	scopedMsh, err := runCLI(t, "scan", "--format", "ndjson", "--project", "msh", "--root", dir)
	if err != nil {
		t.Fatalf("msh scan: %v", err)
	}
	if lines := ndjsonLines(scopedMsh); len(lines) != 1 || !strings.Contains(lines[0], `"b.md"`) {
		t.Errorf("msh subset wrong: %q", scopedMsh)
	}

	// The ops path — the exact function the MCP memory_scan handler calls —
	// returns the same rows as the CLI (one implementation, S-2).
	opsOut, err := Scan(dir, "ndjson", "mercury")
	if err != nil {
		t.Fatalf("ops scan: %v", err)
	}
	if opsOut != scoped {
		t.Errorf("ops path diverges from CLI:\nops: %q\ncli: %q", opsOut, scoped)
	}
}

// G-3: a scoped stale run invents nothing — the rules run over the FULL graph
// and the findings are post-filtered, so a project-P note linked only from a
// project-Q note never false-reports ORPHAN under --project P.
func TestScopedStaleInventsNothing(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "p-note.md", "---\nname: p-note\ndescription: p target cited only from q\ntype: feedback\nproject: p\n---\n\np body.\n")
	writeNote(t, dir, "q-note.md", "---\nname: q-note\ndescription: q citer\ntype: feedback\nproject: q\n---\n\nsee [p](p-note.md).\n")

	unfiltered, err := Stale(dir, "", "all", "info", "ndjson", "")
	if err != nil {
		t.Fatalf("unfiltered stale: %v", err)
	}
	if !strings.Contains(unfiltered, "ORPHAN") || !strings.Contains(unfiltered, "q-note.md") {
		t.Fatalf("expected the q-note ORPHAN in the unfiltered run: %q", unfiltered)
	}

	scopedP, err := Stale(dir, "", "all", "info", "ndjson", "p")
	if err != nil {
		t.Fatalf("scoped stale: %v", err)
	}
	// Pre-filtering the graph would strip q-note's inbound link and invent an
	// ORPHAN for p-note.md; the post-filter yields nothing new.
	if strings.TrimSpace(scopedP) != "" {
		t.Errorf("scoped run invented findings absent from the unfiltered run: %q", scopedP)
	}

	scopedQ, err := Stale(dir, "", "all", "info", "ndjson", "q")
	if err != nil {
		t.Fatalf("scoped q stale: %v", err)
	}
	unfilteredSet := make(map[string]bool)
	for _, l := range ndjsonLines(unfiltered) {
		unfilteredSet[l] = true
	}
	for _, l := range ndjsonLines(scopedQ) {
		if !unfilteredSet[l] {
			t.Errorf("scoped finding absent from the unfiltered run: %s", l)
		}
		if !strings.Contains(l, `"q-note.md"`) {
			t.Errorf("scoped q finding names a foreign file: %s", l)
		}
	}
}

// G-4: the degrade order — a keyless subdirectory note scopes to its first
// path segment; a keyless flat note is unscoped and matches no filter.
func TestDegradeOrder(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "echo_mq/nested.md", "---\nname: nested\ndescription: keyless dir note\ntype: feedback\n---\n\nnested body.\n")
	writeNote(t, dir, "flat.md", "---\nname: flat\ndescription: keyless flat note\ntype: feedback\n---\n\nflat body.\n")

	g, _, err := loadCorpus(dir)
	if err != nil {
		t.Fatal(err)
	}
	nested, ok := g.Node("echo_mq/nested.md")
	if !ok {
		t.Fatal("nested node missing")
	}
	if nested.Project != "echo_mq" {
		t.Errorf("nested Project=%q want echo_mq (first path segment)", nested.Project)
	}
	flat, ok := g.Node("flat.md")
	if !ok {
		t.Fatal("flat node missing")
	}
	if flat.Project != "" {
		t.Errorf("flat keyless note must be unscoped, got %q", flat.Project)
	}

	scoped, err := runCLI(t, "scan", "--format", "ndjson", "--project", "echo_mq", "--root", dir)
	if err != nil {
		t.Fatal(err)
	}
	if lines := ndjsonLines(scoped); len(lines) != 1 || !strings.Contains(lines[0], "echo_mq/nested.md") {
		t.Errorf("--project echo_mq must include exactly the nested note: %q", scoped)
	}
	unfiltered, err := runCLI(t, "scan", "--format", "ndjson", "--root", dir)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(unfiltered, "flat.md") {
		t.Errorf("unscoped note must appear in unfiltered output: %q", unfiltered)
	}
}

// G-5: status precedence — a valid declared status: IS the status (the sniff
// is skipped); an invalid value records a FrontmatterError and the sniff
// fallback governs; an absent key keeps the sniff byte-unchanged.
func TestStatusPrecedence(t *testing.T) {
	dir := t.TempDir()
	writeNote(t, dir, "declared-active.md", "---\nname: da\ndescription: pinned active\ntype: feedback\nstatus: active\n---\n\n(superseded — a body marker the sniff would catch)\n")
	writeNote(t, dir, "declared-superseded.md", "---\nname: ds\ndescription: declared dead\ntype: feedback\nstatus: superseded\n---\n\nclean body, no marker.\n")
	writeNote(t, dir, "keyless-sniff.md", "---\nname: ks\ndescription: legacy sniff regression\ntype: feedback\n---\n\n> superseded by another note.\n")
	writeNote(t, dir, "invalid-status.md", "---\nname: is\ndescription: typoed status value\ntype: feedback\nstatus: retired\n---\n\nclean body.\n")

	g, _, err := loadCorpus(dir)
	if err != nil {
		t.Fatal(err)
	}
	mustNode := func(path string) *graph.Node {
		t.Helper()
		n, ok := g.Node(path)
		if !ok {
			t.Fatalf("node %s missing", path)
		}
		return n
	}

	if n := mustNode("declared-active.md"); n.Status != graph.StatusActive {
		t.Errorf("declared active + sniff-positive body: status=%s want active (the declaration pins it)", n.Status)
	}
	if n := mustNode("declared-superseded.md"); n.Status != graph.StatusSuperseded {
		t.Errorf("declared superseded + clean body: status=%s want superseded", n.Status)
	}
	if n := mustNode("keyless-sniff.md"); n.Status != graph.StatusSuperseded {
		t.Errorf("keyless sniff-positive: status=%s want superseded (fallback regression)", n.Status)
	}
	inv := mustNode("invalid-status.md")
	if inv.FrontmatterError == "" || !strings.Contains(inv.FrontmatterError, "retired") {
		t.Errorf("invalid status must record a FrontmatterError naming the value, got %q", inv.FrontmatterError)
	}
	if inv.Status != graph.StatusActive {
		t.Errorf("invalid declaration + clean body: status=%s want active (the sniff fallback governs)", inv.Status)
	}
}
