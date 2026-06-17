package config

import (
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeFile(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

// The five identity flags and their defaults (MCP4-R1).
func TestRegisterFlagsDefaults(t *testing.T) {
	fs := flag.NewFlagSet("aaw", flag.ContinueOnError)
	f := RegisterFlags(fs)
	if err := fs.Parse(nil); err != nil {
		t.Fatal(err)
	}
	if f.Addr != "localhost:8905" || f.Workspace != "." || f.LogLevel != "info" || f.Stdio || f.WireCheck != WireCheckStrict {
		t.Fatalf("flag defaults drifted: %+v", f)
	}
	for _, name := range []string{"addr", "workspace", "log-level", "stdio", "wire-check"} {
		if fs.Lookup(name) == nil {
			t.Fatalf("identity flag -%s not registered", name)
		}
	}
}

func TestSlogLevel(t *testing.T) {
	for in, want := range map[string]string{"debug": "DEBUG", "info": "INFO", "warn": "WARN", "error": "ERROR", "": "INFO"} {
		lvl, err := SlogLevel(in)
		if err != nil || lvl.String() != want {
			t.Fatalf("SlogLevel(%q) = %v, %v; want %s", in, lvl, err, want)
		}
	}
	if _, err := SlogLevel("loud"); err == nil {
		t.Fatal("unknown level did not error")
	}
}

func TestValidWireCheck(t *testing.T) {
	for _, ok := range []string{WireCheckStrict, WireCheckWarn, WireCheckSkip} {
		if !ValidWireCheck(ok) {
			t.Fatalf("ValidWireCheck(%q) = false", ok)
		}
	}
	if ValidWireCheck("loose") || ValidWireCheck("") {
		t.Fatal("an unknown wire-check mode validated")
	}
}

// MCP4-D1: absent file = the default layer, every source "default".
func TestPolicyDefaults(t *testing.T) {
	p, err := LoadPolicy(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if p.WindowW != DefaultWindowW || p.ThresholdK != DefaultThresholdK || p.QuietCapMinutes != DefaultQuietCapMinutes ||
		p.TTLDays != DefaultTTLDays || p.DedupWindow != DefaultDedupWindow || len(p.LintTokens) != 0 {
		t.Fatalf("default policy drifted: %+v", p)
	}
	knobs := []string{KnobWindowW, KnobThresholdK, KnobQuietCap, KnobTTLDays, KnobDedupWindow, KnobLintTokens}
	for _, k := range knobs {
		if p.Sources[k] != SourceDefault {
			t.Fatalf("source of %s = %q, want default", k, p.Sources[k])
		}
	}
	eff := p.Effective()
	if len(eff) != len(knobs) {
		t.Fatalf("effective_config has %d knobs, want %d", len(eff), len(knobs))
	}
	for _, k := range knobs {
		if eff[k].Source != SourceDefault {
			t.Fatalf("effective_config %s source = %q, want default", k, eff[k].Source)
		}
	}
}

// MCP4-INV2: an edit applies on the next evaluation with no restart — every
// LoadPolicy is a fresh read; the winning source flips to "file" per knob.
func TestPolicyReadThroughEditApplies(t *testing.T) {
	ws := t.TempDir()
	path := PolicyPath(ws)

	writeFile(t, path, `{"window_w_minutes": 5, "quiet_cap_minutes": 0, "ttl_days": 0, "lint_tokens": ["sees"]}`)
	p, err := LoadPolicy(ws)
	if err != nil {
		t.Fatal(err)
	}
	if p.WindowW != 5*time.Minute || p.Sources[KnobWindowW] != SourceFile {
		t.Fatalf("window_w not file-sourced: %v/%s", p.WindowW, p.Sources[KnobWindowW])
	}
	// Zero IN the file is a file-sourced choice, not a default fallthrough.
	if p.QuietCapMinutes != 0 || p.Sources[KnobQuietCap] != SourceFile {
		t.Fatalf("explicit quiet_cap 0 not honored: %d/%s", p.QuietCapMinutes, p.Sources[KnobQuietCap])
	}
	if p.TTLDays != 0 || p.Sources[KnobTTLDays] != SourceFile {
		t.Fatalf("explicit ttl_days 0 not honored: %d/%s", p.TTLDays, p.Sources[KnobTTLDays])
	}
	if len(p.LintTokens) != 1 || p.LintTokens[0] != "sees" || p.Sources[KnobLintTokens] != SourceFile {
		t.Fatalf("lint_tokens not file-sourced: %v/%s", p.LintTokens, p.Sources[KnobLintTokens])
	}
	// The unset knobs stay default.
	if p.ThresholdK != DefaultThresholdK || p.Sources[KnobThresholdK] != SourceDefault {
		t.Fatalf("unset threshold_k drifted: %d/%s", p.ThresholdK, p.Sources[KnobThresholdK])
	}

	// The edit, no restart: the very next load reads the new values.
	writeFile(t, path, `{"window_w_minutes": 10, "threshold_k": 7, "dedup_window_minutes": 2}`)
	p, err = LoadPolicy(ws)
	if err != nil {
		t.Fatal(err)
	}
	if p.WindowW != 10*time.Minute || p.ThresholdK != 7 || p.DedupWindow != 2*time.Minute {
		t.Fatalf("edit did not apply on the next evaluation: %+v", p)
	}
	if p.QuietCapMinutes != DefaultQuietCapMinutes || p.Sources[KnobQuietCap] != SourceDefault {
		t.Fatalf("removed knob did not fall back to default: %d/%s", p.QuietCapMinutes, p.Sources[KnobQuietCap])
	}
}

// A corrupt file or an out-of-range knob yields the default layer AND a
// non-nil error — advisory, never a refusal surface.
func TestPolicyDegradesToDefaults(t *testing.T) {
	ws := t.TempDir()
	path := PolicyPath(ws)

	writeFile(t, path, `{not json`)
	p, err := LoadPolicy(ws)
	if err == nil {
		t.Fatal("corrupt config returned no error")
	}
	if p.WindowW != DefaultWindowW || p.Sources[KnobWindowW] != SourceDefault {
		t.Fatalf("corrupt config did not yield the default layer: %+v", p)
	}

	writeFile(t, path, `{"window_w_minutes": -3, "threshold_k": 0, "ttl_days": -1, "quiet_cap_minutes": 30}`)
	p, err = LoadPolicy(ws)
	if err == nil {
		t.Fatal("out-of-range knobs returned no error")
	}
	if p.WindowW != DefaultWindowW || p.ThresholdK != DefaultThresholdK || p.TTLDays != DefaultTTLDays {
		t.Fatalf("out-of-range knobs did not fall to defaults: %+v", p)
	}
	if p.QuietCapMinutes != 30 || p.Sources[KnobQuietCap] != SourceFile {
		t.Fatalf("the valid knob beside invalid ones was dropped: %d/%s", p.QuietCapMinutes, p.Sources[KnobQuietCap])
	}
}

// MCP4-INV2, both halves: (1) policy-named environment variables have no
// effect; (2) structurally, NO non-test source in apps/aaw reads the
// environment at all — the no-env layer is pinned by a source scan, not just
// by behavior.
func TestNoEnvLayer(t *testing.T) {
	for _, kv := range []string{"AAW_WINDOW_W_MINUTES", "WINDOW_W_MINUTES", "AAW_THRESHOLD_K", "AAW_QUIET_CAP_MINUTES", "AAW_TTL_DAYS", "AAW_DEDUP_WINDOW_MINUTES", "AAW_LINT_TOKENS"} {
		t.Setenv(kv, "1")
	}
	p, err := LoadPolicy(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if p.WindowW != DefaultWindowW || p.ThresholdK != DefaultThresholdK || p.QuietCapMinutes != DefaultQuietCapMinutes {
		t.Fatalf("a policy-named env var took effect: %+v", p)
	}

	// The structural pin: walk the module's non-test sources.
	root, err := moduleRoot()
	if err != nil {
		t.Fatal(err)
	}
	err = filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		src := string(b)
		if strings.Contains(src, "os.Getenv") || strings.Contains(src, "os.LookupEnv") || strings.Contains(src, "os.Environ") {
			t.Errorf("%s reads the environment — no env layer exists (MCP4-INV2)", path)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

// moduleRoot climbs from the package dir to the go.mod home (apps/aaw).
func moduleRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", os.ErrNotExist
		}
		dir = parent
	}
}

// MCP4-D3: the wire-verdict matrix — all five states — with the MCP4-INV3
// byte-comparison: the file is untouched across every state.
func TestWireVerdictMatrix(t *testing.T) {
	committed := `{"mcpServers": {"ide": {"type": "sse", "url": "http://127.0.0.1:64342/sse"}, "aaw": {"type": "streamable-http", "url": "http://localhost:8905/"}}}`

	cases := []struct {
		name          string
		body          string // "" = no .mcp.json on disk
		bound, mode   string
		verdict       string
		wantCommitted string
	}{
		{"skipped by flag", committed, "localhost:8905", WireCheckSkip, WireSkipped, ""},
		{"absent file", "", "localhost:8905", WireCheckStrict, WireAbsent, ""},
		{"absent aaw entry", `{"mcpServers": {"ide": {"type": "sse", "url": "http://127.0.0.1:1/sse"}}}`, "localhost:8905", WireCheckStrict, WireAbsent, ""},
		{"unparseable json", `{not json`, "localhost:8905", WireCheckStrict, WireUnparseable, ""},
		{"unparseable url", `{"mcpServers": {"aaw": {"type": "streamable-http", "url": "not a url"}}}`, "localhost:8905", WireCheckStrict, WireUnparseable, ""},
		{"agree", committed, "localhost:8905", WireCheckStrict, WireAgree, "localhost:8905"},
		{"agree case-folded host", committed, "LOCALHOST:8905", WireCheckWarn, WireAgree, "localhost:8905"},
		{"agree scheme-default port", `{"mcpServers": {"aaw": {"url": "https://localhost/"}}}`, "localhost:443", WireCheckStrict, WireAgree, "localhost:443"},
		{"mismatch port", committed, "localhost:9999", WireCheckWarn, WireMismatch, "localhost:8905"},
		{"mismatch host", committed, "127.0.0.1:8905", WireCheckWarn, WireMismatch, "localhost:8905"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			ws := t.TempDir()
			path := filepath.Join(ws, ".mcp.json")
			if tc.body != "" {
				writeFile(t, path, tc.body)
			}
			before, _ := os.ReadFile(path)

			verdict, detail, gotCommitted := WireCheck(ws, tc.bound, tc.mode)
			if verdict != tc.verdict {
				t.Fatalf("verdict = %s (%s), want %s", verdict, detail, tc.verdict)
			}
			if gotCommitted != tc.wantCommitted {
				t.Fatalf("committed = %q, want %q", gotCommitted, tc.wantCommitted)
			}
			if detail == "" {
				t.Fatal("no detail computed — the diagnosis is part of the contract")
			}

			// MCP4-INV3: never generated, never edited.
			after, _ := os.ReadFile(path)
			if string(before) != string(after) {
				t.Fatalf(".mcp.json changed under the check:\nbefore %q\nafter  %q", before, after)
			}
			if tc.body == "" {
				if _, err := os.Stat(path); !os.IsNotExist(err) {
					t.Fatal("the check GENERATED .mcp.json")
				}
			}
		})
	}
}
