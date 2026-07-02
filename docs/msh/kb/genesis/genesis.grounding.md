# msh genesis — the grounding pack

> The shared, locked input for the two Venus lens architects of the **msh program founding** (scope
> `msh-genesis`, 2026-07-02). Each lens reads this file first; it is the one source for the mission, the
> locked constraints, and the ground facts. The method of record is
> [aaw.architect-approach](../../../aaw/aaw.architect-approach.md) — four-part arms
> (Rationale · 5W · Steelman · Steward), forks surfaced never decided, the §multi-architect debate. The
> run ledger is `../../specs/progress/msh-genesis.progress.md` (D-1..D-4 = the Operator's pre-rulings).

## §0 · Mission

The forward **msh program** turns the msh MCP server into the **hot-context engine** for Claude agents:
precise, budgeted, per-project context assembled from the `memory/` corpus, the `docs/` program trees, and
(by pointer) the session history — replacing fat always-loaded context with tool-served packs. The program
also establishes the **normalized docs/ pattern** and, in its last movement, **normalizes the aaw server +
rewrites docs/aaw** (shorter, mcp-tools-focused, clear agent role routing). The genesis consolidates two
competing lens specs into `msh.design.md` + `msh.roadmap.md` (movements M0–M4); **every roadmap rung ships
product the Operator can use that day**.

## §1 · Locked constraints (not arguable in the lens docs)

1. **D-1 run scope** — this run = genesis + the first build rung (`msh2.1`) only. The memory/ restructure
   is movement M1; the aaw movement is M4 (roadmap text only in this run).
2. **D-2 product shape** — the prompt builder is **MCP context-pack tooling**: `memory_search` +
   `memory_context` `{project, rung, role, task, token_budget}` → ranked, budgeted, cited pack; unset args
   default from the live `.msh-memory.json` anchor; the same assembly registered as an MCP **prompt**.
   Generated role-brief files are CHOSEN-AGAINST. (The internal composition is still argued — F5.)
3. **D-3 formation** — ledgered trio; Apollo absorbed by the Director for design (the D-7 exception).
4. **D-4 namespace** — forward rungs are **msh2.N**; `msh.0–msh.6`/`msh.P2`/`msh.FX` belong to the frozen
   reverse-mode record at [docs/go/msh](../../../go/msh/msh.roadmap.md).
5. **Fences** — the genesis edits nothing outside `docs/msh/` + two supersede banner lines in
   `docs/go/msh/`; the rung edits only `go/msh/`; no `memory/` mass edits; no `go/aaw/` or `docs/aaw/`
   edits. A lens doc PROPOSES; the Operator rules.
6. **Law** — NO-INVENT (every named surface verified at its source with a `file:line`, or written forward-
   tense for surface not yet built); the corpus voice (plain specific prose, no first person, no perceptual
   or interior-state verbs — [aaw.rules](../../../aaw/aaw.rules.md), Voice); no git from any peer; additive
   MCP tool evolution only; no new artifact named `*.registry.json` (that name is the aaw team roster —
   32 live instances under docs/).

## §2 · Ground truth (verified 2026-07-02; paths relative to the repo root)

- **Memory store.** `memory/` is the real, git-tracked root (`~/.claude/projects/-Users-jonny-dev-jonnify/
  memory` is a symlink to it). 69 notes: 44 flat + `aaw/`5 `courses/`3 `echo_graft/`1 `echo_mq/`9
  `elixir/`7. Uniform frontmatter `{name, description, metadata:{node_type: memory, type:
  project×52|feedback×12|reference×4, originSessionId}}`; dense bold-lead prose bodies; `[[wiki-links]]`;
  `MEMORY.md` = the hand-curated index loaded into every Claude session.
- **msh server** (`go/msh`, :8899, ~3.9k prod LOC, cobra CLI + MCP twins over one implementation). 8 tools:
  `memory_scan/graph/stale/audit` (each call re-walks + re-parses the WHOLE corpus and rebuilds the typed
  graph — `memory/command/corpus.go:23-82`; per-node SHA256 already computed `corpus.go:49,144-147`; no
  cache, no index, no ranking, no token budgeting, no pack assembly anywhere), `memory_project`, `mint`
  (brd14), `specs` (speclint: filesystem link+anchor lint over `docs/<AREA>`), `history_search`
  (per-query full scan of `~/.claude/projects/<slug>/*.jsonl`, AND-substring, newest-first). Tool
  registration seam: `cmd/main.go:173-180 buildMCPServer` (8 `AddTool` sites: `cmd/main.go:214-258`,
  `cmd/specs.go:62`, `cmd/mint.go:182`, `cmd/history.go:507`). Type classification tolerates file moves
  (`corpus.go:84-123`, basename-prefix + frontmatter); the vocabulary already accepts unused types
  `law/session_pause/index` (`corpus.go:84-98`); `superseded` is inferred by a fragile 1KB body-text sniff
  (`corpus.go:125-142`).
- **The dormant retrieval seam.** `memory/internal/config/defaults.go:38-46` carries
  `Hugot{Endpoint: localhost:8902}` + `Similarity{Threshold 0.85, TopK 5}` with ZERO consumers — the
  intended Phase-2 embedding hook ([as-built design](../../../go/msh/msh.design.md) records it as parsed,
  consumed by nothing). Nothing listens on :8902 today.
- **The three-way marker wart.** Root-marker probe `.msh.memory.yaml` (`memory/command/root.go:167`) vs
  config loader `msh-memory.yaml`/`.msh-memory.yaml` (`memory/internal/config/config.go:42-43`) vs
  documented `msh.memory.yaml` (`cmd/main.go:187`). Neither file exists in the live corpus.
- **The live anchor** `.msh-memory.json` (repo root, walk-up resolved `memory/command/root.go:123-161`,
  `project.go:15,44-72`): `{root: /Users/jonny/dev/jonnify/memory, project:{name: echo_mq, code: emq,
  roadmap: emq.roadmap.md, state:{status: in_progress, current_rung: emq.4.2}}}` — a live
  "what-is-being-worked-now" scope key.
- **aaw server** (`go/aaw`, :8905, 18 tools): per-scope markdown ledger + `<scope>.registry.json` roster;
  scope index `.aaw/scopes.json`; roles are FREE STRINGS in code (only `director` special-cased); NO
  phases/formations in code — the framework lives in docs/skills; selftest pins the tool count; additive-
  only schema evolution; mcp5 (reconcile CLI), mcp6 (tui), mcp7 (channels/resonance/archival, 18→22)
  specced-not-built under `docs/aaw/mcp/`.
- **Docs canon** (exemplar `docs/echo_mq/`): `<prog>.{design,roadmap,progress,features,testing,
  references}.md` + `program/` + `specs/<rung>.{md,stories.md,llms.md}[+.prompt.md]` +
  `specs/progress/<scope>.{progress.md,registry.json}` + `epics/` + `kb/`. Mercury and codemojex deviate
  (three different ledger placements) — the drift the normalized pattern must end. A new artifact class
  exists: `docs/echo/vision/` direction essays.
- **AAW docs corpus** (M4 input): 7 top-level docs ≈1,250 lines; roles/formations/loop restated 3-4×; the
  LAWS quoted 3×; ZERO MCP-tool references in the core docs (the tool surface lives only in
  `.claude/commands/x.md` §6, `docs/aaw/mcp/`, and five ship/program skills); two byte-identical 595-line
  progress files under `mcp/`; `mcp/x-mode.design.md` carries formation corrections D-7/D-8 not yet folded
  into x.md §12. Role routing is scattered (x.md §5/§12, the x-mode skill, root CLAUDE.md, five ship
  skills) — no single routing table.
- **Ops law.** GOWORK=off builds; `go build -o <bin> ./cmd` (bare `./...` collides); never kill a live MCP
  server — `make mcp` = mcpd hot-swap (:8899 msh, :8905 aaw) + client `/mcp` reconnect; LAW-4 pathspec
  commits by the Director only.

## §3 · The fork surface (candidate input — argue, refine, merge, or add forks; flag any addition)

- **F1 · Store shape.** Re-shard `memory/` into per-program dirs vs keep flat + richer frontmatter keys.
  Decisive: the 44/5 census; move-tolerant typing `corpus.go:84-123`; link/index survival
  (`[[wiki-links]]`, MEMORY.md bullets carry names+paths); scope-as-directory-prune vs scope-as-key.
- **F2 · Frontmatter schema v2 + the index's future.** Which keys (`project`, `scope`, `status`,
  `review_after`, `tags`?) become contract, what gets backfilled across 69 notes; `status: superseded`
  retiring the body sniff (`corpus.go:125-142`); MEMORY.md hand-curated vs msh-generated (or a generated
  COMPANION view first, evidence before retirement).
- **F3 · Retrieval algorithm.** Pure-Go lexical (BM25F over name/description/body + graph proximity from
  seed nodes + type/recency weights + staleness demotion) vs the dormant Hugot embedding seam
  (`defaults.go:38-46`) vs hybrid-behind-a-`Scorer`-interface. Decisive: 69-doc corpus in RAM; dense prose
  synonymy; nothing on :8902; determinism/testability; cost discipline.
- **F4 · Index lifecycle.** Per-call rebuild (today) vs in-process cache keyed on per-file
  `{size, mtime, SHA256}` re-stat vs a persistent on-disk index. Decisive: SHA already computed; the server
  is long-lived under mcpd; a disk index is a second authority against the files.
- **F5 · Pack composition** (inside D-2). `memory_search` shipped first with `memory_context` composed ON
  it vs one assembly tool only; when the MCP prompt registers; where `role` comes from (a param only vs
  read-only from the aaw `<scope>.registry.json` roster); pack granularity (whole note vs lead section);
  citation format (`path#heading`).
- **F6 · The docs/ scope pattern.** A per-program generated content index (NOT named `*.registry.json`) vs
  convention-only enforced by speclint-v2 rules in the existing `specs` tool (shape checks: the artifact
  set, triad naming, ledger placement). Decisive: three-way ledger drift; `specs` today checks only links;
  `docs/msh/` is the pattern's first exemplar either way.
- **F7 · Anchor + scope normalization.** One repo anchor (fix the three-way marker wart, add fields like
  `docs_root` additively) vs a multi-project anchor with an `active` pointer + a write-back
  `memory_project set` tool. Decisive: the wart file:lines (§2); walk-up semantics; one-live-project work
  pattern vs worktree parallelism.
- **F8 · The aaw movement's shape** (M4 — roadmap text only now). Docs-first: rewrite docs/aaw into a short
  mcp-tools-forward set + ONE routing-table authority all skills/CLAUDE.md cite vs server-data-first: serve
  routing/formations from aaw itself and fold mcp7 items (18→22 tools) while the seam is open. Decisive:
  the redundancy census; the selftest pin + additive-only law; roles-as-free-strings.
- **F9 · History in packs.** Budgeted transcript snippets (~10-15% of the pack) vs `originSessionId`
  pointers + a prepared `history_search` invocation only. Decisive: notes ARE the distillation; the
  full-scan cost profile of `history_search`; every note carries `originSessionId`.

## §4 · A candidate msh2 ladder (input, not binding — each lens proposes its own; every rung must SHIP)

msh2.1 anchor integrity (the wart + anchor schema v1.1) → msh2.2 frontmatter v2 + backfill (scoped
scans, honest staleness) → msh2.3 `memory_search` v1 (ranked retrieval) → msh2.4 corpus cache +
graph-proximity (ms-latency) → msh2.5 `memory_context` (THE product) → msh2.6 the MCP prompt + role
awareness → msh2.7 docs-pattern enforcement (speclint v2) → msh2.8 history joins → msh2.9 (optional)
generated MEMORY companion view → msh2.10 (deferred, evidence-gated) Hugot hybrid scorer. M-grouping:
M1 ≈ 2.1–2.2 · M2 ≈ 2.3–2.6 · M3 ≈ 2.7 (+2.9) · M4 = the aaw rungs (shape per F8; ids continue msh2.N).

## §5 · The deliverable contract (per lens)

- **Venus-A — the Steward lens** → `msh.design.A-steward-lens.md` (this dir), **≤250 lines**. The stance:
  reuse-first, live-with-it-for-years, defer-cost, thin-but-robust; the values One authority · Do no harm ·
  Thin but robust · Grounded carry the argument.
- **Venus-B — the Steelman lens** → `msh.design.B-steelman-lens.md` (this dir), **≤350 lines**. The stance:
  the strongest, fully-argued case for the maximal hot-context product — completeness and capability argued
  at full strength, trade-offs honored, never waved away.
- **Both docs:** §0 stance/reframe → §1 the ground (as-built anchoring, reuse/defer map for A; vision +
  substrate table for B) → §2 the thesis in 2–4 calls → §3 the forks (each of F1–F9 argued in the four-part
  arm form with a one-line lens REC; merged/added forks flagged) → §4 the proposed msh2 ladder (a table;
  every rung's SHIPS stated) → §5 boundary + gates posture → §6 the surfaced-forks table for the Operator
  (fork · this lens's arm · the REC · what rules it). End there; no decisions.
- **Process:** register first (`mcp__aaw__agent_register {scope: "msh-genesis", name, role: "architect",
  ccl_id}`); **write-first** — the full §-skeleton lands in the first Write, then sections fill one at a
  time; `mcp__aaw__agent_heartbeat {scope: "msh-genesis", name}` after each filled section; NEVER read the
  sibling lens doc; edit nothing but the own lens file; no git.

## §6 · Required reading (in order; ≤3 further files may be read from the §2/§3 citations)

1. This pack.
2. [aaw.architect-approach](../../../aaw/aaw.architect-approach.md) — the arm form + the debate rules.
3. [docs/go/msh/msh.design.md](../../../go/msh/msh.design.md) — the as-built baseline (NOTE: it lags the
   code — it says 7 tools, the code registers 8; its §8 frontmatter fork is already implemented).
4. [docs/go/msh/msh.roadmap.md](../../../go/msh/msh.roadmap.md) — the as-built ladder + its Seams.
5. `go/msh/memory/command/corpus.go` + `go/msh/cmd/main.go` — the ingestion + registration seams.
