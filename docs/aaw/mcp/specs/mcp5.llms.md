# MCP5 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology, and
> a self-contained build brief. Pairs with the spec mcp5.md and the stories mcp5.stories.md; this rung
> has no runbook — the comprehensive implementation prompt below is the complete build instruction.

## References

- `apps/aaw/cmd/aaw/main.go` — the CLI face, as built: `:33` `flag.Parse()`, `:34-37` the mode word
  (default `serve`, `flag.Arg(0)`), `:38-45` the dispatch switch (`serve` `:39-40`, `selftest`
  `:41-42`, the usage line + exit 2 at `:43-45`) — this rung adds the `reconcile` case and extends the
  usage line. **Invocation is flags-first** (ledger L-5: `flag.Parse` stops at the first non-flag word,
  so flags after the mode silently no-op) — every doc, test, and example in this rung writes
  `aaw -workspace <dir> reconcile <path>…`.
- The run ledger [`../aaw-mcp.progress.md`](../aaw-mcp.progress.md) — **D-14** (the promotion
  directive this rung executes: "mcp5 is promoted to the Reconcile tool rung"; ratification follows
  the spec pass), **D-12** (the formation whose Venus-iteration stage this rung instruments), **D-3**
  (the tool-fatigue precedent: corpus capabilities ride the CLI and ordinary Read/Grep, never a
  dedicated MCP tool — the rule this rung's zero-tool form honors), **L-5** (flags-first).
- The design [`../aaw.mcp.design.md`](../aaw.mcp.design.md) — **§10** (the `aaw audit` zero-MCP-tool
  CLI pattern this rung follows: read-only, no fix mode, findings for a human), **AD-12** (the package
  layout `internal/reconcile/` extends by one seam), **§14** ("deterministic-only intelligence" — the
  foreclosure the classifier honors), **AD-6** (the catalog this rung deliberately does not touch).
- The reconcile discipline (normative upstream): the venus agent charter (`.claude/agents/venus.md` —
  claim extraction and the MATCH / STALE / INVENTED / MISSING / DEFERRED classification) and the
  framework [`../../aaw.framework.md`](../../aaw.framework.md). The CLI mechanizes the EXISTENCE half
  (MATCH / STALE / MISSING); INVENTED and DEFERRED stay agent judgments — a cited-but-absent surface
  is MISSING to the machine, and whether it was invented or deliberately deferred is semantic.
- Depends on mcp1 by id (the repository conventions only — the package reads the tree directly; no
  store, signals, gates, or config dependency; mcp2–mcp4 are not required at build time).

## Requirements

- **MCP5-R1** — the claim grammar is specified in one documented home in `internal/reconcile/` and the
  extractor recognizes exactly three claim kinds over markdown input: (a) cite tokens
  `<path>:<n>` / `<path>:<n>-<m>`, (b) relative markdown links, (c) backticked workspace-relative
  paths; claims dedup per input file. [US: MCP5-US-A1]
- **MCP5-R2** — every claim is probed read-only against the `-workspace` tree (existence; line cites
  additionally `n ≤ lines` and `m ≤ lines`) and classified MATCH (exists, in range) / STALE (exists,
  out of range) / MISSING (absent); a probe target resolving outside the workspace is reported
  contained-refused and never read. [US: MCP5-US-A1]
- **MCP5-R3** — `aaw -workspace <dir> [-json] reconcile <path>…` (flags-first, L-5): per-file delta
  table (claim · kind · status) + tallies; `-json` renders the same content machine-readable; exit
  codes — 0 all MATCH, 1 any STALE or MISSING, 2 usage error or an input outside the workspace; the
  usage line at `cmd/aaw/main.go:44` extends to name the mode. [US: MCP5-US-A2]
- **MCP5-R4** — every output, text and json, carries the limit line: MATCH = existence + line-range
  only; semantic agreement is the reconciling agent's verdict; the classifier emits no class beyond
  the three named. [US: MCP5-US-D1]
- **MCP5-R5** — the package contains no write path: a run creates, modifies, and deletes nothing; the
  report goes to stdout/stderr only; the containment check on inputs precedes any probe.
  [US: MCP5-US-D2]
- **MCP5-R6** — zero MCP surface change: no tool registered, no schema touched; the selftest tool
  count stays 18 and every existing shape is unchanged. [US: MCP5-US-A3]
- **MCP5-R7** — the harness pins the rung: table-driven extractor tests; classifier goldens over
  committed fixtures (≥1 STALE line cite, ≥1 MISSING path, ≥1 contained-refused target); a
  byte-determinism case (two runs over an unchanged tree compare equal); all green under
  `go test -race -count=1`. [US: MCP5-US-D3]

## Execution topology

Runtime: a one-shot CLI pass — parse flags, resolve + contain inputs, extract claims, probe the tree
read-only, classify, render, exit. No server, no store, no locks, no network.

```text
aaw -workspace <dir> [-json] reconcile <path>… 
  ──▶ contain inputs (escape ⇒ exit 2, nothing probed)
  ──▶ per input: read markdown ──▶ extract claims {cite | link | path} (dedup)
  ──▶ per claim: resolve under -workspace ──▶ stat/read-count ──▶ MATCH | STALE | MISSING
                                   └─ escapes ⇒ contained-refused (reported, never read)
  ──▶ render: per-file table + tallies + the limit line   (-json: same content)
  ──▶ exit 0 (all MATCH) | 1 (drift) | 2 (usage/containment)
```

Tasks (each step leaves the app compiling):

```text
1. internal/reconcile/grammar.go: the documented claim grammar + the extractor (3 kinds, dedup)
   ─▶ 2. internal/reconcile/probe.go: resolve-under-workspace + stat/line-count + the classifier
   ─▶ 3. internal/reconcile/report.go: table + tallies + the limit line; the -json shape
   ─▶ 4. cmd/aaw/main.go: the `reconcile` case in the :38 switch + flag -json + the usage line
   ─▶ 5. fixtures + goldens: testdata/ specs incl. STALE, MISSING, contained-refused; extractor
         table tests; the byte-determinism case
   ─▶ 6. the close demo: run over docs/aaw/mcp/specs/ triads; record the verdict at rung close
```

Touched files: `apps/aaw/internal/reconcile/` (new — `grammar.go`, `probe.go`, `report.go`,
`reconcile_test.go`, `testdata/`), `apps/aaw/cmd/aaw/main.go` (the mode word + `-json` + usage),
tests. No MCP tool registration, no store/signals/gates change, no `apps/mcp-go`.

## Agent stories

- **MCP5-AS1** [implements MCP5-US-A1] — Directive: create `internal/reconcile/` with the documented
  claim grammar and the extractor for the three claim kinds, deduping per input file. Acceptance gate:
  table-driven extractor tests cover all three kinds + dedup; `go build ./...` clean.
- **MCP5-AS2** [implements MCP5-US-A1] — Directive: add the prober + classifier — resolve each claim
  under `-workspace`, probe read-only (existence; line-range for cites), classify MATCH / STALE /
  MISSING; report out-of-workspace targets contained-refused without reading them. Acceptance gate:
  classifier goldens over the fixture set (STALE + MISSING + contained-refused) green.
- **MCP5-AS3** [implements MCP5-US-A2] — Directive: wire the `reconcile` mode word into the
  `cmd/aaw/main.go:38` dispatch (flags-first per L-5), with the per-file table, tallies, `-json`, the
  0/1/2 exit contract, and the extended usage line. Acceptance gate: exit-code assertions over fixture
  specs (0, 1, and 2 paths each exercised once).
- **MCP5-AS4** [implements MCP5-US-D1, MCP5-US-D2] — Directive: embed the limit line in both renderers;
  verify by construction that the package holds no write call (no os.Create/WriteFile/Rename/Remove);
  containment precedes probing. Acceptance gate: output-content assertions (text + json carry the limit
  line); a tree-hash comparison before/after a run is equal; a grep over `internal/reconcile/` finds no
  write API.
- **MCP5-AS5** [implements MCP5-US-D3, MCP5-US-A3] — Directive: commit the fixture corpus + goldens and the
  byte-determinism case; run the suite under `-race`; run the live-docs demo over this chapter's triads
  and record the verdict for the rung close. Acceptance gate: `go test -race -count=1 ./...` green;
  `aaw selftest` green at 18 tools; the demo output captured.

## Execution plan — first two stories

1. **MCP5-AS1 — the grammar + extractor.** `internal/reconcile/grammar.go` (the three claim kinds as
   one documented grammar + extraction with dedup) + table tests. Gate: extractor tests green;
   `go build ./...` clean.
2. **MCP5-AS2 — the prober + classifier.** `internal/reconcile/probe.go` (resolve-under-workspace,
   stat + line count, MATCH/STALE/MISSING, contained-refused) + the fixture goldens. Gate: goldens
   green over STALE, MISSING, and contained-refused fixtures.

## Comprehensive implementation prompt

```text
Build MCP5 — the Reconcile tool — as a read-only CLI subcommand over the as-built aaw binary. Edit
apps/aaw only; register NO MCP tool; do not touch apps/mcp-go; run no git. Execute the agent stories
in order, AS1 -> AS5.

AS1 — the grammar. New package apps/aaw/internal/reconcile. Document the claim grammar in one home
(grammar.go) and implement extraction over markdown bytes for exactly three claim kinds: (a) cite
tokens <path>:<n> and <path>:<n>-<m> (path = a workspace-relative file token; n, m = positive line
numbers); (b) relative markdown links (the parenthesized target of a markdown link, fragment
stripped, http and https targets skipped); (c) backticked workspace-relative paths (a code span that
parses as a relative path with a directory separator or a known source extension). Dedup claims per
input file.

AS2 — the probe + classifier. For each claim, resolve against the -workspace root (clean + join;
absolute inputs must sit under the root). A target resolving outside the workspace is
contained-refused: reported with that status, never read. Otherwise probe READ-ONLY: stat for
existence; for line cites, count lines and require n <= lines (and m <= lines when present). Classify:
MATCH (exists, in range) | STALE (exists, line out of range) | MISSING (absent). No other class
exists.

AS3 — the CLI face. Add the `reconcile` case to the mode switch in apps/aaw/cmd/aaw/main.go:38
(beside serve/selftest) and extend the usage line at :44. Invocation is FLAGS-FIRST (ledger L-5):
aaw -workspace <dir> [-json] reconcile <path>... — flags after the mode word silently no-op in
stdlib flag, so docs and tests never write them there. Render the per-file delta table
(claim - kind - status), the tallies, and the limit line; -json renders the same content as one JSON
document. Exit 0 when every claim is MATCH; exit 1 when any claim is STALE or MISSING; exit 2 on a
usage error or an input path outside the workspace (refused before any probe).

AS4 — honesty + safety. The limit line appears in EVERY output, text and json: "MATCH verifies
existence and line-range only; whether the cited site asserts the claim is the reconciling agent's
verdict." The package contains no write path: no os.Create, os.WriteFile, os.Rename, os.Remove,
os.MkdirAll anywhere under internal/reconcile/ (pin with a grep assertion in the tests). Containment
checks precede probing.

AS5 — the harness + demo. Commit testdata/ fixtures including at least one STALE line cite, one
MISSING path, and one contained-refused target; golden the classifier + renderer output; add the
byte-determinism case (run twice over an unchanged tree, compare byte-equal). Then run the live demo:
aaw -workspace /path/to/repo reconcile docs/aaw/mcp/specs/mcp1.md docs/aaw/mcp/specs/mcp3.md and
capture the verdict for the rung close.

End on the gates: GOWORK=off go build ./... clean; GOWORK=off go vet ./apps/aaw/... clean;
GOWORK=off go test -race -count=1 ./apps/aaw/... green (extractor tables, classifier goldens,
exit-code cases, limit-line assertions, no-write-API grep, byte-determinism); aaw selftest green at
18 tools (zero tool-surface change); apps/mcp-go untouched; the tree byte-identical after every test
run; never git. Report the modules changed, the gate results, the demo verdict, and confirmation that
no MCP tool, schema, or error code was added.
```

Spec: mcp5.md · Stories: mcp5.stories.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
