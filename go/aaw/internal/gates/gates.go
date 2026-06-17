// Package gates is the AD-12 gate plane: the closed error vocabulary
// (design §9) every domain refusal renders through, and the containment
// predicate behind the PATH_ESCAPE boundary gate (MCP3-D1, MCP3-D8).
//
// The contract (AD-7): every domain refusal is an IsError tool result whose
// text is "aaw: <CODE>: <detail>" with <CODE> from the closed set below. The
// code is the contract a caller branches on; the detail is prose and may be
// reworded freely. Codes are APPEND-ONLY (MCP3-INV2): a rung may add a
// constant, never rename, retype, or remove one. Protocol failures
// (malformed JSON-RPC, unknown tool) stay the SDK's and never carry an
// aaw: code (MCP3-INV5).
package gates

import (
	"fmt"
	"path/filepath"
	"strings"
)

// The sixteen §9 codes. Constant names equal their wire literals — the §9
// table is the one authority for code → raised-by → meaning.
const (
	SLUG_INVALID        = "SLUG_INVALID"        // init, ledger writers: scope/channel violates ^[a-z0-9][a-z0-9-]*$
	NOT_INITIALIZED     = "NOT_INITIALIZED"     // every scope-bound tool: scope unknown — call aaw_init first
	LEDGER_DIR_REQUIRED = "LEDGER_DIR_REQUIRED" // aaw_init: first init without ledger_dir
	LEDGER_DIR_CONFLICT = "LEDGER_DIR_CONFLICT" // aaw_init: re-init names a different ledger_dir
	PATH_ESCAPE         = "PATH_ESCAPE"         // aaw_init, aaw_spawn (tool_x_resonance later): a path resolves outside the workspace root
	PARENT_NOT_FOUND    = "PARENT_NOT_FOUND"    // aaw_spawn: parent_id matches no registry row
	AGENT_UNKNOWN       = "AGENT_UNKNOWN"       // agent_heartbeat: named agent has no registry row
	NOT_REGISTERED      = "NOT_REGISTERED"      // agent_send: recipient absent or never registered
	GATE_Z_REQUIRES_D   = "GATE_Z_REQUIRES_D"   // tool_x_complete: zero D-n in the ledger (the LAW-4 trigger)
	ARCHIVED            = "ARCHIVED"            // RESERVED: MCP7's archival rung ships the write-refusal WITH its re-open path; no emitter this rung
	ARG_MISSING         = "ARG_MISSING"         // several: a required parameter is empty (incl. the cardinal task_id + slug rule)
	ARTIFACTS_REQUIRED  = "ARTIFACTS_REQUIRED"  // RESERVED: tool_x_resonance (the resonance rung); no emitter this rung
	CORRUPT_STATE       = "CORRUPT_STATE"       // any: an index/registry file failed to parse — refuse rather than overwrite
	INSTANCE_LOCKED     = "INSTANCE_LOCKED"     // boot, not a tool error: a second instance on the same workspace (store/lock.go)
	PORT_BUSY           = "PORT_BUSY"           // RESERVED: the MCP4 boot refusal (a loopback family could not be bound); no emitter this rung
	WIRE_MISMATCH       = "WIRE_MISMATCH"       // RESERVED: the MCP4 boot refusal (.mcp.json disagrees under -wire-check strict); no emitter this rung
)

// Codes is the closed set in §9 table order — the append-only pin the
// constant-set test asserts against.
var Codes = []string{
	SLUG_INVALID,
	NOT_INITIALIZED,
	LEDGER_DIR_REQUIRED,
	LEDGER_DIR_CONFLICT,
	PATH_ESCAPE,
	PARENT_NOT_FOUND,
	AGENT_UNKNOWN,
	NOT_REGISTERED,
	GATE_Z_REQUIRES_D,
	ARCHIVED,
	ARG_MISSING,
	ARTIFACTS_REQUIRED,
	CORRUPT_STATE,
	INSTANCE_LOCKED,
	PORT_BUSY,
	WIRE_MISMATCH,
}

// Errorf renders a domain refusal in the contract form
// "aaw: <CODE>: <detail>" (AD-7). %w wrapping passes through to fmt.Errorf,
// so a CORRUPT_STATE refusal keeps its underlying parse error in the chain.
func Errorf(code, format string, args ...any) error {
	return fmt.Errorf("aaw: "+code+": "+format, args...)
}

// Code reads the closed-set code back out of a refusal — the extractor the
// exact-code tests branch on. A text outside the contract form (a protocol
// error, a bare string) reads back "".
func Code(err error) string {
	if err == nil {
		return ""
	}
	rest, found := strings.CutPrefix(err.Error(), "aaw: ")
	if !found {
		return ""
	}
	code, _, found := strings.Cut(rest, ": ")
	if !found {
		return ""
	}
	return code
}

// Contained is the MCP3-D8 containment predicate: path, absolutized against
// root and cleaned, is reported under-root or escaping. Containment requires
// a separator boundary — a sibling-prefix path (<root>-x) escapes. The same
// predicate backs both faces of the gate: PATH_ESCAPE refuses a new
// out-of-root path at the init/spawn doors; the CONTAINMENT advisory reports
// (never refuses) a write to a legacy out-of-tree scope.
func Contained(root, path string) (resolved string, ok bool) {
	root = filepath.Clean(root)
	if !filepath.IsAbs(path) {
		path = filepath.Join(root, path)
	}
	resolved = filepath.Clean(path)
	return resolved, resolved == root || strings.HasPrefix(resolved, root+string(filepath.Separator))
}
