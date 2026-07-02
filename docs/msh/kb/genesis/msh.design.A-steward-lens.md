# msh2 — the Steward lens (Venus-A)

> Lens A of the msh-genesis debate (scope `msh-genesis`, 2026-07-02). Input:
> [genesis.grounding.md](./genesis.grounding.md) (§1 locked · §2 ground truth · §3 fork surface). Method:
> [aaw.architect-approach](../../../aaw/aaw.architect-approach.md) — four-part arms, forks surfaced never
> decided. Stance: reuse-first · live-with-it-for-years · defer-cost · thin-but-robust. The Operator rules.

## §0 · Stance — the reframe

msh2 is the next 20% on a shipped toolchain, not a greenfield product. The as-built `go/msh` already owns the
hard problems: corpus ingestion per call (walk + parse + hash + typed graph —
`go/msh/memory/command/corpus.go:23-82`), deterministic root resolution
(`go/msh/memory/command/root.go:123-161`), and the one-facade/two-surfaces spine
(`go/msh/cmd/main.go:66,173-180`). The D-2 product needs exactly two new functions — a **scorer** and a
**budgeted assembler**. Nearly everything else proposed — a re-sharded store, a cache, an embedding service,
a write-back tool, server-served formations — is standing surface kept for years ahead of evidence.

The reframe: not "what could the hot-context engine become" but **"the smallest set of standing invariants
that serves a ranked, budgeted, cited pack every day."** A public surface is a multi-year liability; the
corpus is 69 notes / 760KB. The values carry the case: **One authority** (the files are the index; no second
store) · **Do no harm** (no mass rewrite of the Operator's durable memory outside a staged rung) · **Thin but
robust** (each rung one tested contract) · **Grounded** (measure before caching; log misses before
embedding). Where the thin arm is genuinely worse this lens says so (F2's backfill, F8's sweep — priced).

## §1 · The as-built ground — the reuse / restyle / add / DEFER map

Measured for this lens (2026-07-02): the **heaviest** full-corpus command — `msh memory audit`: walk, parse,
SHA-256, graph, all seven stale rules — completes in **0.36s wall (0.31s user), process startup included**,
over the live 69-note / 760KB corpus. Per-node SHA256 is already computed on every load
(`corpus.go:49,144-147`). Every cache/index/service argument below stands on that number.

| As-built surface | Disposition for msh2 |
|---|---|
| `loadCorpus` walk+parse+hash+graph per call (`corpus.go:23-82`) | **REUSE as-is** — the assembler's substrate; the zero-invariant lifecycle (F4) |
| Move-tolerant typing: frontmatter first, basename fallback (`corpus.go:84-123`) | **REUSE** — makes re-sharding unnecessary for classification (F1) |
| The nested-`metadata` coalesce precedent — new key wins, old path falls back (design §8, RULED) | **REUSE the mechanism** for `status:` retiring the supersession sniff (F2) |
| One facade, two surfaces: a tool = one `AddTool` + one `command.*` fn (`main.go:173-180,213-268`) | **REUSE** — search/context are two more rows in the same table |
| `specs`/speclint: filesystem-resolved links over `docs/<AREA>`, `stale.Finding` vocabulary (design §6.1) | **RESTYLE additively** — the F6 shape rules live here, not in a new artifact |
| The anchor `.msh-memory.json` walk-up (`root.go:138-144`; design §3.1) | **RESTYLE additively** — schema v1.1 (`docs_root`), one config spelling (F7) |
| The three-way spelling wart (`root.go:163-174` vs `config.go:41-44` vs `main.go:187`) | **RETIRE at msh2.1** — no such file exists on disk; the zero-migration moment |
| The 1KB supersession body sniff (`corpus.go:125-142`) | **DEMOTE to fallback** behind a declared `status:` key (F2) |
| The `hugot`/`similarity` carriers, zero consumers, nothing on :8902 (`defaults.go:38-46`) | **DEFER standing** — evidence-gated, never scheduled (F3) |
| `history_search` per-query full transcript scan (grounding §2) | **REUSE as a pointer target only** — never inside pack assembly (F9) |
| `mint`/brandedid · server lifecycle · the seven stale rules | **REUSE untouched** |
| **ADD (forward-tense):** a `Scorer`; `memory_search`; `memory_context` + the MCP prompt; speclint shape rules; anchor v1.1 | the entire proposed public growth — five items |

## §2 · The thesis in four calls

1. **Two functions on an existing substrate.** `memory_search` is a `Scorer` over the graph `loadCorpus`
   already builds; `memory_context` is a budgeted fold over search results — both on the one-facade seam.
2. **No second authority, anywhere.** Not a disk index beside the files (F4), a generated MEMORY.md beside
   the curated one (F2), a content index beside the docs tree (F6), or served role tables (F8).
3. **Defer on evidence, with the trigger named.** Cache on a measured p95 (today: 0.36s worst case); embed on
   a logged miss-class; write back when worktree parallelism is real. A named trigger makes deferral a plan.
4. **A mass corpus edit is a destructive at-rest operation.** The one backfill msh2 needs (F2) runs as its
   own staged rung — scripted, byte-diffed, Operator-reviewed — never a shipped msh write surface (design §10).

## §3 · The forks — F1–F9, the steward arm argued

Each fork argues the steward arm in the four-part form and closes with a REC. No forks added; the candidate
cache rung is re-argued under F4 and flagged in §4. Every REC is advice; the Operator rules (§6).

### F1 · Store shape — keep flat, scope by key, no mass re-shard

**Rationale.** Retrieval needs a scope *filter*, not a file move: a `project:` frontmatter key gives the
prune a directory gives, with zero files moved and zero links rewritten.
**5W.** **Why** scoped recall over an unmoved corpus · **What** `project:` as the filter; subdirs stay, new
ones allowed organically (the as-built `aaw/`·`echo_mq/`·`elixir/` pattern) · **Who** corpus author + search
consumers · **When** msh2.2 · **Where** frontmatter + the `memory/command` filter path.
**Steelman.** The corpus already sharded itself where a cluster earned it (44 flat + 25 in 5 subdirs).
Typing is move-tolerant (`corpus.go:84-123`) but MEMORY.md bullets carry *paths* — a mass move rewrites every
index line in one unreviewable diff over the Operator's memory. A key composes with scoring as one filter
term; a directory composes only with walk pruning, worth nothing at a 0.36s worst-case load.
**Steward.** The key is a standing authoring cost, degrading soft (an unkeyed note still ranks, never
scope-boosted). The opposing arm's best point — directories read in a bare listing — is honored: MEMORY.md's
curated sections already give the human that view.
**Steward REC:** flat + `project:` key; organic subdirs unchanged; the mass re-shard CHOSEN-AGAINST.

### F2 · Frontmatter v2 + the index — a two-key contract; MEMORY.md stays hand-curated

**Rationale.** A schema key is contract only if a shipped rule or the scorer consumes it on day one; two
qualify — `project` (F1) and `status` (retiring the fragile supersession sniff).
**5W.** **Why** declared supersession + scoped search · **What** `status:` wins, the sniff demotes to
fallback (the design-§8 coalesce precedent — zero breakage); `tags`/`review_after` NOT contract · **Who**
author, stale engine, scorer · **When** msh2.2; the backfill M1's one staged edit · **Where**
`internal/frontmatter` + `corpus.go:125-142` demoted.
**Steelman.** Two keys retire one real wart and enable scoping; each further key is an authoring tax with no
consumer — `tags` duplicates `[[wiki-links]]` + hand-written descriptions (a second vocabulary = a drift
surface), and no shipped rule reads a `review_after` date. The two-key backfill byte-diffs in one sitting.
**Steward.** Even two keys cost a destructive at-rest backfill (staged per §2.4) and a precedence held
forever. The hand-curated MEMORY.md is the one view the Operator curates and every session loads — retiring
it while building its replacement retires the product's seed; a generated COMPANION is the honest experiment.
**Steward REC:** `project` + `status` only; backfill staged; MEMORY.md hand-curated; companion evidence-gated.

### F3 · Retrieval — pure-Go lexical behind a `Scorer` seam

**Rationale.** 69 dense notes in RAM want a deterministic in-process ranker; the corpus is already engineered
for lexical recall — every note carries a hand-written `description:` and a MEMORY.md hook written to match.
**5W.** **Why** ranked recall, zero new processes or deps · **What** BM25F over name/description/body +
type/recency weights + staleness demotion + graph proximity from seeds, behind one `Scorer` interface ·
**Who** search/context consumers · **When** msh2.3 · **Where** a new internal package beside `internal/graph`.
**Steelman.** Deterministic (golden-fixture testable, no model drift), zero dependencies, zero services —
nothing listens on :8902; the `hugot` block is a parsed-only carrier (`defaults.go:38-46`). Embeddings solve
a synonymy problem the descriptions already solve, at the price of a model artifact, a service under mcpd,
and non-reproducible ranking; their real strength — free-phrased queries — is what the miss-log measures.
**Steward.** BM25F weights are a permanent tuning temptation — pin them with golden-query fixtures the gate
runs. The `Scorer` interface is one type that keeps the hybrid future open; the Hugot trigger is cheap to
arm: log every search whose results the consumer discards, reopen on a demonstrated miss-class.
**Steward REC:** lexical v1 behind `Scorer`, miss-log armed day one; Hugot evidence-gated at the ladder tail.

### F4 · Index lifecycle — per-call rebuild until a measurement says otherwise

**Rationale.** The zero-invariant lifecycle cannot be wrong; a cache buys latency with a coherence invariant
tested forever. Today there is no latency to buy back.
**5W.** **Why** no stale-index bug class · **What** keep `loadCorpus` per call (`corpus.go:23`); the
pre-approved fallback: an in-process `{size, mtime, SHA256}` re-stat cache (SHA already per-node) · **Who**
the :8899 server under mcpd · **When** gated on a measured p95, never scheduled · **Where** `memory/command`.
**Steelman.** The measurement: the heaviest command costs **0.36s including startup and all seven rules**
(§1); a bare load for pack assembly costs a fraction, inside an MCP call an agent already waits seconds for —
and at 10× corpus growth the arithmetic holds. The disk index is worse than a cache: a second authority
against the files, needing invalidation, versioning, and reconcile — for a corpus smaller than one image.
**Steward.** The risk is a sluggish pack call if the corpus grows far past 10× — accepted: the fallback is
pre-shaped (files the sole authority; the cache derived + discardable) and the trigger is a number, not a
debate. *Ladder deviation flagged:* the candidate msh2.4 cache rung dissolves into this gate.
**Steward REC:** per-call rebuild stands; re-stat cache evidence-gated; disk index CHOSEN-AGAINST at any size.

### F5 · Pack composition — search first, context composed on it; prompt with context; role a param

**Rationale.** The primitive (ranked, cited hits) is usable product alone; the pack is a fold over it.
Composition keeps each surface independently testable and independently frozen.
**5W.** **Why** two thin contracts over one opaque one · **What** `memory_search`, then `memory_context` =
budget-fold(search), unset args from the live anchor; the MCP prompt registers with `memory_context` — D-2
calls it *the same assembly*, one contract tested once · **Who** in-session agents · **When** msh2.3 →
msh2.4 · **Where** `memory/command` + two `AddTool` rows.
**Steelman.** Search alone already retires the grep-the-corpus ritual; a context bug stays diagnosable
(search visibly right, fold wrong) where a single assembly tool hides the primitive behind one schema.
Whole-note granularity: the notes are short dense distillations by construction — lead-section splitting adds
a section parser and a citation ambiguity for near-zero budget win at 69 notes.
**Steward.** Two public tools are two frozen contracts under the additive-only law — priced and accepted.
Role-from-the-aaw-roster is declined at full strength: aaw roles are FREE STRINGS in code (grounding §2) — a
cross-server coupling to a surface aaw never promised. `role` stays a scorer param in msh's own config.
**Steward REC:** search first, context composed on it, prompt with context; whole-note; role param-only.

### F6 · The docs/ pattern — convention enforced by speclint-v2 rules in the existing `specs` tool

**Rationale.** Enforcement belongs in the engine that already walks `docs/<AREA>` and emits the
`stale.Finding` vocabulary (design §6.1); a lint rule is stateless where a generated index is a state.
**5W.** **Why** end the three-way ledger drift with no new artifact class · **What** additive shape rules —
artifact set present, triad naming, ledger placement — with `docs/msh/` the first exemplar · **Who** program
authors + CI (`msh specs` non-zero exit) · **When** msh2.5 · **Where** `internal/speclint`.
**Steelman.** A per-program generated content index is a second authority, stale between generations, with a
generator to maintain; the `*.registry.json` name is fenced regardless (grounding §1.6). A shape rule leaves
the tree as the only truth and reports every violation as a Finding with a `file:line`.
**Steward.** Shape rules encode the convention in code — when the convention evolves the rules move with it.
Keep the set small (existence + placement, never style) so it ages at the speed of the artifact set.
**Steward REC:** convention-only + speclint v2 shape rules; the generated per-program index CHOSEN-AGAINST.

### F7 · Anchor — one anchor, one spelling, additive v1.1; no write-back tool

**Rationale.** The wart is three spellings of a file that does not exist — marker probe (`root.go:163-174`)
vs config loader (`config.go:41-44`) vs docstring (`main.go:187`); the zero-migration moment to fix it is now.
**5W.** **Why** one honest resolution story under every call · **What** one canonical config filename (old
spellings read for a window), anchor v1.1 adding `docs_root` additively; NO `memory_project set` · **Who**
every msh invocation — root resolution is the universal predecessor · **When** msh2.1, the D-1-locked rung ·
**Where** `root.go` + `config.go` + the `main.go` docstrings.
**Steelman.** The multi-project anchor with an `active` pointer designs for a work pattern that does not
exist: the live anchor names one project (`echo_mq`, rung `emq.4.2`). The write-back tool would be msh's
FIRST write surface, breaking the read-only invariant (design §10), to save one hand edit of a JSON file.
**Steward.** The single anchor keeps a real, small friction: the Operator hand-edits it on project change —
the cost paid and accepted today. Additive v1.1 keeps the multi-project door open with nothing to unwind.
**Steward REC:** one anchor, one spelling, additive v1.1; write-back/multi-project deferred (trigger: real worktree parallelism).

### F8 · The aaw movement (M4) — docs-first; mcp7 stays unbundled

**Rationale.** The census defect is redundancy in prose — roles restated 3-4×, the LAWS quoted 3×, zero
MCP-tool references in the core docs (grounding §2). A docs defect gets a docs fix, not a server feature.
**5W.** **Why** one routing authority every skill and CLAUDE.md cites · **What** a short mcp-tools-forward
docs/aaw set + ONE routing table; the aaw server untouched; mcp7 (18→22) stays its own specced ladder ·
**Who** every agent loading a skill · **When** M4 — roadmap text only this run (D-1) · **Where** `docs/aaw/`.
**Steelman.** Roles are free strings in aaw code BY DESIGN — the framework deliberately lives in docs and
skills; serving formations from the server data-izes law and creates exactly the second authority One
authority forbids. The "while the seam is open" urgency is false: additive-only evolution means the seam is
NEVER closed, so bundling four new tools with a docs rewrite buys only an unreviewable rung.
**Steward.** Docs-first leaves enforcement human: unswept copies regrow the redundancy, so the sweep of the
five ship skills + the CLAUDE.md pointers is part of M4's priced cost — the steward arm's real expense.
**Steward REC:** M4 = docs-first + one routing table + the citation sweep; mcp7 on its own ladder.

### F9 · History in packs — pointers + a prepared invocation; no snippets

**Rationale.** The notes ARE the distillation of the sessions (every note carries `originSessionId`); paying
pack budget for the least-curated content in the system inverts the corpus's own design.
**5W.** **Why** deterministic, curated packs · **What** each pack citation carries its `originSessionId` + a
ready-to-run `history_search` invocation; transcript text arrives only on the consumer's explicit call ·
**Who** the pack consumer decides when history is worth its cost · **When** msh2.6 · **Where** the assembler.
**Steelman.** The join key is already on every note — the pointer is free. `history_search` is the most
expensive call in the toolchain (a per-query full scan of every session `*.jsonl`); embedding it in every
pack assembly makes the cheap path expensive, and transcripts mutate as sessions run — a snippet-bearing
pack is non-reproducible.
**Steward.** The pointer arm costs a second round-trip exactly when history matters, trusting the consumer to
pay it — accepted. If the miss-log shows pointers systematically unfollowed, the capped snippet tier reopens.
**Steward REC:** pointers + prepared invocation lines; in-pack snippets CHOSEN-AGAINST for v1.

## §4 · The steward msh2 ladder

| Rung | Goal | Boundary | SHIPS (what the Operator uses that day) |
|---|---|---|---|
| **msh2.1** (this run, D-1) | anchor integrity: one config spelling + anchor v1.1 (`docs_root`) + docstring sync | `go/msh` | honest root resolution; the wart dead; `memory_project` reports `docs_root` |
| **msh2.2** | frontmatter v2 minimal (`project`+`status`; sniff→fallback) + scoped scan/stale; the backfill its own staged sub-rung | `go/msh` + one staged `memory/` edit | scoped scans (`--project emq`); declared supersession; an honest census |
| **msh2.3** | `memory_search` v1: BM25F + type/recency/staleness + graph proximity, behind `Scorer`; miss-log armed | `go/msh` | ranked, cited recall — the grep ritual retired |
| **msh2.4** | `memory_context` + the MCP prompt (budget fold on search; whole-note; anchor defaults; `path#heading`) | `go/msh` | **THE product** — the budgeted pack, as tool and prompt |
| **msh2.5** | speclint v2 shape rules; `docs/msh/` authored as the pattern exemplar | `go/msh` + `docs/msh` | docs-pattern drift reported as Findings |
| **msh2.6** | history joins: pointer + prepared-invocation citation lines | `go/msh` | session-trace lines in every pack |
| **msh2.7** (optional) | generated MEMORY **companion** view | `go/msh` | index-future evidence, nothing retired |
| **msh2.8+** (M4) | aaw docs-first rewrite + ONE routing table + the citation sweep | `docs/aaw` only | one routing authority (shape per F8; text-only this run) |

M-grouping: M1 = 2.1–2.2 · M2 = 2.3–2.4 · M3 = 2.5–2.7 · M4 = 2.8+. **Deferred-standing (triggers named,
never scheduled):** re-stat cache (measured p95) · Hugot hybrid (logged miss-class) · `memory_project set` /
multi-anchor (worktree parallelism) · lead-section granularity (budget pressure) · in-pack snippets
(pointers unfollowed). **Deviations from the §4 candidate, flagged:** the cache rung dissolves into the F4
gate; the prompt merges into the context rung (one assembly, D-2); Hugot moves to deferred-standing. Ten
scheduled rungs become eight; the product lands two rungs earlier.

## §5 · Boundary + gates posture

**Boundary.** Every build rung edits `go/msh` only (the D-1 fence); msh2.2's backfill is the one `memory/`
edit, staged as its own Operator-reviewed sub-rung and executed by a one-shot script — never a shipped msh
command, so the read-only invariant (design §10) survives the ladder. Spec artifacts land under `docs/msh/`;
the genesis adds only the two supersede banners to `docs/go/msh/`; `go/aaw` never touched, `docs/aaw` only M4.

**Gates.** The hermetic ladder per `go/CLAUDE.md`: `GOWORK=off go build ./...` + `go vet` + `go test` +
`gofmt -l` silent. Determinism is the pinned property: same corpus + same query → byte-identical ranking and
pack (ties broken by path), held by golden-query fixtures. The tool count moves 8→9→10 as additive minors,
each re-pinned (the design-§10 counting discipline; additive-only per grounding §1.6). The live server is
never killed — mcpd hot-swap + `/mcp` reconnect.

## §6 · The surfaced forks — the Operator's table

| Fork | The steward arm | REC | What rules it |
|---|---|---|---|
| F1 store shape | flat + `project:` key; organic subdirs | no mass re-shard | Operator: a corpus move is destructive at-rest |
| F2 schema + index | two-key contract; staged backfill | MEMORY.md hand-curated; companion evidence-gated | Operator: the schema contract + the index's future |
| F3 retrieval | pure-Go lexical behind `Scorer` | Hugot deferred on miss-log evidence | Operator: dependency + determinism posture |
| F4 index lifecycle | per-call rebuild (0.36s measured) | re-stat cache gated; disk index against | Operator: cheap to defer — no contract at stake |
| F5 pack composition | search → context; prompt with context; role a param | two composed tools; no aaw-roster coupling | Operator: the public tool contracts inside D-2 |
| F6 docs pattern | speclint v2 shape rules | no generated per-program index | Operator: the pattern's enforcement form |
| F7 anchor | one anchor, one spelling, v1.1 additive | no write-back tool | Operator: the anchor contract + read-only law |
| F8 aaw movement | docs-first + one routing table + sweep | mcp7 unbundled | Operator: M4's shape (text-only this run) |
| F9 history | pointers + prepared invocation | no in-pack snippets in v1 | Operator: pack content + reproducibility |

Nothing here is decided: each REC is advice (its reason in §3), losing arms keep their steelman on record, and the Operator rules every row.
