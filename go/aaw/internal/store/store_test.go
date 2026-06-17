package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

func openTempStore(t *testing.T) *Store {
	t.Helper()
	st, err := Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	return st
}

func initScope(t *testing.T, st *Store, name string) *Scope {
	t.Helper()
	sc, _, _, err := st.InitScope(name, "test-op", "ledger-"+name, 0)
	if err != nil {
		t.Fatal(err)
	}
	return sc
}

// MCP1-INV1 + MCP1-INV5: N parallel spawns lose no row and mint no duplicate
// CCL-id; concurrent registry readers always observe a whole, parseable file
// (MCP1-INV2 over the registry).
func TestSpawnConcurrencyProperty(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "alpha")
	dirID, err := sc.SpawnAgent("director", "director", "director", "", "", "")
	if err != nil {
		t.Fatal(err)
	}

	const N = 32
	var wg sync.WaitGroup
	ids := make([]string, N)
	errs := make([]error, N)
	stop := make(chan struct{})
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case <-stop:
					return
				default:
				}
				if _, err := sc.LoadRegistry(); err != nil {
					t.Errorf("torn registry read: %v", err)
					return
				}
			}
		}()
	}
	var spawns sync.WaitGroup
	for i := 0; i < N; i++ {
		spawns.Add(1)
		go func(i int) {
			defer spawns.Done()
			ids[i], errs[i] = sc.SpawnAgent(fmt.Sprintf("peer-%d", i), "implementor", "", dirID, "", "")
		}(i)
	}
	spawns.Wait()
	close(stop)
	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Fatalf("spawn %d: %v", i, err)
		}
	}
	seen := map[string]bool{dirID: true}
	for i, id := range ids {
		if id == "" {
			t.Fatalf("spawn %d minted no id", i)
		}
		if seen[id] {
			t.Fatalf("duplicate CCL-id minted: %s", id)
		}
		seen[id] = true
	}
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := len(r.Agents), N+1; got != want {
		t.Fatalf("registry rows = %d, want %d (a row was lost)", got, want)
	}
	if got, want := r.NextCCL, N+2; got != want {
		t.Fatalf("persisted next_ccl = %d, want %d", got, want)
	}
}

// MCP1-INV1: scopes are independent serialization domains — two scopes spawn
// in parallel without interference.
func TestSpawnCrossScopeParallel(t *testing.T) {
	st := openTempStore(t)
	scopes := []*Scope{initScope(t, st, "alpha"), initScope(t, st, "beta")}
	const N = 16
	var wg sync.WaitGroup
	for _, sc := range scopes {
		dirID, err := sc.SpawnAgent("director", "director", "", "", "", "")
		if err != nil {
			t.Fatal(err)
		}
		for i := 0; i < N; i++ {
			wg.Add(1)
			go func(sc *Scope, i int) {
				defer wg.Done()
				if _, err := sc.SpawnAgent(fmt.Sprintf("peer-%d", i), "implementor", "", dirID, "", ""); err != nil {
					t.Errorf("scope %s spawn %d: %v", sc.Name, i, err)
				}
			}(sc, i)
		}
	}
	wg.Wait()
	for _, sc := range scopes {
		r, err := sc.LoadRegistry()
		if err != nil {
			t.Fatal(err)
		}
		if got, want := len(r.Agents), N+1; got != want {
			t.Fatalf("scope %s rows = %d, want %d", sc.Name, got, want)
		}
	}
}

// MCP1-INV5: a re-spawn of an existing name keeps its CCL-id and refreshes
// spawned_at; a new name still mints a fresh id past the counter.
func TestRespawnKeepsCCLID(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "alpha")
	dirID, err := sc.SpawnAgent("director", "director", "", "", "", "")
	if err != nil {
		t.Fatal(err)
	}
	id1, err := sc.SpawnAgent("Venus", "architect", "architect", dirID, "", "")
	if err != nil {
		t.Fatal(err)
	}
	const sentinel = "2000-01-01T00:00:00Z"
	if err := sc.updateRegistry(func(r *Registry) error {
		r.Find("Venus").SpawnedAt = sentinel
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	id2, err := sc.SpawnAgent("Venus", "architect", "architect", dirID, "", "")
	if err != nil {
		t.Fatal(err)
	}
	if id2 != id1 {
		t.Fatalf("re-spawn re-minted: %s != %s", id2, id1)
	}
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if got := r.Find("Venus").SpawnedAt; got == sentinel {
		t.Fatal("re-spawn did not refresh spawned_at")
	}
	id3, err := sc.SpawnAgent("Mars", "implementor", "", dirID, "", "")
	if err != nil {
		t.Fatal(err)
	}
	if id3 == id1 || id3 == dirID {
		t.Fatalf("new name collided: %s", id3)
	}
}

// MCP1-INV5 over a legacy registry (the live defect shape): rows carrying a
// duplicate suffix and no next_ccl seed the counter at max+1, so no existing
// id is ever re-minted.
func TestMintSeedsFromLegacyRows(t *testing.T) {
	r := &Registry{Scope: "alpha", Agents: []*Agent{
		{Name: "a", CCLID: "ccl-alpha-3"},
		{Name: "b", CCLID: "ccl-alpha-6"},
		{Name: "c", CCLID: "ccl-alpha-6"}, // the historical duplicate, preserved evidence
		{Name: "d", CCLID: "ccl-other-9"}, // a foreign id is not part of this scope's space
	}}
	if got, want := r.mintCCL("alpha"), "ccl-alpha-7"; got != want {
		t.Fatalf("legacy seed minted %s, want %s", got, want)
	}
	if got, want := r.NextCCL, 8; got != want {
		t.Fatalf("next_ccl after legacy seed = %d, want %d", got, want)
	}
}

// MCP1-INV3: the index is files-truth — an out-of-band row deletion stays
// deleted, a hand-added row is honored with no restart, and a server-side
// mutation merges single-row without resurrecting anything.
func TestIndexReadThroughOutOfBand(t *testing.T) {
	st := openTempStore(t)
	initScope(t, st, "alpha")
	if _, err := st.GetScope("alpha"); err != nil {
		t.Fatal(err)
	}

	// The Operator's hand: drop alpha, add beta, directly on disk.
	beta := &Scope{Name: "beta", Operator: "hand", Workspace: st.Workspace, LedgerDir: st.Workspace, CreatedAt: Now()}
	b, err := json.MarshalIndent(map[string]*Scope{"beta": beta}, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(st.indexPath(), b, 0o644); err != nil {
		t.Fatal(err)
	}

	if _, err := st.GetScope("alpha"); err == nil || !strings.Contains(err.Error(), "not initialized") {
		t.Fatalf("deleted row resurrected: err=%v", err)
	}
	if _, err := st.GetScope("beta"); err != nil {
		t.Fatalf("hand-added row not honored: %v", err)
	}

	// A server-side mutation merges its single row only.
	initScope(t, st, "gamma")
	raw, err := os.ReadFile(st.indexPath())
	if err != nil {
		t.Fatal(err)
	}
	idx := map[string]*Scope{}
	if err := json.Unmarshal(raw, &idx); err != nil {
		t.Fatal(err)
	}
	if _, ok := idx["alpha"]; ok {
		t.Fatal("server write resurrected the deleted row")
	}
	if _, ok := idx["beta"]; !ok {
		t.Fatal("server write clobbered the out-of-band row")
	}
	if _, ok := idx["gamma"]; !ok {
		t.Fatal("server write lost its own row")
	}
}

// A corrupt index in the read-through era refuses TYPED per call — no panic,
// no clobber — and a restored file heals on the very next call, no restart
// (the files-are-truth recovery path of MCP1-D4).
func TestIndexCorruptMidServe(t *testing.T) {
	st := openTempStore(t)
	initScope(t, st, "alpha")
	if err := os.WriteFile(st.indexPath(), []byte("{not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := st.GetScope("alpha"); err == nil || !strings.Contains(err.Error(), "corrupt scope index") {
		t.Fatalf("corrupt index not refused with the typed error: %v", err)
	}
	// ScopeNames swallows the read error into an empty list (probe stays a
	// liveness surface while scope-bound calls refuse loudly) — pinned.
	if names := st.ScopeNames(); names != nil {
		t.Fatalf("ScopeNames during corruption = %v, want nil", names)
	}
	// A mutation must refuse rather than treat corrupt-as-empty and clobber
	// the Operator's recoverable file.
	if _, _, _, err := st.InitScope("beta", "op", "ledger-beta", 0); err == nil {
		t.Fatal("InitScope during corruption did not refuse")
	}
	raw, err := os.ReadFile(st.indexPath())
	if err != nil {
		t.Fatal(err)
	}
	if string(raw) != "{not json" {
		t.Fatalf("the corrupt file was clobbered: %q", raw)
	}
	good := map[string]*Scope{"alpha": {Name: "alpha", Operator: "test-op", Workspace: st.Workspace, LedgerDir: filepath.Join(st.Workspace, "ledger-alpha"), CreatedAt: Now()}}
	b, err := json.MarshalIndent(good, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(st.indexPath(), b, 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := st.GetScope("alpha"); err != nil {
		t.Fatalf("restored index not honored on the next call: %v", err)
	}
}

// MCP1-INV5 over the FULL live defect shape at MCP1 entry (the aaw-mcp
// registry, A-7 evidence): a duplicate ccl-6 across two rows, one of them
// spawned-but-never-registered, no persisted counter. Re-spawn keeps the
// duplicate id (preserved evidence, never repaired), the first true mint
// seeds past the max suffix, and registration flips the flag with no id
// churn.
func TestLegacyRegistryLiveShape(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "live")
	legacy := &Registry{Scope: "live", Agents: []*Agent{
		{Name: "director", Role: "director", CCLID: "ccl-live-1", Spawned: true, Registered: true},
		{Name: "Venus-1", Role: "architect", CCLID: "ccl-live-2", Spawned: true, Registered: true},
		{Name: "Venus-2", Role: "architect", CCLID: "ccl-live-3", Spawned: true, Registered: true},
		{Name: "Apollo", Role: "evaluator", CCLID: "ccl-live-4", Spawned: true, Registered: true},
		{Name: "Venus-3", Role: "architect", CCLID: "ccl-live-6", Spawned: true, Registered: true},
		{Name: "SpecAuthor", Role: "architect", CCLID: "ccl-live-6", Spawned: true, Registered: false},
	}}
	b, err := json.MarshalIndent(legacy, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(sc.RegistryPath(), b, 0o644); err != nil { // the hand-rolled pre-counter file
		t.Fatal(err)
	}

	id, err := sc.SpawnAgent("SpecAuthor", "architect", "architect", "ccl-live-1", "", "")
	if err != nil {
		t.Fatal(err)
	}
	if id != "ccl-live-6" {
		t.Fatalf("re-spawn of the legacy row re-minted: %s", id)
	}
	id2, err := sc.SpawnAgent("Mars", "implementor", "", "ccl-live-1", "", "")
	if err != nil {
		t.Fatal(err)
	}
	if id2 != "ccl-live-7" {
		t.Fatalf("first mint over the legacy shape = %s, want ccl-live-7 (max suffix + 1)", id2)
	}
	if _, _, err := sc.RegisterAgent("SpecAuthor", "architect", "", ""); err != nil {
		t.Fatal(err)
	}
	r, err := sc.LoadRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := len(r.Agents), 7; got != want {
		t.Fatalf("rows = %d, want %d", got, want)
	}
	if got, want := r.NextCCL, 8; got != want {
		t.Fatalf("persisted next_ccl = %d, want %d", got, want)
	}
	a := r.Find("SpecAuthor")
	if !a.Registered || a.CCLID != "ccl-live-6" {
		t.Fatalf("registration churned the legacy row: registered=%v ccl=%s", a.Registered, a.CCLID)
	}
	if r.Find("Venus-3").CCLID != "ccl-live-6" {
		t.Fatal("the duplicate evidence row was repaired — it must be preserved")
	}
}

// The uniform refusals around the registry writers survive the rung: an
// unknown parent and a non-director without a parent refuse with the
// established texts; an unregistered recipient refuses agent_send's record.
func TestRegistryRefusalsUnchanged(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "alpha")
	if _, err := sc.SpawnAgent("peer", "implementor", "", "", "", ""); err == nil || !strings.Contains(err.Error(), "requires parent_id") {
		t.Fatalf("non-director without parent: %v", err)
	}
	if _, err := sc.SpawnAgent("peer", "implementor", "", "ccl-alpha-99", "", ""); err == nil || !strings.Contains(err.Error(), "not found in scope") {
		t.Fatalf("unknown parent: %v", err)
	}
	if err := sc.RecordMessage("ghost", "hello"); err == nil || !strings.Contains(err.Error(), "not registered") {
		t.Fatalf("unregistered recipient: %v", err)
	}
	if _, err := sc.SpawnAgent("director", "director", "", "", "", ""); err != nil {
		t.Fatal(err)
	}
	if _, _, err := sc.RegisterAgent("director", "director", "", ""); err != nil {
		t.Fatal(err)
	}
	if err := sc.RecordMessage("director", "hello"); err != nil {
		t.Fatalf("registered recipient refused: %v", err)
	}
}
