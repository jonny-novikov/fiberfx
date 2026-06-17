package store

import (
	"fmt"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"

	"github.com/jonny-novikov/aaw/internal/gates"
)

// The locked ledger model (Operator decision, 2026-06-10): ONE file per scope,
// <ledger_dir>/<scope>.progress.md. Channel sections carry the tag
// {<scope>-<channel>} in their heading; entries are `### <PREFIX>-<n> — <title>`.
// Parse leniently (the hand-written exemplar carries one #-level section
// heading and ##-level entries are accepted), emit strictly (## sections,
// ### entries). Entries are append-only and never rewritten.
//
// The design-§8 grammar, declared (MCP3-D6) — THE single authority for
// "well-formed ledger"; this rung ratifies the as-built faces, it does not
// redesign them. EBNF (parse-lenient, emit-strict):
//
//	ledger    = [preamble], {section} ;
//	preamble  = {line} ;                        (* bytes before the first section heading; preserved verbatim *)
//	section   = sec_head, {entry | prose_line} ;
//	sec_head  = ("#" | "##"), " ", tag, [" ", title], NL ;          (* emit: "##" only *)
//	tag       = "{", scope, "-", channel, "}" ;
//	entry     = ent_head, NL, blank, body ;
//	ent_head  = ("##" | "###"), " ", prefix, "-", nat, [" — ", title], NL ;   (* emit: "###" only *)
//	prefix    = "T"|"A"|"V"|"D"|"L"|"S"|"C"|"E"|"P"|"Z"|"Y"|"R" ;   (* the closed v2 set: ReservedPrefixes *)
//
// The lenient parse faces are entryRe (entries, ^#{2,3}) and the section
// regex in appendLocked (^#{1,2}); the strict emit faces are appendLocked's
// "### " entry head and "## " new-section head. Numbering is whole-file per
// prefix (nextN): hand-written entries are first-class and never collided
// with. A hand heading matching ^#{2,3} [A-Z]+-[0-9]+ is an entry BY
// DEFINITION; a prefix outside ReservedPrefixes is tolerated, collected at
// parse (ParseHealth), surfaced by aaw_status as unknown_prefixes, and never
// gates (MCP3-D7/INV7 — the Z-gate counts D-n entries only). The preservation
// invariant (MCP3-INV6): every previously-existing entry's bytes survive any
// append; emission never widens the lenient forms.

// ReservedPrefixes is the closed v2 entry-prefix vocabulary (design §8), in
// channel-table order. Reserved means the tools own these prefixes' numbering
// domains; it does NOT mean other prefixes are rejected — unknown prefixes
// parse as first-class entries and are reported, never gating.
var ReservedPrefixes = []string{"T", "A", "V", "D", "L", "S", "C", "E", "P", "Z", "Y", "R"}

var reservedPrefixSet = func() map[string]bool {
	m := make(map[string]bool, len(ReservedPrefixes))
	for _, p := range ReservedPrefixes {
		m[p] = true
	}
	return m
}()

// IsReservedPrefix reports whether prefix is in the closed §8 vocabulary.
func IsReservedPrefix(prefix string) bool { return reservedPrefixSet[prefix] }

// Channel maps each tool_x stream to its (channel, prefix) pair.
type Channel struct {
	Name   string // section tag suffix, e.g. "decisions"
	Prefix string // entry prefix, e.g. "D"
	Title  string // section title text
}

// Channels is the closed v2 channel set (proposal §5).
var Channels = map[string]Channel{
	"trace":          {"thinking", "T", "Thinking"},
	"analyze":        {"analysis", "A", "Analysis"},
	"alternative":    {"alternatives", "V", "Alternatives"},
	"decision":       {"decisions", "D", "Decisions"},
	"learning":       {"learnings", "L", "Learnings"},
	"nxm_synthesize": {"nxm", "S", "NxM synthesis"},
	"consensus":      {"consensus", "C", "Consensus"},
	"escalation":     {"escalations", "E", "Escalations"},
	"progress":       {"progress", "P", "Progress"},
	"complete":       {"complete", "Z", "Complete"},
	"report":         {"report", "Y", "Report"},
}

// scopeLocks is the per-scope serialization domain (R-4, MCP1-D1 / ADR-3):
// one writer per scope name across ALL of the scope's files — ledger,
// registry, and messages — broadened by MCP1 from the ledger alone.
var scopeLocks sync.Map // scope name -> *sync.Mutex

func lockFor(scope string) *sync.Mutex {
	m, _ := scopeLocks.LoadOrStore(scope, &sync.Mutex{})
	return m.(*sync.Mutex)
}

var entryRe = regexp.MustCompile(`(?m)^#{2,3} ([A-Z]+)-(\d+)\b`)

// ParseHealth scans the whole ledger once: the per-prefix entry tallies (the
// as-built whole-file shape — every entry-head prefix counts, reserved or
// not) and, separated additively (MCP3-D7), the sorted prefixes outside the
// reserved §8 vocabulary. Unknown prefixes are reported, never gating.
func (sc *Scope) ParseHealth() (map[string]int, []string, error) {
	b, err := os.ReadFile(sc.LedgerPath())
	if os.IsNotExist(err) {
		return map[string]int{}, nil, nil
	}
	if err != nil {
		return nil, nil, err
	}
	t := map[string]int{}
	for _, m := range entryRe.FindAllStringSubmatch(string(b), -1) {
		t[m[1]]++
	}
	var unknown []string
	for p := range t {
		if !IsReservedPrefix(p) {
			unknown = append(unknown, p)
		}
	}
	sort.Strings(unknown)
	return t, unknown, nil
}

// Tallies counts entries per prefix across the whole ledger file.
func (sc *Scope) Tallies() (map[string]int, error) {
	t, _, err := sc.ParseHealth()
	return t, err
}

// nextN returns max(n)+1 for the prefix across the whole file (hand-written
// entries are first-class input: numbering continues after them).
func nextN(content, prefix string) int {
	max := 0
	for _, m := range entryRe.FindAllStringSubmatch(content, -1) {
		if m[1] != prefix {
			continue
		}
		if n, err := strconv.Atoi(m[2]); err == nil && n > max {
			max = n
		}
	}
	return max + 1
}

// titleSplit derives the entry title: when the body's first line is itself in
// "<PREFIX>-<k> — title" form (the hand-written convention), the title is
// lifted into the header and the duplicate line dropped.
func titleSplit(prefix, body string) (title, rest string) {
	body = strings.TrimLeft(body, "\n")
	line, tail, _ := strings.Cut(body, "\n")
	re := regexp.MustCompile(`^` + prefix + `-\d+\s*[—-]+\s*(.+)$`)
	if m := re.FindStringSubmatch(strings.TrimSpace(line)); m != nil {
		return strings.TrimSpace(m[1]), strings.TrimLeft(tail, "\n")
	}
	return "", body
}

// Append writes one entry into the scope's channel section and returns its id
// (e.g. "D-5"). The Z gate (tool_x_complete requires ≥1 D-n) is enforced here.
func (sc *Scope) Append(stream, body string) (string, error) {
	id, _, err := sc.AppendAttributed(stream, body, "")
	return id, err
}

// Attribution reports the registry-side outcome of an attributed append
// (MCP2-D1/D5). Err carries a registry-side failure and is ADVISORY: the
// ledger entry already landed (the durable record leads) and the caller must
// not refuse the tool call on it.
type Attribution struct {
	Actor        string
	Recorded     bool
	Unregistered bool
	Err          error
}

// AppendAttributed is the attributed write (MCP2-D5): under ONE per-scope
// critical section the ledger append lands first, then the registry counter
// follows — the durable audit record leads. A crash between the two files
// loses only this advisory attribution (bounded cross-file drift; the `aaw
// audit` tally-recount, a later rung's CLI, is the named detector). A client
// retry after an ambiguous failure appends a visible duplicate under the
// next n — accepted, inspectable history. An empty actor is the unattributed
// MCP1 write, byte-identical output (MCP2-INV1); an actor with no registry
// row leaves the registry untouched and reports Unregistered for the
// caller's advisory line.
func (sc *Scope) AppendAttributed(stream, body, actor string) (string, Attribution, error) {
	ch, ok := Channels[stream]
	if !ok {
		// An internal invariant error, NOT a domain refusal: the closed
		// streams table in main.go fixes every stream string, so this is
		// unreachable from the tool surface — the documented exemption from
		// the no-bare-fmt.Errorf grep gate (MCP3-D2).
		return "", Attribution{}, fmt.Errorf("unknown stream %q", stream)
	}
	mu := lockFor(sc.Name)
	mu.Lock()
	defer mu.Unlock()

	id, err := sc.appendLocked(ch, body)
	if err != nil {
		return "", Attribution{}, err
	}
	att := Attribution{Actor: actor}
	if actor == "" {
		return id, att, nil
	}
	r, rerr := sc.LoadRegistry()
	if rerr != nil {
		att.Err = rerr
		return id, att, nil
	}
	a := r.Find(actor)
	if a == nil {
		att.Unregistered = true
		return id, att, nil
	}
	a.LastSeenAt = now()
	if a.Activity == nil {
		a.Activity = map[string]int{}
	}
	a.Activity[ch.Prefix]++
	a.AttributedAt = append(a.AttributedAt, now())
	if n := len(a.AttributedAt); n > maxAttributedInstants {
		a.AttributedAt = a.AttributedAt[n-maxAttributedInstants:]
	}
	if serr := sc.saveRegistry(r); serr != nil {
		att.Err = serr
		return id, att, nil
	}
	att.Recorded = true
	return id, att, nil
}

// appendLocked is the ledger write proper; callers hold the scope lock.
func (sc *Scope) appendLocked(ch Channel, body string) (string, error) {
	raw, err := os.ReadFile(sc.LedgerPath())
	if err != nil && !os.IsNotExist(err) {
		return "", err
	}
	content := string(raw)

	if ch.Prefix == "Z" { // LAW-4 trigger: Z-n requires ≥1 locked D-n
		hasD := false
		for _, m := range entryRe.FindAllStringSubmatch(content, -1) {
			if m[1] == "D" {
				hasD = true
				break
			}
		}
		if !hasD {
			return "", gates.Errorf(gates.GATE_Z_REQUIRES_D, "tool_x_complete refused: no D-n decision is locked for scope %q (LAW-4: Z-n requires ≥1 D-n)", sc.Name)
		}
	}

	n := nextN(content, ch.Prefix)
	id := fmt.Sprintf("%s-%d", ch.Prefix, n)
	title, rest := titleSplit(ch.Prefix, body)
	header := "### " + id
	if title != "" {
		header += " — " + title
	}
	entry := header + "\n\n" + strings.TrimRight(rest, "\n") + "\n"

	tag := "{" + sc.Name + "-" + ch.Name + "}"
	secRe := regexp.MustCompile(`(?m)^#{1,2} ` + regexp.QuoteMeta(tag)) // lenient: # or ## section heading
	loc := secRe.FindStringIndex(content)
	if loc == nil {
		// New channel section at EOF (strict emit: ## heading).
		if content != "" && !strings.HasSuffix(content, "\n") {
			content += "\n"
		}
		content += "\n## " + tag + " " + ch.Title + "\n\n" + entry
	} else {
		// Insert at the end of the section: before the next #/## heading that
		// is NOT an entry heading, or at EOF.
		insertAt := len(content)
		headRe := regexp.MustCompile(`(?m)^#{1,2} `)
		for _, h := range headRe.FindAllStringIndex(content, -1) {
			if h[0] <= loc[0] {
				continue
			}
			// Skip ##-level ENTRY headings (lenient hand-written entries).
			line := content[h[0]:]
			if i := strings.IndexByte(line, '\n'); i >= 0 {
				line = line[:i]
			}
			if entryRe.MatchString(line) {
				continue
			}
			insertAt = h[0]
			break
		}
		head := strings.TrimRight(content[:insertAt], "\n")
		tail := content[insertAt:]
		joint := "\n\n" + entry
		if tail != "" {
			joint += "\n"
		}
		content = head + joint + tail
	}

	if err := writeFileAtomic(sc.LedgerPath(), []byte(content), 0o644); err != nil {
		return "", err
	}
	return id, nil
}
