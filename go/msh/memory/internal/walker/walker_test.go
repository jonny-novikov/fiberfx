package walker

import (
	"os"
	"path/filepath"
	"testing"
)

func TestWalkMarkdownIgnoresDotDirs(t *testing.T) {
	dir := t.TempDir()
	mkfile(t, filepath.Join(dir, "a.md"), "x")
	mkfile(t, filepath.Join(dir, "b.txt"), "x")
	if err := os.Mkdir(filepath.Join(dir, ".hidden"), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	mkfile(t, filepath.Join(dir, ".hidden", "c.md"), "x")
	mkfile(t, filepath.Join(dir, "topics", "d.md"), "x")

	entries, err := WalkMarkdown(dir)
	if err != nil {
		t.Fatalf("walk: %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("expected 2 entries, got %d: %+v", len(entries), entries)
	}
	wantRel := []string{"a.md", "topics/d.md"}
	for i, e := range entries {
		if e.RelPath != wantRel[i] {
			t.Errorf("entry %d: rel=%q want %q", i, e.RelPath, wantRel[i])
		}
		if e.Size != 1 {
			t.Errorf("entry %d: size=%d want 1", i, e.Size)
		}
	}
}

func TestWalkMarkdownEmptyRootRejected(t *testing.T) {
	if _, err := WalkMarkdown(""); err == nil {
		t.Fatal("expected error for empty root")
	}
}

func TestWalkMarkdownMissingRootError(t *testing.T) {
	if _, err := WalkMarkdown(filepath.Join(t.TempDir(), "nope")); err == nil {
		t.Fatal("expected error for missing root")
	}
}

func TestWalkMarkdownCaseInsensitiveExt(t *testing.T) {
	dir := t.TempDir()
	mkfile(t, filepath.Join(dir, "A.MD"), "x")
	entries, err := WalkMarkdown(dir)
	if err != nil {
		t.Fatalf("walk: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(entries))
	}
}

func mkfile(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}
}
