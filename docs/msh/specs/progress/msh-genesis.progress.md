# msh-genesis — AAW scope ledger

## {msh-genesis-thinking} Thinking

### T-1 — the msh program founding: mission + formation

Found the forward msh program at docs/msh/ — the hot-context/search engine + prompt builder for Claude agents over the memory/ corpus and the docs/ trees — via the multi-architect debate (aaw.architect-approach §multi-architect debate): Venus-A (Steward lens) ∥ Venus-B (Steelman lens) author competing specs from one shared grounding pack (kb/genesis/genesis.grounding.md); the Director stages the disagreement in kb/genesis/msh.synthesis.md (per-fork CONVERGED/DIVERGED ledger); the Operator rules the forks; the ruled synthesis consolidates into msh.design.md + msh.roadmap.md (movements M0–M4, rung namespace msh2.N, product shipped every rung); then the first build rung msh2.1 ships in go/msh. Plan of record: ~/.claude/plans/the-implementation-plan-to-radiant-piglet.md. Formation: Director + 2 Venus (real spawns, LAW-1) + 1 Mars at the rung; Apollo absorbed by the Director per D-7 (docs/aaw/mcp/x-mode.design.md).

## {msh-genesis-decisions} Decisions

### D-1 — run scope: genesis + first build rung

RULED: Operator, 2026-07-02 (planning-session AskUserQuestion). This run founds the program (docs/msh canon + supersede banners, committed) AND ships the ladder's first build rung in go/msh. The memory/ restructure (M1) and the aaw movement (M4) ship later, one rung per run. CHOSEN-AGAINST: genesis-only (defers all product); genesis + whole memory movement (heavier, mass memory/ edits before the roadmap has settled the schema).

### D-2 — the prompt builder is MCP context-pack tools

RULED: Operator, 2026-07-02. The product shape of the prompt builder: msh serves memory_search + memory_context — {project, rung, role, task, token_budget} → ranked, budgeted, cited context pack; unset args default from the live .msh-memory.json anchor; the same assembly registered as an MCP prompt (slash-invokable). Agents pull context by tool call. CHOSEN-AGAINST: msh-generated role-brief files on disk (a second, staleable authority duplicating what a live tool serves); the lens docs may still argue the INTERNAL composition (search-first vs pack-first, F5).

### D-3 — genesis formation: the ledgered trio

RULED: Operator, 2026-07-02. Director + Venus-A (Steward lens) + Venus-B (Steelman lens), real spawned agents on the fable model (LAW-2), aaw-ledgered on scope msh-genesis; one Mars at the msh2.1 rung. Apollo is absorbed by the Director for the design phase per D-7 (docs/aaw/mcp/x-mode.design.md — Apollo removed from design phases); named here as the standing exception. CHOSEN-AGAINST: unledgered trio (no durable run record); Director-solo authoring (sacrifices the independent-lens integrity the steward/steelman method exists for).

### D-4 — the forward rung namespace is msh2.N

RULED: Operator, 2026-07-02. The frozen reverse-mode record at docs/go/msh/ already occupies msh.0–msh.6 + msh.P2 + msh.FX; the forward roadmap numbers its rungs msh2.1, msh2.2, … (the aaw2.*/emq3.* precedent: a v2 ladder namespace over an as-built v1). CHOSEN-AGAINST: continuing msh.7+ (couples new numbering to the frozen tree); carrying the namespace as an open fork into the run (a naming stall on every artifact the genesis authors).

### D-5 — F7 ruled: msh2.1 is read-only minimal

RULED: Operator, 2026-07-02 (gate round 1). msh2.1 = one canonical config-marker spelling (legacy spellings read for a deprecation window) + anchor schema v1.1 additive `docs_root` + docstring sync. NO write surface: the toolchain stays read-only verbatim. CHOSEN-AGAINST (steelman kept on record): multi-project anchor {projects[], active} + atomic `memory_project set` — reopens on the named trigger: real worktree parallelism.

### D-6 — F6 ruled: the docs trees JOIN the pack engine

RULED: Operator, 2026-07-02 (gate round 1). The product is a program-context engine, not a memory-recall engine: speclint-v2 shape rules make the program trees reliable, then the walker/graph engine ingests them as additional corpus roots (root-tagged nodes; memory-only invariants fenced per root); rung packs carry the rung's roadmap row + the design sections it cites. No generated per-program index artifact, ever (both lenses). CHOSEN-AGAINST: lint-only enforcement with memory-only packs — its steelman (one-root simplicity) is honored by sequencing: the loader API change is priced once, after the cache.

### D-7 — F4 ruled: the snapshot cache is scheduled BEFORE ingestion

RULED: Operator, 2026-07-02 (gate round 1; the conditional arm, resolved by F6=IN). The in-process corpus snapshot ({size, mtime} re-stat with the SHA256 backstop; one standing invariant — every read goes through the snapshot API) ships as its own rung ahead of multi-root ingestion, because docs trees are 10–50× the memory corpus. The disk index is CHOSEN-AGAINST at any size (both lenses: a second authority against the files). The steward evidence-arm survives as the gate's teeth: the rung carries a latency gate measured on the live corpus, and A's 0.36s baseline is the recorded pre-cache number.

### D-8 — F2 ruled: the schema contract is 3-key with a day-one consumer

RULED: Operator, 2026-07-02 (gate round 1; the staged middle). Frontmatter v2 contract = {project, status, review_after}: `project` feeds scoping (F1), `status` retires the 1KB supersession body-sniff (demoted to fallback via the coalesce precedent), and `review_after` gets its DAY-ONE consumer built in the same rung — a new stale rule emitting a finding when the date is past due. One staged, audited, byte-diffed 69-note backfill. `tags` is NOT contract — deferred to miss-log evidence (the synonymy class). CHOSEN-AGAINST: 2-key strict (a second backfill later priced but not chosen); 4-key full (tags without a consumer = a drift surface).

### D-9 — F5a ruled: the pack is section-capable

RULED: Operator, 2026-07-02 (gate round 2). memory_context truncation semantics: whole note when budget allows, lead section when tight, truncation ONLY at heading boundaries — token_budget is a real contract. Citations are path#heading in every mode (the heading slugs are already parsed on every walk; the splitter is a formatter). CHOSEN-AGAINST: whole-note-only (its steelman — truncation ambiguity — is answered by the heading-boundary-only rule).

### D-10 — F5b ruled: role is a caller param in v1

RULED: Operator, 2026-07-02 (gate round 2). The role signal enters the scorer as a caller param only; no cross-server file coupling in v1 (aaw roles are free strings the server never promised as a contract). Named trigger: when the M4 routing surface ships (D-12 / F8), the role default joins the SERVED routing authority — a tool contract, not a scraped file. CHOSEN-AGAINST: the read-only <scope>.registry.json roster join (its steelman — zero-arg role-correct calls — is deferred to the served-table trigger, not lost).

### D-11 — F9 ruled: history rides as pointers first; the snippet tier is evidence-gated

RULED: Operator, 2026-07-02 (gate round 2; the staged arm). v1 packs carry originSessionId pointers + a prepared, ready-to-run history_search invocation per cited note (deterministic, cheap — the join key is on every node). The miss-log measures whether pointers go unfollowed; the moment that evidence lands, the capped-snippet tier ships as its own rung (ONE search per pack, §history ≤10% of token_budget hard cap) adopting B's declared-degrade contract verbatim: §budget reports RAN / CAPPED / DEGRADED — a silently empty §history is a gate failure. CHOSEN-AGAINST: snippets-now (reproducibility + per-pack scan cost ahead of evidence); pointers-only-closed (the frontier argument earns the named reopen).

### D-12 — F8 ruled: M4 is server-data-first

RULED: Operator, 2026-07-02 (gate round 2). The single aaw routing authority is SERVED: aaw grows routing/formation query tools (additive fold toward the specced mcp7 set, selftest tool-count re-pinned), sequenced tools-then-docs; docs/aaw is then rewritten short and mcp-tools-forward as pointers to the served table; the exit gate is measurable — the restatement census reaches one. The steward arm's priced sweep survives inside the movement: the five ship skills + the CLAUDE.md pointers are swept to cite the one authority, and the two byte-identical mcp progress files + the stranded D-7/D-8 x-mode corrections are folded in the docs rung. M4 stays roadmap text only in this run (D-1); the go/aaw + docs/aaw fences are re-ruled at M4-open. CHOSEN-AGAINST: docs-first with the server untouched (its One-authority objection is answered by making the served table THE authority and the docs its pointers).

## {msh-genesis-learnings} Learnings

### L-1 — msh2.1 craft findings (recorded at the Director gate)

(1) PRE-EXISTING gofmt debt, untouched by the rung, named per do-no-harm: memory/internal/linkx/extractor_test.go · memory/internal/stale/context.go · memory/internal/stale/rules.go fail `gofmt -l` from HEAD — a separate scoped concern for the Operator, never folded into a rung commit. (2) UNTRACKED pre-existing feature files in the island: go/msh/cmd/history.go + history_test.go (history_search, shipped 2026-06-30) have never been committed — a blanket `git add go/msh` would silently sweep another concern into the rung commit; the rung pathspec must name its exact files. (3) The new walk-up tests use t.Chdir (Go ≥1.24; module go 1.25.0) — fine here, a floor to remember when touching toolchains. (4) The 0.36s full-audit baseline (lens A measurement) stands recorded for the msh2.4 latency gate.

## {msh-genesis-complete} Complete

### Z-1 — msh-genesis complete: the program founded + msh2.1 shipped

M0: docs/msh founded (grounding pack → lens pair A/B → synthesis → rulings D-1..D-12 → design + roadmap + references + progress + program manual + specs README; docs/go/msh superseded by banner) — committed 18c34942 + 7cd4af54; `msh specs msh` clean. msh2.1: anchor integrity built by Mars-1 to the Venus-A triad — ONE shared marker list (canonical `.msh-memory.yaml`, 3 legacy spellings silent-windowed, old literals grep-proven gone from the call sites), anchor v1.1 additive `docs_root` resolved inside LoadMemoryConfig, docstrings synced, tool count pinned at 8; gates: build/vet green, 77 fresh test runs 0 fail, gofmt clean on touched files, Director 3-probe (live nested walk-up · legacy-marker root resolution · docs_root round-trip) green, mcpd hot-swap live (msh pid 70076), MCP-transport memory_project smoke green. The rung commit follows this entry (LAW-4).
