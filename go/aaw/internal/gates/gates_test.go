package gates_test

import (
	"errors"
	"path/filepath"
	"testing"

	"github.com/jonny-novikov/aaw/internal/gates"
)

// MCP3-INV2 pin: the closed set is exactly the sixteen §9 codes, in table
// order, each constant equal to its wire literal — a rename, removal, or a
// seventeenth code fails here before any caller breaks.
func TestClosedCodeSet(t *testing.T) {
	want := []string{
		"SLUG_INVALID",
		"NOT_INITIALIZED",
		"LEDGER_DIR_REQUIRED",
		"LEDGER_DIR_CONFLICT",
		"PATH_ESCAPE",
		"PARENT_NOT_FOUND",
		"AGENT_UNKNOWN",
		"NOT_REGISTERED",
		"GATE_Z_REQUIRES_D",
		"ARCHIVED",
		"ARG_MISSING",
		"ARTIFACTS_REQUIRED",
		"CORRUPT_STATE",
		"INSTANCE_LOCKED",
		"PORT_BUSY",
		"WIRE_MISMATCH",
	}
	if got, wantN := len(gates.Codes), len(want); got != wantN {
		t.Fatalf("closed set holds %d codes, want %d", got, wantN)
	}
	for i, w := range want {
		if gates.Codes[i] != w {
			t.Fatalf("Codes[%d] = %q, want %q (the set is append-only, order is the §9 table)", i, gates.Codes[i], w)
		}
	}
}

// MCP3-D1: the render is exactly "aaw: <CODE>: <detail>", the extractor reads
// the code back, %w wrapping passes through, and a non-contract text reads "".
func TestErrorfRenderAndCodeExtractor(t *testing.T) {
	err := gates.Errorf(gates.SLUG_INVALID, "scope %q violates the slug rule", "Bad.Slug")
	if got, want := err.Error(), `aaw: SLUG_INVALID: scope "Bad.Slug" violates the slug rule`; got != want {
		t.Fatalf("render = %q, want %q", got, want)
	}
	if got := gates.Code(err); got != gates.SLUG_INVALID {
		t.Fatalf("Code = %q, want %q", got, gates.SLUG_INVALID)
	}

	inner := errors.New("invalid character 'n'")
	wrapped := gates.Errorf(gates.CORRUPT_STATE, "corrupt scope index %s: %w", "/x/scopes.json", inner)
	if !errors.Is(wrapped, inner) {
		t.Fatal("%w did not pass through Errorf")
	}
	if got := gates.Code(wrapped); got != gates.CORRUPT_STATE {
		t.Fatalf("Code over a wrapped refusal = %q, want %q", got, gates.CORRUPT_STATE)
	}

	for _, e := range []error{nil, errors.New("plain failure"), errors.New(`unknown tool "no_such_tool"`)} {
		if got := gates.Code(e); got != "" {
			t.Fatalf("Code(%v) = %q, want empty — only the contract form carries a code", e, got)
		}
	}
}

// MCP3-D8: the containment predicate — relative paths absolutize against the
// root, cleaning is applied, the root itself is contained, and escapes (.. or
// a sibling-prefix path) are reported with their resolved form.
func TestContainedPredicate(t *testing.T) {
	root := t.TempDir()
	outside := t.TempDir() // a sibling of root, never under it

	cases := []struct {
		name, path, resolved string
		ok                   bool
	}{
		{"relative under root", "ledger", filepath.Join(root, "ledger"), true},
		{"dot is the root", ".", root, true},
		{"nested relative", "a/b/c", filepath.Join(root, "a", "b", "c"), true},
		{"cleaned inside", "a/../b", filepath.Join(root, "b"), true},
		{"absolute under root", filepath.Join(root, "sub"), filepath.Join(root, "sub"), true},
		{"root itself", root, root, true},
		{"dot-dot escape", "..", filepath.Dir(root), false},
		{"cleaned escape", "a/../../esc", filepath.Join(filepath.Dir(root), "esc"), false},
		{"absolute outside", outside, outside, false},
		{"sibling prefix", root + "-sibling", root + "-sibling", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			resolved, ok := gates.Contained(root, tc.path)
			if resolved != tc.resolved || ok != tc.ok {
				t.Fatalf("Contained(%q, %q) = (%q, %v), want (%q, %v)", root, tc.path, resolved, ok, tc.resolved, tc.ok)
			}
		})
	}
}
