# msh — design lens B · the steelman (the maximal hot-context product)

> One of two independent lens documents of the **msh-genesis** debate (scope `msh-genesis`, 2026-07-02), argued
> per [aaw.architect-approach](../../../aaw/aaw.architect-approach.md) from the shared locked
> [genesis.grounding.md](./genesis.grounding.md). This lens argues the strongest case for the **maximal
> hot-context product** — capability at full strength, every cost named and priced. The sibling lens was argued
> independently and never read. This document PROPOSES; every fork ends at the Operator.

## §0 · Stance — the one-call pack, argued at full strength

The maximal product: a Claude agent opens a rung and **one call** returns the precise, budgeted, cited pack it
needs — memory notes ranked by a scorer that actually ranks (lexical · graph proximity · type · recency ·
staleness · role), the active program's docs sections carried in, the frontier's transcript signal included,
every line citing `path#heading`. The docs/ pattern becomes machine-legible so the program trees join the pack
engine; the aaw movement ends with **one routing authority** an agent can query. Fat always-loaded context is
replaced by tool-served, per-rung context.

The core claim: **this is composition, not invention.** The §1 census shows the expensive parts already built
and idle — the typed graph, the per-node hash, the heading slugs, the staleness engine, the live anchor, the
session join key, the embedding socket. The missing assembly is exactly the cheap part.

Pre-empting the steward objection ("69 notes; grep suffices; defer"): the product's consumer is an agent under
a token budget, not a person at a shell. The cost of *no* ranking is paid per-session, forever, as always-on
context load and hand-navigation; the maximal arms' costs are priced in their Steward parts.

## §1 · The grounded substrate — what exists today, and what it enables

Every capability the maximal product needs has a shipped seam (verified 2026-07-02; paths repo-relative; facts
not read directly cite the locked [grounding §2](./genesis.grounding.md) or the [design](../../../go/msh/msh.design.md)):

| # | As-built fact | Where | What it already funds |
|---|---|---|---|
| 1 | every call loads the WHOLE corpus into RAM — bodies + headings maps | `go/msh/memory/command/corpus.go:17-21,23-82` | pack assembly composes over already-resident data |
| 2 | per-node SHA256 computed on every walk | `corpus.go:49,144-147` | the cache key (F4) is already minted — the cache is a missing map |
| 3 | heading slugs extracted per note, accessor shipped | `corpus.go:70-74,156-161` | `path#heading` citations + section-granularity packs cost a formatter |
| 4 | typed graph: 7 edge kinds, per-node type + `superseded` status | `corpus.go:55,62-64`; [design §5](../../../go/msh/msh.design.md) | graph proximity, type weights, supersession demotion — ranking inputs, shipped |
| 5 | stale engine: 7 context-aware rules over the same graph | [design §6](../../../go/msh/msh.design.md) | per-note staleness demotion for the scorer |
| 6 | dormant embedding socket: `Hugot{Endpoint :8902, TimeoutSeconds 30}` + `Similarity{0.85, TopK 5}`, ZERO consumers | `go/msh/memory/internal/config/defaults.go:38-46` | the hybrid scorer's config exists today; F3 gives it a socket |
| 7 | live anchor `.msh-memory.json`, walk-up resolved, carries `current_rung` | `go/msh/memory/command/root.go:138-144`; grounding §2 | default args for the one-call pack — the scope key is live |
| 8 | `originSessionId` parsed onto every node (post-FX nested read) | [design §4, §8 resolution](../../../go/msh/msh.design.md) | the history join key is already on the node — a lookup, not a search |
| 9 | `history_search` shipped: sessionId + timestamp + role + snippet, newest-first, limit semantics | `go/msh/cmd/history.go:438-441,505-524` | the pack's frontier source returns exactly the needed row |
| 10 | tool registration is four additive registrar calls | `go/msh/cmd/main.go:173-180` | new tools = new lines; additive-minor evolution is the shipped pattern |
| 11 | speclint is a second link engine sharing `linkx` + the `Finding` vocabulary | [design §6.1](../../../go/msh/msh.design.md) | shape rules (F6) extend a shipped checker; no new tool |
| 12 | aaw roster `<scope>.registry.json` on disk; roles are free strings in aaw code | grounding §2 | a read-only role join needs no aaw edit — the fence holds |

An arm below is argued maximal only where a shipped seam funds it; where none does, the arm is forward-tense
and its full price appears in its Steward.

## §2 · The thesis in 2–4 calls

The product, as a rung-open session runs it (forward-tense; tool names per D-2):

1. **`memory_context {token_budget: 4000}`** — unset args default from the live anchor (`echo_mq` / `emq.4.2`;
   `role` from the aaw roster row when a scope is live). Returns THE pack: **§project** (the anchor header) ·
   **§memory** (top-ranked note sections, whole-note when budget allows, lead-section when tight, each cited
   `memory/echo_mq/echomq-3.0.0-wire-cutover.md#prod-build-gotchas`) · **§docs** (the rung's roadmap row + the
   design §§ it links) · **§history** (one budgeted snippet, or the prepared invocation) · **§budget**
   (requested / spent / dropped, every drop named).
2. **`memory_search {query: "IPv6 conn_opts", project: "echo_mq"}`** — the ad-hoc follow-up: ranked, cited rows
   over the same scorer.
3. *(optional)* **`history_search {…}`** — the prepared invocation carried in §history.

The same assembly registers as an MCP **prompt** (D-2), so a harness can inject the pack at session-open with
zero agent calls. Today a rung-open costs the always-loaded `MEMORY.md` index plus hand-navigation — thousands
of tokens spent whether relevant or not. The pack replaces that with one call whose cost is *chosen*
(`token_budget`) and whose contents are *accountable* — every line cited, every drop named.

## §3 · The forks, argued (F1–F9, the steelman arm of each)

Each fork argues this lens's arm in the four-part form of the [architect-approach](../../../aaw/aaw.architect-approach.md);
the Steward prices it honestly. F6 is refined (flagged). The pack's output schema is NOT a fork — a **contract
set** (the approach's second instrument), authored at msh2.5, reconciled against implementation + call sites.

### F1 · Store shape — flat store, scope as a contract KEY

**Rationale.** The engine ranks by keys; a retrieval scope must be expressible per note and cross-cutting (one
feedback note serving three programs), which a directory cannot express.

**5W.** **Why** — scoped packs need a scope signal on every note; today scope is implied by 5 ad-hoc subdirs
over a 44-note flat majority (grounding §2). **What** — a list-valued `project:` frontmatter key as the scope
authority; directories demoted to human convenience. **Who** — the scorer consumes; authors write one key.
**When** — with schema v2 at msh2.2 (M1). **Where** — `memory/` frontmatter + the corpus model.

**Steelman.** The code already treats the tree as non-authoritative: `classifyType` falls to basename heuristics
precisely so a moved file keeps its type (`go/msh/memory/command/corpus.go:84-123`) — the key completes a design
the code committed to. A key expresses what a directory cannot: multi-scope membership, scope rename without a
file move, honest partial membership. The re-shard alternative is a destructive migration of durable memory
that buys the scorer nothing: cross-cutting notes still need the key afterward.

**Steward.** An unset key must degrade honestly (containing-directory name, then unscoped) or absence becomes
silent exclusion from every scoped pack; the scope vocabulary must equal the anchor's project codes.

**Steelman REC:** keep flat; `project:` is the scope authority, backfilled at msh2.2; directories human-only.

### F2 · Frontmatter schema v2 + the index's future — the schema IS the feature space

**Rationale.** Every ranking signal not derivable from text must be a declared key; the schema is the scorer's
feature space. v2 adds `{project, status, review_after, tags}` to the shipped four.

**5W.** **Why** — `status: superseded` retires the 1024-byte body sniff; `review_after` declares staleness;
`tags` widen recall over dense-prose synonymy. **What** — the v2 keys, a 69-note audited backfill, a
msh-GENERATED companion beside the hand-curated `MEMORY.md`. **Who** — the scorer; the Operator reviews the
companion. **When** — msh2.2 (M1); companion msh2.9 (M3). **Where** — `memory/` + `internal/frontmatter`.

**Steelman.** The sniff is the exhibit: supersession — a hard ranking demotion — is today inferred from a
substring match over the first 1KB of body (`corpus.go:125-142`); one declared key ends that class of inference.
The backfill is at the cheapest point of the corpus's life: 69 notes, one audited rung, `memory_audit` the gate.
The companion is evidence-before-retirement: the derived index runs beside the hand one, divergence is
reviewable, retirement is an Operator ruling on observed fidelity.

**Steward.** Each v2 key is a multi-year parse invariant; the backfill is a mass edit of durable memory — fenced
out of this run (locked §1.5), movement-scheduled at M1 with backup + byte-diff discipline. The companion must
never write `MEMORY.md`.

**Steelman REC:** v2 keys + audited backfill at msh2.2; companion at msh2.9; hand index retires only on evidence.

### F3 · Retrieval algorithm — hybrid behind a `Scorer` seam; lexical composite ships first

**Rationale.** Pack quality is ranking quality; this fork decides whether ranking is an architecture or an
afterthought. The arm: a `Scorer` interface (forward-tense), first implementation a deterministic lexical
composite — BM25F over name/description/body + graph proximity + type/recency weights + staleness demotion.

**5W.** **Why** — dense bold-lead prose defeats naive substring search; every needed signal already exists with
no composition (§1 rows 4–5). **What** — the `Scorer` contract + the composite lexical v1; weights via the
existing config machinery. **Who** — `memory_search` + `memory_context`; golden-rank fixtures pin it. **When** —
msh2.3; graph proximity msh2.4; the Hugot consumer msh2.10. **Where** — a new `memory/internal` scoring package.

**Steelman.** Every input the composite needs is computed on every call *today*: the typed graph, per-node type
and status, stale findings. Determinism is itself a capability: golden-rank fixtures gate regressions call by
call, which no embedding offers. The dormant seam is real: the `Hugot` + `Similarity` blocks are parsed into
every config resolve with zero consumers (`defaults.go:38-46`); the interface gives that carried config its
socket, so msh2.10 plugs in without touching a call site. The named cost — an interface with one implementation
— beats retrofitting a seam under a shipped monolithic ranker.

**Steward.** Held honest by capping the named implementations at two (lexical, hybrid) and by the msh2.10
evidence gate — nothing listens on :8902 today, and a local model server is an operational dependency the
Operator prices separately. Weights-as-config invites tuning drift; the golden fixtures are the counterweight.

**Steelman REC:** `Scorer` + lexical composite at msh2.3; the Hugot hybrid scheduled at msh2.10, evidence-gated.

### F4 · Index lifecycle — the in-process re-stat cache; the disk index rejected on capability grounds

**Rationale.** Every tool call re-walks, re-parses, and rebuilds the typed graph (`corpus.go:23-82`); without a
cache `memory_context` is O(k·corpus) per call. The long-lived server under mcpd is the natural cache host.

**5W.** **Why** — ms-latency packs; assembly calls scan/graph/stale/score internally without multiplying walks.
**What** — an in-process corpus snapshot invalidated by per-file re-stat on `{size, mtime}` with the SHA256
backstop; a changed file re-parses whole. **Who** — every tool, transparently. **When** — msh2.4. **Where** —
`go/msh/memory/command`; the facade already owns `corpusSource` (bodies + headings resident, `corpus.go:17-21`).

**Steelman.** The cache key is already minted: every node carries its body SHA256 on every walk
(`corpus.go:49,144-147`) — the arm adds a map and a re-stat loop, not new machinery. Sixty-nine stats per call
is microseconds; correctness stays file-authoritative because a re-stat precedes every read — the files remain
the single authority, the cache a *verified mirror*. The maximal-looking arm — a persistent disk index — is
rejected on capability grounds: it adds a second authority, a corruption surface, and a migration story, and
buys latency the RAM snapshot already delivers.

**Steward.** One standing invariant added: no tool reads the corpus except through the snapshot API.
Invalidation is contained (compare-and-reparse; no TTLs, no watchers); mtime-only trust is the known trap, and
the SHA backstop must be tested as such.

**Steelman REC:** in-process `{size, mtime, SHA256}` re-stat cache at msh2.4; the disk index CHOSEN-AGAINST.

### F5 · Pack composition — search first, context composed ON it; role joined read-only; sections, not blobs

**Rationale.** D-2 locks the product shape; F5 is its internal composition. Two tools with a composition arrow —
`memory_search` the testable retrieval primitive, `memory_context` = search × budget × dedupe × citations — keep
the risky surface (ranking) hardening under real use before the pack contract pins.

**5W.** **Why** — a ranked list is independently gateable; a pack is debuggable by its parts only if the parts
are tools. **What** — `memory_search {query, project, type, limit}` → ranked cited rows; `memory_context
{project, rung, role, task, token_budget}` → the §2 pack; the same assembly as the MCP prompt. **Who** — any
agent at rung-open. **When** — search msh2.3 · context msh2.5 · prompt msh2.6. **Where** — the `memory/command`
facade; registration extends `buildMCPServer` additively (`main.go:173-180`).

**Steelman.** The citation substrate is already parsed: heading slugs are extracted for every note on every walk
(`corpus.go:70-74`, accessor `:156-161`) — `path#heading` costs a formatter. Section granularity makes
`token_budget` a real contract and aligns with how the corpus is authored (dense bold-lead prose, grounding §2):
whole note when budget allows, lead section when tight, truncation only at heading boundaries. Role: the aaw
roster is a file on disk — a read-only join needs no aaw change, honors the no-`go/aaw` fence, degrades to the
`role` param when absent.

**Steward.** `memory_context`'s output schema becomes THE public contract of the program — the largest freeze
liability in this lens. Priced two ways: search ships first so ranking churn precedes the pack pin, and the pack
schema is a contract set (§3 head) reconciled against implementation and call sites.

**Steelman REC:** search-then-context; prompt at msh2.6; role param-first, roster default; sections; `path#heading`.

### F6 · The docs/ scope pattern — shape rules + DIRECT ENGINE INGESTION (refined: the posed arms merged)

**Rationale.** The pack draws on `memory/` AND the docs/ program trees, but the fork as posed (generated index
vs convention-only) omits the strongest arm: the engine ingesting normalized docs/ trees *directly* as
additional corpus roots, with speclint-v2 shape rules making them reliable enough to ingest — **flagged: F6
refined by merging its arms.**

**5W.** **Why** — a rung pack must carry the rung's roadmap row and the design §§ it cites; three different
ledger placements across programs prove convention alone does not hold (grounding §2). **What** — speclint-v2
shape rules (artifact set · triad naming · ledger placement) + multi-root ingestion via the same walker/graph
machinery; no generated index. **Who** — the pack engine; authors get shape findings at authoring time.
**When** — msh2.7 (M3). **Where** — `internal/speclint` (extend) + the corpus loader (root → roots).

**Steelman.** The two engines already share their substance: speclint reuses `linkx` and emits the same
`Finding` vocabulary as the stale engine (design §6.1) — shape rules are new checks in a shipped checker. Direct
ingestion means zero generated artifacts: no side index drifting against the tree, no regeneration discipline,
no second authority — the tree IS the index, exactly as `memory/` is today, serving people (one convention) and
the engine (every program tree pack-eligible) at once. A generated content index would be a cache wearing a
contract's name; F4 owns caching.

**Steward.** Multi-root ingestion widens the corpus model — a real loader API change, priced once; docs trees
are 10–50× the memory corpus in bytes, so F4's cache becomes load-bearing (cache before ingestion). Docs nodes
carry a root tag so memory-only invariants (the orphan rule, the index exemption) do not leak across roots.

**Steelman REC:** speclint-v2 shape rules + direct multi-root ingestion at msh2.7; no generated index artifact.

### F7 · Anchor + scope normalization — the multi-project anchor + the write-back tool

**Rationale.** The repo verifiably runs several programs at once while the anchor names exactly one (the live
anchor pins `echo_mq / emq.4.2`); every context switch is a hand edit of JSON. The anchor is the pack's
default-args source (F5), so its fidelity bounds the one-call promise.

**5W.** **Why** — unset `memory_context` args default from the anchor (D-2); it must be cheap to keep true.
**What** — schema v1.1, additive: `projects[]` + an `active` pointer; `memory_project set {name?, rung?,
status?}` writing atomically; the wart collapsed to one documented spelling (probe `root.go:163-174` · config
loader grounding §2 · docs `main.go:187`, `root.go:58`). **Who** — the Operator + Director at rung-open.
**When** — msh2.1, the locked first build rung (D-1). **Where** — `go/msh/memory/command/{project,root}.go`.

**Steelman.** The resolver already does the hard part — anchor precedence and marker ascent are shipped
(`root.go:138-144,150-160`); v1.1 is a schema widening, not a resolver rewrite. The write-back tool is the
honest maximal move: state that changes at rung cadence should be written by a tool — the live anchor's
`emq.4.2`, stale by hand-edit inertia while other programs ship, is the observable alternative. The full price,
stated: the FIRST write surface in a read-only tool. The master invariant survives literally — the anchor is
repo-root config, not the `memory/` corpus — restated: *corpus read-only; the anchor is the single writable
config, written atomically or not at all.*

**Steward.** A write tool can corrupt the file every session stands on: temp+rename atomic write,
schema-validate before write, refuse on parse error, never create-from-nothing without an explicit arg. The
multi-project shape must not change walk-up semantics (nearest anchor wins — worktrees keep working).

**Steelman REC:** schema v1.1 `{projects[], active}` + `memory_project set` at msh2.1; one marker spelling.

### F8 · The aaw movement's shape (M4) — server-data-first; the routing authority is the server

**Rationale.** The routing drift is structural, not editorial: roles/formations restated 3–4×, the LAWS quoted
3×, zero MCP-tool references in the core docs, the D-7/D-8 corrections stranded outside x.md (grounding §2).
Prose restatement is *why* it drifted; a docs-only rewrite reproduces the cause with fresher text.

**5W.** **Why** — an agent's first question ("what is this role's charter on this scope?") should have one
queryable answer. **What** — aaw serves routing/formations (forward-tense query tools), mcp7 folded in the same
seam (18→22, additive-minor, selftest re-pinned); docs/aaw rewritten short, citing the served table. **Who** —
every spawned agent, the ship skills, CLAUDE.md. **When** — M4; **roadmap text only in this run** (D-1).
**Where** — `go/aaw` (future rungs, fence Operator-ruled) + `docs/aaw`.

**Steelman.** Roles are free strings in aaw's code with only `director` special-cased (grounding §2) — the
server is already the neutral place where roles exist without semantics; serving the semantics beside the
strings closes the loop without a second registry. The additive-only law and the selftest tool-count pin are the
safety case that makes 18→22 a bounded, provable change. The exit gate is measurable — the restatement census
reaches one; a docs-only M4 leaves the recurrence mechanism intact, re-forked by the next skill edit.

**Steward.** Coupling M4 to server rungs makes the movement heavier and puts final docs correctness downstream
of a build — priced by sequencing inside M4 (routing tools land, then the docs pin to them). Formation semantics
entering a server is squarely inside the Operator's decision rights; the served table is a frozen contract aaw
carries for years.

**Steelman REC:** M4 = server-data-first, sequenced tools-then-docs; 18→22 additive fold; text-only this run.

### F9 · History in packs — budgeted frontier snippets, hard-capped, with a declared degrade path

**Rationale.** The frontier is exactly what the corpus lacks: a note is written *after* distillation, so the
current rung's freshest signal — the Operator's last words about it — exists only in the transcripts. A
pointer-only pack under-serves the precise moment the product exists for: rung-open on live work.

**5W.** **Why** — agents under token and latency pressure do not reliably chase pointers; a carried snippet is
read, a pointer is a maybe. **What** — ONE `history_search` per pack (terms from rung/task), §history capped at
~10% of `token_budget`; over-latency or under-relevance degrades to the prepared invocation + `originSessionId`
pointers — loudly, never silently. **Who** — the rung-opening agent. **When** — msh2.8 (M3). **Where** — the
assembly composing the shipped tool (`registerHistoryTool` threads the repo root, `history.go:505-524,438-441`).

**Steelman.** The join key is already on every node — `originSessionId` parses onto the node today (§1 row 8),
so "the sessions behind this note" is a lookup, not a search — and the shipped tool already returns exactly the
row the pack needs: sessionId + timestamp + role + snippet, newest-first. The named price is the scan — a full
per-query pass over the project's JSONL transcripts (grounding §2) — paid once per pack, bounded by `limit` and
the term set. The gate specifies its own liveness: §budget reports whether history RAN, was CAPPED, or DEGRADED
— a silently empty §history is a gate failure.

**Steward.** Transcripts are the least-curated source in the pack; a weak snippet spends budget a strong note
wanted — the 10% cap and notes-first ordering bound the blast radius to one section. The scan cost grows with
transcript volume; the latency cap is enforced in the assembly. Local transcripts, ephemeral packs.

**Steelman REC:** budgeted snippets at ~10% hard cap with a declared RAN/CAPPED/DEGRADED report; msh2.8.

## §4 · The proposed msh2 ladder

Deltas from the grounding's candidate ladder, flagged: the `Scorer` seam pinned at msh2.3; docs multi-root
ingestion explicit at msh2.7; msh2.8 carries snippets, not pointers only; M4 is two named server-data-first
rungs; msh2.10 scheduled-not-orphaned. **[FENCE]** marks an Operator-ruled fence change at movement-open. Every
rung ships.

| Rung | M | Goal | Boundary | SHIPS (usable that day) |
|---|---|---|---|---|
| msh2.1 | M0/M1 | anchor integrity: wart → one spelling; schema v1.1 `{projects[], active}`; `memory_project set` | `go/msh` | a trustworthy anchor + a rung-switch tool replacing hand-edited JSON |
| msh2.2 | M1 | frontmatter v2 `{project, status, review_after, tags}` + 69-note audited backfill | `go/msh` + `memory/` **[FENCE: one scoped mass-edit rung]** | scoped scan/stale (`project` filter); the supersession sniff retired |
| msh2.3 | M2 | `memory_search` v1: the `Scorer` seam + the lexical composite | `go/msh` | ranked, cited retrieval replacing hand-grep over the corpus |
| msh2.4 | M2 | the corpus snapshot cache (`{size, mtime, SHA256}` re-stat) + graph-proximity scoring | `go/msh` | ms-latency on all tools; link-aware ranking |
| msh2.5 | M2 | `memory_context` — THE pack (assembly · budget · dedupe · `path#heading` citations · §budget report) | `go/msh` | the one-call rung-open pack of §2 |
| msh2.6 | M2 | the MCP prompt + role awareness (read-only aaw roster join) | `go/msh` | role-shaped packs; harness-injectable at session-open |
| msh2.7 | M3 | speclint-v2 shape rules + docs multi-root ingestion | `go/msh` (+ `docs/msh` as exemplar) | docs sections in packs; the pattern lintable everywhere |
| msh2.8 | M3 | history in packs: budgeted frontier snippets + declared degrade | `go/msh` | frontier context carried, not pointed at |
| msh2.9 | M3 | the generated MEMORY companion view | `go/msh` | the index derived + auditable against the hand index |
| msh2.10 | M3→deferred | the Hugot hybrid `Scorer` (evidence-gated: :8902 live + a measured lexical-miss corpus) | `go/msh` | semantic recall where lexical misses, same socket |
| msh2.11 | M4 | aaw routing surface: routing/formation query tools; 18→22 additive fold; selftest re-pinned | `go/aaw` **[FENCE: M4 Operator ruling]** | one queryable routing authority |
| msh2.12 | M4 | docs/aaw rewrite-to-pointers: short, mcp-tools-forward; restatement census → 1 | `docs/aaw` **[FENCE: M4 Operator ruling]** | agent-fast aaw docs citing the served table |

This run builds msh2.1 only (D-1); everything below the first row is roadmap material the genesis consolidates.

## §5 · Boundary + gates posture

**Boundary.** This run: `docs/msh/` + two supersede banner lines in `docs/go/msh/` (genesis) and `go/msh/`
(msh2.1) — the locked fence, unchanged by this lens. On the ladder, the maximal arms require exactly three fence
changes, each named in §4 and each an Operator ruling at movement-open: the scoped `memory/` backfill rung
(msh2.2) and the M4 pair (`go/aaw`, `docs/aaw`). Honest fences are the maximal ladder's discipline.

**Gates.** The go/ workspace law carries: `GOWORK=off go build|vet|test` + `gofmt -l` clean, per-module. On top,
each capability rung brings a gate specified to prove its own liveness — never satisfiable by a no-op:

- **tool-count pin** — the registered tool count pinned in a test (aaw's selftest discipline); each addition re-pins;
- **golden-rank fixtures** — ranked order over a fixture corpus asserted byte-stable; a weight change is a visible diff;
- **citation gate** — every pack `path#heading` resolves against the live tree (speclint re-used) or the gate fails;
- **budget gate** — the pack fits `token_budget`; §budget accounts for every drop; silent overflow or omission fails;
- **liveness gate** — §history reports RAN/CAPPED/DEGRADED; the roster join JOINED/ABSENT; presence proves itself;
- **latency gate** — pack assembly under a stated ms bound on the live corpus, measured in test (funded by msh2.4);
- **anchor write gate** — `memory_project set` round-trips a parse; a corrupted-input fixture is refused, never half-written;
- **additive MCP evolution** — locked (grounding §1.6); every new tool is a minor; no breaks, no renames.

## §6 · The surfaced-forks table

The lens's arms, side by side, for the Director's synthesis and the Operator's ruling. This lens decides nothing.

| Fork | The steelman arm | REC (one line) | What rules it |
|---|---|---|---|
| F1 store shape | flat + `project:` key as scope authority | keep flat; key backfilled at msh2.2 | whether scope is a key or a directory — data-model rights |
| F2 schema v2 + index | full v2 feature space + generated companion | v2 + audited backfill; companion at msh2.9; hand index retired only on evidence | the mass-edit allowance + the index's authority |
| F3 retrieval | hybrid-behind-`Scorer`; lexical first | `Scorer` + composite at msh2.3; Hugot scheduled at msh2.10, evidence-gated | the interface commitment + the future model dependency |
| F4 index lifecycle | in-process re-stat cache | cache at msh2.4; disk index CHOSEN-AGAINST | the one-snapshot-API invariant |
| F5 pack composition | search-then-context; sections; roster-joined role | two composed tools; prompt at msh2.6; `path#heading` | the pack schema freeze — THE public contract |
| F6 docs pattern **(refined — arms merged)** | speclint-v2 rules + direct multi-root ingestion | both at msh2.7; no generated index artifact | accepting ingestion over a side artifact; loader API change |
| F7 anchor | multi-project v1.1 + `memory_project set` | ship at msh2.1; one marker spelling | the FIRST write surface — the invariant restatement |
| F8 aaw movement | server-data-first; docs-as-pointers | M4 = routing tools then docs rewrite; 18→22 fold; text-only this run | movement weight + formation policy entering a server |
| F9 history | budgeted snippets ~10% + declared degrade | snippets at msh2.8 | transcript curation risk vs frontier value |

Added forks: none; F6 refined (flagged). The pack schema is a contract set at msh2.5 (§3 head). The Operator rules.
