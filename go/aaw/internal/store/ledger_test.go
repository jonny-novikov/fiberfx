package store

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"testing"
)

// maxEntryN re-derives the highest <prefix>-<n> in a ledger with a scan
// independent of the production parser, so the golden does not test the
// parser with itself.
func maxEntryN(content, prefix string) int {
	re := regexp.MustCompile(`(?m)^#{2,3} ` + prefix + `-([0-9]+)\b`)
	max := 0
	for _, m := range re.FindAllStringSubmatch(content, -1) {
		if n, err := strconv.Atoi(m[1]); err == nil && n > max {
			max = n
		}
	}
	return max
}

func nonBlankLines(s string) []string {
	var out []string
	for _, l := range strings.Split(s, "\n") {
		if strings.TrimSpace(l) != "" {
			out = append(out, l)
		}
	}
	return out
}

// assertLinesSurvive checks every prior non-blank line still appears, in
// order, after the append — "prior entry bytes survive verbatim" at the
// line level (the appender only splits at blank-line seams).
func assertLinesSurvive(t *testing.T, before, after string) {
	t.Helper()
	got := nonBlankLines(after)
	i := 0
	for _, line := range nonBlankLines(before) {
		for i < len(got) && got[i] != line {
			i++
		}
		if i == len(got) {
			t.Fatalf("prior line lost or reordered: %q", line)
		}
		i++
	}
}

// MCP1-US5 parse-compat golden: the hardened store parses the committed
// hand-written exemplar ledgers, continues numbering per prefix, and loses
// no prior line.
func TestExemplarLedgerParseCompat(t *testing.T) {
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

			tallies, err := sc.Tallies()
			if err != nil {
				t.Fatal(err)
			}
			total := 0
			for _, n := range tallies {
				total += n
			}
			if total == 0 {
				t.Fatal("exemplar parsed to zero entries")
			}

			wantN := maxEntryN(string(src), "T") + 1
			id, err := sc.Append("trace", "T-0 — compat probe\n\nappended by the parse-compat golden")
			if err != nil {
				t.Fatal(err)
			}
			if want := fmt.Sprintf("T-%d", wantN); id != want {
				t.Fatalf("numbering did not continue: got %s, want %s", id, want)
			}

			after, err := os.ReadFile(sc.LedgerPath())
			if err != nil {
				t.Fatal(err)
			}
			assertLinesSurvive(t, string(src), string(after))
			if !strings.Contains(string(after), "### "+id+" — compat probe") {
				t.Fatalf("appended entry %s not present", id)
			}
		})
	}
}

// MCP1-INV1: ledger numbering stays gap-free under concurrent appends — the
// per-scope writer serializes them.
func TestLedgerConcurrentAppendsGapFree(t *testing.T) {
	st := openTempStore(t)
	sc := initScope(t, st, "gapfree")
	const M = 16
	ids := make([]string, M)
	var wg sync.WaitGroup
	for i := 0; i < M; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			id, err := sc.Append("trace", fmt.Sprintf("body %d", i))
			if err != nil {
				t.Errorf("append %d: %v", i, err)
				return
			}
			ids[i] = id
		}(i)
	}
	wg.Wait()
	seen := map[string]bool{}
	for _, id := range ids {
		seen[id] = true
	}
	for n := 1; n <= M; n++ {
		if !seen[fmt.Sprintf("T-%d", n)] {
			t.Fatalf("gap in ledger numbering: T-%d missing (got %v)", n, ids)
		}
	}
}
