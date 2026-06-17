package store

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/mcp-go/v2/mcp"
)

// wireStatus mirrors the gate-console payload the test asserts on.
type wireStatus struct {
	Gates struct {
		ZEligible bool `json:"z_eligible"`
		DCount    int  `json:"d_count"`
		ZCount    int  `json:"z_count"`
	} `json:"gates"`
	Liveness []struct {
		Name          string `json:"name"`
		Role          string `json:"role"`
		Verdict       string `json:"verdict"`
		WinningSource string `json:"winning_source"`
	} `json:"liveness"`
	Signals []struct {
		Code string `json:"code"`
		At   string `json:"at"`
		Msg  string `json:"msg"`
	} `json:"signals"`
	Archived     bool           `json:"archived"`
	WireContract string         `json:"wire_contract"`
	ParseOK      bool           `json:"parse_ok"`
	EntryCount   int            `json:"entry_count"`
	Tallies      map[string]int `json:"tallies"`
}

func (s *wireStatus) row(name string) (verdict, source string) {
	for _, r := range s.Liveness {
		if r.Name == name {
			return r.Verdict, r.WinningSource
		}
	}
	return "", ""
}

func (s *wireStatus) signal(code string) bool {
	for _, sg := range s.Signals {
		if sg.Code == code {
			return true
		}
	}
	return false
}

func countLines(t *testing.T, path, needle string) int {
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

// The MCP2 evidence plane over the real wire, against a hermetic server
// process and workspace: the 18-tool surface, actor attribution (registered,
// unregistered-advisory), heartbeat with the 240-minute cap, the three-source
// liveness verdicts, the gate console (MCP2-INV5: one call, no greps), the
// R-4 degraded run emitting nothing (MCP2-INV4 / W-1), two-clause V-SOLO-1
// firing with dedup, and FAKE-N re-routed to .claude/audit.log — every signal
// advisory, no call refused (MCP2-INV3).
func TestMCP2WireGateConsole(t *testing.T) {
	bin := filepath.Join(t.TempDir(), "aaw-mcp2-under-test")
	moduleRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	build := exec.Command("go", "build", "-o", bin, "./cmd/aaw")
	build.Dir = moduleRoot
	build.Env = append(os.Environ(), "GOWORK=off")
	if out, err := build.CombinedOutput(); err != nil {
		t.Fatalf("building the server under test: %v\n%s", err, out)
	}

	ws := t.TempDir()
	port := freePort(t)
	srv := exec.Command(bin, "-addr", "127.0.0.1:"+port, "-workspace", ws, "serve")
	if err := srv.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		srv.Process.Kill()
		srv.Wait()
	})
	waitTCP(t, "127.0.0.1:"+port)

	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "mcp2-wire-test", Version: "test"}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: "http://127.0.0.1:" + port + "/"}, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer session.Close(ctx)

	call := func(name string, args map[string]any, wantErr bool) map[string]any {
		t.Helper()
		res, err := session.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil {
			t.Fatalf("%s transport error: %v", name, err)
		}
		if res.IsError != wantErr {
			detail := ""
			for _, c := range res.Content {
				if tc, ok := c.(*mcp.TextContent); ok {
					detail += tc.Text
				}
			}
			t.Fatalf("%s IsError=%v, want %v (%s)", name, res.IsError, wantErr, detail)
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
	getStatus := func(scope string) *wireStatus {
		t.Helper()
		res, err := session.CallTool(ctx, &mcp.CallToolParams{Name: "aaw_status", Arguments: map[string]any{"scope": scope}})
		if err != nil || res.IsError {
			t.Fatalf("aaw_status: err=%v isError=%v", err, res != nil && res.IsError)
		}
		b, err := json.Marshal(res.StructuredContent)
		if err != nil {
			t.Fatal(err)
		}
		st := &wireStatus{}
		if err := json.Unmarshal(b, st); err != nil {
			t.Fatal(err)
		}
		return st
	}

	// MCP2-R7: the tool surface is 18 = 17 v1 + agent_heartbeat.
	tools, err := session.ListTools(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := len(tools.Tools), 18; got != want {
		t.Fatalf("tool surface = %d, want %d", got, want)
	}

	scope := "mcp2-wire"
	ledgerDir := filepath.Join(ws, "ledger")
	auditLog := filepath.Join(ws, ".claude", "audit.log")
	call("aaw_init", map[string]any{"scope": scope, "operator": "wire-test", "ledger_dir": ledgerDir}, false)

	// The only hard process gate, unchanged: Z before any D refuses.
	call("tool_x_complete", map[string]any{"task_id": scope, "slug": scope, "body": "Z-0 — premature"}, true)

	dirOut := call("aaw_spawn", map[string]any{"scope": scope, "role": "director", "name": "director"}, false)
	dirID, _ := dirOut["ccl_id"].(string)
	if dirID == "" {
		t.Fatal("spawn minted no ccl_id")
	}
	call("agent_register", map[string]any{"scope": scope, "name": "director", "role": "director"}, false)

	// Venus: spawn-declared deliverable + a declared-quiet window over the cap.
	venusFile := filepath.Join(ws, "venus-design.md")
	if err := os.WriteFile(venusFile, []byte("draft"), 0o644); err != nil {
		t.Fatal(err)
	}
	call("aaw_spawn", map[string]any{"scope": scope, "role": "architect", "name": "Venus", "parent_id": dirID, "deliverable": venusFile}, false)
	call("agent_register", map[string]any{"scope": scope, "name": "Venus", "role": "architect"}, false)
	hb := call("agent_heartbeat", map[string]any{"scope": scope, "name": "Venus", "note": "heads-down authoring", "quiet_for_minutes": 10000}, false)
	quietUntil, err := time.Parse(time.RFC3339, hb["quiet_until"].(string))
	if err != nil {
		t.Fatal(err)
	}
	if d := time.Until(quietUntil); d > 241*time.Minute || d < 235*time.Minute {
		t.Fatalf("quiet window = %v, want capped at 240m", d)
	}

	// Mercury: liveness by deliverable mtime alone (the Q-4 shape, live).
	mercuryFile := filepath.Join(ws, "mercury-notes.md")
	if err := os.WriteFile(mercuryFile, []byte("notes"), 0o644); err != nil {
		t.Fatal(err)
	}
	call("aaw_spawn", map[string]any{"scope": scope, "role": "implementor", "name": "Mercury", "parent_id": dirID, "deliverable": mercuryFile}, false)
	call("agent_register", map[string]any{"scope": scope, "name": "Mercury", "role": "implementor"}, false)
	future := time.Now().Add(10 * time.Second)
	if err := os.Chtimes(mercuryFile, future, future); err != nil {
		t.Fatal(err)
	}

	// Attributed writes: three director entries (T, D, Z) and one ghost.
	call("tool_x_trace", map[string]any{"task_id": scope, "slug": scope, "body": "T-0 — directed trace", "actor": "director"}, false)
	call("tool_x_trace", map[string]any{"task_id": scope, "slug": scope, "body": "T-0 — ghost trace", "actor": "ghost"}, false)
	call("tool_x_decision", map[string]any{"task_id": scope, "slug": scope, "body": "D-0 — directed decision", "actor": "director"}, false)
	call("tool_x_complete", map[string]any{"task_id": scope, "slug": scope, "body": "Z-0 — directed close", "actor": "director"}, false)

	// US1-AC2 over the wire: the ghost write proceeded, the advisory line
	// landed, and no row was created.
	if n := countLines(t, auditLog, "UNREGISTERED-ATTRIBUTION"); n != 1 {
		t.Fatalf("UNREGISTERED-ATTRIBUTION lines = %d, want 1", n)
	}
	regPath := filepath.Join(ledgerDir, scope+".registry.json")
	regRaw, err := os.ReadFile(regPath)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(regRaw), "ghost") {
		t.Fatal("a registry row was created for the unregistered actor")
	}

	// The R-4 degraded run (every attributed entry is the director's) crossed
	// a Z-append: V-SOLO-2 is computed but NEVER emitted, and V-SOLO-1 stays
	// quiet (Venus is quiet-declared, Mercury active — clause one false).
	if n := countLines(t, auditLog, "V-SOLO"); n != 0 {
		t.Fatalf("V-SOLO lines after the degraded run = %d, want 0", n)
	}

	// FAKE-N re-routed to audit.log, advisory (the calls succeed), deduped.
	out := call("agent_register", map[string]any{"scope": scope, "name": "Imposter", "role": "implementor"}, false)
	if fake, _ := out["fake_n_signal"].(bool); !fake {
		t.Fatalf("fake_n_signal not raised: %v", out)
	}
	call("agent_register", map[string]any{"scope": scope, "name": "Imposter2", "role": "implementor"}, false)
	if n := countLines(t, auditLog, "FAKE-N"); n != 1 {
		t.Fatalf("FAKE-N lines = %d, want 1 (dedup: one per scope/code/window)", n)
	}

	// MCP2-INV5: the gate console in one call.
	st := getStatus(scope)
	if !st.Gates.ZEligible || st.Gates.DCount != 1 || st.Gates.ZCount != 1 {
		t.Fatalf("gates = %+v, want z_eligible with d_count=1 z_count=1", st.Gates)
	}
	if !st.ParseOK || st.EntryCount != 4 || st.Tallies["T"] != 2 {
		t.Fatalf("parse health: ok=%v entries=%d tallies=%v", st.ParseOK, st.EntryCount, st.Tallies)
	}
	// wire_contract LANDED with mcp4 (the MCP2 deferral, closed as this pin
	// instructed): the served verdict is the one the BOOT computed — this
	// hermetic workspace has no .mcp.json, so the verdict is "absent" (and
	// absent never refuses a strict boot).
	if st.Archived || st.WireContract != "absent" {
		t.Fatalf("archived=%v wire_contract=%q, want wire_contract=absent", st.Archived, st.WireContract)
	}
	if v, s := st.row("director"); v != "active" || s != "touch" {
		t.Fatalf("director row = %s/%s, want active/touch", v, s)
	}
	if v, s := st.row("Venus"); v != "quiet-declared" || s != "quiet-window" {
		t.Fatalf("Venus row = %s/%s, want quiet-declared/quiet-window", v, s)
	}
	if v, s := st.row("Mercury"); v != "active" || s != "deliverable-mtime" {
		t.Fatalf("Mercury row = %s/%s, want active/deliverable-mtime", v, s)
	}
	if !st.signal("UNREGISTERED-ATTRIBUTION") || !st.signal("FAKE-N") || st.signal("V-SOLO-1") {
		t.Fatalf("open signals wrong: %+v", st.Signals)
	}

	// Stale every non-director row out of band (files are truth; the server
	// reads through), then re-evaluate: both V-SOLO-1 clauses now hold — all
	// peers stale AND three director-attributed entries within the window.
	regRaw, err = os.ReadFile(regPath) // re-read: registrations landed since
	if err != nil {
		t.Fatal(err)
	}
	reg := &Registry{}
	if err := json.Unmarshal(regRaw, reg); err != nil {
		t.Fatal(err)
	}
	stale := time.Now().UTC().Add(-2 * time.Hour).Format(time.RFC3339)
	for _, a := range reg.Agents {
		if a.Name == "director" {
			continue
		}
		a.LastSeenAt, a.QuietUntil = stale, ""
	}
	b, err := json.MarshalIndent(reg, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(regPath, b, 0o644); err != nil {
		t.Fatal(err)
	}
	old := time.Now().Add(-3 * time.Hour)
	for _, f := range []string{venusFile, mercuryFile} {
		if err := os.Chtimes(f, old, old); err != nil {
			t.Fatal(err)
		}
	}

	st = getStatus(scope)
	if !st.signal("V-SOLO-1") {
		t.Fatalf("V-SOLO-1 not open after the stale edit: %+v", st.Signals)
	}
	if v, s := st.row("Venus"); v != "stale" || s != "touch" {
		t.Fatalf("staled Venus row = %s/%s, want stale/touch", v, s)
	}
	if n := countLines(t, auditLog, "V-SOLO-1"); n != 1 {
		t.Fatalf("V-SOLO-1 lines = %d, want 1", n)
	}
	getStatus(scope) // a second evaluation inside the window
	if n := countLines(t, auditLog, "V-SOLO-1"); n != 1 {
		t.Fatalf("V-SOLO-1 lines after re-evaluation = %d, want 1 (dedup)", n)
	}
	if n := countLines(t, auditLog, "V-SOLO-2"); n != 0 {
		t.Fatalf("V-SOLO-2 lines = %d, want 0 — computed, never emitted", n)
	}
}
