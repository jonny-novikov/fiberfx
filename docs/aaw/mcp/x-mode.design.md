# x-mode — the protocol design record (aaw-mcp Design Phase, stage D4)

> **The protocol-side D4 deliverable** of the `aaw-mcp` Design Phase, Director-authored
> (ccl-aaw-mcp-1) under the deliverable split the Operator ratified in-session 2026-06-11
> (ledger D-9): the server-side spec pair `aaw.mcp.design.md` + `aaw.mcp.roadmap.md` is the
> Venus-3 Senior Consolidator's deliverable (D-8); **this document records what the phase taught
> about X-MODE itself** — the formation correction (D-7), the synthesis-agent rule (D-8), the
> protocol-document deltas the phase earned, and the protocol↔v2-server binding. Status:
> **PROPOSED** — nothing here is canon, and no protocol document is edited, before Operator
> approval; the fenced edits are itemized in §3 with their landing vehicles. Framing per
> LAW-3.1, propagated to any prompt or edit derived from this record.

Authority chain: `aaw.mcp.progress.md` D-6 (synthesis delegation + the Director picks) → D-7
(the formation correction, Operator lock) → D-8 (the synthesis-agent rule + the spec-pair
deliverable, superseding D-6's execution) → D-9 (the two-document split). Evidence base:
`design/apollo.evaluation.md` (DESIGN-GRADE; W-1/W-2/W-3; §4.3), the two designs, the two
cross-reviews, and this session's live findings.

---

## 1 · The corrected Design Phase formation (D-7, Operator lock)

**The standing Apollo evaluation stage is removed from Design Phases.** The Venus-1 ↔ Venus-2
cross-review IS the evaluation: two independent designs, each adversarially reviewing the other,
already produce the agreements/challenges/grafts and the convergence/divergence map a synthesis
needs. The corrected formation:

```
Venus-1 ∥ Venus-2  →  cross-review  →  synthesis  →  OPERATOR APPROVAL
(independent designs   (each reviews     (Director — or a real-venus      (feedback gate —
 + ADR set each,        the sibling's;    Senior Consolidator for a        nothing is canon,
 identical locked       the concessions   large corpus, per D-8 —          NO code, before it)
 constraints, distinct  ARE the           authoring the spec-system
 leading lenses)        evaluation)       pair design + roadmap)
```

- **Apollo's high-utilization home is the Flat-L2 topology inside a rung** — evaluating results
  between Mars-1 and Mars-2 iterations and the post-build verification — not long-form design
  adjudication. Rationale (Pragmatic Agile Delivery, D-7): the D3 Apollo pass in the `aaw-mcp`
  phase confirmed rather than changed the outcome the cross-reviews already carried; its marginal
  catches were real but synthesis-grade; the cost — a fourth long-running agent per design phase
  — is not warranted.
- **The duties migrate, they do not vanish.** The synthesis stage (Director or Consolidator) now
  owns the checks Apollo's design-phase charter carried, each demonstrated in
  `apollo.evaluation.md`: the **graft-collision check** (W-1: two reviews adopting opposite
  positions on one point — follow the position grounded in recorded evidence), the
  **crossed-concession check** (W-2: concessions written concurrently can cross in flight; the
  residual is a deliberate pick, never inherited from whichever review is read last), the
  **unexamined-dimension probe** (W-3: at least one question neither design asked — the policy
  home's git-visibility was found this way), and the **echo-chamber adjudication** when a
  convergence's independence is questioned (the A-2 method: artifact specifics beyond every
  available upstream + citation anatomy + timing arithmetic).
- **Scope of effect** (D-7): every Design Phase forward, including the paused `emq-design` phase
  — after the venus-2-review re-drive completes, `emq-design` proceeds directly to Director
  synthesis → Operator approval, with no Apollo stage. Work already delivered (the `aaw-mcp`
  `apollo.evaluation.md`) stays a first-class synthesis input: work done is evidence, not waste.

## 2 · The synthesis-agent rule (D-8, Operator correction)

**A SYSTEM-spec synthesis is authored by the real `venus` agent type** — `.claude/agents/venus.md`
spawned as `subagent_type: venus`, carrying its charter, its `Skill` tool, and its model natively
— **not** by a `general-purpose` agent wearing the charter in-prompt, and **not** by the Director
solo (V-SOLO-4). This revises the x-mode SKILL §1 "tool-availability rule" for the synthesis
stage specifically:

- **The ceremony asymmetry, recorded honestly.** The venus agent definition carries no
  `mcp__aaw__*` tools, so the spawned consolidator cannot self-register; **the Director records
  the registry ceremony on the agent's behalf** (`aaw_spawn` from the Director's context; the
  spawn is real — a separate execution context — so LAW-1's substance holds) with an
  honest-formation note in the ledger, per the `aaw.rules.md` formation-availability provision.
  The agent writes no ledger entries; its deliverables + its report are the stage record, and the
  Director writes the stage's P/Z/Y entries.
- **The deliverable is the spec-system pair** per the /spec-write method: `<system>.design.md`
  (the design/index: architecture, catalog, vocabularies, the decision record by pointer, the
  master invariant) + `<system>.roadmap.md` (the delivery plan: the architecture decision and its
  reversible seam, the thin-rung build ladder with Ships/Demo/Harness/Feedback per rung and
  per-rung diff boundaries). The donor designs remain the ADR record — the pair consolidates by
  citation, never re-derives.
- The `general-purpose` + charter-in-prompt pattern remains valid for peers that MUST run the aaw
  ceremony and audit tools from their own context (rung-stage Venus/Mars/Apollo in the Flat-L2
  pipeline) until the agent definitions gain the `mcp__aaw__*` allowlist.

## 3 · The protocol-document delta ledger

Each delta: the file, the verified current state, the edit, its authority, and its landing
vehicle. **None of these edits is applied by this record** — x.md, the skill, and the peer
charters are Operator-fenced; the approval of this record is the grant for Δ1–Δ4 and Δ6–Δ7,
and Δ5 rides the build rung per D-6.

| # | File · site | Current (verified this session) | The edit | Authority |
| --- | --- | --- | --- | --- |
| Δ1 | `.claude/commands/x.md` §12 | formation = Venus-1 ∥ Venus-2 → cross-review → **Apollo evaluation** → Director ratify → Operator approval | drop the standing Apollo stage; insert the §1 corrected diagram + the migrated-duties list; name the real-venus consolidator option for large corpora | D-7, D-8 |
| Δ2 | `.claude/skills/x-mode/SKILL.md` §2b | same Apollo-stage formation | the same correction as Δ1 | D-7 |
| Δ3 | `.claude/skills/x-mode/SKILL.md` §1 | "Specialized peers — the tool-availability rule": always spawn `general-purpose` + charter | add the D-8 exception: the Design-Phase synthesis stage spawns the real `venus` type; the Director records its ceremony (the §2 asymmetry) | D-8 |
| Δ4 | `.claude/agents/apollo.md` | charter includes the design-phase evaluation duty ("Evaluate a Design Phase") | narrow to rung-level: inter-Mars iteration evaluation + post-build verification; design-phase adjudication removed (duties migrated per §1) | D-7 ("Apollo's charter narrows accordingly"); peer-def edit requires the explicit Operator grant |
| Δ5 | `.claude/commands/x.md` §5 bootstrap (line 123) | `mcp__aaw__aaw_init(scope, operator)` — no `ledger_dir`, which first-init REQUIRES (PoC `store.go:118-120`; both designs; apollo §7.2-2) | add the `ledger_dir` argument to the documented call shape | F-2 — carried as a named build-rung task (D-6); the doc-vs-server divergence must not survive the build rung |
| Δ6 | `.claude/skills/x-mode/SKILL.md` §1 bootstrap block | calls `mcp__aaw__init` / `mcp__aaw__spawn` — names that do not exist on the wire (the registered tools are `mcp__aaw__aaw_init` / `mcp__aaw__aaw_spawn`; found live this session — `ToolSearch` resolves only the real names; x.md §5 already uses them correctly) | correct the two tool names; add `ledger_dir` (the Δ5 fix applies here too) | live finding, this session; R-9 (names are the contract) |
| Δ7 | `.claude/commands/x.md` §6 table (+§3 pipelines) | lists the 12 ledger writers incl. `tool_x_resonance` (R-n); no `channel_*` / `agent_heartbeat` rows; `tool_x_resonance` row carries no measurement caveat | on v2 ship: add the `channel_publish` / `channel_poll` / `channel_list` and `agent_heartbeat` rows; annotate R-n with the baseline_note caveat (shared-input inflation — same-brief peers restating locks score a guaranteed Jaccard floor); `tool_memory_*` never enters (D-3) | D-3, D-6; lands with the v2 build, not before |

## 4 · The protocol↔v2-server binding (the loop as v2 tool calls)

Tool semantics are owned by `aaw.mcp.design.md` (one authority); this section owns the
protocol-side call pattern an x-mode run follows on the v2 server.

```
D0  probe                                   → availability is point-in-time (emq-design L-1);
                                              re-probe at every run bootstrap; wire_contract verdict read
    aaw_init(scope, operator, ledger_dir,   → idempotent; scope_created/ledger_created disambiguated;
             ttl_days)                        a hand-written ledger is never touched
    aaw_spawn(role: director …)             → ccl-<scope>-1; agent_register from the same context
S1  [sharpen]  Director: tool_x_trace T-n (the §0 derivation) · tool_x_decision D-n (formation lock)
S2  [build]    peers, each from its OWN context where its tools allow (else the §2 asymmetry):
               aaw_spawn(parent_id: ccl-<scope>-1, model: <id>, deliverable: <artifact path>)
               + agent_register; `actor: <Codename>` on EVERY write (the attribution line in
               every spawn brief); agent_heartbeat(quiet_for_minutes) before heads-down
               authoring — or lease-at-dispatch: the Director heartbeats FOR the peer it
               dispatches; channel_publish/channel_poll for durable peer coordination
               (the harness's SendMessage stays the low-latency path)
    gate-hold  Director: aaw_status — tallies, per-agent liveness verdicts (winning source named),
               open signals; the gate decision is a D-n entry
S3  [ship]     deliverables land in the tree (md-first); the ledger records, the tree proves
S4  [demo]     rung formations: Apollo between Mars passes (its D-7 home);
               tool_x_consensus C-n; tool_x_resonance R-n over the peer artifacts
               (deterministic measurement; read the baseline_note before acting on the number)
S5  [review]   Director: aaw_status pre-close — gates.z_eligible IS the x.md §10 precondition check
S6  [feedback] tool_x_learning L-n · tool_x_complete Z-n (refused while no D-n — the LAW-4
               trigger) · tool_x_report Y-n; the commit itself is the Director's, outside the
               server (or out-of-band per the formation's git discipline)
```

**The hot-ledger discipline** (earned live in this phase): the scope ledger is a coordination
medium shared with the Operator, who appends decisions out-of-band mid-session — twice in this
phase a decision landed within one minute of a Director write (D-8 arrived between a heading
census and the next append, which therefore minted D-9). The rules: re-read the decisions section
immediately before every write and before finalizing any deliverable; never pre-number an entry
in prose before the server mints it; entry numbering is collision-safe by construction (`nextN`
re-parses the whole file at append time under the per-scope writer lock), so the race costs at
most a stale plan, never a corrupt ledger. A new Operator decision supersedes any in-flight
brief's restatement of the old one.

## 5 · Sources

`docs/aaw/mcp/aaw.mcp.progress.md` — D-6, D-7, D-8, D-9 (the authorities); C-1; L-1/L-2; P-1/P-2
· `design/apollo.evaluation.md` — the verdict, W-1/W-2/W-3, §4.3, §7 (the migrated duties
demonstrated) · `design/venus-1.md` + `design/venus-2.md` + the two cross-reviews (the corpus the
formation correction was measured against) · `docs/aaw/mcp/aaw.mcp.proposal.md` (R/Q, as amended)
· `.claude/commands/x.md` §5/§6/§12 + `.claude/skills/x-mode/SKILL.md` §1/§2b (the delta targets,
read this session) · `docs/aaw/aaw.rules.md` (the formation-availability provision §2 applies) ·
the live PoC ceremony evidence: `docs/aaw/mcp/aaw-mcp.registry.json`.

---

*Director · ccl-aaw-mcp-1 · stage D4 (protocol record) · the server-side pair is authored in
parallel by Venus-3 (ccl-aaw-mcp-6) per D-8 · FULL STOP for Operator approval follows the pair's
delivery · no git by any peer or the Director; the Operator commits out-of-band at approval (D-1
clause 6).*
