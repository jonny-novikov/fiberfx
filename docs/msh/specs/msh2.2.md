# msh2.2 — frontmatter v2 + the backfill (the rung spec)

> M1 · go-code + memory-data. Derives from [msh.design.md](../msh.design.md) §3 (schema v2, D-8) + §4
> (invariants) and the [msh.roadmap.md](../msh.roadmap.md) msh2.2 row; settles Seam S-2 (§3 here) and
> executes the S-4 fence (§5). Stories: [msh2.2.stories.md](./msh2.2.stories.md); brief:
> [msh2.2.llms.md](./msh2.2.llms.md). Boundary: `go/msh` + the one fenced `memory/` backfill. All cited
> lines and the corpus census verified 2026-07-02.

## §1 · Goal

Frontmatter v2 (D-8) in four moves plus one fenced data edit: **(a)** the parser reads three new contract
keys — `project` (scoping), `status` (declared supersession), `review_after` (review date) — top-level
only (§3.1); **(b)** `memory_scan` + `memory_stale` gain a project filter (CLI `--project`, additive MCP
`project` param); **(c)** a declared `status:` becomes the source of truth and the 1KB body sniff demotes
to fallback, firing only when the key is absent; **(d)** a NEW `REVIEW-DUE` stale rule consumes
`review_after` day-one under an injected reference date (§3.5). **(e)** The 70-note backfill keys the
live corpus as a staged, byte-diffed sub-rung (§5). SHIPS: scoped scans; declared supersession;
review-due findings; an honestly-keyed corpus.

## §2 · The ground, verified

| Fact | Where |
|---|---|
| `Status` enum `active`/`superseded`; `Node.Status` serialized | `go/msh/memory/internal/graph/node.go:15-20,29` |
| The sniff sets status from the first 1KB of body | `go/msh/memory/command/corpus.go:62-64,125-142` |
| Parser precedent: top-level beats nested `metadata:` (coalesce) | `go/msh/memory/internal/frontmatter/parse.go:74-79,87-95` |
| Normalization precedent: lowercase + trim | `go/msh/memory/command/corpus.go:85` |
| Flag surfaces the filter joins | `go/msh/memory/command/scan.go:41` · `stale.go:55-57` |
| Rule registry: `Rule{Name, Apply(g,cfg,src)}`, one file per rule | `go/msh/memory/internal/stale/rules.go:17-44` |
| A rule consuming `Node.Status` | `go/msh/memory/internal/stale/rule_supersede_cycle.go:16` |
| MCP registrations gaining the param | `go/msh/cmd/main.go:225-234` (stale) · `:247-256` (scan) |
| Shared CLI/MCP wrappers | `go/msh/memory/command/ops.go:20,80,118` |
| The tool pin: exactly 8, by name set | `go/msh/cmd/mcp_test.go:236-263` |
| Audit doc-vs-code: Long promises any-error exit; code checks DEAD-TARGET only | `go/msh/memory/command/audit.go:17` vs `:44` |

**The corpus (as-shipped 2026-07-02):** 71 notes + `memory/MEMORY.md` (the hand index — never touched by
tooling) = 72 files: 46 flat + `aaw/` 5 + `courses/` 3 + `echo_graft/` 1 + `echo_mq/` 9 + `elixir/` 7.
The roadmap row's "69-note backfill" was the genesis-day count; the corpus gained two notes since (the
latest, `codemojex-write-suite.md`, during this very run) — the backfill derives its enumeration at apply
time, so the count drift self-heals.
ZERO v2 keys present. **The sniff census: 0 notes** — a live `msh memory scan` reports every node
`active`; the only two supersession markers sit far past the 1KB window and mark inner sections, not the
note (`redis-reframe-echomq.md:157`, `courses/echomq-course-spec.md:46`). The one declared tombstone
(`echo_mq/echomq-umbrella-app.md`) frames its content "Residual facts still true" — an active note about
a removed thing, not a superseded note (§5 R-3).

## §3 · The contract decisions (Seam S-2 settled here)

### §3.1 · Placement: top-level, exclusively

The three v2 keys live **top-level**, beside `name`/`description`; they are never read from `metadata:`.
Design §3 names them CONTRACT keys — the corpus keeps non-contract provenance (`node_type`,
`originSessionId`) nested, and a contract key is first-class. The coalesce precedent exists to serve an
EXISTING nested convention; the new keys have zero corpus presence (§2), so a dual read would double the
contract surface with no legacy to serve. A v2 key spelled under `metadata:` is not read; the degrade
order (§3.3) governs such a note, and the scan surface makes the miss visible.

### §3.2 · Arity: scalar (S-2a)

`project:` is ONE slug. A list-valued project is the deferred `tags` key by another name —
multi-membership re-entering through the scoping key would bypass the D-8 ruling. The corpus straddlers
(e.g. `memory/cm-ship-program.md`, spanning codemojex-node + mercury + the echo engine) already carry the
cross-program thread as `[[links]]` — a straddler declares its PRIMARY program and the graph carries the
rest. The degrade source (a directory name) is inherently scalar, and exact-match filtering stays
deterministic.

### §3.3 · The degrade order + filter semantics (S-2b — the roadmap candidate confirmed, made precise)

`effective_project(note)`, computed in ONE place at corpus load:

1. the declared top-level `project:`, normalized lowercase + trimmed (the `corpus.go:85` precedent), when
   non-empty;
2. else the FIRST PATH SEGMENT of the note's root-relative path when the note lives in a subdirectory
   (`echo_mq/foo.md` → `echo_mq`; the containing-directory name at depth 1, defined for any depth);
3. else — flat at the root and keyless — **unscoped**: the empty value.

`--project P` / MCP `project` selects nodes with `effective_project == P` (both sides normalized). An
unscoped note matches NO filter and appears only in unfiltered output; no reserved unscoped selector ships
(§7). `MEMORY.md` carries no frontmatter and stays unscoped forever. **Scan filters the node rows. Stale
post-filters the findings**: rules always run over the FULL graph, then findings are kept when their
`File`'s effective project equals `P`. Pre-filtering the graph would invent findings (a node linked only
from another project would false-report `ORPHAN`) — the filter is a view, never a different corpus.

### §3.4 · `status:` semantics

Values: exactly the shipped enum — `active` | `superseded` (`node.go:15-20`; no third value invented),
normalized lowercase + trimmed. Precedence, per the design's coalesce framing (D-8): a present + valid key
IS the status — `status: active` pins a note active even where the body sniff would fire, and
`status: superseded` declares supersession the sniff cannot see; the sniff runs ONLY when the key is
absent, byte-unchanged as the fallback. A present + INVALID value is NOT a declaration: the node records a
deterministic `FrontmatterError` (visible in scan output) and the sniff fallback governs — an unreadable
declaration degrades loudly to the old behavior, never silently to a guess.

### §3.5 · `review_after:` + the `REVIEW-DUE` rule

Format `YYYY-MM-DD` (Go layout `2006-01-02`, on the trimmed value). The rule — registry name `REVIEW-DUE`
(the `rules.go:22-30` name family), file `rule_review_due.go`:

- present + parseable + **ref ≥ review_after** → one **warn** finding per note (`File` = the note, `Line`
  1, `Target` = the date; the message names date + ref) — visible at the default warn filter and in the
  audit's warn+ print, never failing the audit exit (advisory tier);
- present + unparseable → one **error** finding (`invalid review_after`) — the audit gate catches a bad date;
- superseded nodes are skipped (a dead note carries no review obligation); keyless nodes yield nothing.

**Determinism (design §4.3, addressed head-on):** the rule NEVER reads the wall clock. The reference date
is an explicit, day-granular parameter — `stale.Run` (`rules.go:44`) grows it, and the production callers
(`ops.go:80,118` + the cobra stale/audit commands) compute it ONCE per invocation as the current UTC date.
Contract: same corpus + same query + **same reference date** → byte-identical findings; production output
may change only at a UTC day boundary. Golden fixtures inject fixed dates and stay byte-stable forever.
Due fires ON the named day (`review_after: 2026-08-01` fires 2026-08-01) — delay-by-one buys nothing.

## §4 · Deliverables (the go-code half)

1. **Parser v2**: `Frontmatter` (`parse.go:10-15`) + `rawFrontmatter` gain `Project`, `Status`,
   `ReviewAfter` (strings), read top-level only (§3.1); the old keys' nested coalesce untouched.
2. **Node surface**: `graph.Node` (`node.go:22-34`) gains `Project` + `ReviewAfter` (omitempty JSON tags);
   `loadCorpus` (`corpus.go:43-64`) computes `effective_project` into `Node.Project`, applies the §3.4
   precedence, and records the invalid-status `FrontmatterError`.
3. **Scoped scan**: `--project` flag beside `scan.go:41` + `scanArgs.Project` (`main.go:201-204`) +
   `ops.Scan` (`ops.go:20`) grows the param; one shared node filter in `command`; `PrettyScan`
   (`render/pretty.go:15,23`) gains a PROJECT column after STATUS; NDJSON carries the fields via tags.
4. **Scoped stale**: `--project` beside `stale.go:55-57` + `staleArgs.Project` (`main.go:189-195`) +
   `ops.Stale` (`ops.go:80`) grows the param; findings post-filtered per §3.3. `memory_audit` stays
   unscoped — the whole-corpus gate.
5. **`REVIEW-DUE`**: `rule_review_due.go` + the registry row (`rules.go:32-42`); `AllRules`/`Run` grow the
   injected reference date (§3.5); callers supply the UTC-day production default.
6. **Audit exit honesty**: the exit trigger becomes ANY error-severity count > 0, aligning `audit.go:44`
   to its own contract line (`audit.go:17`); `DEAD-TARGET` (error, `rule_dead_target.go:35`) stays
   covered; an invalid `review_after` now fails audit alike. Live corpus: 0 errors — no behavior change
   at HEAD.
7. **Docstring sync**: the scan + stale tool descriptions (`main.go:227,249`) name the new metadata and
   rule; the CLI Long strings likewise; no tool renamed.
8. **The pin stays 8**: no new tool this rung — `TestToolCountPin` (`mcp_test.go:236-263`) is untouched
   and must stay green as-is.

## §5 · The backfill sub-rung (the memory-data half; S-4 fenced)

The one scoped `memory/` mass edit, pre-announced at Seam S-4 and re-confirmed at M1-open. The manual's
memory-data ladder ([program §3](../program/msh.program.md)) binds verbatim.

- **The script is a throwaway**: it lives in the session scratchpad, is never committed, and never enters
  `go/msh` — msh stays read-only (design §4.1); the script is the Operator-reviewed hand, not a write path.
- **Backup first**: the whole `memory/` tree copied aside before any write.
- **Mechanics: text-insertion only** — the `project:` line inserted immediately BEFORE the `metadata:`
  line (the corpus-uniform anchor, safe against wrapped `description:` values); no YAML reserialization
  (it churns quoting/key order and drowns the review). Every hunk in the byte-diff is a pure one-line
  insertion.
- **R-1 — the 25 dir notes**: `project:` = the directory name verbatim (`aaw`, `courses`, `echo_graft`,
  `echo_mq`, `elixir`). Declared equals degraded today; the scope survives a future flattening.
- **R-2 — the 46 flat notes**: `project:` = the note's primary program slug from the closed vocabulary the
  brief carries (the program's docs-tree / ship-command name: `mercury`, `codemojex`, `msh`, `aaw`, …).
  The full note→slug table is EMITTED by the script as a dry-run artifact and Director-reviewed BEFORE
  apply — the rules are the authority; the enumeration derives at apply time against the live tree.
- **R-3 — `status:`**: written ONLY where the sniff fires today or a note is a declared tombstone. The
  census (§2): the sniff fires nowhere; the one tombstone is ruled ACTIVE (its residual facts are
  load-bearing — a superseded mark would demote a live gotcha under msh2.3's staleness demotion). **The
  backfill writes ZERO `status:` keys** — restated for Director confirmation at the dry-run review.
- **R-4 — `review_after:`**: ZERO keys. Review dates are per-note Operator judgment, not a mechanical
  rule; the key enters the corpus organically. The rule ships fixture-proven (G-6), not corpus-exercised.
- **The dirty-tree carve-out (as-shipped: SIX files; the tree moved mid-run)**: at commit time the
  Operator's uncommitted `[memory]` batch spanned `memory/MEMORY.md`, `memory/codemojex-program.md`,
  `memory/mercury-design-system.md`, `memory/mercury-dual-vitest-jestdom-trap.md` (tracked edits) plus
  `memory/codemojex-write-suite.md` + `memory/mercury-visual-regression-harness.md` (untracked) —
  `mercury-dual-vitest-jestdom-trap.md` joined the batch AFTER the backfill's backup, so the carve-out grew
  from the three Venus foresaw to six. The backfill keys the four dirty NOTES on disk like every other
  note, but the rung's backfill commit is the git-computed pure-insertion set (`git diff --numstat` == `1
  0`), which self-excludes any note the Operator also touched — their `project:` lines ride the Operator's
  own batch. `MEMORY.md` is not keyed at all.

## §6 · Invariants held

- **Read-only (design §4.1)**: msh gains no write path; the backfill hand is a scratchpad script,
  discarded after apply. **One authority (§4.2)**: `effective_project` computed once at corpus load;
  every surface reads `Node.Project`. **Determinism (§4.3)**: the reference date is injected (§3.5);
  goldens pin bytes; finding order stays `sortFindings` (`rules.go:68-81`), untouched. **Additive-minor
  (§4.4)**: both tools grow one optional param; nothing renamed, removed, or narrowed; the pin stays 8.
  **Scope fences (§4.6)**: `go/msh` + the §5 fence; nothing else.

## §7 · Boundary + non-goals

Boundary: `go/msh` + the one fenced `memory/` backfill (§5). Non-goals, each ruled or deferred: no `tags`
key (D-8 — miss-log trigger); no nested `metadata:` read for v2 keys (§3.1); no unscoped-selector flag; no
`--ref-date` CLI flag (the injection is internal; an additive flag can follow a real use); no sniff
removal (demoted, not deleted); no `memory_search` / scorer (msh2.3); no snapshot (msh2.4); no new MCP
tool; no `MEMORY.md` edit; no anchor change.

## §8 · Gates (the closed list)

The go-code ladder ([program/msh.program.md](../program/msh.program.md) §3), verbatim:

```bash
cd go/msh
GOWORK=off go build -o "$TMPDIR/msh-gate" ./cmd   # NEVER bare ./... — cmd output collision
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l . | grep -v vendor   # expect silence
make mcp                      # repo root: mcpd hot-swap :8899 — NEVER pkill a live server
# client /mcp reconnect → one live smoke call (G-9)
```

The memory-data ladder (program §3), verbatim, for §5: backup → staged script → byte-diff review →
`msh memory audit` = 0 errors before AND after → `git diff memory/` reviewed by the Operator →
`MEMORY.md` untouched by tooling. Before AND after-leg both green as-shipped: 72 files, error=0 warn=0 info=1.

Rung extras (each a test in the suite unless marked):

- **G-1** parser: the three keys parse top-level; a v2 key nested under `metadata:` is ignored.
- **G-2** scoped scan counts (fixture): unfiltered = N; `--project P` returns exactly the P subset;
  unscoped notes excluded from every filter; the MCP `project` param returns the same rows.
- **G-3** scoped stale post-filter: a fixture where project P links into project Q shows NO invented
  finding under `--project P` vs the unfiltered run.
- **G-4** degrade order: a keyless subdirectory note scopes to its first path segment; a keyless flat
  note is unscoped.
- **G-5** status precedence: declared `active` + sniff-positive body → active; declared `superseded` +
  clean body → superseded; keyless sniff-positive → superseded (the fallback regression); invalid →
  `FrontmatterError` + fallback.
- **G-6** `REVIEW-DUE` golden fixture (under `go/msh/memory/testdata/`, fixed injected ref): due /
  not-yet / boundary (ref == date) / invalid date / superseded-skip — byte-stable across runs.
- **G-7** audit exit: any error-severity finding exits non-zero (D6).
- **G-8** the pin stays 8: `TestToolCountPin` green, untouched.
- **G-9** live smoke after `make mcp`: `memory_scan {project: "echo_mq"}` over MCP returns exactly the
  echo_mq-scoped rows (the 9 `echo_mq/` dir notes at the census; the count re-pins from the applied
  R-2 table if it maps a flat note in).
- **G-10** backfill (marked: ledger evidence, not a suite test): every note carries `project:` (a grep
  total over `memory/**/*.md` minus `MEMORY.md`); the byte-diff is pure frontmatter insertions; scan
  STATUS values byte-identical pre/post; audit after-leg = 0 errors, counts unchanged from the before-leg.

## §9 · Traceability

| Deliverable | Stories | Gates |
|---|---|---|
| D1 parser v2 (top-level) | S-1, S-7 | G-1 |
| D2 node surface + effective project | S-4, S-5 | G-4, G-5 |
| D3 scoped scan (CLI + MCP + render) | S-1, S-2 | G-2, G-9 |
| D4 scoped stale (post-filter) | S-3 | G-3 |
| D5 REVIEW-DUE + injected ref | S-8, S-10 | G-6 |
| D6 audit exit honesty | S-9 | G-7 |
| D7 docstring sync | S-11 | (review) |
| D8 pin stays 8 | S-11 | G-8 |
| §5 backfill (R-1..R-4 + carve-out) | S-12, S-13 | G-10 + the memory-data ladder |
| (regression) sniff fallback | S-6 | G-5 |
