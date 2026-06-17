package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/jonny-novikov/aaw/internal/gates"
)

// MCP3-D3 / MCP3-INV3: the created split. First init reports both flags true;
// re-init reports both false; a first init over a pre-existing hand-written
// ledger reports the row new but the file kept — and the v1 `created` meaning
// (the row was new) is exactly scope_created.
func TestInitScopeCreatedSplit(t *testing.T) {
	st := openTempStore(t)

	sc, scopeCreated, ledgerCreated, err := st.InitScope("alias", "op", "ledger-alias", 0)
	if err != nil {
		t.Fatal(err)
	}
	if !scopeCreated || !ledgerCreated {
		t.Fatalf("first init: scope_created=%v ledger_created=%v, want true/true", scopeCreated, ledgerCreated)
	}

	re, scopeCreated, ledgerCreated, err := st.InitScope("alias", "op", "", 0)
	if err != nil {
		t.Fatal(err)
	}
	if scopeCreated || ledgerCreated {
		t.Fatalf("re-init: scope_created=%v ledger_created=%v, want false/false", scopeCreated, ledgerCreated)
	}
	if re.LedgerDir != sc.LedgerDir {
		t.Fatalf("re-init changed the row: %s != %s", re.LedgerDir, sc.LedgerDir)
	}
	// Re-init repeating the same dir stays an idempotent re-open.
	if _, scopeCreated, _, err = st.InitScope("alias", "op", "ledger-alias", 0); err != nil || scopeCreated {
		t.Fatalf("repeat-dir re-init: created=%v err=%v", scopeCreated, err)
	}

	// A hand-written ledger is first-class input: the row is new, the file
	// pre-exists, so ledger_created is false and the bytes are untouched.
	handDir := filepath.Join(st.Workspace, "ledger-hand")
	if err := os.MkdirAll(handDir, 0o755); err != nil {
		t.Fatal(err)
	}
	handLedger := filepath.Join(handDir, "hand.progress.md")
	const handBytes = "# hand — written by the Operator\n\n### D-1 — a hand decision\n\nlocked by hand\n"
	if err := os.WriteFile(handLedger, []byte(handBytes), 0o644); err != nil {
		t.Fatal(err)
	}
	_, scopeCreated, ledgerCreated, err = st.InitScope("hand", "op", "ledger-hand", 0)
	if err != nil {
		t.Fatal(err)
	}
	if !scopeCreated || ledgerCreated {
		t.Fatalf("init over a hand ledger: scope_created=%v ledger_created=%v, want true/false", scopeCreated, ledgerCreated)
	}
	after, err := os.ReadFile(handLedger)
	if err != nil {
		t.Fatal(err)
	}
	if string(after) != handBytes {
		t.Fatal("init touched the hand-written ledger")
	}
}

// MCP3-D8 / MCP3-INV8, the store door: an out-of-root ledger_dir refuses
// PATH_ESCAPE at first init creating nothing — no index row, no directory —
// while a legacy out-of-tree row keeps reading, appending, and re-initing.
func TestInitScopePathEscapeAtTheDoor(t *testing.T) {
	st := openTempStore(t)

	// Absolute escape: a sibling temp dir is outside the workspace root.
	outside := t.TempDir()
	_, _, _, err := st.InitScope("esc-abs", "op", outside, 0)
	if got := gates.Code(err); got != gates.PATH_ESCAPE {
		t.Fatalf("absolute escape refused with %q (%v), want PATH_ESCAPE", got, err)
	}
	if _, err := st.GetScope("esc-abs"); gates.Code(err) != gates.NOT_INITIALIZED {
		t.Fatalf("the refused init created a row: %v", err)
	}

	// Relative escape: ".."-traversal out of the root; the target dir must
	// not be created.
	sibling := filepath.Join(filepath.Dir(st.Workspace), "esc-rel-ledger")
	_, _, _, err = st.InitScope("esc-rel", "op", filepath.Join("..", "esc-rel-ledger"), 0)
	if got := gates.Code(err); got != gates.PATH_ESCAPE {
		t.Fatalf("relative escape refused with %q (%v), want PATH_ESCAPE", got, err)
	}
	if _, statErr := os.Stat(sibling); !os.IsNotExist(statErr) {
		t.Fatalf("the refused init created the out-of-root dir %s (stat: %v)", sibling, statErr)
	}

	// A legacy out-of-tree row (hand-written index — files are truth) is
	// honored: reads, appends, and a repeat-dir re-init proceed, no
	// retro-refusal.
	legacyDir := t.TempDir()
	row := &Scope{Name: "legacy", Operator: "hand", Workspace: st.Workspace, LedgerDir: legacyDir, CreatedAt: Now()}
	b, err := json.MarshalIndent(map[string]*Scope{"legacy": row}, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Dir(st.indexPath()), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(st.indexPath(), b, 0o644); err != nil {
		t.Fatal(err)
	}
	sc, err := st.GetScope("legacy")
	if err != nil {
		t.Fatalf("legacy row not honored on read: %v", err)
	}
	if _, err := sc.Append("trace", "T-0 — legacy append"); err != nil {
		t.Fatalf("legacy row refused an append: %v", err)
	}
	if _, _, _, err := st.InitScope("legacy", "hand", legacyDir, 0); err != nil {
		t.Fatalf("legacy repeat-dir re-init retro-refused: %v", err)
	}
}

// entryBlocks slices a ledger into entry byte-spans with a scan independent
// of the production parser: each block runs from its entry head to the next
// heading, trimmed of trailing newlines (the splice's blank-line seam is the
// only byte run the appender may renormalize).
func entryBlocks(content string) []string {
	headRe := regexp.MustCompile(`(?m)^#{1,6} `)
	entRe := regexp.MustCompile(`^#{2,3} [A-Z]+-[0-9]+\b`)
	locs := headRe.FindAllStringIndex(content, -1)
	var out []string
	for i, l := range locs {
		line := content[l[0]:]
		if j := strings.IndexByte(line, '\n'); j >= 0 {
			line = line[:j]
		}
		if !entRe.MatchString(line) {
			continue
		}
		end := len(content)
		if i+1 < len(locs) {
			end = locs[i+1][0]
		}
		out = append(out, strings.TrimRight(content[l[0]:end], "\n"))
	}
	return out
}

// MCP3-D6 / MCP3-INV6, the lenient-in/strict-out golden over the COMMITTED
// exemplars: parsing a ledger that holds lenient forms and appending to it
// preserves every prior entry's bytes verbatim, emits only the strict
// canonical form for the new content, and continues whole-file numbering.
func TestGrammarLenientInStrictOutGolden(t *testing.T) {
	for _, scope := range []string{"emq-design", "aaw-mcp"} {
		t.Run(scope, func(t *testing.T) {
			src, err := os.ReadFile(filepath.Join("testdata", scope+".progress.md"))
			if err != nil {
				t.Fatal(err)
			}
			dir := t.TempDir()
			sc := &Scope{Name: scope, LedgerDir: dir}
			if err := os.WriteFile(sc.LedgerPath(), src, 0o644); err != nil {
				t.Fatal(err)
			}

			wantT := maxEntryN(string(src), "T") + 1
			wantD := maxEntryN(string(src), "D") + 1
			idT, err := sc.Append("trace", "T-0 — grammar golden\n\nlenient in")
			if err != nil {
				t.Fatal(err)
			}
			idD, err := sc.Append("decision", "D-0 — grammar golden\n\nstrict out")
			if err != nil {
				t.Fatal(err)
			}
			if idT != fmt.Sprintf("T-%d", wantT) || idD != fmt.Sprintf("D-%d", wantD) {
				t.Fatalf("numbering did not continue whole-file: got %s/%s, want T-%d/D-%d", idT, idD, wantT, wantD)
			}

			afterB, err := os.ReadFile(sc.LedgerPath())
			if err != nil {
				t.Fatal(err)
			}
			after := string(afterB)
			blocks := entryBlocks(string(src))
			if len(blocks) == 0 {
				t.Fatal("exemplar sliced to zero entry blocks")
			}
			for _, block := range blocks {
				if !strings.Contains(after, block) {
					head, _, _ := strings.Cut(block, "\n")
					t.Fatalf("a prior entry's bytes did not survive verbatim: %q", head)
				}
			}
			// Strict emit: the new entries carry ###-level heads only.
			for _, id := range []string{idT, idD} {
				if !strings.Contains(after, "\n### "+id+" — grammar golden\n") {
					t.Fatalf("new entry %s not emitted in the strict canonical form", id)
				}
				if strings.Contains(after, "\n## "+id+" ") {
					t.Fatalf("emission widened the lenient entry form for %s", id)
				}
			}
		})
	}
}

// MCP3-INV6 over the lenient faces explicitly: a #-level section head and a
// ##-level entry head parse as first-class; the append lands INSIDE the
// lenient section (no duplicate section is created), is emitted strictly, and
// numbering continues after the hand entry. A fresh scope's first append
// pins the strict new-section emit.
func TestLenientFacesAndStrictEmission(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "len")
	fixture := "# preamble kept verbatim\n\n# {len-thinking} Thinking\n\n## T-7 — a hand entry\n\nhand body\n"
	if err := os.WriteFile(sc.LedgerPath(), []byte(fixture), 0o644); err != nil {
		t.Fatal(err)
	}

	id, err := sc.Append("trace", "T-0 — tool entry\n\ntool body")
	if err != nil {
		t.Fatal(err)
	}
	if id != "T-8" {
		t.Fatalf("numbering after the hand T-7 = %s, want T-8", id)
	}
	afterB, err := os.ReadFile(sc.LedgerPath())
	if err != nil {
		t.Fatal(err)
	}
	after := string(afterB)
	for _, kept := range []string{"# preamble kept verbatim", "# {len-thinking} Thinking", "## T-7 — a hand entry\n\nhand body"} {
		if !strings.Contains(after, kept) {
			t.Fatalf("lenient form not preserved verbatim: %q", kept)
		}
	}
	if strings.Count(after, "{len-thinking}") != 1 {
		t.Fatal("the lenient section head was not matched — a duplicate section was created")
	}
	if !strings.Contains(after, "\n### T-8 — tool entry\n") {
		t.Fatal("the new entry was not emitted at the strict ### level")
	}

	// The strict new-section emit on a section-less ledger.
	sc2 := initScope(t, st, "fresh")
	if _, err := sc2.Append("decision", "D-0 — first entry\n\nbody"); err != nil {
		t.Fatal(err)
	}
	freshB, err := os.ReadFile(sc2.LedgerPath())
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(freshB), "\n## {fresh-decisions} Decisions\n\n### D-1 — first entry\n") {
		t.Fatalf("new section not emitted in the strict canonical form:\n%s", freshB)
	}
}

// MCP3-D7 / MCP3-INV7: a hand `### ADR-3` is tolerated as a first-class
// entry, collected at parse, and never gates — the Z-gate keeps counting D-n
// entries only.
func TestUnknownPrefixToleratedReportedNeverGates(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "adr")
	fixture := "# adr — scope ledger\n\n### ADR-3 — a hand architecture record\n\nhand-written history\n"
	if err := os.WriteFile(sc.LedgerPath(), []byte(fixture), 0o644); err != nil {
		t.Fatal(err)
	}

	tallies, unknown, err := sc.ParseHealth()
	if err != nil {
		t.Fatal(err)
	}
	if len(unknown) != 1 || unknown[0] != "ADR" {
		t.Fatalf("unknown prefixes = %v, want [ADR]", unknown)
	}
	if tallies["ADR"] != 1 {
		t.Fatalf("the ADR entry is not first-class in the tallies: %v", tallies)
	}

	// The unknown prefix never alters the Z-gate: no D-n yet, so complete
	// refuses; after a D it passes.
	if _, err := sc.Append("complete", "Z-0 — premature"); gates.Code(err) != gates.GATE_Z_REQUIRES_D {
		t.Fatalf("Z-gate over an ADR-only ledger: %v, want GATE_Z_REQUIRES_D (ADR is not D)", err)
	}
	if _, err := sc.Append("decision", "D-0 — locked"); err != nil {
		t.Fatal(err)
	}
	if _, err := sc.Append("complete", "Z-0 — done"); err != nil {
		t.Fatalf("Z after D refused: %v", err)
	}
	after, err := os.ReadFile(sc.LedgerPath())
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(after), "### ADR-3 — a hand architecture record\n\nhand-written history") {
		t.Fatal("the hand ADR entry did not survive the appends verbatim")
	}

	// Reserved prefixes report no unknowns.
	if _, unknown, err := sc.ParseHealth(); err != nil || len(unknown) != 1 {
		t.Fatalf("post-append parse health: unknown=%v err=%v, want [ADR] only", unknown, err)
	}
}
