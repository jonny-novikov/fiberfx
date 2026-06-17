# aaw-mcp — AAW scope ledger

## {aaw-mcp-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: the §0 derivation for the aaw-mcp Design Phase (2026-06-11)

Mode: Flat-L2 — Design Phase (x.md §12 / x-mode §2b). First fully-registered AAW formation: the
PoC server (apps/aaw, 2.0.0-min) records its successor's design run.

5W.
- Who: Operator jonny (approval gate) + Director (main session, ccl-aaw-mcp-1) + Venus-1 ∥ Venus-2
  (independent architects) + Apollo (D3 consensus evaluator). Mars does not spawn.
- What: the architectural design + ADR set for the FULLY-FLEDGED aaw MCP server, leveraging
  docs/aaw/aaw.framework.md as normative input. Key artifact (D4 Director synthesis):
  docs/aaw/mcp/aaw.mcp.design.md. Per-Venus designs: docs/aaw/mcp/design/venus-{1,2}.md;
  cross-reviews + apollo.evaluation.md beside them.
- Where: docs/aaw/mcp/** only, plus this ledger + registry. Zero code edits; the PoC stays as-is.
- When: now; the build rung runs only after the Operator approves the design.
- Why: the minimal server was a proof of concept (Operator, 2026-06-11); the full server must be
  the machine for the framework — the six-stage Author/Agent loop, the four artifacts + named
  instruments, the roles and fences, the two formations + the Design Phase variant, the two
  directions + the delta taxonomy, the LAWS and anti-patterns.

Solution space.
- A. Director designs solo — REJECTED: V-SOLO-4, the violation class the formation exists to stop.
- B. One Venus — REJECTED: no independence, no consensus; the Operator ordered Venus ×2 + consensus.
- C. Venus-1 ∥ Venus-2 → cross-review → Apollo consensus → Director synthesis → Operator approval —
  SELECTED (the §12 formation, Operator-ordered 2026-06-11).
- D. Defer behind the emq-design D2 re-drive — REJECTED: the Operator ordered this phase now; the
  ≤2-heavy-agent ceiling queues the emq-design re-drive behind this phase instead.

Invariants → runnable checks.
- INV-A both designs on disk before any cross-review: ls docs/aaw/mcp/design/.
- INV-B independence: no sibling reads until the Director's D2 instruction; Apollo probes for
  cross-contamination at D3.
- INV-C locked constraints honored: greps for the single-file ledger model, the mcp__aaw__*
  namespace, streamable-http :8905, the Q-3 ship set, Go-on-apps/mcp-go; re-litigation BLOCKS.
- INV-D every SDK/framework/protocol claim cited: apps/mcp-go file:line, framework/rules doc
  sections, modelcontextprotocol.io or engine URLs; no invention.
- INV-E tree delta: only docs/aaw/mcp/** + this ledger/registry change; apps/aaw untouched.
- INV-F the consensus artifact exists (apollo.evaluation.md + a C-n ledger entry) before the
  Director synthesizes aaw.mcp.design.md.

Reductive minimization: the phase produces design documents only; the smallest correct increment is
the ADR set + the synthesis, with the PoC untouched until the approved design licenses the build.

### T-2 — Venus-1 derivation summary: protocol/tool-surface-first design at design/venus-1.md

Inputs: aaw.framework.md + aaw.rules.md + x.md §1/§3/§5/§6/§8/§10/§12 (normative); aaw.mcp.proposal.md R-1…R-10/Q-1…Q-5 (requirements); PoC apps/aaw as keep-or-redesign input (main.go, store.go, ledger.go — every cited surface re-verified at file:line); live findings emq-design L-1/L-2 + P-2/D-3, aaw-mcp T-1/D-1; SDK apps/mcp-go (server.go, streamable_server.go, tool.go, protocol.go, event.go, auth/auth.go); MCP transports spec fetched 2026-06-11 (sessionless operation legal; client MUST support application/json POST responses; 404 → re-initialize).

Key alternatives ruled out: stateful sessions + EventStore resumability (machinery for server→client streams a tools-only server never uses; stateless + JSONResponse + no session id discharges R-6 by construction); session-bound attribution (harness gives no per-agent session guarantee; explicit as/from/for params instead); mandatory peer heartbeats and long V-SOLO-1 thresholds (Q-4 closed instead by three-source liveness fusion: attributed-call touch ∨ agent_lease window ∨ deliverable-file mtime — file-backed, validated by this very authoring pattern); embedding/LLM-judged recall and resonance (non-reproducible verdicts in an enforcer; deterministic lexical + citation-set measurement, limits recorded in-entry); index exemption from R-1 (forbidden by lock; L-2 fixed by read-through cache + read-merge-write + atomic rename); messages kept inside registry.json (rewrite amplification; moved to append-only <scope>.messages.jsonl); hard LAW-3 refusal on ledger bodies (audit trail held hostage to a style gate; advisory warnings instead).

Spine: the server = the machine for the framework's three pillars — file plane (transparency: index/ledger/registry/messages/audit.log all plain files, files-are-truth restored including the index), gate plane (inspection: boundary gates refuse, Z-requires-D kept, FAKE-N + V-SOLO-1 detected on file-plane evidence only, V-SOLO-2/3/4 explicitly evidence-base-only), recall plane (adaptation recorded + findable: tool_memory_recall with path:line citation discipline, tool_memory_audit as the corpus lint and L-2 regression harness). 24 tools = the 17 v1 names preserved + the locked Q-3 ship set (resonance, channel publish/poll/list with history = poll(after_seq:0)) + agent_lease; one serialization domain per scope covering all three scope files; ledger grammar formalized as EBNF with whole-file-per-prefix numbering; closed 14-code error vocabulary; additive-only schema evolution; tokenless localhost auth with SDK protections + workspace path containment. 30 ADRs; one deliberate output break (created → scope_created/ledger_created); forks surfaced not decided: policy constants W/K/lease-cap, archived-write strictness, the created-flag break.

### T-3 — Venus-2 derivation summary (stage D1, framework-integration/operations-first lens)

Inputs: aaw.framework.md + aaw.rules.md + x.md §5/§12 (normative); aaw.mcp.proposal.md R-1..R-10/Q-1..Q-5 (requirements); PoC apps/aaw (main.go, store.go, ledger.go) as keep-or-redesign input; live findings emq-design.progress.md P-2/L-1/L-2 + aaw-mcp.progress.md T-1/D-1 + Operator amendment D-2 (config/ports/wire-contract); SDK apps/mcp-go (server.go, streamable_server.go, tool.go, event.go, transport.go, auth/auth.go) read at file:line; live state .aaw/scopes.json + aaw-mcp.registry.json + .mcp.json. Sibling design/venus-1.md NOT read (independence held).

Key alternatives ruled out, with the ruling ADR: read-once index kept / re-read-merge / mtime-reload / R-1 exemption — all rejected for read-through-no-cache (ADR-1; merge cannot distinguish deletion from addition); ledger-only locking kept — rejected after deriving the unguarded registry read-modify-write race + len()-based CCL-id mint collision under the documented parallel-spawn ceremony (ADR-2); append-at-EOF and JSONL-sidecar ledger redesigns — rejected as violating the locked hand-written-first-class single-file model (ADR-4 ratifies the PoC engine + names the byte-preservation invariant); server-derived default ledger_dir — rejected for required+workspace-contained, with the x.md §5 bootstrap-signature doc delta surfaced as fork F-2 (ADR-5; live scopes.json rows in /tmp and TMPDIR are the evidence); transport-grade per-agent identity and _meta attribution — rejected for in-band optional actor param after deriving the one-shared-MCP-session trust model (ADR-7); mandatory heartbeats and mtime-probe liveness — rejected for composite liveness (attributed-call touch + agent_heartbeat with declared quiet window), all V-SOLO/FAKE-N signals advisory to .claude/audit.log, never blocking (ADR-8/9, the Q-4 resolution); server-side stage machine, tool_x_delta channel, artifact-manager scope — all rejected for convention-over-schema with hard gates kept deterministic-only (Z-requires-D, slug, parent, containment) (ADR-15/16/17); Stateless mode + EventStore — rejected for stateful+SessionTimeout, zero-loss carried by files not sessions (ADR-18); bearer token — held out of v2, surfaced as fork F-1 (ADR-19); config file and env-only config — rejected for flags>AAW_* env>defaults (ADR-23); auto-increment port scan + global port registry — rejected for explicit per-workspace ports, all-or-nothing dual-stack bind (the PoC partial-bind loopback split-brain derived and closed), fail-fast collision (ADR-24); .mcp.json generation — rejected for boot-time detection + probe/status wire_contract verdict, never editing operator config (ADR-25).

The design's spine: the server is the machine for the framework as PROCESS RECORDER + EVIDENCE ENGINE, never enforcer-of-judgment — §2.1 maps every framework concept to a surface or an explicit out-of-scope ADR; data plane = 5 file kinds, all greppable, atomic-rename or O_APPEND (ADR-3), one writer per scope; trust model = one shared session, in-band self-declared attribution, artifacts outrank timestamps; 24-tool catalog = 17 PoC kept name-stable + Q-3 ship set designed (resonance R-n w/ optional score; channel_* as durable topic log over messages.jsonl, delivery stays harness; tool_memory_recall=grep-grade, tool_memory_audit=the server's own files-are-truth integrity gate) + agent_heartbeat (Q-4); Q-1=yes (aaw_status as one-call gate console); Q-2=per-scope registry + messages split (fork F-3); conformance = 4 tiers incl. committed exemplar parse-compat goldens + in-memory-transport round-trips + 24-tool selftest pin (R-7 additive-only schemas). Deliverable: docs/aaw/mcp/design/venus-2.md — 25 ADRs, 3 forks (F-1 token, F-2 bootstrap signature, F-3 per-scope file count), all 6 locks restated and held.

### T-4 — D4 bootstrap: state reconnaissance, the path amendment, and the synthesis method

RECON. This session (the Director context, ccl-aaw-mcp-1, resumed) found stage D3 CLOSED on tree evidence: design/apollo.evaluation.md (401 lines, verdict DESIGN-GRADE, §11.2 design-shaped charter complete — un-prompted findings §4.3, attack-that-held §5, echo-chamber adjudication §4.1/4.2) + the C-1 consensus record. Operator decisions D-4 (tokenless ratified) and D-5 (apps/mcp-go free to modify) landed mid-D3 out-of-band. The ledger grew LIVE during this session's reads (189 → 231 lines between two reads minutes apart; aaw_status caught the file mid-growth at C:1/D:4 before D-5 landed) — hot-ledger discipline applied from here: re-read before every write; entry numbering stays collision-safe by construction (nextN re-parses at append time under the per-scope lock, ledger.go:68-79).

PATH AMENDMENT. The Operator's /x-mode command routes D4 to this session and amends the deliverable path: docs/aaw/mcp/design/x-mode.design.md (was docs/aaw/mcp/aaw.mcp.design.md per T-1/D-1). Co-location with the four stage artifacts keeps the whole Design Phase record in one directory; the name names the consumer protocol — the server is the x-mode machine (12 of its 22 tools are the tool_x_* writers).

FORMATION. No new spawns at D4: D3 needed no re-drive (the evaluation is on disk and gate-complete); the Director synthesizing solo at D4 is the §12 stage assignment ("Director ratify (synthesis)"), not a V-SOLO — the formation's peer work (two designs, two cross-reviews, one evaluation) is on disk under registered identities. The D3 gate was held by reviewing the evaluation against the §12 + §11.2 requirements: convergence/divergence table (30 rows), ADR completeness (zero undocumented decisions after the exchange), constraint fidelity (zero re-litigation), echo-chamber probe (A-2 adjudicated genuine on three artifact indicators; A-5 timeline-clean), synthesis recommendation per axis. PASS.

METHOD. The synthesis composes Apollo's §7.1 re-derived base+grafts (each verified against the tree per evaluation §8) with the donor ADRs read in full this session (venus-1: all 33 ADRs + §3 catalog + §3.13 EBNF + §3.14 vocabulary; venus-2: all 25 ADRs + §2.1 framework map + §2.3 trust model + §2.7/ADR-22 conformance). The two cross-reviews are consumed through the C-1/P-2 records and Apollo's row-level adjudications rather than a third independent re-read — recorded honestly as the method; Apollo's evaluation explicitly re-derived (not inherited) the graft lists and logged its verification pass. Director picks owed at D4 per W-2/§6: the two permanent tool names, the config fine structure, the W-3 policy-home reconciliation, plus the dispositions of Apollo's three §4.3 un-prompted findings. Locked next as a single clause-structured decision (the D-1 precedent).

### T-5 — Venus-3 consolidation trace (recorded Director-side; the venus agent def carries no mcp__aaw__* tools — Formation-availability provision, honest record)

Venus-3 (real `venus` agent type per D-8, harness id Venus-3@aaw-mcp) consolidated the corpus into the two D-8/D-9 deliverables: aaw.mcp.design.md (675 lines, 15 sections + AD-1…AD-12 + the 22-tool catalog + EBNF + 16-code vocabulary + donor-pointer decision record) and aaw.mcp.roadmap.md (296 lines, MCP-1…MCP-8 thin-rung ladder over milestones M1–M4, Pragmatic Agile Delivery).

Method: base = venus-1; all 14 §7.1 grafts applied (mapping in the design's §13 + Y-report); retained-venus-1 list fully carried; every D-6/D-8/D-9 pick recorded as DECIDED with rationale. Cross-reviews consumed via section maps + Apollo's row adjudications + C-1/P-2 (the T-4 method); verified directly in tree: main.go:155-184/:173/:322-330/:338-340, SDK Stateless :281 / JSONResponse :289 / GetSessionID server.go:138-146, .mcp.json, the .gitignore directory-form `.aaw/`, exemplar numbering T-2/D-5/P-3/L-3 + the #-level heading at :83.

Judgment calls surfaced (none a fork): (1) deliverable paths followed D-8/D-9-as-executed — the aaw.mcp.* pair, no file at aaw.design.md; (2) W-3 carried in the D-9 sharpened two-line glob form; (3) wire-verdict reachability stated per mode (mismatch reachable only under `warn`); (4) liveness verdict label `quiet` (consequence of the D-6(a) heartbeat pick); (5) `reopened_at` homed on scope rows; (6) venus-1's three-plane framing reduced to file+gate planes (D-3-safe); (7) corpus-lint package named internal/integrity.

### T-6 — MCP1 build stage entered (2026-06-11, Operator instruction: "Fan out Mars to implement ready to go mcp1.specs.md")

**Mode:** Flat-L2 build pipeline per `specs/mcp1.prompt.md` (build pass → harden pass → verify → one LAW-4 pathspec commit). The Venus stage is pre-discharged: the brief (`mcp1.llms.md`) + runbook (`mcp1.prompt.md`) exist on disk, authored from the settled design corpus (`design/venus-1.md` ADRs 1/2/3/4/22 + `design/apollo.evaluation.md` §8), and the runbook declares "Settled forks — no open Operator decision". The Operator's "ready to go" is the Stage-1 gate.

**Director seat resumed**, not re-spawned: the registry carries `director` = `ccl-aaw-mcp-1` from the design-phase session; this session resumes that seat (the durable registry row is the seat, the emq-design D-5 pattern). A re-spawn through the live PoC's `len(r.Agents)+1` mint (`cmd/aaw/main.go:173`) was deliberately avoided — see L-4.

**Pre-spawn sanity probe (anchors re-verified, read-only):** `ledger.go:41-46` = the per-scope `ledgerLocks sync.Map` (the lock to broaden) ✓; `main.go:173` = `cclID := fmt.Sprintf("ccl-%s-%d", in.Scope, len(r.Agents)+1)` ✓; in-place `os.WriteFile` at `store.go:97` (index), `store.go:203` (registry), `ledger.go:171` (ledger) ✓; `apps/mcp-go` present (untouched this rung) ✓; design corpus on disk ✓. All five grounding rows of the runbook's table are real — no re-derivation owed.

**Concurrency note:** the emq-design scope's Venus-2 (cross-review) runs concurrently; Mars + Venus-2 = the ≤2 heavy-agent cap, no further spawns until one lands. **Hermeticity fence for the build:** the live aaw server process is serving this session's two scopes — Mars must never bind a server or the flock against the live `/Users/jonny/dev/jonnify/.aaw`, never kill the running process; every test runs in temp workspaces.

## {aaw-mcp-decisions} Decisions

### D-1 — Formation locked: live-ceremony Flat-L2 Design Phase, lens-split dual Venus, consensus before synthesis

(1) FORMATION: Venus-1 ∥ Venus-2 (general-purpose spawns adopting the venus.md charter, identical
constraint base, distinct leading lenses, spawned in one message, no sibling reads until D2) →
D2 cross-review (same instances resumed) → D3 Apollo design evaluation + the consensus record
(tool_x_consensus C-n + design/apollo.evaluation.md) → D4 Director synthesis at
docs/aaw/mcp/aaw.mcp.design.md → FULL STOP for Operator approval. (2) CEREMONY IS LIVE: every peer
runs aaw_spawn(parent_id ccl-aaw-mcp-1) + agent_register from its own context against the running
PoC server — the first fully-registered AAW team; the registry is the LAW-1 evidence. (3) LENSES:
Venus-1 = protocol/tool-surface-first (full tool catalog incl. the Q-3 ship set, ledger formal
semantics, registry/liveness model, wire/session/auth); Venus-2 = framework-integration/operations-
first (the aaw.framework.md mapping — six-stage loop, formations, directions, delta taxonomy, LAWS
detection — plus lifecycle/ops: index consistency, TTL/archival, observability, testing strategy).
(4) CONCURRENCY: the two Venuses occupy the ≤2-heavy ceiling; the emq-design D2 re-drive (only
venus-2.review-of-venus-1.md missing) queues behind this phase. (5) DELIVERABLE PATHS fixed as in
T-1; the proposal (aaw.mcp.proposal.md R-1…R-10/Q-1…Q-5) is the requirements source; the PoC is
as-built input under keep-or-redesign ADRs; aaw.framework.md is normative input. (6) NO git by any
peer or the Director; the Operator commits out-of-band at approval. No code this phase.

### D-2 — Operator brief amendment (mid-D1): configuration + custom port assignment are REQUIRED design coverage

Operator feedback 2026-06-11: the designs have not delivered the server's CONFIGURATION surface and
CUSTOM PORT ASSIGNMENT. Both architects must cover, as ADR(s) with steelmanned alternatives: the
config model (flags vs config file vs env, precedence, defaults — the PoC has only -addr/-workspace
flags); the listen address/port as first-class configuration (custom port assignment beyond the
default 8905; multi-instance/multi-workspace port selection; collision handling); and how the
`.mcp.json` wire contract stays in agreement with a custom port (detection, validation, or
generation — the design decides and records the trade-off). Venus-1 extends the delivered
design/venus-1.md; Venus-2 folds the coverage into the still-owed design/venus-2.md. The D1 gate
now includes this coverage on both designs.

### D-3 — Operator decision (mid-D2): tool_memory_{recall,audit} are DROPPED from the ship set — omit from all documentation, commands, and skills, to avoid tool fatigue

The Q-3 ship set narrows to tool_x_resonance + the channel_* family; tool_memory_{recall,audit}
join pantry_* and tool_x_flow_prompt in the OUT set. This also resolves the Venus-2 provenance
erratum (proposal §3 attributed tool_memory to x.md; x.md carries no such occurrence) — by
deletion. Consequences: (1) the proposal's §3/R-10/§5-footnote/Q-3 are amended by the Director;
(2) the D1 designs' tool_memory ADRs (venus-1 ADR-16/17; venus-2 ADR-14) stand as RECORD but their
decisions are superseded — the D2 reviews spend no depth on them and the D4 synthesis ships no
memory tools; (3) the tool count drops accordingly (the catalog = 17 v1 names + resonance +
channel_* + the liveness tool the synthesis picks); (4) memory-style recall over the ledger corpus
remains available to agents through ordinary Read/Grep — the capability is not lost, only the
dedicated tool surface.

### D-4 — Operator decision (mid-D3): fork F-1 resolved — TOKENLESS v2

The Operator observed the live no-auth behavior ("MCP works without authorization") and, presented
with the three options, ratified the architects' convergent position: v2 ships tokenless — loopback
bind (nothing off-machine connects) + the SDK's built-in protections + workspace path containment;
the accepted exposure is local processes calling the tools; the SDK auth seam (apps/mcp-go
auth/auth.go) stays documented for a later major, never wired in v2. Bearer-token and
optional-token alternatives considered and declined (ceremony + secret lifecycle not worth the
local-isolation gain for a workspace-local enforcer). Consequence for D4: the open-fork list
shrinks to F-2 (the x.md:123 bootstrap-signature doc edit), C-1 (transport — carrying Venus-1's
testable resolution: stateless as intent + one live harness-dial probe at the build gate), and C-2
(the policy-constants home / config model).

### D-5 — Operator decision LOCKED (mid-D3): apps/mcp-go is FREE TO MODIFY to fit aaw needs

The vendored SDK (module github.com/fiberfx/mcp-go/v2 at apps/mcp-go) is a first-party fork and
may be modified for the aaw server — it is no longer a read-only constraint. Consequences:
(1) C-1 (transport) widens — where a design treated stock SDK behavior as fixed (session handling,
JSONResponse mode, reconnect semantics, error shaping), the synthesis may prefer a stock
configuration AND hold SDK modification as the sanctioned fallback if the build-gate probe demands
it; (2) any \"the SDK forces X\" claim in either design downgrades from constraint to default;
(3) the build rung's diff boundary EXTENDS to apps/mcp-go (pathspec + review scope accordingly);
(4) modifications carry the same no-invent/cite discipline — an SDK change is a designed, ADR'd
change, never an ad-hoc patch; (5) documentation duty discharged at: this entry, the proposal §6
(amended), apps/mcp-go/AGENTS.md (top note for future build agents), and the D4 synthesis's locked
list. Upstream-sync consequence recorded: local modifications fork the SDK's upstream lineage —
future upstream pulls become merges; accepted by the lock.

### D-6 — Quality gate passed; synthesis delegated to Venus-3 Senior Consolidator at aaw.design.md (Operator, 2026-06-11)

The Operator ratifies Apollo's D3 DESIGN-GRADE verdict: the quality gate passes to synthesis. **Pragmatic Agile Delivery is the key principle** — the design stage closes by shipping the final consolidated design, written to be buildable in thin rungs, fast-paced but robust. The final is authored by a spawned **Venus-3 Senior Consolidator** agent (not the Director) at the path **`docs/aaw/mcp/aaw.design.md`** (note: supersedes the earlier working name `aaw.mcp.design.md`). The design document is the source from which the build specs are written.

Director picks riding into the synthesis (per apollo.evaluation.md §6/§7.2, made deliberately here, binding because tool names are permanent under R-9):

- **(a) Liveness tool name: `agent_heartbeat`.** The bare attributed touch is the dominant call shape; "lease" misdescribes a touch with no window. Shape as settled: `(scope, name, note?, quiet_for_minutes?)`, merged with venus-1's three-source fusion + lease-at-dispatch + cap-as-policy.
- **(b) Channel read-tool name: `channel_poll`.** Names the incremental primary use; history is the degenerate `after_seq: 0` call.
- **(c) Config composition:** the strictest one-authority form both concessions co-sign — **no env layer anywhere; no per-knob policy flag overrides**; identity = boot flags, policy = the tree-visible `.aaw/config.json`. **W-3 fix: keep the home and add the `.gitignore` negation `!.aaw/config.json`** (recorded in the design; the actual .gitignore edit lands at the build rung).
- **(d) F-1:** already ratified by the Operator as D-4 (tokenless v2; seam named).
- **C-1:** stateless as design intent + the live harness-dial probe at the build gate; probe failure flips to the stateful configuration.
- **F-2:** the x.md:123 bootstrap-signature doc edit is carried as a named build-rung task.
- **§4.3-2:** fixed write order (ledger append, then registry counter) + the `aaw audit` tally-recount as the named drift detector. **§4.3-3:** retry duplicates documented as accepted (visible, inspectable history). **W-1:** V-SOLO-2 stays evidence-only per venus-2's self-correction, overriding venus-1's G-4 adoption.
- Policy defaults recorded in the design: W=45 min, K=3, cap=240 min (Operator-tunable policy, not a fork).

### D-7 — Apollo is redundant in the Design Phase; Venus-1 ↔ Venus-2 cross-review IS the evaluation (Operator lock, 2026-06-11)

The Operator locks a formation correction: **a standing Apollo evaluation stage must not run in a Design Phase — it runs too long, and it duplicates work the formation already does.** The Venus-1 ↔ Venus-2 cross-review IS the evaluation: two independent designs, each adversarially reviewing the other, already produce the agreements/challenges/grafts and the convergence/divergence map a synthesis needs. Apollo's high-utilization home is the **Flat-L2 aaw topology inside a rung** — evaluating results between mars-1 and mars-2 iterations — not long-form design adjudication.

The Design Phase formation (x.md §12, x-mode SKILL §2b) therefore simplifies to:
**Venus-1 ∥ Venus-2 → cross-review → Director synthesis (or a Venus-3 Senior Consolidator for a large corpus) → Operator approval.**

Rationale (Pragmatic Agile Delivery): AAW requires pragmatic rung movement — shipping working product fast-paced but robust, improving the discipline. The D3 Apollo pass in this very phase confirmed rather than changed the outcome the cross-reviews already carried (DESIGN-GRADE; base + grafts were re-derivable from the reviews); its marginal catches (W-1/W-3) are real but synthesis-grade, catchable by the consolidator. The cost — a fourth long-running agent per design phase — is not.

Scope of effect: applies forward to every Design Phase, including the paused **emq-design** phase — after venus-2's review re-drive completes, emq-design proceeds directly to Director synthesis → Operator approval (no Apollo stage). The aaw-mcp phase's already-delivered apollo.evaluation.md stays a first-class synthesis input (work done is evidence, not waste). Apollo's charter narrows accordingly: rung-level verification and inter-Mars iteration evaluation, not design-phase adjudication.

### D-8 — Synthesis authored by the real `venus` agent type (design + roadmap, aaw.mcp.* family); supersedes D-6's stand-in (Operator, 2026-06-11)

Correction to D-6's execution: the final synthesis is authored by the **`venus` agent type** (`.claude/agents/venus.md` — the spec-steward/architect, carrying its charter + `Skill` tool + model natively), NOT a `general-purpose` agent wearing the venus charter in-prompt, and NOT the Director solo. The aaw MCP server is a SYSTEM spec, so per venus.md §"The Design Phase" the design + ADR set is Venus's deliverable; a Director-solo system spec is the V-SOLO-4 violation. The earlier general-purpose Venus-3 spawn was rejected before it ran — no orphan.

Deliverable is the spec-system PAIR (per the /spec-write method), both in the `aaw.mcp.*` family (consistent with the existing `aaw.mcp.proposal.md`), superseding D-6's single `aaw.design.md`:
- **`docs/aaw/mcp/aaw.mcp.design.md`** — the design/index: framework→server map, trust model, architecture (file plane + store discipline), the 22-tool catalog with schemas/gates, the closed error vocabulary, the ledger grammar, signals/attribution/liveness/channels/resonance/config, the `aaw audit` CLI, conformance, the SDK-modification policy (D-5), the decision record (ADRs by pointer), the master invariant, the closed error set.
- **`docs/aaw/mcp/aaw.mcp.roadmap.md`** — the delivery plan: the architecture decision + its reversible seam, the master invariant, "thin but robust", the **thin-rung build ladder** (Pragmatic Agile Delivery — rung 1 = smallest shippable increment over the PoC; each rung names Ships/Demo/Harness/Feedback + its diff boundary, which extends to apps/mcp-go per D-5; first-boot parse-compat over the hand-written exemplar ledgers is an early gate), seams & open decisions.

Synthesis is settled (do not re-litigate): base = venus-1; the 14 grafts + retained-wins per apollo.evaluation.md §7.1; the Director picks locked in D-6 (agent_heartbeat, channel_poll, no-env/no-per-knob-flags config + W-3 negation, tokenless v2, stateless+probe, F-2 doc task, write-order + aaw audit drift detector, retry-dup accepted, W-1 evidence-only, policy defaults W=45/K=3/cap=240). D-3 holds: tool_memory_* omitted entirely; 22-tool surface. Venus authors the design + ADRs first, the roadmap second, independently and to the specs.approach.md shapes; it surfaces (never decides) any genuinely-residual fork to the Operator.

### D-9 — Deliverable split ratified (Operator, 2026-06-11, in-session): two documents close D4

The Operator resolved the D-6-vs-command fork (AskUserQuestion, this session): TWO documents.

(1) **docs/aaw/mcp/aaw.design.md** — the consolidated SERVER design of record, authored by the spawned **Venus-3 Senior Consolidator** per D-6; source for the build specs; base = venus-1's protocol spine + the apollo §7.1 graft list, every D-6 pick applied verbatim; buildable in thin rungs (Pragmatic Agile Delivery).

(2) **docs/aaw/mcp/design/x-mode.design.md** — the X-MODE PROTOCOL design record, Director-authored: the D-7 simplified Design Phase formation (Apollo removed from design phases; cross-review IS the evaluation; Venus-3 consolidator option), Apollo's charter narrowing to rung-level evaluation, the protocol-doc deltas this phase earned (x.md §12 + x-mode SKILL §2b formation rewrite; F-2 = x.md:123 ledger_dir; the x-mode SKILL §1 stale abbreviated tool names mcp__aaw__init/spawn vs the real mcp__aaw__aaw_init/aaw_spawn — found live this session), and the protocol↔v2-server binding (the loop as v2 tool calls, by reference to aaw.design.md). Protocol-doc edits themselves land only with Operator approval (the docs are Operator-fenced); F-2 rides the build-rung pathspec per D-6.

W-3 precision carried into both docs: the `.gitignore:201` pattern is the DIRECTORY form `.aaw/` — a bare `!.aaw/config.json` negation under an ignored directory is a git no-op; the correct edit is the glob conversion `.aaw/*` + `!.aaw/config.json` (two lines, build-rung task).

## {aaw-mcp-learnings} Learnings

### L-1 — The running PoC has an unlocked registry read-modify-write (Venus-1 unprompted finding); stagger ceremonies until the full server ships

Venus-1's D1 report surfaced: every registry write in the PoC is an unlocked read-modify-write
(apps/aaw/cmd/aaw/main.go:155-218 + internal/store/store.go:182-204) — two CONCURRENT aaw_spawn or
agent_register calls on one scope can lose an agent row. The ledger path is mutex-serialized; the
registry path is not — the exact R-4 defect class on the sibling file. Design resolution: Venus-1
ADR-3 (one per-scope serialization domain covering ledger + registry + messages). OPERATIONAL
GUIDANCE for the remainder of this run (and any run on the PoC): sequence ceremony calls — spawn
peers' registrations one stage at a time (the current formation already does: Director, then the
two Venuses ~26s apart, then Apollo at D3 solo); avoid instructing two peers to register
simultaneously. The full server closes this by construction.

### L-2 — Second PoC defect (Venus-1, surfaced by the D-2b analysis): continue-on-one-family dual-stack bind can family-split a port across instances

The PoC binds both loopback families but CONTINUES when one family fails (cmd/aaw/main.go:322-330;
fatal only at zero listeners :338-340) — introduced as lenience in the dual-loopback fix of the
localhost ::1-vs-127.0.0.1 mismatch. Combined with multi-workspace boots (no shared flock in the
PoC), two instances can each hold ONE family of the same port behind one URL, splitting a single
client's dials between two servers. OPERATIONAL GUIDANCE until the full server ships: run exactly
one aaw instance on this machine (the current state); do not boot a second workspace's instance on
port 8905. Design resolution: Venus-1 ADR-32 (all-or-nothing dual-stack bind, PORT_BUSY refusal,
diagnosed collision naming the holder) + ADR-2 (flock single-instance guard).

### L-3 — The CCL re-mint fired live on this phase's own ceremony: Venus-3's id moved 5 → 6 under two parallel Director sessions

Observed in the registry at D4 close: two Director sessions each ran aaw_spawn for the name "Venus-3" (~23:00Z and 23:09:52Z). The PoC's spawn handler finds the existing row by name but OVERWRITES its CCLID with a fresh `len(r.Agents)+1` mint (main.go:173-179) — the row's identity moved from ccl-aaw-mcp-5 (this session's mint, the id Venus-3 was briefed with and stamped into both deliverables' footers) to ccl-aaw-mcp-6 (the parallel session's re-mint). One row, both ceremonies merged, no FAKE-N (registered ≤ spawned) — but the identity evidence drifted under the exact defect class L-1/venus-1 ADR-22/venus-2 ADR-2 name, now with a third failure articulation: re-spawn of an existing name re-mints rather than preserves (identity continuity broken).

Standing: the v2 design already closes this (AD-3 persisted `next_ccl`; aaw_spawn's documented "re-spawn of an existing name keeps its CCL-id"); MCP-2 is the closing rung. The deliverables' `ccl-aaw-mcp-5` footers are the honest as-briefed record and stay untouched (do-no-harm; this entry is the reconciliation). Operational guidance until MCP-2 ships: one Director session per scope, or stagger ceremonies and re-read aaw_status before citing a CCL-id.

### L-4 — The live registry exhibits the exact defects MCP1 closes: a duplicate CCL-id and a time-travel row

`aaw_status(aaw-mcp)` at MCP1 stage entry shows: (a) `Venus-3` and `SpecAuthor-mcp2` BOTH carry `ccl_id: ccl-aaw-mcp-6` — the `len(r.Agents)+1` mint (`cmd/aaw/main.go:173`) re-minted an existing id after registry evolution (MCP1-INV5's violation, live); (b) `Venus-3` has `registered_at: 23:00:18` EARLIER than `spawned_at: 23:09:52` — an unlocked read-modify-write interleaving artifact (MCP1-INV1's violation class, live); (c) `SpecAuthor-mcp2` is `spawned: true, registered: false` — a row state the FAKE-N tally reads as spawn-without-register. The rung's concurrency property (N parallel spawns → N rows, N distinct ids) and the persisted `next_ccl` mint are validated by production evidence before a line is written. The defective rows are PRESERVED as evidence — no manual registry repair before the build's own tests pin the fixed behavior.

## {aaw-mcp-progress} Progress

### P-1 — Stage D1 CLOSED, gate green (2026-06-11; the first fully-registered formation's first stage)

Both independent designs on disk, reported, amendment D-2 covered:
- design/venus-1.md — 1270 lines, 33 ADRs (D-2 → ADR-31/32/33), protocol/tool-surface-first; ~95
  citations; closing trace T-2. Two unprompted PoC findings (the unserialized registry RMW → L-1;
  the continue-on-one-family bind → L-2).
- design/venus-2.md — 1112 lines, 25 ADRs (D-2 → ADR-23/24/25), framework-integration/ops-first;
  ~120 citations; closing trace T-3; LAW-3.1 self-audit run pre-report; provenance correction
  (proposal §3 attributes tool_memory to x.md, but x.md carries no such occurrence — erratum for D4).

Gate evidence: INV-A ls; INV-C lock greps clean on both, re-litigation probes zero; INV-E apps/aaw
untouched (operator committed the batch out-of-band); registry = 3 agents spawned+registered with
parent links (LAW-1 machine evidence, first time); tallies at close T:3 D:2 L:2.

Load-bearing DIVERGENCES for D2 (contradictions first): (a) transport — V1 ADR-5 stateless +
JSONResponse + no session id vs V2 ADR-18 stateful sessions + SessionTimeout; (b) config D-2a —
V1 ADR-31 flags=identity + .aaw/config.json policy (mtime read-through), NO env vs V2 ADR-23
flags > AAW_* env > defaults, NO config file; (c) Q-4 + the 24th tool — V1 ADR-10 three-source
fusion + agent_lease vs V2 ADR-8 call-touch + agent_heartbeat(quiet_for); (d) attribution — V1
ADR-9 as/from/for vs V2 ADR-7 single actor param; (e) channel surface — V1 publish/poll/list vs
V2 publish/history/list; (f) resonance depth — V1 prescriptive deterministic metric vs V2 looser
R-n + optional fields; (g) port-collision behavior — V1 diagnosed (probe the holder) vs V2
fatal-fast. CONVERGENT independently: the index L-2 fix, the per-scope serialization domain (both
found the registry race; V2 also the len()-based CCL mint collision), all-or-nothing dual-stack
bind, wire-contract validation-never-generation, no-token Q-5, write-refusing archival with
re-init reopen, memory_audit as the server's own integrity gate, messages → JSONL. Fork sets to
consolidate at D4: V1×3 (policy constants — home interacts with (b); archived-write strictness;
created-flag break) + V2×3 (F-1 bearer seam; F-2 x.md §5 init-signature doc fix; F-3 files-per-
scope count). D2 launched: same instances resumed, no fresh spawns (one identity per seat).

### P-2 — Stage D2 CLOSED on tree evidence (2026-06-11 ~01:00)

Both cross-reviews on disk: venus-1.review-of-venus-2.md (370 lines — 19 agreements as ADR pairs
with why-classes, 8 steelmanned challenges each with a proposed resolution, 12 grafts + a
keep-list; fork consolidation 6→4) and venus-2.review-of-venus-1.md (32KB; report not sent — the
third file-then-silence occurrence for Venus-2, retrospective item). Venus-1's headline: C-1
transport — stateful sessions retain the one R-6 failure path (restart → dead session id → client
404-recovery dependence) while the stated cost of stateless is a capability the stateful design
never uses; PROPOSED RESOLUTION IS TESTABLE (stateless as intent + one live harness-dial probe at
the build gate; failure flips to the stateful configuration — both put zero-loss in files).
Surviving forks for D4/Operator: F-1 bearer token; F-2 x.md:123 bootstrap signature doc edit
(verified real); C-1 transport (with the testable resolution); C-2 policy home (the config-model
choice). Concessions ran both ways (V1 yields the index cache, the actor param, the heartbeat
shape; V2's review on disk for Apollo). D-3 honored in the review (memory family = 2 one-liners;
post-D-3 surface 22 tools; venus-2's `aaw audit` CLI subcommand flagged as the zero-tool home of
the L-2 regression check).

INDEPENDENCE CAVEAT FOR D3 (the echo-chamber probe, sharpened): the Director's L-1 ledger entry
(the unserialized registry RMW, from Venus-1's first report, ~21:30Z) was on disk BEFORE
venus-2.md landed (21:39Z) and Venus-2's brief pointed at this ledger — so A-2's "independent
identical finding" has a possible common upstream. Venus-2's added specificity (the len()-based
CCL mint collision, absent from L-1) argues genuine derivation, but Apollo must adjudicate from
the artifacts. A-5 (the dual-stack family-split) is CLEAN — the L-2 entry postdates venus-2.md.
D3 launched: Apollo solo (per the L-1 ceremony-staggering guidance).

### P-3 — Stage D3 closed on tree evidence; D4 in flight under the D-8/D-9 execution (2026-06-11)

D3 CLOSED: design/apollo.evaluation.md (401 lines, DESIGN-GRADE, the §11.2 design-shaped charter complete) + C-1; gate held by the Director this session (T-4). Per D-7 the standing Apollo design-evaluation stage is retired going forward; this phase's delivered evaluation stays a first-class synthesis input.

D4 EXECUTION (per D-6 → D-7 → D-8 → D-9):
- design/x-mode.design.md DELIVERED (Director-authored, the protocol-side record): the corrected Design Phase formation + the migrated synthesis duties (W-1/W-2/W-3-class checks, echo-chamber adjudication), the D-8 synthesis-agent rule + ceremony asymmetry, the seven-row protocol-document delta ledger (x.md §12/§5:123/§6, SKILL §1/§2b incl. the stale abbreviated tool names found live, apollo.md narrowing — all fenced, landing only with Operator approval or the named build rung), the protocol↔v2-server call-pattern binding, and the hot-ledger discipline earned live (D-8 landed between a heading census and the next append → the Director's split decision minted D-9).
- Venus-3 Senior Consolidator SPAWNED as the real venus agent type per D-8 (harness id Venus-3-2@aaw-mcp; registry ccl-aaw-mcp-6, parent ccl-aaw-mcp-1; ceremony recorded Director-side — the venus def carries no mcp__aaw__* tools; honest-formation note per aaw.rules.md). Brief: consolidate the corpus into docs/aaw/mcp/aaw.mcp.design.md + aaw.mcp.roadmap.md (design first, roadmap second, specs.approach.md shapes, thin-rung ladder, donor-cited, settled synthesis verbatim, hot-ledger re-read before finalizing, no git, report to director).

NEXT: gate Venus-3's pair against the D-8 composition directive (spot-check groundings + graft coverage + no re-litigation), then Z/Y and FULL STOP for Operator approval. No git by any peer or the Director (D-1 clause 6).

### P-4 — Stage D4 CLOSED: the consolidated pair delivered and gate-verified; the two Director threads reconciled (2026-06-11)

DELIVERED (tree evidence): aaw.mcp.design.md (675 lines) + aaw.mcp.roadmap.md (296 lines), authored by Venus-3 (real venus type per D-8). Director gate re-run independently (not trusted from the agent's report): voice 0 banned / 0 first-person / 0 perceptual-verb hits in both files; fences balanced (6/0); every relative link resolves on disk; ZERO tool_memory mentions (D-3 held); tool enumeration 22/22 = the 17 v1 names verbatim + agent_heartbeat + tool_x_resonance + channel_publish/poll/list; every D-6/D-8/D-9 pick present in the text (AD-1 stateless+C-1 probe, AD-4 heartbeat + ledger-then-counter write order, AD-8 no-env/no-per-knob + W-3 glob pair, channel_poll §7.3, retry-dups accepted §8, W-1 evidence-only AD-5, W=45/K=3/cap=240).

THREAD RECONCILIATION: two Director sessions worked D4 concurrently. This thread: D-6/D-7/D-8, the Venus-3 spawn (real venus type), the delivered pair, this gate. The parallel thread: T-4/D-9/P-3, design/x-mode.design.md (the protocol-side record), its own Venus-3 ceremony (the L-3 re-mint). As-executed convergence: the D-9 two-document split is honored in SUBSTANCE — the server design of record landed as the D-8 PAIR (aaw.mcp.design.md + aaw.mcp.roadmap.md; D-9's `aaw.design.md` name superseded as-executed, no file exists there) beside the Director-authored x-mode.design.md. Both Venus briefs targeted the same pair; the tree holds one converged copy (675/296 exactly matching this thread's Venus-3 report).

NEXT: Z/Y, then FULL STOP at the Operator approval gate (D-1 clause: nothing is canon before approval; no git by any peer or Director).

### P-5 — Post-gate reconcile: five D-8-conformance corrections landed; file state of record is 681/296 (2026-06-11)

The P-4 gate and Z-1's drift-detector line record aaw.mcp.design.md at 675 lines — the state
BEFORE this thread's Venus-3 (Venus-3-2, registry ccl-aaw-mcp-6) applied five surgical
D-8-conformance corrections to the found-on-disk pair: (1–2) the aaw_init output brought to the
settled three-field alias form {scope_created, ledger_created, created ≡ scope_created} (apollo
row 18; §7.1 + AD-6 — the on-disk draft carried the two-field form); (3) the -wire-check third
state off → skip (the settled strict|warn|skip); (4) the apps/mcp-go/AGENTS.md note-in-place
pointer added to §12 (the D-5 documentation-duty chain); (5) the resonance baseline_note made
REQUIRED content of every emitted R-n entry, server-supplied when the caller omits the field
(apollo row 10, "carried as a requirement"). File state of record NOW: aaw.mcp.design.md
681 lines · aaw.mcp.roadmap.md 296 lines (unchanged). Gates re-run post-edit: voice 0 hits on
both files, fences even, every relative link resolves. Z-1 stands unedited (append-only); this
entry reconciles its drift-detector line for the Operator. The close ceremony (P-3/P-4/Z-1/Y-1)
is the Director's record and is not duplicated; hand-written entry per R-2 (this seat carries
no mcp__aaw__* tools). No git by any peer or the Director; the Operator commits out-of-band at
approval.

## {aaw-mcp-consensus} Consensus

### C-1 — D3 consensus record: DESIGN-GRADE; six of seven contested decisions resolve toward venus-1; three D4 warnings (graft collision, crossed names, git-ignored policy home)

Apollo (ccl-aaw-mcp-4) renders the D3 design evaluation; full record at design/apollo.evaluation.md.

VERDICT: DESIGN-GRADE. All six locks + D-2/D-3 held in both designs and both reviews, zero re-litigation; every documented decision carries an ADR with >=2 steelmanned alternatives; every per-design gap is caught and filled by the opposite review; no blocking item stands.

AGREEMENT MATRIX (compact). CONVERGENT: index files-win fix (same-evidence, store.go:70-98); serialization domain + persisted next_ccl mint (same-evidence, main.go:155-184/:173 — verified real); atomic temp+fsync+rename w/ O_APPEND carve-out; ledger engine (complementary: EBNF <-> preservation invariant + goldens); all-or-nothing dual-stack bind (A-5, the phase's strongest — unprompted defect main.go:322-330/:338-340, timeline-clean); never-generate .mcp.json; archival (V1 fork#2 dissolved); messages.jsonl split (V2 F-3 dissolved); auth substance (no token, SDK protections); Q-1 status console; out-of-scope set (exact match); advisory-only signals + honest sensory horizon; Q-4 mechanism (twin instruments independently invented). DIVERGENT-RESOLVED-BY-REVIEW: transport — V2 conceded stateless+JSONResponse+no-session-id on V1's C-1 evidence, carrying V1's TESTABLE condition (one live harness-dial probe at the build gate; failure flips to stateful — both put zero-loss in files); config core — V2 conceded identity/policy split + tree-visible policy file; resonance — V2 conceded the deterministic measurement, retiring its caller-score variant, with the conceded shared-input baseline-inflation caveat REQUIRED in the emitted entry; port collision — V2 conceded diagnosed refusal (+capped probe, refusal-path-only); wire default — V2 conceded strict-refuse (+V2's three-state flag + unparseable verdict); attribution param — V1 conceded the single actor name; attribution site — V2's S2.2 challenge adjudicated VALID on V1's own EBNF (no attribution production; registry-side only); created flag — alias variant from both sides (V1 fork#3 dissolved); LAW-3 lint advisory — V2 conceded on its own terms; gaps filled by named donor ADRs (V2 lacked flock/error-vocabulary/draft/model; V1 lacked the conformance ADR). DIVERGENT-OPEN (to Operator/D4): F-1 bearer token DOWNGRADED to consensus ratification (one word; the S5 attack held); F-2 x.md:123 doc edit STANDS (verified); C-1 transport conditionally resolved (probe-as-decider); C-2 fine structure = two crossed picks (env-for-identity; per-knob policy flags) + W-3; two crossed TOOL NAMES (lease/heartbeat, poll/history — mechanisms settled, names permanent under R-9, Director picks).

ECHO-CHAMBER ADJUDICATION: A-2 = genuine same-evidence convergence, not inheritance — venus-2's ADR-2 carries three specifics beyond L-1's content (the len(r.Agents)+1 mint at main.go:173, the duplicate-CCL-mint failure mode, the live 26s near-miss measurement), and its ledger citation anatomy (D-1 at :49-66; D-2 from the resume brief; no L-1 cite) matches a pre-L-1 file state. A-5 CONFIRMED timeline-clean and independently articulated. Un-prompted probe (neither design examined): W-3 — the conceded policy home .aaw/config.json is git-IGNORED (.gitignore:200-201), contradicting ADR-31's own versionable-in-git rationale; plus cross-file write coupling under crash (ledger entry vs activity counter) and retry-after-ambiguous-failure duplicate entries. ATTACK THAT HELD: the shared tokenless posture — browser vector blocked threefold at verified SDK defaults (streamable_server.go:309-317/:390/:400-401 + non-simple-POST preflight); same-user-process vector conceded openly, and a token closes nothing (the token file is readable by the same process). W-1 GRAFT COLLISION: V1-review G-4 adopts the V-SOLO-2 Z-time emit that V2-review S5 self-corrects away on the proposal's R-4 degraded-run record — follow the self-correction; evidence-only.

SYNTHESIS RECOMMENDATION (one paragraph): base = venus-1 (the protocol spine: 22-tool post-D-3 catalog with schemas/gates, EBNF + numbering semantics, closed error vocabulary, 33 ADRs materially intact through review — and six of seven contested decisions resolved toward it), grafting from venus-2 the integration and ops layer: the S2.1 framework map + S2.3 trust model as sections, pure read-through index (same mechanism for the policy file), registry-side-only actor attribution + UNREGISTERED-ATTRIBUTION/CONTAINMENT codes, the liveness tool shape (note? + quiet_for_minutes?) merged with V1's three-source fusion + lease-at-dispatch + cap + winning-source verdict, the four-tier conformance ADR with V1's exemplar gate slotted in (+ hermetic temp workspace fixing V1's selftest/containment interaction), terminology fence, legacy-row hydration + migration notes, observability concretes, unparseable wire verdict, V-SOLO-2 evidence-only (W-1), the resonance baseline_note, status parse-health fields, and the aaw audit CLI subcommand ADOPTED as the zero-tool home of the L-2 regression + corpus lint + the new cross-file-drift recount (D-3-compatible). D4 must resolve: the two tool names, the S6-c config composition (recommended: no env anywhere, no per-knob policy flags — each architect's concession over each original), W-3's one-line .gitignore reconciliation, then FULL STOP for Operator approval on F-1 (ratify consensus), F-2 (doc edit), and the C-1 probe-as-decider conditional.

## {aaw-mcp-complete} Complete

### Z-1 — The aaw-mcp Design Phase is COMPLETE; all five stages closed; awaiting Operator approval

D0 ceremony (live, first fully-registered formation) → D1 two independent designs (venus-1 33 ADRs · venus-2 25 ADRs) → D2 cross-reviews (19/8/12 · 19/7/19) → D3 evaluation DESIGN-GRADE + C-1 consensus (apollo.evaluation.md; per D-7, the last standing design-phase Apollo run) → D4 synthesis: aaw.mcp.design.md + aaw.mcp.roadmap.md (Venus-3, real venus type) + design/x-mode.design.md (Director, parallel thread), all gate-verified (P-4).

File state of record at close (drift detector for the Operator): aaw.mcp.design.md 675 lines / aaw.mcp.roadmap.md 296 lines / design/x-mode.design.md 12,889 bytes; the design/ dir additionally holds the four stage artifacts. Decisions D-1…D-9 locked; learnings L-1…L-3 (two PoC defect classes + the live CCL re-mint); the v2 surface = 22 tools, MCP-1…MCP-8 ladder.

GATE NOW WITH THE OPERATOR: approve the design pair (and the protocol record) → the build proceeds to MCP-1 per the roadmap; reject/amend → feedback edits the design (adapt). Nothing is canon, and no production code is written, before approval. No git by any peer or the Director; the Operator commits out-of-band.

## {aaw-mcp-report} Report

### Y-1 — Final report: the full aaw MCP server v2 is designed, consolidated, and gate-verified — one approval gates the build

WHAT EXISTS: a complete, build-facing design system under docs/aaw/mcp/ — the requirements (aaw.mcp.proposal.md), the design of record (aaw.mcp.design.md: master invariant, framework→server map, trust model, AD-1…AD-12, the 22-tool catalog with schemas + per-tool error codes, the EBNF ledger grammar with the preservation invariant, the closed 16-code error vocabulary, the aaw audit CLI, four-tier conformance, the D-5 SDK policy, a 30-row donor-pointer decision record, the foreclosure list), the delivery plan (aaw.mcp.roadmap.md: MCP-1…MCP-8 thin rungs, M1 floor / M2 contract / M3 evidence engine / M4 proof, per-rung Ships·Demo·Harness·Feedback + diff boundary), the protocol record (design/x-mode.design.md), and the full evidence base (two designs, two cross-reviews, one evaluation, this ledger, the live registry).

HOW IT WAS PROVEN: every stage closed on tree evidence; the synthesis re-derived (not inherited); the Director's gate re-ran voice/fences/links/D-3/tool-count independently; load-bearing cites re-verified in the tree; the phase's own ceremony produced live evidence for two design decisions (the hot-ledger growth → hot-ledger discipline; the CCL re-mint 5→6 → AD-3/MCP-2).

RESIDUALS FOR THE OPERATOR AT APPROVAL: (1) approve/amend the pair as canon; (2) the C-1 probe-as-decider conditional rides MCP-4 (only rejecting probe-as-decider re-opens the transport fork); (3) the protocol-doc edits (x.md §12 formation rewrite per D-7, SKILL §2b, the F-2 line, apollo.md narrowing) are Operator-fenced and land only under the standing grant — itemized in design/x-mode.design.md; (4) policy defaults W=45/K=3/cap=240 are tunable policy. Build entry point: MCP-1 (goldens + parse-compat gate, zero production lines).
