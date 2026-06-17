package store

import (
	"encoding/json"
	"testing"
)

// MCP4-D4 / MCP4-INV4: the as-built model field is pinned record-only. The
// field landed in MCP2 (Agent.Model, applied in SpawnAgent/RegisterAgent);
// these are the running checks the deferral's formal close requires — the
// continuity rule and the additive shape, not a re-implementation.

func mcp4Scope(t *testing.T) (*Store, *Scope) {
	t.Helper()
	st, err := Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	sc, _, _, err := st.InitScope("m4", "tier", "ledger", 0)
	if err != nil {
		t.Fatal(err)
	}
	return st, sc
}

func mcp4Row(t *testing.T, sc *Scope, name string) *Agent {
	t.Helper()
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	a := r.Find(name)
	if a == nil {
		t.Fatalf("no registry row for %q", name)
	}
	return a
}

// Recorded at spawn/register; empty-keeps-stored on re-spawn/re-register
// (the CCL-id continuity rule applied to model); a non-empty value updates.
func TestModelRecordedAndContinuity(t *testing.T) {
	_, sc := mcp4Scope(t)

	cclID, err := sc.SpawnAgent("director", "director", "", "", "", "opus")
	if err != nil {
		t.Fatal(err)
	}
	if got := mcp4Row(t, sc, "director").Model; got != "opus" {
		t.Fatalf("model after spawn = %q, want opus", got)
	}

	// Re-spawn WITHOUT model: the stored value is kept, identity unchanged.
	reID, err := sc.SpawnAgent("director", "director", "", "", "", "")
	if err != nil {
		t.Fatal(err)
	}
	if reID != cclID {
		t.Fatalf("re-spawn moved the CCL-id %s -> %s", cclID, reID)
	}
	if got := mcp4Row(t, sc, "director").Model; got != "opus" {
		t.Fatalf("model after empty re-spawn = %q, want the stored opus", got)
	}

	// Re-register WITHOUT model: still kept.
	if _, _, err := sc.RegisterAgent("director", "director", "", ""); err != nil {
		t.Fatal(err)
	}
	if got := mcp4Row(t, sc, "director").Model; got != "opus" {
		t.Fatalf("model after empty re-register = %q, want the stored opus", got)
	}

	// A non-empty model on re-register updates the record.
	if _, _, err := sc.RegisterAgent("director", "director", "", "claude-opus-4-8"); err != nil {
		t.Fatal(err)
	}
	if got := mcp4Row(t, sc, "director").Model; got != "claude-opus-4-8" {
		t.Fatalf("model after re-register = %q, want claude-opus-4-8", got)
	}
	// And a non-empty model on re-spawn updates it too.
	if _, err := sc.SpawnAgent("director", "director", "", "", "", "opus"); err != nil {
		t.Fatal(err)
	}
	if got := mcp4Row(t, sc, "director").Model; got != "opus" {
		t.Fatalf("model after re-spawn = %q, want opus", got)
	}
}

// Additive against MCP3 shapes (MCP4-INV4): an MCP3-era row without the key
// decodes clean; an empty model marshals to NO key (omitempty); a client
// holding MCP3 shapes decodes a model-carrying row without error.
func TestModelAdditiveShape(t *testing.T) {
	// An MCP3-era registry row (no model key) stays valid.
	var legacy Agent
	if err := json.Unmarshal([]byte(`{"name":"venus","role":"architect","spawned":true,"registered":true}`), &legacy); err != nil {
		t.Fatal(err)
	}
	if legacy.Model != "" {
		t.Fatalf("legacy row decoded a phantom model %q", legacy.Model)
	}

	// An empty model emits no key — the wire shape only grows when recorded.
	b, err := json.Marshal(&Agent{Name: "venus", Role: "architect"})
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != "" && jsonHasKey(t, b, "model") {
		t.Fatalf("empty model marshaled a key: %s", b)
	}

	// A deferred-schema client holding the MCP3 row shape decodes a
	// model-carrying row without error (the unknown key is skipped).
	full, err := json.Marshal(&Agent{Name: "mars", Role: "implementor", Model: "opus"})
	if err != nil {
		t.Fatal(err)
	}
	if !jsonHasKey(t, full, "model") {
		t.Fatalf("recorded model emitted no key: %s", full)
	}
	var mcp3Shape struct {
		Name string `json:"name"`
		Role string `json:"role"`
	}
	if err := json.Unmarshal(full, &mcp3Shape); err != nil {
		t.Fatalf("an MCP3-shape client failed on the additive row: %v", err)
	}
	if mcp3Shape.Name != "mars" || mcp3Shape.Role != "implementor" {
		t.Fatalf("MCP3-shape decode drifted: %+v", mcp3Shape)
	}
}

func jsonHasKey(t *testing.T, b []byte, key string) bool {
	t.Helper()
	m := map[string]any{}
	if err := json.Unmarshal(b, &m); err != nil {
		t.Fatal(err)
	}
	_, ok := m[key]
	return ok
}
