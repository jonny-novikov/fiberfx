// Package config is the AD-8 boot/config plane (MCP4-D1, MCP4-D3): the five
// identity flags, the <workspace>/.aaw/config.json policy read-through with
// the per-knob effective-config report, and the .mcp.json wire check.
//
// Identity is flags-only. Runtime policy is files-truth: the Operator-edited
// .aaw/config.json is read through on every evaluation (no cache, no mtime
// keying — the AD-2 pure read-through), so an edit applies on the next call
// with no restart. Precedence is file > built-in default, per knob, each
// knob's winning source reported in probe.effective_config. NO environment
// layer and NO per-knob policy flag exists anywhere in apps/aaw (D-6(c),
// MCP4-INV2). The server never writes the config file, and never generates
// or edits .mcp.json (MCP4-INV3).
package config

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// ---- boot identity: the five flags (MCP4-R1) ----

// Flags is the parsed boot identity: these five locate the workspace and the
// listener before any file plane exists; nothing else does. No per-knob
// policy flag exists — policy is the config file's (MCP4-D1).
type Flags struct {
	Addr      string
	Workspace string
	LogLevel  string
	Stdio     bool
	WireCheck string
}

// RegisterFlags declares the five identity flags on fs; the returned struct
// is populated by fs.Parse. Flags go BEFORE the mode word — flag.Parse stops
// at the first non-flag argument (the L-5 quirk).
func RegisterFlags(fs *flag.FlagSet) *Flags {
	f := &Flags{}
	fs.StringVar(&f.Addr, "addr", "localhost:8905", "listen/connect address")
	fs.StringVar(&f.Workspace, "workspace", ".", "workspace root (scope index lives at <workspace>/.aaw/scopes.json)")
	fs.StringVar(&f.LogLevel, "log-level", "info", "stderr log level: debug|info|warn|error")
	fs.BoolVar(&f.Stdio, "stdio", false, "serve MCP over stdio instead of HTTP (a development convenience — AD-1; no listener, the wire check reports skipped)")
	fs.StringVar(&f.WireCheck, "wire-check", WireCheckStrict, "wire-contract check of the workspace .mcp.json aaw entry: strict|warn|skip")
	return f
}

// SlogLevel maps -log-level to its slog.Level; an unknown level errors —
// boot identity is never silently coerced.
func SlogLevel(s string) (slog.Level, error) {
	switch strings.ToLower(s) {
	case "debug":
		return slog.LevelDebug, nil
	case "", "info":
		return slog.LevelInfo, nil
	case "warn":
		return slog.LevelWarn, nil
	case "error":
		return slog.LevelError, nil
	}
	return 0, fmt.Errorf("unknown -log-level %q (debug|info|warn|error)", s)
}

// ---- runtime policy: the .aaw/config.json read-through (MCP4-D1) ----

// The built-in default layer (the D-6 policy defaults W=45/K=3/cap=240). The
// signals constants alias these, so each value keeps one authority.
const (
	DefaultWindowWMinutes     = 45
	DefaultThresholdK         = 3
	DefaultQuietCapMinutes    = 240
	DefaultTTLDays            = 0 // 0 = no TTL hint
	DefaultDedupWindowMinutes = DefaultWindowWMinutes

	DefaultWindowW     = DefaultWindowWMinutes * time.Minute
	DefaultDedupWindow = DefaultDedupWindowMinutes * time.Minute
)

// DefaultLintTokens is the built-in lint token list: empty — the LAW-3
// advisory lint that consumes it is a later rung's; the knob is homed here
// (MCP4-D1) so the list is Operator-tunable the day the consumer lands.
var DefaultLintTokens []string

// Knob names — the .aaw/config.json keys, equal to the effective_config
// report keys (one vocabulary for the file and the probe).
const (
	KnobWindowW     = "window_w_minutes"
	KnobThresholdK  = "threshold_k"
	KnobQuietCap    = "quiet_cap_minutes"
	KnobTTLDays     = "ttl_days"
	KnobDedupWindow = "dedup_window_minutes"
	KnobLintTokens  = "lint_tokens"
)

// The winning sources (MCP4-D1: precedence file > built-in default).
const (
	SourceFile    = "file"
	SourceDefault = "default"
)

// Policy is the resolved runtime policy; Sources names each knob's winning
// source for probe.effective_config.
type Policy struct {
	WindowW         time.Duration
	ThresholdK      int
	QuietCapMinutes int
	TTLDays         int
	DedupWindow     time.Duration
	LintTokens      []string
	Sources         map[string]string
}

// fileConfig is the .aaw/config.json shape; every knob optional. Pointers
// distinguish absent from zero (a ttl_days of 0 in the file is a file-sourced
// choice, not a fallthrough to the default).
type fileConfig struct {
	WindowWMinutes     *int      `json:"window_w_minutes"`
	ThresholdK         *int      `json:"threshold_k"`
	QuietCapMinutes    *int      `json:"quiet_cap_minutes"`
	TTLDays            *int      `json:"ttl_days"`
	DedupWindowMinutes *int      `json:"dedup_window_minutes"`
	LintTokens         *[]string `json:"lint_tokens"`
}

// Defaults is the pure built-in layer: every knob at its default, every
// source "default".
func Defaults() Policy {
	return Policy{
		WindowW:         DefaultWindowW,
		ThresholdK:      DefaultThresholdK,
		QuietCapMinutes: DefaultQuietCapMinutes,
		TTLDays:         DefaultTTLDays,
		DedupWindow:     DefaultDedupWindow,
		LintTokens:      DefaultLintTokens,
		Sources: map[string]string{
			KnobWindowW:     SourceDefault,
			KnobThresholdK:  SourceDefault,
			KnobQuietCap:    SourceDefault,
			KnobTTLDays:     SourceDefault,
			KnobDedupWindow: SourceDefault,
			KnobLintTokens:  SourceDefault,
		},
	}
}

// PolicyPath is the policy file location under a workspace root.
func PolicyPath(workspace string) string {
	return filepath.Join(workspace, ".aaw", "config.json")
}

// LoadPolicy reads <workspace>/.aaw/config.json fresh — the pure read-through
// (AD-2): no cache, so an Operator edit applies on the next evaluation with
// no restart. An absent file is the default layer with no error. An
// unreadable or unparseable file, or an out-of-range knob, yields the default
// layer for the affected knobs AND a non-nil error: policy is an advisory
// plane — callers log and proceed, no tool call blocks on it. The file is
// only ever read; the server never writes it (MCP4-INV2).
func LoadPolicy(workspace string) (Policy, error) {
	p := Defaults()
	path := PolicyPath(workspace)
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return p, nil
	}
	if err != nil {
		return p, fmt.Errorf("reading %s: %w (the default layer applies)", path, err)
	}
	var fc fileConfig
	if err := json.Unmarshal(b, &fc); err != nil {
		return p, fmt.Errorf("parsing %s: %w (the default layer applies)", path, err)
	}
	var errs []error
	badKnob := func(knob string, v int, want string) {
		errs = append(errs, fmt.Errorf("%s: %s = %d, want %s (the default applies)", path, knob, v, want))
	}
	if v := fc.WindowWMinutes; v != nil {
		if *v > 0 {
			p.WindowW, p.Sources[KnobWindowW] = time.Duration(*v)*time.Minute, SourceFile
		} else {
			badKnob(KnobWindowW, *v, "a positive minute count")
		}
	}
	if v := fc.ThresholdK; v != nil {
		if *v > 0 {
			p.ThresholdK, p.Sources[KnobThresholdK] = *v, SourceFile
		} else {
			badKnob(KnobThresholdK, *v, "a positive count")
		}
	}
	if v := fc.QuietCapMinutes; v != nil {
		if *v >= 0 {
			p.QuietCapMinutes, p.Sources[KnobQuietCap] = *v, SourceFile
		} else {
			badKnob(KnobQuietCap, *v, "a non-negative minute count")
		}
	}
	if v := fc.TTLDays; v != nil {
		if *v >= 0 {
			p.TTLDays, p.Sources[KnobTTLDays] = *v, SourceFile
		} else {
			badKnob(KnobTTLDays, *v, "a non-negative day count")
		}
	}
	if v := fc.DedupWindowMinutes; v != nil {
		if *v > 0 {
			p.DedupWindow, p.Sources[KnobDedupWindow] = time.Duration(*v)*time.Minute, SourceFile
		} else {
			badKnob(KnobDedupWindow, *v, "a positive minute count")
		}
	}
	if v := fc.LintTokens; v != nil {
		p.LintTokens, p.Sources[KnobLintTokens] = *v, SourceFile
	}
	return p, errors.Join(errs...)
}

// Knob is one effective_config row: the effective value with its winning
// source (MCP4-D1).
type Knob struct {
	Value  any    `json:"value"`
	Source string `json:"source"`
}

// Effective renders the per-knob report for probe.effective_config. Window
// knobs report in minutes, matching their config.json keys.
func (p Policy) Effective() map[string]Knob {
	return map[string]Knob{
		KnobWindowW:     {int(p.WindowW / time.Minute), p.Sources[KnobWindowW]},
		KnobThresholdK:  {p.ThresholdK, p.Sources[KnobThresholdK]},
		KnobQuietCap:    {p.QuietCapMinutes, p.Sources[KnobQuietCap]},
		KnobTTLDays:     {p.TTLDays, p.Sources[KnobTTLDays]},
		KnobDedupWindow: {int(p.DedupWindow / time.Minute), p.Sources[KnobDedupWindow]},
		KnobLintTokens:  {p.LintTokens, p.Sources[KnobLintTokens]},
	}
}

// ---- the wire check (MCP4-D3) ----

// The wire-check modes; strict is the default (AD-9).
const (
	WireCheckStrict = "strict"
	WireCheckWarn   = "warn"
	WireCheckSkip   = "skip"
)

// ValidWireCheck reports whether s names a wire-check mode.
func ValidWireCheck(s string) bool {
	return s == WireCheckStrict || s == WireCheckWarn || s == WireCheckSkip
}

// The computed wire verdicts (MCP4-R5). No constant or defaulted verdict is
// ever reported: WireCheck computes one, or the field stays absent.
const (
	WireAgree       = "agree"
	WireMismatch    = "mismatch"
	WireAbsent      = "absent"
	WireUnparseable = "unparseable"
	WireSkipped     = "skipped"
)

// WireCheck validates the workspace .mcp.json aaw entry against the bound
// address (MCP4-D3): the comparison target is the entry url's host:port
// (host compared case-insensitively; an elided url port reads as the scheme
// default). committed carries the entry's host:port when one parsed — the
// "-addr <committed>" direction of the strict-refusal fix. The file is ONLY
// read, never written or generated (MCP4-INV3). An absent .mcp.json or
// absent aaw entry is the verdict "absent" — never a refusal, so a fresh
// workspace boots clean under strict.
func WireCheck(workspace, boundAddr, mode string) (verdict, detail, committed string) {
	if mode == WireCheckSkip {
		return WireSkipped, "wire check skipped by -wire-check skip", ""
	}
	path := filepath.Join(workspace, ".mcp.json")
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return WireAbsent, fmt.Sprintf("no .mcp.json at %s", path), ""
	}
	if err != nil {
		return WireUnparseable, fmt.Sprintf("reading %s: %v", path, err), ""
	}
	var doc struct {
		MCPServers map[string]struct {
			Type string `json:"type"`
			URL  string `json:"url"`
		} `json:"mcpServers"`
	}
	if err := json.Unmarshal(b, &doc); err != nil {
		return WireUnparseable, fmt.Sprintf("parsing %s: %v", path, err), ""
	}
	entry, ok := doc.MCPServers["aaw"]
	if !ok {
		return WireAbsent, fmt.Sprintf("%s has no mcpServers.aaw entry", path), ""
	}
	u, err := url.Parse(entry.URL)
	if err != nil || u.Host == "" {
		return WireUnparseable, fmt.Sprintf("%s mcpServers.aaw.url %q does not parse to a host", path, entry.URL), ""
	}
	cHost, cPort := u.Hostname(), u.Port()
	if cPort == "" {
		switch u.Scheme {
		case "http":
			cPort = "80"
		case "https":
			cPort = "443"
		default:
			return WireUnparseable, fmt.Sprintf("%s mcpServers.aaw.url %q carries no port and no defaulting scheme", path, entry.URL), ""
		}
	}
	committed = net.JoinHostPort(cHost, cPort)
	bHost, bPort, err := net.SplitHostPort(boundAddr)
	if err != nil {
		return WireUnparseable, fmt.Sprintf("bound address %q: %v", boundAddr, err), committed
	}
	if strings.EqualFold(cHost, bHost) && cPort == bPort {
		return WireAgree, fmt.Sprintf("%s mcpServers.aaw.url agrees with the bound address %s", path, boundAddr), committed
	}
	return WireMismatch, fmt.Sprintf("%s mcpServers.aaw.url names %s but the bound address is %s", path, committed, boundAddr), committed
}
