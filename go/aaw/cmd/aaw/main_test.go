package main

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/aaw/internal/gates"
	"github.com/jonny-novikov/aaw/internal/signals"
	"github.com/jonny-novikov/aaw/internal/store"
)

// The MCP3-D5 in-process round-trip tier, over mcp.NewInMemoryTransports
// against the real tool registration (newServer): every tool exercised, every
// in-band domain gate refused at least once with its exact §9 code asserted,
// the SDK protocol plane contrasted (an unknown tool is never an aaw: code),
// the additive init split and unknown_prefixes surfaces read back, and the
// MCP3-D8 containment pair proven at the doors (PATH_ESCAPE creates nothing)
// and on a legacy out-of-tree row (one deduplicated CONTAINMENT advisory,
// never a refusal). The tier homes beside newServer because the registration
// is package-main; the store-level halves live in internal/store/mcp3_test.go.
func TestMCP3InProcessRoundTrip(t *testing.T) {
	ctx := context.Background()
	ws := t.TempDir()
	st, err := store.Open(ws)
	if err != nil {
		t.Fatal(err)
	}
	server := newServer(st, nil, nil, nil)
	serverTransport, clientTransport := mcp.NewInMemoryTransports()
	ss, err := server.Connect(ctx, serverTransport, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ss.Close(ctx) })
	client := mcp.NewClient(&mcp.Implementation{Name: "mcp3-inproc", Version: "test"}, nil)
	cs, err := client.Connect(ctx, clientTransport, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cs.Close(ctx) })

	textOf := func(res *mcp.CallToolResult) string {
		s := ""
		for _, c := range res.Content {
			if tc, ok := c.(*mcp.TextContent); ok {
				s += tc.Text
			}
		}
		return s
	}
	call := func(name string, args map[string]any) *mcp.CallToolResult {
		t.Helper()
		res, err := cs.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil {
			t.Fatalf("%s transport error: %v", name, err)
		}
		return res
	}
	ok := func(name string, args map[string]any) map[string]any {
		t.Helper()
		res := call(name, args)
		if res.IsError {
			t.Fatalf("%s refused: %s", name, textOf(res))
		}
		if res.StructuredContent == nil {
			return nil
		}
		b, err := json.Marshal(res.StructuredContent)
		if err != nil {
			t.Fatal(err)
		}
		out := map[string]any{}
		if err := json.Unmarshal(b, &out); err != nil {
			t.Fatal(err)
		}
		return out
	}
	// refuse asserts the EXACT closed-set code, not IsError alone
	// (MCP3-INV4): the code is the contract, the detail is prose.
	refuse := func(name string, args map[string]any, code string) {
		t.Helper()
		res := call(name, args)
		if !res.IsError {
			t.Fatalf("%s succeeded, want the %s refusal", name, code)
		}
		if text := textOf(res); !strings.HasPrefix(text, "aaw: "+code+": ") {
			t.Fatalf("%s refused with %q, want code %s", name, text, code)
		}
	}
	countLines := func(path, needle string) int {
		t.Helper()
		b, err := os.ReadFile(path)
		if os.IsNotExist(err) {
			return 0
		}
		if err != nil {
			t.Fatal(err)
		}
		n := 0
		for _, l := range strings.Split(string(b), "\n") {
			if strings.Contains(l, needle) {
				n++
			}
		}
		return n
	}

	// The tool surface stays 18 (MCP3 ships contracts, not capability).
	tools, err := cs.ListTools(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := len(tools.Tools), 18; got != want {
		t.Fatalf("tool surface = %d, want %d", got, want)
	}

	// --- the init gates ---
	refuse("aaw_init", map[string]any{"scope": "Bad.Slug", "ledger_dir": "x"}, gates.SLUG_INVALID)
	refuse("aaw_init", map[string]any{"scope": "fresh"}, gates.LEDGER_DIR_REQUIRED)
	refuse("aaw_init", map[string]any{"scope": "esc", "ledger_dir": "../esc-ledger"}, gates.PATH_ESCAPE)
	refuse("aaw_status", map[string]any{"scope": "esc"}, gates.NOT_INITIALIZED) // the refused init created nothing

	initOut := ok("aaw_init", map[string]any{"scope": "main", "operator": "tier", "ledger_dir": "ledger"})
	if initOut["created"] != true || initOut["scope_created"] != true || initOut["ledger_created"] != true {
		t.Fatalf("first init flags: %v, want created=scope_created=ledger_created=true", initOut)
	}
	reOut := ok("aaw_init", map[string]any{"scope": "main"})
	if reOut["created"] != false || reOut["scope_created"] != false || reOut["ledger_created"] != false {
		t.Fatalf("re-init flags: %v, want all false (created aliases scope_created)", reOut)
	}
	ledgerPath, _ := initOut["ledger_path"].(string)
	if ledgerPath == "" {
		t.Fatalf("init returned no ledger_path: %v", initOut)
	}
	refuse("aaw_init", map[string]any{"scope": "main", "ledger_dir": "elsewhere"}, gates.LEDGER_DIR_CONFLICT)

	// --- the registry gates ---
	// An ABSENT required property fails at the SDK's schema-validation plane;
	// the domain ARG_MISSING covers the as-built empty-parameter checks, so
	// the gates are exercised with explicit empty values.
	refuse("aaw_spawn", map[string]any{"scope": "main", "role": "director", "name": ""}, gates.ARG_MISSING) // name empty (the handler door)
	dirOut := ok("aaw_spawn", map[string]any{"scope": "main", "role": "director", "name": "director"})
	dirID, _ := dirOut["ccl_id"].(string)
	if dirID == "" {
		t.Fatal("spawn minted no ccl_id")
	}
	refuse("aaw_spawn", map[string]any{"scope": "main", "role": "architect", "name": "Venus", "parent_id": dirID, "deliverable": "../outside.md"}, gates.PATH_ESCAPE)
	refuse("aaw_spawn", map[string]any{"scope": "main", "role": "implementor", "name": "Mars"}, gates.ARG_MISSING) // non-director without parent_id (store.go)
	refuse("aaw_spawn", map[string]any{"scope": "main", "role": "implementor", "name": "Mars", "parent_id": "ccl-main-99"}, gates.PARENT_NOT_FOUND)
	ok("agent_register", map[string]any{"scope": "main", "name": "director", "role": "director"})
	refuse("agent_register", map[string]any{"scope": "main", "name": "ghost", "role": ""}, gates.ARG_MISSING) // role empty
	refuse("agent_heartbeat", map[string]any{"scope": "main", "name": ""}, gates.ARG_MISSING)
	refuse("agent_heartbeat", map[string]any{"scope": "main", "name": "nobody"}, gates.AGENT_UNKNOWN)
	ok("agent_heartbeat", map[string]any{"scope": "main", "name": "director", "quiet_for_minutes": 5})
	refuse("agent_send", map[string]any{"scope": "main", "to": "ghost", "body": "hello"}, gates.NOT_REGISTERED)
	ok("agent_send", map[string]any{"scope": "main", "to": "director", "body": "hello"})
	// The refused spawns created nothing: the registry holds the director only.
	if st := ok("aaw_status", map[string]any{"scope": "main"}); len(st["agents"].([]any)) != 1 {
		t.Fatalf("refused spawns left rows behind: %v", st["agents"])
	}

	// --- the ledger gates, then every writer exercised once ---
	refuse("tool_x_trace", map[string]any{"task_id": "", "slug": "", "body": ""}, gates.ARG_MISSING) // the cardinal rule
	refuse("tool_x_trace", map[string]any{"task_id": "main", "slug": "Bad.Slug", "body": "T-0 — bad slug"}, gates.SLUG_INVALID)
	refuse("tool_x_trace", map[string]any{"task_id": "ghostly", "slug": "ghostly", "body": "T-0 — no scope"}, gates.NOT_INITIALIZED)
	refuse("tool_x_complete", map[string]any{"task_id": "main", "slug": "main", "body": "Z-0 — premature"}, gates.GATE_Z_REQUIRES_D)
	for _, w := range []struct{ tool, body string }{
		{"tool_x_trace", "T-0 — tier trace"},
		{"tool_x_analyze", "A-0 — tier analysis"},
		{"tool_x_alternative", "V-0 — tier alternative"},
		{"tool_x_decision", "D-0 — tier decision"},
		{"tool_x_learning", "L-0 — tier learning"},
		{"tool_x_nxm_synthesize", "S-0 — tier synthesis"},
		{"tool_x_consensus", "C-0 — tier consensus"},
		{"tool_x_escalation", "E-0 — tier escalation"},
		{"tool_x_progress", "P-0 — tier progress"},
		{"tool_x_complete", "Z-0 — tier close"},
		{"tool_x_report", "Y-0 — tier report"},
	} {
		ok(w.tool, map[string]any{"task_id": "main", "slug": "main", "body": w.body + "\n\ntier body"})
	}
	ok("probe", map[string]any{})

	// --- unknown_prefixes: a hand ### ADR-3 is reported, never gating ---
	f, err := os.OpenFile(ledgerPath, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := f.WriteString("\n### ADR-3 — a hand record\n\nhand-written history\n"); err != nil {
		t.Fatal(err)
	}
	f.Close()
	stOut := ok("aaw_status", map[string]any{"scope": "main"})
	unknown, _ := stOut["unknown_prefixes"].([]any)
	if len(unknown) != 1 || unknown[0] != "ADR" {
		t.Fatalf("unknown_prefixes = %v, want [ADR]", stOut["unknown_prefixes"])
	}
	if stOut["parse_ok"] != true {
		t.Fatalf("an unknown prefix degraded parse health: %v", stOut)
	}
	ok("tool_x_trace", map[string]any{"task_id": "main", "slug": "main", "body": "T-0 — post-ADR append\n\nstill appends"})

	// --- the SDK contrast (MCP3-INV5): an unknown tool stays a protocol
	// error, never an aaw: domain code ---
	if _, err := cs.CallTool(ctx, &mcp.CallToolParams{Name: "no_such_tool", Arguments: map[string]any{}}); err == nil {
		t.Fatal("unknown tool did not fail at the protocol plane")
	} else if strings.Contains(err.Error(), "aaw: ") {
		t.Fatalf("the protocol plane leaked a domain code: %v", err)
	}

	// --- the MCP3-D8 rider: a legacy out-of-tree row is honored with one
	// deduplicated CONTAINMENT advisory, never a refusal ---
	legacyDir := t.TempDir() // a sibling of ws — outside the workspace root
	idxPath := filepath.Join(ws, ".aaw", "scopes.json")
	raw, err := os.ReadFile(idxPath)
	if err != nil {
		t.Fatal(err)
	}
	idx := map[string]*store.Scope{}
	if err := json.Unmarshal(raw, &idx); err != nil {
		t.Fatal(err)
	}
	idx["legacy"] = &store.Scope{Name: "legacy", Operator: "hand", Workspace: ws, LedgerDir: legacyDir, CreatedAt: store.Now()}
	merged, err := json.MarshalIndent(idx, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(idxPath, merged, 0o644); err != nil {
		t.Fatal(err)
	}
	auditLog := filepath.Join(ws, ".claude", "audit.log")
	ok("tool_x_trace", map[string]any{"task_id": "legacy", "slug": "legacy", "body": "T-0 — legacy write\n\nproceeds with an advisory"})
	if n := countLines(auditLog, signals.CodeContainment); n != 1 {
		t.Fatalf("CONTAINMENT lines after the first legacy write = %d, want 1", n)
	}
	ok("tool_x_decision", map[string]any{"task_id": "legacy", "slug": "legacy", "body": "D-0 — legacy decision\n\nstill proceeds"})
	ok("aaw_status", map[string]any{"scope": "legacy"}) // reads carry no advisory and no refusal
	if n := countLines(auditLog, signals.CodeContainment); n != 1 {
		t.Fatalf("CONTAINMENT lines after the second legacy write = %d, want 1 (dedup: one per scope/code/window)", n)
	}
	// The in-root scope's writes never emit the advisory.
	if n := countLines(auditLog, "scope=main"); n != 0 {
		t.Fatalf("the contained scope emitted %d advisory lines, want 0", n)
	}

	// --- CORRUPT_STATE last: the clobbered index refuses typed on the next
	// call (files are truth; no restart, no overwrite) ---
	if err := os.WriteFile(idxPath, []byte("{not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	refuse("aaw_status", map[string]any{"scope": "main"}, gates.CORRUPT_STATE)
}
