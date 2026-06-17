# MCP5 · the Reconcile tool

> The reconcile stage of the Author/Operator loop, given a machine: `aaw reconcile` — a deterministic,
> read-only CLI subcommand (the design-§10 `aaw audit` zero-MCP-tool pattern, the D-3 tool-fatigue
> precedent) that extracts every `file:line` cite, relative link, and workspace path a spec claims,
> probes the real tree, classifies each claim MATCH / STALE / MISSING, and renders the delta table the
> pre-build reconcile runs on. Adds no MCP tool; the catalog is untouched.

## Goal

The fifth rung of the build ladder, inside milestone M2: mechanize the mechanical half of the reconcile
discipline. Every rung's pre-build sharpening (the D-12 formation: Venus iteration = pre-build reconcile
+ brief refresh against HEAD) extracts the spec's claims and probes them against the tree by hand grep —
toil this ladder has paid repeatedly (the D-13 remediation and the mcp3 deep-pass each hand-probed
dozens of cites; a drifted cite that slips through mis-directs a build — the mcp2 wrong-file pin and the
retired `design/` links are the recorded cost). mcp5 ships `aaw reconcile`: flags-first invocation
(the L-5 rule), one or more workspace-contained markdown inputs, deterministic claim extraction (the
three claim kinds: `file:line` cite tokens, relative markdown links, backticked workspace paths), a
read-only tree probe (existence + line-range validity), the MATCH / STALE / MISSING classification, a
per-file delta table with tallies, `-json` output, and gate-able exit codes (0 = no drift, 1 = drift
found, 2 = usage or containment refusal). The honest limit is embedded in every report: a MATCH verifies
existence and line-range only — whether the cited site asserts what the spec claims stays with the
reconciling agent. Zero MCP-tool change: the surface stays 18, and the v2 catalog end-state stays 22
(D-3's rule — corpus capabilities ride the CLI and ordinary Read/Grep, never a dedicated tool surface).
Build formation: **standard tier** (a new package; the roadmap's "How the roadmap runs").

## Rationale (5W)

- **Why**   — the agent pays today's cost in mis-directed builds: every rung's pre-build sharpening
  re-derives "does the cited file exist, is the cited line in range, does the linked path resolve" by
  hand grep, and one drifted cite that slips through mis-directs a build — the mcp2 wrong-file pin and
  the retired `design/` links are the recorded cost. The developer pays in unauditable specs: no
  one-command, read-only way exists to ask whether a chapter's claims still hold over the tree. The
  mechanical half of the reconcile is deterministic and belongs to the machine; the semantic half
  (does the site assert the claim; is an absent surface invented or deliberately deferred) is judgment
  and stays with the agent. The Operator promoted this rung by directive (ledger D-14), displacing the
  transport rung.
- **What**  — the `aaw reconcile` CLI subcommand: the documented claim grammar + extractor, the
  read-only tree prober, the MATCH / STALE / MISSING classifier, the per-file delta table + tallies +
  the embedded limit line, `-json`, the exit-code contract, and workspace containment.
- **Who**   — two audiences, named. **The agent** — the server's primary users: the spec steward
  running the pre-build reconcile inside its sharpening loop and the Director running the pre-ratify
  drift gate get the mechanical verdict as one command, one delta table, and one exit code, with
  judgment spent only on the semantic half. **The developer** — the human who maintains the server and
  its spec corpus: a one-command, read-only, workspace-contained audit of any chapter, the claim
  grammar pinned by goldens, and a report honest about what a MATCH does and does not verify.
- **When**  — after mcp4 in the ladder (in code it depends only on the tree and mcp1's repository
  conventions — no store, signal, or config dependency); every later rung's sharpening runs it. The
  transport posture + C-1 probe this rung displaced ride **mcp8** (the conformance-closure + cutover
  rung: the probe's restart-invisibility content is the cutover demo — the displacement resolution).
- **Where** — `apps/aaw/internal/reconcile/` (new — extractor, prober, classifier: pure functions over
  bytes and read-only fs probes; the AD-12 layout extended by one seam) and the mode dispatch in
  `apps/aaw/cmd/aaw/main.go:33-45` (the third mode word beside `serve`/`selftest`; the usage line at
  `:44` extends), plus tests and committed fixtures. No MCP tool, no schema, no store change, no
  `apps/mcp-go`.

## Scope

- **In**  — the claim grammar, in one documented home: (a) cite tokens `<path>:<n>` / `<path>:<n>-<m>`,
  (b) relative markdown links, (c) backticked workspace-relative paths; per-file claim dedup; the
  read-only probe (stat + line count); the classification MATCH (target exists; any line cite within
  range) / STALE (target exists; a line cite out of range) / MISSING (target absent); the per-file
  delta table + tallies + the limit line; `-json`; exit codes 0/1/2; flags-first invocation (L-5);
  workspace containment — an input or probe target resolving outside `-workspace` refuses (exit 2)
  and probes nothing; byte-determinism across re-runs over an unchanged tree.
- **Out** — any MCP tool surface (the catalog stays 18 at this rung and 22 at v2 end — the D-3
  precedent names the dedicated-tool cost; promoting a `mcp__aaw__` reconcile tool later is an Operator
  decision, surfaced here and not taken); semantic claim verification (agent work, by design — the
  machine cannot know what a cite asserts); any fix or rewrite mode (rewriting specs would forge the
  record — the §10 no-fix rule); the server-corpus integrity lint (`aaw audit`, mcp7 — audit probes the
  SERVER's own files against each other; reconcile probes SPEC claims against the tree); the transport
  posture + the C-1 probe (mcp8 — the displacement this rung's promotion caused, resolved there).

## Deliverables

- **MCP5-D1** — the **claim grammar + extractor**: the three claim kinds above, specified in one
  documented home in `internal/reconcile/`; extraction over any markdown input; per-file dedup so one
  cite probed once is reported once.
- **MCP5-D2** — the **tree prober + classifier**: every extracted claim probed read-only against the
  `-workspace` tree (existence; for line cites, `n ≤ line count` and `m ≤ line count` where present)
  and classified MATCH / STALE / MISSING; probe targets resolving outside the workspace are reported
  as contained-refused, never read.
- **MCP5-D3** — the **CLI face**: the `reconcile` mode word in the `cmd/aaw/main.go:38` dispatch beside
  `serve` and `selftest` (flags-first per L-5 — `aaw -workspace <dir> reconcile <path>…`); one or more
  input paths; the per-file delta table (claim · kind · status) + tallies; `-json` for machines; exit
  codes — 0 all MATCH, 1 any STALE or MISSING, 2 usage or containment refusal; the usage line at
  `main.go:44` extended to name the mode.
- **MCP5-D4** — **honesty + safety, by construction**: the limit line in every output, text and json
  ("MATCH = existence + line-range only; semantic agreement is the reconciling agent's verdict");
  no write path exists anywhere in the package — a run creates, modifies, and deletes nothing; the
  containment refusal precedes any probe.
- **MCP5-D5** — the **harness**: table-driven extractor tests; classifier goldens over committed
  fixtures (at minimum one STALE line cite and one MISSING path); a byte-determinism check (two runs
  over an unchanged tree compare equal); `go test -race` green; the live-docs demo (a run over this
  chapter's own triads) recorded at rung close.

## Invariants

- **MCP5-INV1** — **deterministic.** Same inputs + same tree → byte-identical output; the package reads
  no clock, no randomness, no network, no environment.
- **MCP5-INV2** — **read-only.** A run leaves the tree byte-identical — no file is created, modified,
  or deleted by any code path in the package; the report goes to stdout/stderr only.
- **MCP5-INV3** — **zero tool-surface change.** The MCP catalog stays 18; no tool is registered, no
  schema changes; a deferred-schema client holding mcp4 shapes is unaffected; the selftest pin is
  unchanged.
- **MCP5-INV4** — **contained.** Only inputs and probe targets resolving under `-workspace` are ever
  read; an escaping input refuses with exit 2 before any probe runs.
- **MCP5-INV5** — **honest verdicts.** Every report carries the limit line; a MATCH never claims
  semantic agreement, and the classifier emits no verdict class beyond the three named.

## Definition of Done

- [ ] the claim grammar is documented in one home and the extractor recognizes all three claim kinds
      with per-file dedup (MCP5-D1).
- [ ] every claim is probed read-only and classified MATCH / STALE / MISSING; out-of-workspace targets
      are contained-refused, never read (MCP5-D2, MCP5-INV4).
- [ ] `aaw -workspace <dir> reconcile <path>…` works flags-first (L-5); the table, tallies, `-json`,
      and the 0/1/2 exit contract behave as specified; the usage line names the mode (MCP5-D3).
- [ ] the limit line is present in every text and json output; the package contains no write path; the
      tree is byte-identical after any run (MCP5-D4, MCP5-INV2, MCP5-INV5).
- [ ] extractor table tests, classifier goldens (STALE + MISSING fixtures), and the byte-determinism
      check are green under `go test -race` (MCP5-D5, MCP5-INV1).
- [ ] the tool surface is unchanged (18); `aaw selftest` is green; `apps/mcp-go` is untouched; the
      live-docs demo run is recorded (MCP5-INV3) — demoable.

Stories: ./mcp5.stories.md · Agent brief: ./mcp5.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
