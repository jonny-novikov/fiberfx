# msh genesis · Director synthesis — the lens-pair fork ledger

> **The Director STAGES the disagreement, not averages it**
> ([aaw.architect-approach](../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Inputs: the
> two independently-authored lens docs — [A · Steward](./msh.design.A-steward-lens.md) (250L) and
> [B · Steelman](./msh.design.B-steelman-lens.md) (350L) — both argued from the locked
> [grounding pack](./genesis.grounding.md); neither read the other. The three judgments stay separate: the
> architects argued, this synthesis stages, the Operator rules. **No fork is decided below.** Rulings are
> recorded in §5 as they land (ledger channel `{msh-genesis-decisions}`).

## §0 · The result in one line

The lenses **CONVERGED on the engine's spine** — flat store scoped by a `project:` key, a deterministic
lexical scorer behind a `Scorer` seam, `memory_search` first with `memory_context` composed ON it,
`path#heading` citations, and **no second authority anywhere** (disk index, generated docs index, and
generated-MEMORY.md-replacement all rejected by both) — and **DIVERGED on eight Operator questions** in three
bands: the *scope band* (F7 does msh grow its first write surface at msh2.1 · F6 do the docs trees join the
pack engine · F9 do transcripts ride in packs), the *schedule band* (F4 cache now-vs-evidence · F2 schema
2-key-vs-4-key), and the *contract band* (F5 pack granularity · F5 role source · F8 where the aaw routing
authority lives).

## §1 · The cross-lens fork ledger

| Fork | Lens A (Steward) | Lens B (Steelman) | Verdict |
|---|---|---|---|
| **F1 store shape** | flat + `project:` key; organic subdirs; no mass re-shard | flat + **list-valued** `project:` key as scope authority; dirs human-only | **CONVERGED** (sub-nuance: key arity + unset-key degrade → the msh2.2 triad) |
| **F2 schema v2** | contract = `project`+`status` only; a key is contract only with a day-one consumer | full `{project, status, review_after, tags}`; the schema IS the scorer's feature space | **DIVERGED** — breadth (§3.2). Converged inside it: staged/audited backfill as its own rung; MEMORY.md stays hand-curated; companion view evidence-before-retirement |
| **F3 retrieval** | pure-Go lexical behind `Scorer`; miss-log day one; Hugot deferred-standing (trigger: logged miss-class) | same lexical composite behind `Scorer` at msh2.3; Hugot **scheduled** msh2.10, evidence-gated | **CONVERGED** on substance (seam + deterministic v1 + golden-rank fixtures + evidence before Hugot); placement nuance → Seams |
| **F4 index lifecycle** | per-call rebuild stands — **0.36s measured** full audit incl. startup; cache evidence-gated on p95; cache rung dissolved | in-proc `{size, mtime, SHA256}` re-stat snapshot at msh2.4; one invariant (all reads via snapshot API); ms-latency + no multiplied walks inside pack assembly | **DIVERGED** — schedule (§3.1); both reject the disk index. **COUPLED to F6:** B itself prices ingestion as "cache before ingestion" |
| **F5 pack composition** | search → context; prompt WITH context rung; **whole-note** granularity; role **param-only** | search → context; prompt its own rung; **section** granularity (slugs already parsed); role **param-first + read-only aaw-roster default** | **CONVERGED** on composition + citations; **DIVERGED** on granularity (§3.4) and role source (§3.5); prompt timing → Seams |
| **F6 docs pattern** | speclint-v2 shape rules only; docs linted, **not ingested**; no generated index | **refined (flagged):** shape rules + **direct multi-root ingestion** — docs trees become corpus roots, packs carry a §docs section; no generated index | **DIVERGED** — product scope (§3.3); converged inside it: no generated per-program index artifact; `docs/msh/` the first exemplar |
| **F7 anchor** | one anchor, one spelling, additive v1.1 `docs_root`; **NO write-back** (first write surface refused; trigger: worktree parallelism) | multi-project v1.1 `{projects[], active}` + **`memory_project set`** write-back at msh2.1; invariant restated (corpus read-only; anchor the single writable config, atomic) | **DIVERGED** — shapes **this run's build rung** (§3.6); converged inside it: the wart collapses to one spelling at msh2.1 |
| **F8 aaw movement (M4)** | docs-first: short docs/aaw + ONE routing-table doc + the citation sweep; server untouched; mcp7 unbundled | server-data-first: aaw serves routing/formations (18→22 additive fold, selftest re-pinned), docs become pointers; census→1 measurable | **DIVERGED** — M4 authority (§3.7); converged: M4 is roadmap text only in this run (D-1) |
| **F9 history in packs** | `originSessionId` pointers + a prepared `history_search` invocation; snippets CHOSEN-AGAINST v1 | ONE budgeted search per pack; §history ≤10% hard cap; **RAN/CAPPED/DEGRADED declared**, degrade to pointers | **DIVERGED** — pack content (§3.8) |
| Ladder shape | 8 scheduled rungs; product at msh2.4; deferred-standing set with named triggers | 12 scheduled rungs; product at msh2.5; 3 `[FENCE]` rungs named | derives from the rulings; consolidated in the roadmap |

Added forks: none (A); F6 refined by merging its posed arms (B, flagged). Both lenses independently name the
`memory_context` output schema **the program's largest freeze liability** and route it to the
architect-approach's second instrument — a **contract set** authored with the pack rung and reconciled against
implementation + call sites. That shared instinct is adopted as the pack rung's method regardless of any ruling.

## §2 · The convergences — build-ready regardless of rulings

- **Store:** `memory/` stays flat; scope arrives as a `project:` frontmatter key; organic subdirs remain; no
  mass re-shard, ever, without a ruling. The backfill (whatever the schema) is its own staged, audited,
  byte-diffed rung — never a shipped msh write path.
- **Index authority:** the files are the only authority. No persistent disk index (both lenses,
  independently, on One-authority grounds). MEMORY.md stays hand-curated; any generated view is a COMPANION
  whose retirement is an evidence-based Operator ruling.
- **Scoring:** a `Scorer` interface with a deterministic pure-Go lexical composite v1 (BM25F over
  name/description/body + type/recency weights + staleness demotion + graph proximity), pinned by
  golden-rank fixtures; ties broken by path. Hugot/embeddings never ship before an evidence gate (:8902 live
  + a demonstrated lexical miss-class from a day-one miss-log).
- **Product composition (inside D-2):** `memory_search` ships before `memory_context`; the pack is a
  budgeted fold over search; unset args default from the live anchor; every pack line cites `path#heading`;
  the MCP prompt registers the same assembly. A §budget accounting (requested/spent/dropped) is part of the
  pack contract (B's gate culture; A-compatible).
- **The wart:** the three-way config-marker spelling collapses to ONE canonical name at msh2.1 (no such file
  exists on disk — the zero-migration moment). Anchor schema changes are additive.
- **Docs enforcement floor:** speclint-v2 shape rules (artifact set · triad naming · ledger placement) in the
  existing `specs` tool; findings with `file:line`; `docs/msh/` is the pattern's first exemplar; **no
  generated per-program content index**, and nothing new named `*.registry.json`.
- **Evolution law:** additive-minor MCP tools only; the registered tool count pinned in a test and re-pinned
  per addition (aaw's selftest discipline adopted); the live server never killed — mcpd hot-swap + `/mcp`
  reconnect; `GOWORK=off` gates.
- **M4 in this run:** roadmap text only. Both lenses honor the D-1 fence.

## §3 · The divergences — staged for ruling

### §3.1 · F4 — the cache: schedule it, or gate it on a number? (couples §3.3)
**A:** the heaviest full-corpus command measures **0.36s wall including process startup and all seven stale
rules** on the live corpus; a cache bought now buys latency nobody is losing and costs a coherence invariant
tested forever; the fallback is pre-shaped and its trigger is a number (measured p95), not a debate.
**B:** pack assembly composes scan+graph+stale+score in ONE call — without a snapshot the engine re-walks per
internal pass; the cache key (per-node SHA256) is already minted on every walk, so the arm is a map plus a
re-stat loop; the files stay authoritative because a re-stat precedes every read.
**Coupling:** if §3.3 rules docs ingestion IN, B's own Steward line applies — docs trees are 10–50× the
memory corpus, and the cache becomes load-bearing BEFORE ingestion.
**Rules it:** whether a standing coherence invariant is bought on capability grounds or on a measured number.

### §3.2 · F2 — the schema: two keys or four?
**A:** a key is a contract only if a shipped rule or the scorer consumes it on day one — `project` (scoping)
and `status` (retires the 1KB supersession body sniff) qualify; `tags` duplicates `[[wiki-links]]` + the
hand-written descriptions (a second vocabulary = a drift surface); no shipped rule reads `review_after`.
**B:** the schema is the scorer's feature space; declare it once at the cheapest moment of the corpus's life
(69 notes, one audited backfill) instead of re-opening frontmatter per movement; `review_after` turns
staleness from inference into declaration; `tags` widen recall over dense-prose synonymy.
**Rules it:** the authoring tax per note vs a second backfill later; whether recall-widening keys precede or
follow the miss-log evidence.

### §3.3 · F6 — do the docs trees join the pack engine? (the product-scope headline)
**A:** enforcement only — speclint-v2 rules make the pattern lintable; the pack serves memory notes; docs
stay navigable by link, and the engine's corpus model stays one-root simple.
**B:** the rung pack must carry the rung's roadmap row + the design §§ it cites — that is what "hot context
for the current rung" means; ingestion via the same walker/graph machinery, docs nodes root-tagged so
memory-only invariants do not leak; no generated artifact — the tree IS the index; shape rules exist
precisely to make the trees reliable enough to ingest.
**Rules it:** the product's scope — memory-recall engine vs program-context engine; a real loader API change
(root → roots) priced once; the F4 coupling above.

### §3.4 · F5a — pack granularity: whole notes or sections?
**A:** the notes are short dense distillations by construction; a section splitter adds a parser + a citation
ambiguity for near-zero budget win at 69 notes.
**B:** section granularity is what makes `token_budget` a real contract (whole note when budget allows, lead
section when tight, truncation only at heading boundaries); the heading slugs are already parsed on every
walk — the splitter is a formatter, not a parser.
**Rules it:** the pack contract's truncation semantics — the schema both lenses call the biggest freeze.

### §3.5 · F5b — the `role` signal: param-only, or read-only aaw-roster default?
**A:** aaw roles are FREE STRINGS with only `director` special-cased — a cross-server coupling to a surface
aaw never promised; `role` stays a scorer param in msh's own config.
**B:** the roster is a file on disk; a read-only join needs no aaw edit, honors the go/aaw fence, degrades to
the param when absent, and makes the bare rung-open call role-correct with zero args.
**Rules it:** whether msh may read another server's on-disk artifact as a soft default — a coupling-posture
question, not a code-size one.

### §3.6 · F7 — the anchor at msh2.1: fix-and-document, or multi-project + msh's first write surface?
**A:** one anchor, one spelling, additive `docs_root`; the multi-project shape designs for a work pattern the
live anchor disproves (it names exactly one project); the write-back tool would be msh's FIRST write surface,
breaking the read-only invariant to save one hand edit of a JSON file. Trigger named: real worktree
parallelism reopens the fork.
**B:** the anchor is the pack's default-args source, so its fidelity bounds the one-call promise — and the
live anchor's `emq.4.2` is exactly the hand-edit-inertia exhibit; the invariant survives restated (*corpus
read-only; the anchor is the single writable config, temp+rename atomic, schema-validated, refuse-on-parse-
error*); walk-up semantics unchanged so worktrees keep working.
**Rules it:** this run's build scope (D-1 locks msh2.1 as the rung) + the read-only law's exact wording.

### §3.7 · F8 — M4: where does the routing authority live?
**A:** the census defect is prose redundancy — a docs defect gets a docs fix: a short mcp-tools-forward
docs/aaw + ONE routing-table doc + the priced citation sweep of the five ship skills; serving formations from
the server data-izes law and creates the second authority One-authority forbids; "the seam is open" urgency
is false under additive-only evolution.
**B:** the drift is structural, not editorial — restatement is WHY it drifted, and a docs-only rewrite
reproduces the cause with fresher text; roles already live in the server as free strings, so serving the
semantics beside the strings closes the loop; 18→22 is bounded by the additive law + the selftest pin; the
exit gate is measurable (restatement census reaches one).
**Rules it:** formation policy entering a server (squarely the Operator's decision right) vs a standing
human sweep discipline. May be RULED now (the roadmap writes M4 to it) or carried as the named M4-open fork.

### §3.8 · F9 — history: pointers, or one budgeted snippet with a declared degrade?
**A:** the notes ARE the distillation; transcripts are the least-curated, mutating source — a snippet-bearing
pack is non-reproducible, and `history_search` is the most expensive call in the toolchain; the pointer is
free (the join key is on every note). Reopen trigger: the miss-log shows pointers systematically unfollowed.
**B:** the frontier — the Operator's last words about the live rung — exists ONLY in transcripts; agents
under pressure do not chase pointers; ONE search per pack, ≤10% hard cap, and the §budget line must declare
RAN / CAPPED / DEGRADED so a silently empty §history is a gate failure, not a shrug.
**Rules it:** pack reproducibility vs frontier value; the cost profile of a per-pack transcript scan.

## §4 · Carried to the roadmap's Seams (deferrable nuances, named)

- **Hugot placement** — scheduled tail rung (B: msh2.10) vs deferred-standing with named triggers (A); the
  evidence gate itself is converged.
- **Key arity + degrade** — scalar vs list-valued `project:`; unset-key degrade order — settled in the
  msh2.2 triad.
- **Prompt registration timing** — with the context rung (A) vs its own rung (B) — settled by ladder length.
- **The msh2.2 backfill fence** — one scoped `memory/` mass-edit rung, staged + byte-diffed (both lenses) —
  restated at M1-open for the Operator's explicit allowance.

## §5 · Rulings (Operator, 2026-07-02, two gate rounds; ledger channel `{msh-genesis-decisions}`)

- **D-5 · F7 (§3.6)** — msh2.1 is **read-only minimal**: one canonical marker spelling + additive v1.1
  `docs_root`; NO write surface. Multi-project + `memory_project set` reopens on real worktree parallelism.
- **D-6 · F6 (§3.3)** — the docs trees **JOIN the pack engine**: shape rules first, then direct multi-root
  ingestion (root-tagged nodes); no generated index artifact, ever.
- **D-7 · F4 (§3.1)** — the snapshot cache is **SCHEDULED before ingestion** (the conditional arm, resolved
  by D-6); the disk index CHOSEN-AGAINST at any size; A's 0.36s stands as the recorded pre-cache baseline.
- **D-8 · F2 (§3.2)** — schema v2 = **{project, status, review_after}**, with a new review-due stale rule as
  `review_after`'s day-one consumer; `tags` deferred to miss-log evidence.
- **D-9 · F5a (§3.4)** — packs are **section-capable**: whole note when budget allows, lead section when
  tight, truncation only at heading boundaries; `path#heading` in every mode.
- **D-10 · F5b (§3.5)** — `role` is a **caller param** in v1; the default joins the SERVED routing authority
  when D-12's tools ship (a tool contract, not a scraped file).
- **D-11 · F9 (§3.8)** — history rides as **pointers + a prepared invocation** in v1; the ≤10% snippet tier
  ships on miss-log evidence, adopting the RAN/CAPPED/DEGRADED declared-degrade contract verbatim.
- **D-12 · F8 (§3.7)** — M4 is **server-data-first**, sequenced tools-then-docs; the ship-skills +
  CLAUDE.md citation sweep, the duplicate-progress-file dedup, and the D-7/D-8 x-mode fold ride the docs
  rung; the go/aaw + docs/aaw fences are re-ruled at M4-open.

The losing arms keep their steelman on record in §3 and in the lens docs; every reopen trigger is named in
the roadmap's deferred-standing set.
