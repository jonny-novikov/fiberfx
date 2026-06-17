package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveExplicit(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "custom.yaml")
	body := []byte(`deleted_paths:
  - apps/foo/**
removed_tools:
  - bad_tool
`)
	if err := os.WriteFile(path, body, 0o644); err != nil {
		t.Fatal(err)
	}
	cfg, src, err := Resolve(path, dir)
	if err != nil {
		t.Fatal(err)
	}
	if src != path {
		t.Errorf("src=%s", src)
	}
	if len(cfg.DeletedPaths) != 1 || cfg.DeletedPaths[0] != "apps/foo/**" {
		t.Errorf("deleted_paths=%v", cfg.DeletedPaths)
	}
	if len(cfg.RemovedTools) != 1 || cfg.RemovedTools[0] != "bad_tool" {
		t.Errorf("removed_tools=%v", cfg.RemovedTools)
	}
	if len(cfg.ContextWhitelistKeywords) == 0 {
		t.Error("expected default context whitelist when not provided")
	}
}

func TestResolveDirectoryPrimary(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "msh-memory.yaml")
	if err := os.WriteFile(path, []byte("deleted_paths: [apps/x/**]\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	cfg, src, err := Resolve("", dir)
	if err != nil {
		t.Fatal(err)
	}
	if src != path {
		t.Errorf("src=%s want %s", src, path)
	}
	if cfg.DeletedPaths[0] != "apps/x/**" {
		t.Errorf("deleted_paths=%v", cfg.DeletedPaths)
	}
}

func TestResolveDirectoryDotted(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, ".msh-memory.yaml")
	if err := os.WriteFile(path, []byte("removed_tools: [foo]\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	cfg, src, err := Resolve("", dir)
	if err != nil {
		t.Fatal(err)
	}
	if src != path {
		t.Errorf("src=%s", src)
	}
	if cfg.RemovedTools[0] != "foo" {
		t.Errorf("removed_tools=%v", cfg.RemovedTools)
	}
}

func TestResolveFallsBackToDefaults(t *testing.T) {
	dir := t.TempDir()
	cfg, src, err := Resolve("", dir)
	if err != nil {
		t.Fatal(err)
	}
	if src != "<defaults>" {
		t.Errorf("src=%s", src)
	}
	if len(cfg.DeletedPaths) == 0 {
		t.Error("defaults missing deleted_paths")
	}
}

func TestResolveMalformedYAML(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "msh-memory.yaml")
	if err := os.WriteFile(path, []byte("deleted_paths: [unterminated\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	_, _, err := Resolve("", dir)
	if err == nil {
		t.Fatal("expected malformed yaml error")
	}
}

func TestDefaultsHaveAllSections(t *testing.T) {
	d := Defaults()
	if len(d.DeletedPaths) == 0 {
		t.Error("missing deleted_paths defaults")
	}
	if len(d.RemovedTools) == 0 {
		t.Error("missing removed_tools defaults")
	}
	if len(d.ContextWhitelistKeywords) == 0 {
		t.Error("missing whitelist defaults")
	}
	if len(d.IgnoreOrphans) == 0 {
		t.Error("missing ignore_orphans defaults")
	}
	if d.Hugot.Endpoint == "" {
		t.Error("missing hugot endpoint default")
	}
	if d.Similarity.DefaultThreshold == 0 {
		t.Error("missing similarity threshold default")
	}
}
