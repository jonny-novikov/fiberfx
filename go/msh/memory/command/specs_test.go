package command

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSpecsLinksExplicitPath(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "a.md"), []byte("# A\n\n[dead](missing.md)\n"), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}

	// An explicit existing directory path is used as-is (no area-name resolution).
	out, err := SpecsLinks(dir, "", "ndjson", "info")
	if err != nil {
		t.Fatalf("SpecsLinks: %v", err)
	}
	if !strings.Contains(out, "DEAD-TARGET") {
		t.Errorf("expected a DEAD-TARGET finding, got:\n%s", out)
	}
	if n := strings.Count(strings.TrimSpace(out), "\n") + 1; n != 1 {
		t.Errorf("expected exactly 1 ndjson finding, got %d:\n%s", n, out)
	}
}

func TestSpecsLinksPrettyNoFindings(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "ok.md"), []byte("# OK\n\nno links here\n"), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}
	out, err := SpecsLinks(dir, "", "pretty", "warn")
	if err != nil {
		t.Fatalf("SpecsLinks: %v", err)
	}
	if !strings.Contains(out, "no findings") {
		t.Errorf("expected 'no findings', got: %q", out)
	}
}

func TestSpecsLinksUnknownArea(t *testing.T) {
	// A name that resolves to <repo>/docs/<name> which does not exist must error.
	if _, err := SpecsLinks("zzz_definitely_not_an_area", "docs", "ndjson", "warn"); err == nil {
		t.Errorf("expected an error for an unknown area name")
	}
}

func TestSpecsLinksInvalidFormat(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "a.md"), []byte("# A\n"), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}
	if _, err := SpecsLinks(dir, "", "xml", "warn"); err == nil {
		t.Errorf("expected an error for an invalid format")
	}
}
