package main

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

// TestServerRegistry guards the two aaw invariants that are gate-invisible but
// break the wire if violated: its flags MUST precede the `serve` word
// (flag.Parse stops at the first non-flag arg), and `-addr` MUST be the literal
// "localhost:8905" — aaw's strict wire-check compares the host string with no
// 127.0.0.1 normalization against .mcp.json, so "127.0.0.1:8905" would refuse to
// boot under -wire-check strict.
func TestServerRegistry(t *testing.T) {
	root := "/repo"
	byName := map[string]Server{}
	for _, s := range servers(root) {
		byName[s.Name] = s
	}

	aaw, ok := byName["aaw"]
	if !ok {
		t.Fatal("aaw missing from registry")
	}
	if got := aaw.ServeArgs[len(aaw.ServeArgs)-1]; got != "serve" {
		t.Errorf("aaw ServeArgs must end with the mode word \"serve\" (flags before mode); got %q", got)
	}
	if !slices.Contains(aaw.ServeArgs, "localhost:8905") {
		t.Errorf("aaw must bind the literal localhost:8905 (wire-check has no host normalization); args=%v", aaw.ServeArgs)
	}
	if slices.Contains(aaw.ServeArgs, "127.0.0.1:8905") {
		t.Errorf("aaw must NOT use 127.0.0.1 — the wire-check would refuse it; args=%v", aaw.ServeArgs)
	}
	if !slices.Contains(aaw.ServeArgs, root) {
		t.Errorf("aaw -workspace must be the repo root %q (where .mcp.json lives); args=%v", root, aaw.ServeArgs)
	}
	if aaw.LockPath == "" || !aaw.DualStack {
		t.Errorf("aaw must declare its instance LockPath and DualStack bind; got LockPath=%q DualStack=%v", aaw.LockPath, aaw.DualStack)
	}

	msh, ok := byName["msh"]
	if !ok {
		t.Fatal("msh missing from registry")
	}
	if msh.DualStack || msh.LockPath != "" {
		t.Errorf("msh has no flock and binds a single socket; got LockPath=%q DualStack=%v", msh.LockPath, msh.DualStack)
	}
	wantMshRoot := filepath.Join(root, "memory")
	if !slices.Contains(msh.ServeArgs, wantMshRoot) {
		t.Errorf("msh --root must be %q (the .msh-memory.json anchor); args=%v", wantMshRoot, msh.ServeArgs)
	}
}

func TestBindAddrs(t *testing.T) {
	reg := servers("/repo")
	for _, s := range reg {
		got := s.bindAddrs()
		if s.DualStack {
			if len(got) != 2 {
				t.Errorf("%s dual-stack must probe two families; got %v", s.Name, got)
			}
		} else if len(got) != 1 {
			t.Errorf("%s single-socket must probe one address; got %v", s.Name, got)
		}
	}
}

func TestStateWord(t *testing.T) {
	cases := []struct {
		live, listening bool
		want            string
	}{
		{true, true, "running"},
		{true, false, "starting"},
		{false, true, "foreign"},
		{false, false, "stopped"},
	}
	for _, c := range cases {
		if got := stateWord(c.live, c.listening); got != c.want {
			t.Errorf("stateWord(%v,%v)=%q want %q", c.live, c.listening, got, c.want)
		}
	}
}

func TestResolveRoot(t *testing.T) {
	// A directory that holds the repo markers resolves; a bare temp dir does not.
	repo := t.TempDir()
	for _, m := range []string{".mcp.json", "go/aaw", "go/msh"} {
		p := filepath.Join(repo, m)
		if filepath.Ext(p) == ".json" {
			if err := os.WriteFile(p, []byte("{}"), 0o644); err != nil {
				t.Fatal(err)
			}
		} else if err := os.MkdirAll(p, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	if got, err := resolveRoot(repo); err != nil || got != repo {
		t.Errorf("resolveRoot(explicit repo)=%q,%v want %q,nil", got, err, repo)
	}
	if _, err := resolveRoot(t.TempDir()); err == nil {
		t.Error("resolveRoot of a non-repo dir must error")
	}
	// Walk-up: a nested dir under the repo finds the root.
	nested := filepath.Join(repo, "go", "aaw", "cmd")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}
	if got := walkUpForRoot(nested); got != repo {
		t.Errorf("walkUpForRoot(%q)=%q want %q", nested, got, repo)
	}
}

func TestPastTenseAndFirstLine(t *testing.T) {
	if got := pastTense("restart"); got != "restarted" {
		t.Errorf("pastTense(restart)=%q", got)
	}
	if got := firstLine("line one\nline two"); got != "line one …" {
		t.Errorf("firstLine multi=%q", got)
	}
	if got := firstLine("solo"); got != "solo" {
		t.Errorf("firstLine solo=%q", got)
	}
}
