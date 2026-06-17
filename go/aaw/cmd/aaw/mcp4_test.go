package main

import (
	"context"
	"encoding/json"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/aaw/internal/config"
	"github.com/jonny-novikov/aaw/internal/gates"
	"github.com/jonny-novikov/aaw/internal/store"
)

// holdOneFamily binds [::1]:0 — the family-split culprit: a holder on ONE
// loopback family of an otherwise free port.
func holdOneFamily(t *testing.T) (net.Listener, string) {
	t.Helper()
	l, err := net.Listen("tcp6", "[::1]:0")
	if err != nil {
		t.Skipf("no IPv6 loopback on this host: %v", err)
	}
	t.Cleanup(func() { l.Close() })
	return l, strconv.Itoa(l.Addr().(*net.TCPAddr).Port)
}

// MCP4-D2 / MCP4-INV1: with one family held by a foreign (non-MCP) process,
// the localhost bind refuses PORT_BUSY with lsof guidance — never a
// one-family bind, nothing left bound, the holder probe capped.
func TestBindLocalhostAllOrNothingForeignHolder(t *testing.T) {
	_, port := holdOneFamily(t)

	start := time.Now()
	listeners, err := bindLocalhost(port)
	elapsed := time.Since(start)
	if err == nil {
		for _, l := range listeners {
			l.Close()
		}
		t.Fatal("bind succeeded with a family held")
	}
	if !strings.Contains(err.Error(), gates.PORT_BUSY) {
		t.Fatalf("refusal lacks the reserved code: %v", err)
	}
	if !strings.Contains(err.Error(), "lsof") {
		t.Fatalf("foreign holder earned no lsof guidance: %v", err)
	}
	// The probe is capped ~500 ms; generous slack for a loaded host.
	if elapsed > 5*time.Second {
		t.Fatalf("holder probe ran %v — the cap did not hold", elapsed)
	}
	// All-or-nothing left nothing bound: the free family is re-bindable.
	l4, err := net.Listen("tcp4", "127.0.0.1:"+port)
	if err != nil {
		t.Fatalf("the refused boot leaked its tcp4 listener: %v", err)
	}
	l4.Close()
}

// MCP4-D2: when the holder answers as an aaw instance, the refusal names its
// workspace and version — the two-instance diagnosis.
func TestBindLocalhostRefusalNamesAawHolder(t *testing.T) {
	hold, port := holdOneFamily(t)

	ws := t.TempDir()
	st, err := store.Open(ws)
	if err != nil {
		t.Fatal(err)
	}
	lk, err := store.AcquireInstanceLock(st.Workspace)
	if err != nil {
		t.Fatal(err)
	}
	defer lk.Release()
	server := newServer(st, lk, &bootInfo{startedAt: store.Now(), wire: config.WireAbsent}, nil)
	handler := mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return server }, nil)
	go http.Serve(hold, handler)

	_, err = bindLocalhost(port)
	if err == nil {
		t.Fatal("second instance bound despite the held family")
	}
	if !strings.Contains(err.Error(), gates.PORT_BUSY) {
		t.Fatalf("refusal lacks the reserved code: %v", err)
	}
	if !strings.Contains(err.Error(), st.Workspace) || !strings.Contains(err.Error(), version) {
		t.Fatalf("aaw holder not named by workspace+version: %v", err)
	}
	// Never a one-family bind: the free family is re-bindable afterwards.
	l4, err := net.Listen("tcp4", "127.0.0.1:"+port)
	if err != nil {
		t.Fatalf("the refused boot leaked its tcp4 listener: %v", err)
	}
	l4.Close()
}

// MCP4-D3 / MCP4-INV3: only strict refuses, only on mismatch/unparseable —
// so the served verdict mismatch is reachable only under warn.
func TestWireRefusesMatrix(t *testing.T) {
	refusing := map[string]bool{
		config.WireCheckStrict + "/" + config.WireMismatch:    true,
		config.WireCheckStrict + "/" + config.WireUnparseable: true,
	}
	for _, mode := range []string{config.WireCheckStrict, config.WireCheckWarn, config.WireCheckSkip} {
		for _, verdict := range []string{config.WireAgree, config.WireMismatch, config.WireAbsent, config.WireUnparseable, config.WireSkipped} {
			want := refusing[mode+"/"+verdict]
			if got := wireRefuses(mode, verdict); got != want {
				t.Fatalf("wireRefuses(%s, %s) = %v, want %v", mode, verdict, got, want)
			}
		}
	}
}

// MCP4-D5: one banner line carries the listener, the wire verdict, and the
// resolved absolute workspace.
func TestBannerLine(t *testing.T) {
	line := bannerLine("127.0.0.1:8905", "/abs/workspace", config.WireAgree)
	for _, needle := range []string{version, "http://127.0.0.1:8905/", "/abs/workspace", "wire_contract agree"} {
		if !strings.Contains(line, needle) {
			t.Fatalf("banner %q lacks %q", line, needle)
		}
	}
}

// The MCP4 in-process boot surface: probe/aaw_status carry what the boot
// computed (started_at, listeners, instance id, wire_contract), the
// effective-config read-through flips sources file/default with NO restart
// and reaches a live tool (the heartbeat quiet cap), the model surfaces on
// the liveness row, and per-scope reopened_at reads through from the raw
// index. Covers MCP4-US-A1/A2, the US-D1 no-restart clause, and US-D4's
// status-row half.
func TestMCP4InProcessBootSurface(t *testing.T) {
	ctx := context.Background()
	ws := t.TempDir()

	// The committed wire contract this boot agrees with.
	mcpJSON := filepath.Join(ws, ".mcp.json")
	if err := os.WriteFile(mcpJSON, []byte(`{"mcpServers": {"aaw": {"type": "streamable-http", "url": "http://localhost:7905/"}}}`), 0o644); err != nil {
		t.Fatal(err)
	}
	mcpBytes, err := os.ReadFile(mcpJSON)
	if err != nil {
		t.Fatal(err)
	}

	st, err := store.Open(ws)
	if err != nil {
		t.Fatal(err)
	}
	lk, err := store.AcquireInstanceLock(st.Workspace)
	if err != nil {
		t.Fatal(err)
	}
	defer lk.Release()

	verdict, detail, _ := config.WireCheck(st.Workspace, "localhost:7905", config.WireCheckStrict)
	if verdict != config.WireAgree {
		t.Fatalf("boot wire verdict = %s (%s), want agree", verdict, detail)
	}
	boot := &bootInfo{startedAt: store.Now(), listeners: []string{"127.0.0.1:7905", "[::1]:7905"}, wire: verdict}
	server := newServer(st, lk, boot, nil)

	serverTransport, clientTransport := mcp.NewInMemoryTransports()
	ss, err := server.Connect(ctx, serverTransport, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ss.Close(ctx) })
	client := mcp.NewClient(&mcp.Implementation{Name: "mcp4-inproc", Version: "test"}, nil)
	cs, err := client.Connect(ctx, clientTransport, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cs.Close(ctx) })

	ok := func(name string, args map[string]any) map[string]any {
		t.Helper()
		res, err := cs.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil {
			t.Fatalf("%s transport error: %v", name, err)
		}
		if res.IsError {
			t.Fatalf("%s refused", name)
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
	knob := func(eff map[string]any, name string) (float64, string) {
		t.Helper()
		row, _ := eff[name].(map[string]any)
		if row == nil {
			t.Fatalf("effective_config lacks %s: %v", name, eff)
		}
		v, _ := row["value"].(float64)
		s, _ := row["source"].(string)
		return v, s
	}

	// --- probe: the boot surface in one payload (US-A2), defaults layer ---
	probe := ok("probe", map[string]any{})
	if probe["started_at"] != boot.startedAt {
		t.Fatalf("started_at = %v, want %s", probe["started_at"], boot.startedAt)
	}
	if ls, _ := probe["listeners"].([]any); len(ls) != 2 {
		t.Fatalf("listeners = %v, want the two loopback families", probe["listeners"])
	}
	if id, _ := probe["instance_id"].(string); id == "" {
		t.Fatal("probe carries no instance_id")
	}
	if probe["wire_contract"] != config.WireAgree {
		t.Fatalf("probe wire_contract = %v, want agree (computed, never defaulted)", probe["wire_contract"])
	}
	eff, _ := probe["effective_config"].(map[string]any)
	if v, s := knob(eff, config.KnobQuietCap); v != float64(config.DefaultQuietCapMinutes) || s != config.SourceDefault {
		t.Fatalf("quiet_cap before the edit = %v/%s, want %d/default", v, s, config.DefaultQuietCapMinutes)
	}
	if _, present := probe["reopened_at"]; present {
		t.Fatalf("reopened_at fabricated with no stamps on disk: %v", probe["reopened_at"])
	}

	// --- the config edit applies with NO restart (US-D1), same session ---
	if err := os.MkdirAll(filepath.Join(ws, ".aaw"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(config.PolicyPath(ws), []byte(`{"window_w_minutes": 7, "quiet_cap_minutes": 1}`), 0o644); err != nil {
		t.Fatal(err)
	}
	probe = ok("probe", map[string]any{})
	eff, _ = probe["effective_config"].(map[string]any)
	if v, s := knob(eff, config.KnobWindowW); v != 7 || s != config.SourceFile {
		t.Fatalf("window_w after the edit = %v/%s, want 7/file", v, s)
	}
	if v, s := knob(eff, config.KnobQuietCap); v != 1 || s != config.SourceFile {
		t.Fatalf("quiet_cap after the edit = %v/%s, want 1/file", v, s)
	}
	if v, s := knob(eff, config.KnobThresholdK); v != float64(config.DefaultThresholdK) || s != config.SourceDefault {
		t.Fatalf("threshold_k = %v/%s, want %d/default", v, s, config.DefaultThresholdK)
	}

	// --- the edited cap reaches a live tool: heartbeat clamps to 1 minute ---
	// (with policy-named env vars set: no env layer exists — MCP4-INV2)
	t.Setenv("AAW_QUIET_CAP_MINUTES", "999")
	t.Setenv("QUIET_CAP_MINUTES", "999")
	ok("aaw_init", map[string]any{"scope": "m4", "operator": "tier", "ledger_dir": "ledger"})
	ok("aaw_spawn", map[string]any{"scope": "m4", "role": "director", "name": "director", "model": "opus"})
	hb := ok("agent_heartbeat", map[string]any{"scope": "m4", "name": "director", "quiet_for_minutes": 200})
	quietUntil, err := time.Parse(time.RFC3339, hb["quiet_until"].(string))
	if err != nil {
		t.Fatalf("quiet_until unparseable: %v", err)
	}
	if cap := time.Now().UTC().Add(2 * time.Minute); quietUntil.After(cap) {
		t.Fatalf("quiet_until %s exceeds the file-edited 1-minute cap (no-restart read-through failed, or an env layer exists)", quietUntil)
	}

	// --- aaw_status: wire_contract + the model on the liveness row ---
	status := ok("aaw_status", map[string]any{"scope": "m4"})
	if status["wire_contract"] != config.WireAgree {
		t.Fatalf("aaw_status wire_contract = %v, want agree", status["wire_contract"])
	}
	rows, _ := status["liveness"].([]any)
	if len(rows) != 1 {
		t.Fatalf("liveness rows = %v, want 1", status["liveness"])
	}
	if row, _ := rows[0].(map[string]any); row["model"] != "opus" {
		t.Fatalf("liveness row model = %v, want opus (US-D4)", row["model"])
	}

	// --- a DELETED config.json falls back to the default layer with no
	// refusal: the next evaluation reads defaults, tools keep working ---
	if err := os.Remove(config.PolicyPath(ws)); err != nil {
		t.Fatal(err)
	}
	probe = ok("probe", map[string]any{})
	eff, _ = probe["effective_config"].(map[string]any)
	if v, s := knob(eff, config.KnobQuietCap); v != float64(config.DefaultQuietCapMinutes) || s != config.SourceDefault {
		t.Fatalf("quiet_cap after the delete = %v/%s, want %d/default", v, s, config.DefaultQuietCapMinutes)
	}
	hb = ok("agent_heartbeat", map[string]any{"scope": "m4", "name": "director", "quiet_for_minutes": 200})
	quietUntil, err = time.Parse(time.RFC3339, hb["quiet_until"].(string))
	if err != nil {
		t.Fatalf("quiet_until unparseable after the delete: %v", err)
	}
	if floor := time.Now().UTC().Add(100 * time.Minute); quietUntil.Before(floor) {
		t.Fatalf("quiet_until %s still clamped after the config delete — the default layer did not apply", quietUntil)
	}

	// --- per-scope reopened_at reads through from the raw index ---
	idxPath := filepath.Join(ws, ".aaw", "scopes.json")
	raw, err := os.ReadFile(idxPath)
	if err != nil {
		t.Fatal(err)
	}
	idx := map[string]map[string]any{}
	if err := json.Unmarshal(raw, &idx); err != nil {
		t.Fatal(err)
	}
	stamp := "2026-06-11T00:00:00Z"
	idx["m4"]["reopened_at"] = stamp
	merged, err := json.MarshalIndent(idx, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(idxPath, merged, 0o644); err != nil {
		t.Fatal(err)
	}
	probe = ok("probe", map[string]any{})
	reopened, _ := probe["reopened_at"].(map[string]any)
	if reopened["m4"] != stamp {
		t.Fatalf("reopened_at = %v, want m4 -> %s", probe["reopened_at"], stamp)
	}

	// --- MCP4-INV3: the whole session never touched .mcp.json ---
	after, err := os.ReadFile(mcpJSON)
	if err != nil {
		t.Fatal(err)
	}
	if string(after) != string(mcpBytes) {
		t.Fatal(".mcp.json changed under the server")
	}

	// A second boot under warn against a disagreeing bound address is the
	// ONLY road to a served mismatch (MCP4-INV3): strict refuses it first.
	v2, _, _ := config.WireCheck(st.Workspace, "localhost:9999", config.WireCheckWarn)
	if v2 != config.WireMismatch {
		t.Fatalf("warn-mode verdict = %s, want mismatch", v2)
	}
	if wireRefuses(config.WireCheckWarn, v2) {
		t.Fatal("warn refused — mismatch must proceed loudly")
	}
	if !wireRefuses(config.WireCheckStrict, v2) {
		t.Fatal("strict did not refuse the mismatch")
	}

	// And the warn-mode boot SERVES that mismatch in-band (US-A1 AC2): a
	// second server over the same store, carrying the warn-computed verdict.
	server2 := newServer(st, nil, &bootInfo{startedAt: store.Now(), listeners: []string{"127.0.0.1:9999"}, wire: v2}, nil)
	st2, ct2 := mcp.NewInMemoryTransports()
	ss2, err := server2.Connect(ctx, st2, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ss2.Close(ctx) })
	client2 := mcp.NewClient(&mcp.Implementation{Name: "mcp4-warn", Version: "test"}, nil)
	cs2, err := client2.Connect(ctx, ct2, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cs2.Close(ctx) })
	call2 := func(name string, args map[string]any) map[string]any {
		t.Helper()
		res, err := cs2.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil || res.IsError {
			t.Fatalf("%s failed under warn: %v", name, err)
		}
		b, _ := json.Marshal(res.StructuredContent)
		out := map[string]any{}
		if err := json.Unmarshal(b, &out); err != nil {
			t.Fatal(err)
		}
		return out
	}
	if got := call2("probe", map[string]any{})["wire_contract"]; got != config.WireMismatch {
		t.Fatalf("warn-mode probe wire_contract = %v, want mismatch", got)
	}
	if got := call2("aaw_status", map[string]any{"scope": "m4"})["wire_contract"]; got != config.WireMismatch {
		t.Fatalf("warn-mode aaw_status wire_contract = %v, want mismatch", got)
	}
}

// US-D3 AC1's "both directions": the strict-refusal remedy names the
// edit-the-file direction AND the re-flag direction — or the repair
// fallback when no committed host:port parsed (unparseable).
func TestWireFixBothDirections(t *testing.T) {
	fix := wireFix("/ws", "localhost:7905", "localhost:8905")
	for _, needle := range []string{"/ws/.mcp.json", `"http://localhost:7905/"`, "-addr localhost:8905"} {
		if !strings.Contains(fix, needle) {
			t.Fatalf("fix %q lacks %q", fix, needle)
		}
	}
	if fix := wireFix("/ws", "localhost:7905", ""); !strings.Contains(fix, "repair") {
		t.Fatalf("unparseable fix lacks the repair direction: %q", fix)
	}
}

// US-A1: the verdict is never constant and never defaulted — a server with
// NO boot-computed verdict (nil bootInfo: an in-process harness without a
// bind plane) OMITS wire_contract from probe and aaw_status rather than
// fabricating one (MCP4-INV3).
func TestWireContractNeverDefaulted(t *testing.T) {
	ctx := context.Background()
	st, err := store.Open(t.TempDir())
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
	client := mcp.NewClient(&mcp.Implementation{Name: "mcp4-nilboot", Version: "test"}, nil)
	cs, err := client.Connect(ctx, clientTransport, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cs.Close(ctx) })

	out := func(name string, args map[string]any) map[string]any {
		t.Helper()
		res, err := cs.CallTool(ctx, &mcp.CallToolParams{Name: name, Arguments: args})
		if err != nil || res.IsError {
			t.Fatalf("%s failed: %v", name, err)
		}
		b, _ := json.Marshal(res.StructuredContent)
		m := map[string]any{}
		if err := json.Unmarshal(b, &m); err != nil {
			t.Fatal(err)
		}
		return m
	}
	if v, present := out("probe", map[string]any{})["wire_contract"]; present {
		t.Fatalf("nil-boot probe fabricated wire_contract %v", v)
	}
	out("aaw_init", map[string]any{"scope": "nilboot", "operator": "tier", "ledger_dir": "ledger"})
	if v, present := out("aaw_status", map[string]any{"scope": "nilboot"})["wire_contract"]; present {
		t.Fatalf("nil-boot aaw_status fabricated wire_contract %v", v)
	}
}
