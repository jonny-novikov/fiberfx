package command

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadMemoryConfigWalkUp(t *testing.T) {
	root := t.TempDir()
	sub := filepath.Join(root, "a", "b")
	if err := os.MkdirAll(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	doc := `{"root":"mem","project":{"name":"echo_mq","code":"emq","roadmap":"emq.roadmap.md","state":{"status":"in_progress","current_rung":"emq.4.1"}}}`
	if err := os.WriteFile(filepath.Join(root, ".msh-memory.json"), []byte(doc), 0o644); err != nil {
		t.Fatal(err)
	}

	mc, err := LoadMemoryConfig(sub)
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if mc == nil {
		t.Fatal("expected config, got nil")
	}
	if mc.Project.Name != "echo_mq" || mc.Project.Code != "emq" {
		t.Errorf("project = %+v", mc.Project)
	}
	if mc.Project.State.CurrentRung != "emq.4.1" || mc.Project.State.Status != "in_progress" {
		t.Errorf("state = %+v", mc.Project.State)
	}
	// a relative root resolves against the .msh-memory.json directory
	if want := filepath.Join(root, "mem"); mc.Root != want {
		t.Errorf("root = %q want %q", mc.Root, want)
	}
}

func TestLoadMemoryConfigAbsent(t *testing.T) {
	mc, err := LoadMemoryConfig(t.TempDir())
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if mc != nil {
		t.Errorf("expected nil for absent config, got %+v", mc)
	}
}

func TestLoadMemoryConfigDocsRoot(t *testing.T) {
	t.Run("relative resolves against the anchor dir", func(t *testing.T) {
		dir := t.TempDir()
		doc := `{"docs_root":"docs/msh"}`
		if err := os.WriteFile(filepath.Join(dir, ".msh-memory.json"), []byte(doc), 0o644); err != nil {
			t.Fatal(err)
		}
		mc, err := LoadMemoryConfig(dir)
		if err != nil {
			t.Fatalf("load: %v", err)
		}
		if want := filepath.Join(dir, "docs", "msh"); mc.DocsRoot != want {
			t.Errorf("docs_root = %q want %q", mc.DocsRoot, want)
		}
	})
	t.Run("absolute passes through", func(t *testing.T) {
		dir := t.TempDir()
		abs := filepath.Join(dir, "docs")
		doc := fmt.Sprintf(`{"docs_root":%q}`, abs)
		if err := os.WriteFile(filepath.Join(dir, ".msh-memory.json"), []byte(doc), 0o644); err != nil {
			t.Fatal(err)
		}
		mc, err := LoadMemoryConfig(dir)
		if err != nil {
			t.Fatalf("load: %v", err)
		}
		if mc.DocsRoot != abs {
			t.Errorf("docs_root = %q want %q", mc.DocsRoot, abs)
		}
	})
}

func TestRenderProjectDocsRoot(t *testing.T) {
	// present: the docs: line in text, the docs_root key in json
	mc := &MemoryConfig{Root: "/m", DocsRoot: "/d/docs", Source: "/x/.msh-memory.json"}
	text, err := renderProject(mc, "text")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(text, "docs:    /d/docs") {
		t.Errorf("text output missing the docs line:\n%s", text)
	}
	js, err := renderProject(mc, "json")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(js, `"docs_root": "/d/docs"`) {
		t.Errorf("json output missing docs_root:\n%s", js)
	}

	// absent: a v1.0 anchor degrades soft — dash in text, key omitted in json
	v10 := &MemoryConfig{Root: "/m", Source: "/x/.msh-memory.json"}
	text, err = renderProject(v10, "text")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(text, "docs:    -") {
		t.Errorf("text output missing the docs dash:\n%s", text)
	}
	js, err = renderProject(v10, "json")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(js, "docs_root") {
		t.Errorf("json must omit docs_root when unset:\n%s", js)
	}
}

func TestRenderProject(t *testing.T) {
	mc := &MemoryConfig{
		Root:   "/m",
		Source: "/x/.msh-memory.json",
		Project: Project{
			Name: "echo_mq", Code: "emq", Roadmap: "emq.roadmap.md",
			State: ProjectState{Status: "in_progress", CurrentRung: "emq.4.1"},
		},
	}
	text, err := renderProject(mc, "text")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"echo_mq", "emq", "emq.4.1", "in_progress", "emq.roadmap.md", "/m"} {
		if !strings.Contains(text, want) {
			t.Errorf("text output missing %q:\n%s", want, text)
		}
	}
	js, err := renderProject(mc, "json")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(js, `"current_rung": "emq.4.1"`) {
		t.Errorf("json output missing current_rung:\n%s", js)
	}
}
