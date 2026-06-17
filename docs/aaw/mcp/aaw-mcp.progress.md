# aaw-mcp — AAW scope ledger

> File: `aaw-mcp.progress.md` — the scope's slug-derived ledger, the server's only possible write
> target (the §8 slug grammar forbids dots, so a dotted scope is `SLUG_INVALID`). The dotted-family
> alias `aaw.mcp.progress.md` (design · roadmap · proposal · progress) is a same-directory symlink
> to this file: D-14 introduced the dotted rename, D-15 inverted the shim so that no write ever
> targets a symlink under either binary (the live PoC's in-place write or HEAD's atomic rename).
> The channel tags `{aaw-mcp-…}` are scope-derived and unchanged. Entries below this line are
> append-only history and keep their as-written paths.

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

### T-7 — MCP1 build derivation (Mars, ccl-aaw-mcp-7): per-deliverable path + the non-forced choices

Per-deliverable implementation path (every site cited against the re-verified grounding):

- MCP1-D3 first (AS1): NEW `internal/store/atomic.go` — `writeFileAtomic(path, data, perm)` = `os.CreateTemp` in the target dir → write → chmod 0644 → `f.Sync()` → close → `os.Rename` (the llms execution-plan mechanism verbatim). Routed through it: the index writer (was `store.go:97`), the registry writer (was `store.go:203`), the ledger appender (was `ledger.go:171`), AND the `InitScope` ledger-head creation (was `store.go:131` — the grounding table listed three sites; the spec's words "every whole-file write (index, registry, ledger)" cover this fourth, and the gate grep would have caught it).
- MCP1-D4 (AS2): the resident `scopes map[string]*Scope` field is REMOVED from `Store`; `readIndex()` re-reads `.aaw/scopes.json` per call under `s.mu`; `writeIndex()` persists a map freshly read in the same critical section (single-row merge — ADR-1's consequence: out-of-band edits to other rows survive any server write). `Open` keeps the boot-time corrupt-index fail-fast (parse + discard), holding nothing.
- MCP1-D1 (AS3): `ledgerLocks` → `scopeLocks` (same `sync.Map`-of-mutexes mechanism, per ADR-3's decision "the PoC mechanism broadened"); new unexported `updateRegistry(fn)` = lockFor → LoadRegistry → fn → atomic save; `SaveRegistry` UNEXPORTED to `saveRegistry` so an unlocked registry write is impossible by construction (cmd/aaw was its only caller). The `InitScope` ledger-head write nests store→scope — the one nesting the spec permits.
- MCP1-D2 (AS3): `Registry.NextCCL` persisted field; `mintCCL` mints `ccl-<scope>-<n>` and advances; the spawn row keeps an existing CCL-id and refreshes `spawned_at` (ADR-22 identity continuity). The mint reads no `len(r.Agents)` anywhere.
- MCP1-D5 (AS4): NEW `internal/store/lock.go` — `AcquireInstanceLock(workspace)` = open `.aaw/aaw.lock`, `syscall.Flock(LOCK_EX|LOCK_NB)`, write `<instance_id> pid=<pid>`, hold for life; refusal error carries `INSTANCE_LOCKED` + the holder line; `runServer` acquires after `store.Open`, `log.Fatalf` (exit 1) on refusal; `probe` surfaces holder via new output-only fields `instance_id`/`pid`.
- Call sites (`cmd/aaw/main.go`): the spawn/register/send handlers thin to `sc.SpawnAgent` / `sc.RegisterAgent` / `sc.RecordMessage` — every refusal text preserved verbatim; the FAKE-N log stays in the handler.

Non-forced choices, alternatives weighed:
1. Registry-write shape: (a) exported generic `UpdateRegistry(fn)` called with closures from main.go vs (b) three store methods mirroring the handlers. Chose (b): the INV1 acceptance gate demands "a concurrency property runs N parallel aaw_spawn" — only a store-level spawn surface lets the -race property drive the REAL production path rather than a test-local copy of the closure. (a) would leave the spawn semantics untestable except via transport.
2. Legacy `next_ccl` seed (ADR-22 states no rule for registries predating the counter): (a) seed 1 — collides with every live row; (b) seed len(agents)+1 — the banned pattern; (c) seed max(existing `ccl-<scope>-<n>` suffix)+1 — the only rule that never re-mints against the live registry's duplicate ccl-aaw-mcp-6 shape (A-7 evidence). Chose (c); pinned by TestMintSeedsFromLegacyRows reproducing the live defect shape verbatim.
3. Index form: ADR-1's full decision is an mtime+size-validated cache; the MCP1 spec text is PURE read-through ("the resident scope map is removed; every scope lookup reads"). Built the spec's pure form — the rung contract overrides the fuller design; the cache is a later optimization if ever needed.
4. Flock dependency: golang.org/x/sys (a go.mod edit, dep promotion) vs stdlib `syscall.Flock` (darwin+linux, zero module churn). Chose stdlib — diff containment.
5. The O_APPEND clause of D3/R3 is VACUOUS this rung: no `messages.jsonl` (ADR-14, the channels rung) and no `.claude/audit.log` writer (ADR-11, MCP2) exist in the as-built tree; messages remain registry-resident and are covered by the broadened scope lock. No dead `appendLine` helper added — the clause becomes operative when those rungs land.
6. `probe` holder surface: D5/R5/US4-AC2 mandate the holder in probe; R6's "schemas unchanged" is honored at the input surface (no new tool, no new parameter — ProbeIn untouched); `instance_id`+`pid` are output-only additions. Instance-id form (unpinned by the corpus): `aaw-<pid>-<boot-unix>` — greppable, deterministic, no rand.

Gate: build+vet clean · 12 tests green under -race (INV1 N=32 property + cross-scope + gap-free ledger; INV2 torn-read property + crash shape; INV3 out-of-band golden; INV4 in-process + two-process exec test; INV5 resume + legacy seed; US5 parse-compat goldens over both exemplar snapshots in testdata/) · 10× -race determinism loop on the concurrency properties green · hermetic selftest 17 tools PASS · greps clean · apps/mcp-go untouched.

### T-8 — MCP1 harden derivation (Mars, ccl-aaw-mcp-7): US walk → one un-discharged criterion → REMEDIATE-1; five adversarial probes → 3 tests added/extended + 2 findings

Independent full-gate re-run on the final tree, cache defeated (-count=1): build PASS, vet PASS, 14/14 tests PASS under -race (12.8s), hermetic selftest PASS (17 tools, port 18941, temp workspace), gofmt -l empty, all no-invent greps clean, apps/mcp-go untouched. New/extended tests additionally ran -count=5 green (flake resistance).

US acceptance walk (every Given/When/Then, the discharging check named): US1-AC1/AC2 → TestSpawnConcurrencyProperty (N=32 ⊇ 2, distinct ids, N+1 rows, next_ccl=N+2). US2-AC1 → TestWriteFileAtomicCrashLeavesPriorWhole; US2-AC2 → TestWriteFileAtomicNeverTorn. US3-AC1/AC2 → TestIndexReadThroughOutOfBand (delete stays deleted; hand-added row honored, no restart). US4-AC1 → TestSecondServerProcessRefused (exit non-zero, INSTANCE_LOCKED, first answers HTTP after). US4-AC2 ("probe reports the holder instance id and pid") was the ONE criterion no check discharged at build close — the build pass wired the surface and demoed it by hand but pinned nothing. REMEDIATE-1: an MCP-client assertion added inside TestSecondServerProcessRefused — connect over the real wire to the running holder, CallTool("probe"), unmarshal StructuredContent (the SDK field verified at apps/mcp-go/mcp/protocol.go:90), assert instance_id non-empty AND pid == the actual holder process pid. US5-AC1 → TestExemplarLedgerParseCompat (both exemplars; numbering continues per an independent re-scan; prior non-blank lines survive in order). US5-AC2 → the fresh hermetic selftest + TestRegistryRefusalsUnchanged (refusal texts verbatim). REMEDIATE count: 1 of MAX 3.

Adversarial probes (the harden delta), each resolved:
(a) Corrupt .aaw/scopes.json MID-SERVE (read-through era, past Open's fail-fast) → TEST ADDED TestIndexCorruptMidServe: scope-bound calls refuse TYPED ("corrupt scope index …"), no panic; InitScope during corruption REFUSES rather than treating corrupt-as-empty — the Operator's recoverable file is never clobbered (asserted byte-identical after the refused mutation); restoring a valid file heals on the very next call, no restart — the files-are-truth recovery virtue of the read-through design. Pinned alongside: ScopeNames swallows the read error into an empty list (see the learning).
(b) Flock release on process DEATH → TEST EXTENDED: after the refusal + probe assertions, the holder is killed; a fresh AcquireInstanceLock on the same workspace succeeds (ADR-2's crashed-holder consequence, previously asserted only in prose).
(c) Legacy seed against the spawned:true/registered:false row shape (the SpecAuthor-mcp2 live defect, A-7) → TEST ADDED TestLegacyRegistryLiveShape reproducing the FULL live registry shape (duplicate ccl-6 across two rows, one spawned-never-registered, no counter): re-spawn of the never-registered name KEEPS its duplicate id (evidence preserved, not repaired); the first true mint seeds max-suffix+1 = 7; registering the row flips the flag with no id churn; final next_ccl persists 8; 7 rows.
(d) Stale <file>.tmp.* accumulation after a crash → assertion added to the crash test (the stale temp is inert after a subsequent successful write: never read, never renamed over, never deleted) + FINDING: stale temps accumulate unboundedly across crashes; cost is directory clutter only (CreateTemp's random suffixes never collide with stale ones); a boot-time sweep is a later-rung candidate, deliberately NOT added here (diff containment).
(e) gofmt -l over apps/aaw/internal/store + cmd/aaw → empty.

Hermeticity: every test against t.TempDir() + ephemeral ports; the selftest workspace under /tmp on port 18941; binaries built to /tmp; the live server, the live .aaw, and port 8905 untouched this pass (all child-process invocations flags-first per L-5 — no repeat of the bind slip).

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

### D-10 — OPERATOR CALIBRATION (2026-06-11): build ceremony is tiered to rung size; MCP1 closes settled-tier

The Operator's mid-rung feedback, verbatim intent: the full AAW Director orchestration (build pass + separate harden pass + separate Apollo verify + four-task chain) was overcomplicated for the trivial MCP1 task. Remediation applied this turn:

1. **MCP1 close descoped to settled tier** — Mars's build pass already carried the complete gate (build/vet/race + 10× loop, two-process flock ×2, parse-compat golden, hermetic selftest, greps); Mars stood down from the extended five-probe harden checklist (keeping only what was in flight and green); the separate Apollo verify spawn is CANCELLED. Remaining close: the Director's independent gate re-run (the x.md pre-commit duty — a gate not run is a gate not vouched for) + Z-n + the one LAW-4 pathspec commit the runbook assigns.
2. **The standing rule, written into the specs** (the calibration the Operator ordered): `aaw.mcp.roadmap.md` "How the roadmap runs" now carries the three-tier formation rule — Settled (one implementor pass + Director gate re-run + commit; no separate harden/verify spawns), Standard (build + ONE second context, harden or verify, not both), Full (open fork / auth-data-deploy risk / system spec → the complete pipeline or the §12 Design Phase). `mcp1.prompt.md`'s Mode line recalibrated with the as-run record; `mcp2.specs.md` Goal pinned to standard tier.
3. **Scope of the critique** — sizing, not rigor: the emq-design Design Phase keeps its full formation (real architecture forks, a re-founded system spec — full tier by the rule). The Director executed the calibration edits Solo (User-override exception, named per x.md §1/LAW-3.3) — spawning an architect to write three spec paragraphs would re-commit the same error.

### D-11 — APPROVED: the design pair is canon; build opens at MCP-1; ceremony cut to the lawful minimum (Operator, 2026-06-11)

(1) The Operator ratifies aaw.mcp.design.md (681 ln state of record, P-5) + aaw.mcp.roadmap.md as CANON. The build proceeds per the ladder, entry MCP-1. (2) Spec naming as-chosen at sharpening: `mcpN.{specs,llms,prompt}.md` under docs/aaw/mcp/specs/ (supersedes the roadmap's proposed `mcp.N.*`; acceptance criteria carried inline in specs/llms — no separate .stories.md for tests-only rungs). (3) PROCESS CORRECTION (Operator feedback, stage-6): the value/ceremony ratio has become minimum — ceremony contracts to what the LAWS require: real spawns recorded (LAW-1), one executable gate per rung, one P-entry per rung close, Z-requires-D at scope close. No multi-entry narration, no standing evaluation stages (D-7), no reports longer than their diff. Pragmatic shipping product is the measure; the discipline improves by shipping, not by recording.

### D-12

D-n — Operator MINDSET (2026-06-11): the fast-paced build formation — Venus iteration → Mars-1 → Mars-2 refine → Director Solo review + close

Build rungs run: Venus iteration (pre-build reconcile + brief refresh against HEAD) → Mars-1 build → Mars-2 refine (gate + remediate) → the Director's Solo review and close (independent gate re-run + the one LAW-4 pathspec commit). No standing evaluator stage; ceremony per D-11. Applied from MCP2. Hygiene executed with this entry: the stale test flock residue (apps/aaw/internal/store/.aaw/, dead pid) removed; the canon-batch docs commit left to the Operator (staging observed in progress at decision time).

### D-13

D-n — The WRITING TRIAD LAW (Operator, 2026-06-11): root chapter index mandatory + mcp[N].md triad naming; violation remediated

The Operator halted mcp4 sharpening on a law violation: the spec ladder under docs/aaw/mcp/specs/ had NO root chapter file (the docs/echomq/specs/emq/emq.md pattern) and used fused mcpN.specs.md files instead of the established specs.approach triad. LOCKED: every spec chapter carries a root index (specs/mcp.md) and each rung is the full triad mcpN.md + mcpN.stories.md + mcpN.llms.md (+ optional mcpN.prompt.md runbook); the fused form is retired. The missing index had let two scope drifts pass unnoticed — the drafted mcp3 dropped the roadmap row's §8 EBNF grammar half, and the drafted mcp4 pulled mcp5's transport posture + C-1 probe in.

REMEDIATION EXECUTED (Venus-4, ccl-aaw-mcp-11, real venus type per D-8): specs/mcp.md authored (value ladder w/ as-executed statuses, master invariant, the §9 sixteen-code closed vocabulary, conventions, map); mcp1/mcp2 re-homed verbatim into spec+stories pairs (mcp1 parity zero-loss; mcp2's one delta = a stale citation CORRECTED against the tree — model application is internal/store/store.go:348/:375, not main.go); mcp3 split + EXTENDED to its full roadmap row (7 deliverables — vocabulary + EBNF lenient-parse/strict-emit/reserved-prefixes/parse-health); mcp4 split + RE-SCOPED to config/ports/wire (transport/C-1 referenced out to mcp5; the model field honestly reconciled as LANDED EARLY in mcp2's harden — main.go:73/:86/:138/:378, store.go:48 — mcp4-D4 closes the deferral formally by pinning tests); mcp4.llms.md authored fresh. Director gate independent re-run: 14-file census exact, six specs.approach gates PASS (two adjudicated expected-hits: the conventions bullet documenting the banned-token list; mcp1.prompt.md's deliberate pre-law-name historical annotations), traceability closure complete, all links resolve. Roadmap reconciled by the Director: status line canon (D-11) + the Triad-naming seam RESOLVED. Resume = mcp3 build from mcp3.llms.md.

### D-14

The run ledger renamed to aaw.mcp.progress.md (the dotted family) with a slug-derived symlink shim (Operator directive, 2026-06-11).

- The file `aaw-mcp.progress.md` is renamed `aaw.mcp.progress.md`, joining the dotted `aaw.mcp.*` family (design · roadmap · proposal · progress). A head blockquote in the ledger documents the rename; entries below it keep their as-written paths (append-only history is not rewritten).
- The scope slug stays `aaw-mcp`: the slug grammar (`store.go:28`, `^[a-z0-9][a-z0-9-]*$`) forbids dots, and the ledger path is slug-derived — `<ledger_dir>/<scope>.progress.md` (`store.go:235-237`). A scope named `aaw.mcp` cannot exist.
- The shim: a same-directory symlink `aaw-mcp.progress.md` → `aaw.mcp.progress.md`. The live pre-mcp1 binary (PID 16744) writes the ledger with a whole-file `os.WriteFile(sc.LedgerPath(), …)`, which follows symlinks — this entry, appended through the shim, is the live verification.
- Forward seam (owed to the cutover rung): the post-mcp1 store writes ledgers via atomic temp+fsync+rename, and a rename onto the link path REPLACES the symlink with a regular file — at v2 cutover the shim breaks silently, forking the ledger. The cutover rung (mcp8, or earlier if a rung restarts the server) must resolve it: resolve symlinks before the atomic rename (filepath.EvalSymlinks), or support an explicit per-scope ledger filename, or return the ledger to the slug-derived name.
- Inbound references updated in 9 docs (specs/mcp.md · mcp1.md · mcp1.prompt.md · mcp2.llms.md · mcp4.llms.md · aaw.mcp.roadmap.md · aaw.mcp.design.md · x-mode.design.md · apps/mcp-go/AGENTS.md). The committed goldens under apps/aaw/internal/store/testdata/ keep their slug-derived names — the harness derives `scope+".progress.md"` (ledger_test.go:62, mcp2_test.go:21); they are snapshots, not links.
- Same directive, recorded for context: specs/mcp.progress.md (the implementation dashboard) is authored alongside, and mcp5 is promoted to the Reconcile tool rung — the mcp5 promotion is ratified in its own entry after the Venus spec pass.

### D-15

D-n — Ledger shim inverted: the SLUG name is the real file, the dotted name is the read alias (the restart fuse defused)

FINDING (Mars, ccl-aaw-mcp-8, withheld for the Director's lock — correct fence): the in-flight rename (dotted `aaw.mcp.progress.md` = real file, slug `aaw-mcp.progress.md` = symlink) carried a restart fuse. The live server (pre-MCP1 binary) appends via in-place os.WriteFile, which FOLLOWS symlinks — safe today. HEAD's append path is writeFileAtomic (ledger.go:237 → atomic.go:37 os.Rename), and rename(2) REPLACES a symlink at the destination — verified empirically. On the first append after the live server restarts onto the HEAD binary, the slug symlink would silently become a regular file holding all new entries while the dotted canonical froze: silent ledger divergence, with the restart guaranteed by the mcp1 close's own residual.

DECISION (the reductive-minimal realization, zero code): INVERT the shim — `aaw-mcp.progress.md` is the real file (the server's only possible write target: the ledger path derives from the scope slug, and a dotted scope is SLUG_INVALID, so the dotted name can never be written by the server), `aaw.mcp.progress.md` is a symlink alias for the dotted-family doc references. Safe under BOTH binaries by construction — no write ever targets a symlink. Executed at decision time; this entry's own append through the slug path on the live server is the live verification the withheld variant could not honestly claim. Alternatives declined: EvalSymlinks in writeFileAtomic (a code change that must land AND be restarted-onto before the fuse fires — race-prone; remains available as later hardening if a write-through-symlink path ever becomes legitimate); reverting the rename (destroys the dotted-family intent). Registry stays slug-named, un-shimmed (no doc references it by a dotted name). The frozen testdata goldens are untouched. Git note for the Operator batch: the slug path returns to a regular file (M), the dotted path is a new symlink blob (??).

### D-16

The mcp5 Reconcile-tool promotion RATIFIED — the triad is specced, the ladder is reconciled, the displaced transport rides mcp8 (Director, on the Venus-5 pass; Operator directive per D-14).

- **The rung's shape (ratified):** mcp5 ships `aaw reconcile` — a deterministic, read-only CLI subcommand on the design-§10 `aaw audit` zero-MCP-tool pattern. It extracts the three documented claim kinds a spec makes (`file:line` cite tokens, relative markdown links, backticked workspace paths), probes the real tree read-only, classifies each claim MATCH / STALE / MISSING into a per-file delta table with tallies, `-json`, and gate-able exit codes (0 no drift / 1 drift / 2 usage-or-containment). Every report carries the honesty limit: MATCH verifies existence + line-range only; semantic agreement stays the reconciling agent's verdict. No §8 grammar addition, no seventeenth error code, zero tool-surface change — the count column stays 18 at mcp5 and 22 at v2 end, so no design amendment row was needed. The CLI-vs-MCP-tool fork is surfaced, not taken: the D-3 tool-fatigue precedent plus §14 deterministic-only intelligence decide CLI; promoting an `mcp__aaw__` reconcile tool later is a named Operator decision in the rung's Feedback-asked.
- **The displaced content (ratified):** the transport posture + C-1 probe land at mcp8 with zero renumbering — the probe is a gate by nature and its restart-invisibility transcript IS the cutover demo; nothing in mcp6/mcp7 binds on session mode; AD-1 already fixes stateless as canon intent with the flip a one-option zero-loss configuration change. mcp4 stays as specced (folding there would re-open a specced triad for no dependency gain); mcp8's diff boundary extends to `apps/mcp-go` only if the probe or conformance exposes an SDK defect (D-5).
- **Surfaces reconciled (verified against the tree by an independent Director sweep):** the mcp5 triad authored (`specs/mcp5.md` D1–D5/INV1–INV5 · `mcp5.stories.md` US1–US5 with full Coverage · `mcp5.llms.md` R1–R7/AS1–AS5, traceability closed); `specs/mcp.md` (status line, mcp5 row §10·AD-12, mcp8 row absorbs AD-1, dependency arc); `aaw.mcp.roadmap.md` (header status, ladder rows, arc, M2/M4, per-rung sections, seams C-1 → mcp8); `mcp4.md`/`mcp4.llms.md` transport references re-homed to mcp8 with the displacement note; the retired-proposal links in the Maps and the mcp1/mcp2/mcp3 briefs converted to the `git show 74d8a899:` history pattern. Gates green; the two expected-hits (the Conventions banned-token bullet; a grammar example inside a fenced prompt) adjudicated, not defects.
- **Escalation to the Operator (report-only; the design is Operator-amended):** `aaw.mcp.design.md` carries two broken links to the retired proposal (~:20, ~:665), `x-mode.design.md` one, and `mcp2.md:97` cites `aaw.mcp.proposal.md:74-79` as a backtick token — recommend the same `git show 74d8a899:` pattern ride the commit batch.
- **Ledger head-note synced to D-15:** the slug name is the real file, the dotted name is the read alias; this entry's own append is written through the slug path.
- mcp5 enters the dashboard as **specced** (stage 1 of 4); M2 · The contract = mcp3 build-grade · mcp4 specced · mcp5 specced. The build order is unchanged: mcp3 fires first on the Operator's word.

### D-17

The roadmap gains the value measurement — framework productivity, proven at mcp6 (Operator directive 2026-06-11; Director senior-authored, chapter-doc fence).

- **The frame:** every rung before mcp6 is an UPFRONT RUNG — an instrument built ahead of the point where its value is exercised. A rung's own gate proves correctness, not value; the ladder's value criterion is aaw framework productivity (how much of a formation's coordination the server carries instead of the Director's hands), and that quantity now has a measurement: **the coordination of authoring mcp6 itself**.
- **The instrument:** mcp6 is the measurement rung by construction — the first rung whose whole formation (sharpen → build → ship → close) can run end-to-end on the upfront instruments, and whose own subject (durable message channels) is coordination. Each upfront instrument carries one named stage of the mcp6 authoring with a countable outcome: mcp5 `aaw reconcile` carries the pre-build sharpen (drift caught by exit code vs hand-grep); mcp1 carries the ceremonies (server-recorded vs hand-written); mcp2 carries liveness + the one-read close gate (false-silent verdicts, target 0); mcp3 carries refusal diagnosis (undiagnosed free-text failures, target 0); mcp4 carries the dial surface (misdialed/wire-drifted sessions, target 0).
- **The inverse metric, above the rest:** manual out-of-band interventions — every step the Operator or the Director performed by hand that an instrument should have carried. Each intervention recorded at the mcp6 close is a named finding with a disposition: an mcp7/mcp8 deliverable, a future-rung candidate, or a documented non-goal. The measurement feeds the ladder.
- **Surfaces edited (roadmap only + view sync):** `aaw.mcp.roadmap.md` — new section "The value measurement — framework productivity, proven at mcp6" (the upfront-rung definition, the instrument-to-stage table, the tally rule) placed before "The ladder at a glance"; the ladder-intro names mcp6's extra **Measurement** row; the §mcp6 iteration row gains the Measurement bullet and its Feedback-asked gains the tally read ("which manual intervention should the next rung retire first"); the M3 milestone row carries "the measurement lands". View sync: `specs/mcp.progress.md` mcp6 rows name the measurement role. The mcp6 triad remains unauthored — when it is, the spec inherits the Measurement row as a deliverable.
- **Consequence for the build order:** the measurement binds mcp6's authoring to run AFTER the upfront instruments it counts are live — mcp3 built (750bda97, second context owed), mcp4 + mcp5 specced and next to build. No renumbering; the dependency arc already reads this way.

### D-18

mcp4 pre-build reconcile RATIFIED — BUILD-GRADE, verdict GO (Venus-mcp4 grounding pass vs HEAD 750bda97; Director spot-verified; recorded Director-side per the venus-def precedent).

- **The verdict:** no INVENTED, no MISSING claims; every drift was a line-number shift from the mcp3 diff, re-pinned in mcp4.md (six cites + the gates-route pin) and mcp4.llms.md (references + two added grounding bullets + four prompt-block corrections). mcp4.stories.md untouched (no file:line claims).
- **Director spot-verification (independent, against the tree):** main.go:518-521 bind lenience · :32-33 flags · :166 StatusOut wire_contract omission comment · store.go:50/:364/:391 model field + empty-keeps-stored applications · gates.go:37-38 PORT_BUSY/WIRE_MISMATCH reserved with no-emitter comments · lock.go:44 INSTANCE_LOCKED rendered through the gates constant (the pinned emission route) · zero os.Getenv/os.LookupEnv in non-test code. All real.
- **Locked build contracts:** order AS1 config plane → AS2 honest bind → AS3 wire check → AS4 model pins (tests only) → AS5 banner/probe + F-2 held-or-granted. Gate: GOWORK=off build + vet + test -race -count=1 (config read-through incl. no-env · two-instance family-split refusal · wire-verdict matrix ×5 · model additive/continuity · banner/probe) + selftest green at 18 tools + the MCP1 goldens. Diff boundary: cmd/aaw/main.go + NEW internal/config/ + internal/signals/ (consumers re-pointed, constants kept as the default layer) + internal/store/** (tests) + .gitignore (two W-3 lines) + .claude/commands/x.md:123 (the one F-2 line, held and reported absent the grant). NO apps/mcp-go; tool surface stays 18; only the two reserved codes gain emitters.
- **Standing Operator items riding as specced (neither blocks):** F-2 stays Operator-fenced — the build holds + reports unless the grant is confirmed at build time; the wire-check strict-default question stays in the roadmap's Feedback-asked.
- **Sequencing note:** the Venus-5 two-audience framing pass (Operator directive: 5W per-audience + stories re-cut US-D[N]/US-A[N] + llms tag re-points, mcp4+mcp5) is IN FLIGHT on the same triad; the passes are orthogonal (framing vs grounding) and Venus-5 is instructed to apply on top of the re-pinned state, preserving every cite. The Mars-mcp4 build fires after the framing pass lands, so the brief Mars reads carries the final story ids.
- mcp4 advances on the dashboard: specced → build-grade. The upfront-rung march (D-17): mcp3 built · mcp4 build-grade · mcp5 specced — the measurement at mcp6 nears.

### D-19

The mcp4 + mcp5 two-audience reconcile RATIFIED — the rungs' value is now articulated per audience: US-D[N] the developer, US-A[N] the agent (Operator directive 2026-06-11; Venus-5 ccl-aaw-mcp-13 pass; Director-verified).

- **The frame:** the prior Rationale/stories addressed a role soup (Operator / maintainer / spec steward / Director / harness). The reconcile collapses it into the two real audiences — the developer (the human who boots, tunes `.aaw/config.json`, owns `.mcp.json`, audits, commits) and the agent (the server's primary users: the peers who dial the tools, read `probe`/`aaw_status`, record ceremonies, and run `aaw reconcile` in their loops). The 5W Who bullets name both audiences with each one's value; the Why bullets lead with the cost each pays today.
- **The re-cut (verified on disk):** mcp4 5→7 stories — US-D1 (policy in a committed file) · US-D2 (no family-split) · US-D3 (wire checked, never written — the file stays the developer's) · US-A1 (the verdict in-band: the wire verdict surfaced where agents read) · US-D4 (model on the audit record) · US-D5 (honest boot banner) · US-A2 (the probe payload in one call). mcp5 5→6 stories — US-A1 (the pre-build reconcile in one command — the steward is an agent) · US-A2 (the scriptable drift gate — the Director is an agent) · US-D1 (honest MATCH limit) · US-D2 (read-only, risk-free corpus) · US-A3 (the locked catalog: a deferred-schema client unaffected) · US-D3 (the grammar pinned by goldens).
- **Director verification (independent sweep):** structure 6/6 sections + exact 5W on both specs; every D# in both Coverage lines; INV1–INV4 (mcp4) and INV1–INV5 (mcp5) all encoded; every R# `[US:]`-tagged and every AS# `[implements]`-tagged over the NEW ids (two sweep flags adjudicated false-positive by reading — R4/R5 tags sit beyond the regex window); links + fences clean; ZERO old-form `MCPn-USk` ids anywhere in the tree; the Venus-mcp4 grounding re-pins (D-18) survived the framing pass intact — the two passes composed cleanly after the mid-flight coordination message.
- **The conventions line:** specs/mcp.md "Story audiences (from mcp4 on)" — stories split US-D[N]/US-A[N]; mcp1–mcp3 keep their as-shipped numbering (history is not rewritten).
- **View sync (Director):** the index value-ladder rows corrected to the blockquote's truth — mcp3 shipped (750bda97), mcp4 build-grade (D-18).
- **Standing:** mcp4 remains BUILD-GRADE with the framing now final — the Mars-mcp4 build can fire on the Operator's word from the re-pointed brief; mcp5 specced. The mcp6 measurement (D-17) gains its audience frame for free: the productivity tally counts what the server carries for AGENTS; the manual-intervention inverse metric counts what still falls on the DEVELOPER.

### D-20 — The mcp-go TODO-resolution parallel rung (Operator directive): every TODO in apps/mcp-go resolved, isolated, independent of mcp4

Operator directive (verbatim intent): "Each 'TODO' in /Users/jonny/dev/jonnify/apps/mcp-go must be resolved in the parallel rang (independent, mcp-go isolated)." Authority: D-5 (apps/mcp-go FREE TO MODIFY, ADR-recorded — commit 74d8a899 made the fork policy explicit). Provenance established first: the inventory is ~70 TODO markers in non-test code + ~20 in tests, ALL predating every build rung — `git log --follow` places even resource_traversal_invariant_test.go in the original vendoring commit 4ed0b4fe; no aaw Mars authored any of them; every prior rung's diff boundary explicitly excluded apps/mcp-go (mcp1 Z-2: "apps/mcp-go untouched").

Locked resolution semantics (Director interpretation, Operator-amendable): each TODO is dispositioned exactly one of two ways — (a) IMPLEMENTED: the smallest correct change, only where local, low-risk, and provable by the rung gate; or (b) SETTLED: the marker rewritten to a `// settled(aaw): …` fork-decision comment carrying the original upstream attribution/issue ref plus a one-line rationale (upstream wishlist items, protocol-behavior forks, and Windows-only fixes default to settled — this repo's fork does not track upstream's wishlist, per D-5). End state: `grep -rn "TODO" apps/mcp-go --include="*.go"` returns ZERO matches; the report carries the full per-TODO disposition table (file:line → implemented|settled + rationale).

Rung contract: peer = Mars-mcpgo (ccl-aaw-mcp-18, registered). Diff boundary = apps/mcp-go/** ONLY (no apps/aaw, no specs, no ledger, NO git). Gate = GOWORK=off go build ./... + go vet ./... + go test -race -count=1 ./... green inside apps/mcp-go, PLUS the dependent-module cross-check: apps/aaw still builds and its tests stay green (read-verified, never edited). Never touches the live :8905 server or binds its port. Tier: standard (build + the Director's independent gate re-run; a second context only if the diff turns risk-bearing). Runs PARALLEL to and independent of mcp4 — the two rungs share no files, so no ordering constraint; concurrency stays at the ≤2 heavy ceiling (Mars-mcp4 + Mars-mcpgo).

### D-21 — D-20 amendment (Operator directive): TODOs naming a concrete upstream API surface are SHIPPED, not settled

Operator directive mid-rung: "Ship upstream API-surface mentioned in replacement comments instead of TODO." This amends D-20's resolution semantics for the mcp-go rung: where a TODO (or a `settled(aaw)` replacement comment already written this rung) names a CONCRETE upstream API surface — export this interface/type/function/field, expose this functionality to users, make this value configurable — the disposition is now (c) SHIPPED: implement that surface, additively, smallest correct change, gate-provable. The known qualifying set from the inventory: transport.go:73/:86 (unexported interfaces marked "should this be exported?"), client.go:187 (type + field export), streamable_server.go:752 (jsonResponse export) + :759 (logger export), streamable_client.go:281 ("propose exporting these"), shared.go:400 (timeout configurability), resource.go:135 (expose to user ResourceHandlers), protocol.go:1434 (CompleteRequest and related types) — Mars-mcpgo verifies each in source and may identify further qualifiers by the same criterion.

The (b) SETTLED disposition remains correct for: design musings/debates ("rethink the framer interface", "consider a different API"), protocol-behavior forks, Windows-only fixes, batching/perf speculation, and upstream-issue items with no named surface. Files already dispositioned this rung are REVISITED under the new criterion. The disposition table gains the third column value `shipped`; every shipped surface is named in the report with its new exported identifier. Gate unchanged (D-20): build + vet + test -race green in apps/mcp-go, apps/aaw cross-check green, zero-TODO grep. Boundary unchanged: apps/mcp-go/** only. Ledger note: the Operator committed the partial sweep out-of-band mid-rung (apps/mcp-go clean at 73 TODOs remaining) — the close-time review accounts for pre-staged copies (AM re-add flag pattern).

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

### L-5 — aaw CLI flags silently no-op after the mode word (flags-first is mandatory)

Surprise hit while standing up the INV4 two-process test: `aaw serve -addr 127.0.0.1:PORT -workspace WS` IGNORES both flags. `flag.Parse()` (stdlib) stops at the first non-flag argument — `serve` — so everything after it is positional and the flags keep their DEFAULTS: `localhost:8905` (the live wire contract's port) and `-workspace .` (the invoker's cwd). The correct invocation is flags-first: `aaw -addr … -workspace … serve`.

Two consequences:
1. The doc comment at `cmd/aaw/main.go:5-6` ("aaw serve [-addr …] [-workspace …]") and the usage string at `:43` document the broken order — a PRE-EXISTING defect OUTSIDE this rung's boundary (changing CLI parse semantics is not in the MCP1 brief). Surfaced here for a later rung or the Director; not fixed.
2. The failure shape is quiet and now interacts with the flock: a stray flags-after-mode boot falls back to port 8905 + cwd — in this build pass it merely failed the 8905 bind against the live instance and exited (live server, live `.aaw`, and the lock all untouched; the stray run's flock landed in the debug cwd). Post-MCP1, the same mistake run from the live workspace root would acquire `.aaw/aaw.lock` momentarily before dying on the bind. Every operator runbook, test, and harness boot of `aaw` must put flags BEFORE the mode word.

The rung's own surfaces are flags-order-correct: the two-process test and the hermetic selftest invoke flags-first (with a constraint comment at the exec site in lock_test.go).

### L-6 — Harden-pass findings: two degraded surfaces named with their cost (neither a fault, both candidates for later rungs)

1. ScopeNames swallows a corrupt-index read error into an empty list (store.go ScopeNames returns nil on readIndex failure — the signature has no error channel, inherited from the PoC where the resident map could not fail). Consequence: while .aaw/scopes.json is corrupt, probe answers ok:true with scopes:[] — a probe-only observer cannot distinguish "no scopes exist" from "the index is unreadable", though ANY scope-bound call refuses loudly with the typed "corrupt scope index …" error, so the state is diagnosable one call deep. Pinned as-built by TestIndexCorruptMidServe. Cost: one misleading diagnostic surface during a rare, operator-induced state. Candidate fix belongs to the closed error-vocabulary rung (probe could carry an index_error field), NOT a silent signature change here.

2. Stale <file>.tmp.* files accumulate across crashes, unboundedly. writeFileAtomic cleans its temp on every failure path it can see, but a hard kill between CreateTemp and Rename strands one temp; nothing ever sweeps the directory. The stranded temp is provably inert (asserted in TestWriteFileAtomicCrashLeavesPriorWhole: never read, never renamed over, untouched by later writes — CreateTemp's random suffixes cannot collide with stale names). Cost: directory clutter in .aaw/ and ledger dirs proportional to crash count. A boot-time sweep (unlink <file>.tmp.* older than the boot) is a one-liner candidate for the config/ports/wire rung or an operator runbook line; deliberately not added this rung (diff containment).

3. Durability nuance worth one sentence at the verify: writeFileAtomic fsyncs the FILE, not the parent DIRECTORY — exactly ADR-4's specified discipline ("temp, fsync, rename"). Process-crash atomicity (MCP1-INV2's claim) is fully covered; under POWER LOSS the rename itself may not yet be durable, so a just-acknowledged entry could be absent after reboot — still "at most the in-flight entry, never a torn file" (INV2's wording holds; the file is whole either way). A dir-fsync would close it at the cost of one fd+sync per write; that is a design decision for a later rung if the Operator wants power-loss durability promoted into the contract.

### L-7 — A mid-rung directive amendment can race an in-flight peer to its report: require an explicit amendment-acknowledgment before accepting the verdict

Observed live on the mcp-go rung: the Operator amended D-20 mid-rung (D-21: API-surface TODOs are SHIPPED, not settled), the Director relayed it to Mars-mcpgo's inbox while the sweep was in flight — and the peer's BUILT report landed with all eight D-21 qualifiers dispositioned settled and ZERO reference to the amendment. The message was delivered (routing confirmed) but never processed: an agent deep in a long file-by-file pass reads its inbox at turn boundaries, and a report-shaped final turn can consume the queue without acting on it. The report was otherwise complete and gate-green, which is exactly what makes the miss dangerous — a verdict that looks closed while a binding directive is unapplied.

Rule going forward: when a directive amendment is sent to an in-flight peer, the peer's next report is NOT acceptable unless it explicitly references the amendment (applied, or reasoned non-application). The Director checks for the reference before gating; absence = automatic remediation pass, not a close. Cost this time: one extra round-trip (the remediation charter re-lists the eight surfaces verbatim). Related: the hot-ledger discipline covers out-of-band WRITES racing the Director; this is the dual — Director directives racing a PEER's read horizon.

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

### P-6 — MCP1 build pass CLOSED, Director gate PASS (2026-06-11); harden pass launched, same Mars identity

Mars (ccl-aaw-mcp-7, minted clean) built D1–D5: scopeLocks per-scope domain + unexported saveRegistry (unlocked write impossible by construction) · persisted NextCCL + mintCCL + re-spawn-keeps-id · writeFileAtomic routed through index/registry/ledger + the 4th site the grounding table missed (InitScope ledger-head) · pure read-through index per the spec (ADR-1's mtime-cache variant deliberately not built — contract words over design fullness) · stdlib-flock instance guard + INSTANCE_LOCKED + holder in probe. Gate: build/vet clean; `go test -race` 12+2 green + 10× determinism loop green (66s); two-process flock PASS twice (in-suite + live shell demo); parse-compat golden over both live ledgers PASS; hermetic selftest PASS (17 tools); greps clean; apps/mcp-go untouched; diff = M{main,ledger,store}.go + NEW{atomic,lock}.go + 4 tests + testdata.

Six deltas FLAGGED not silent, Director-accepted at this gate, queued for Apollo re-check: (1) probe OUTPUT fields instance_id/pid — D5/R5/US4-AC2 mandate the holder; "schemas unchanged" read as input-surface (only implementable reading); (2) O_APPEND clause vacuous — no messages.jsonl/.claude/audit.log writers exist in the as-built tree (later rungs); no dead helper added; (3) legacy next_ccl seed = max existing suffix+1 (unpinned by ADR-22; forced by INV5 + the live duplicate-ccl-6; test-pinned); (4) registry logic relocated into store methods so -race drives the real path (refusal texts verbatim); (5) the 4th atomic site; (6) instance_id form `aaw-<pid>-<boot-unix>` (unpinned). Boundary finding surfaced not fixed: CLI flags silently no-op after the mode word (L-5) — flags-first is mandatory; one debug run harmlessly bumped the live 8905 bind (OS-refused; live workspace untouched; all tests hermetic).

### P-7 — Session close: D4 protocol record + mcp1/mcp2 triads delivered and gated; one recorded deviation

Delivered this session (Director ccl-aaw-mcp-1 + Venus-3 ccl-aaw-mcp-5 + SpecAuthor-mcp2): design/x-mode.design.md (the protocol record, D-9 split) · aaw.mcp.design.md + aaw.mcp.roadmap.md (Venus-3; ratified canon by D-11) · specs/mcp1.{specs,llms,prompt}.md (Director; built + closed at 7972859f, settled tier per D-10) · specs/mcp2.{specs,llms}.md (fan-out; specs committed w/ the standard-tier pin, llms untracked). Gate sweep: all 8 files PASS (structure/voice/fences/traceability/links; one checker false-negative fixed in the harness, not the files). Deviation recorded, not rewritten (the closed-rung drift rule): mcp1 D3's O_APPEND clause names messages.jsonl/.claude/audit.log, which have no as-built site at HEAD — the discipline is fixed, the objects land at mcp2 (audit.log) and mcp6 (jsonl split); as-built defers via apps/aaw/internal/store/atomic.go:11; surfaced by the Mars-1 verification at HEAD (gate green 14/14 -race + hermetic selftest + two-process flock). Deferred as cosmetic under D-11 minimal ceremony: mcp1↔mcp2 sibling footer links on the committed triad. Resume = mcp2 build (standard tier) from mcp2.llms.md.

### P-8

P-X — MCP2 CLOSED at HEAD f44f0539: evidence plane shipped, gate green, deltas adjudicated (2026-06-11)

MCP2 (attribution · liveness · status gate console) built by Mars-2 (ccl-aaw-mcp-9), committed out-of-band by the Operator as f44f0539 "PRAGMATIC DELIVERY ONLY". Director gate re-run independently at HEAD: go build/vet clean, go test -race -count=1 ./... GREEN (signals 2.3s + store 14.9s; 25 top-level tests = 14 MCP1 carried + 11 new). Tool surface 18 (17 v1 + agent_heartbeat); apps/mcp-go porcelain-empty; live server + real .claude/audit.log untouched.

Delta adjudication (Mars surfaced 7): 2/3/5/6/7 ACCEPTED as documented realizations (z_eligible=d_count≥1, archived=TTL-hint lapse, counter-on-ledger-writers-only, vacuous V-SOLO-1 over zero peers, sliding-window dedup). Delta 4 (wire_contract constant "ok") — RESOLVED: omitted at HEAD (main.go:154-156), the asserted-gate shape correctly refused; the config/ports/wire rung adds it back COMPUTED. Delta 1 (model field) — DEFERRED to mcp4 per the reconciled mcp2.llms.md:62-64 (no as-built tool supplies a model param; it is an mcp4 status-row surface alongside the computed wire_contract verdict). A harden pass was dispatched then STOOD DOWN: both items were already resolved in the reconciled tree — no second build needed (standard tier satisfied by build + post-build reconcile + Director gate).

Milestone M2 (the contract) advances: MCP2 done; MCP-3 (error vocabulary) + MCP-4 (boot/wire/config, owning the deferred model + computed wire_contract) are the remaining M2 rungs. NEXT: sharpen mcp3 + mcp4 spec pairs.

### P-9

MCP3 COMPLETE (standard-tier close) — the error vocabulary + the §8 grammar formalization is built, second-context-verified CLEAN, and committed at 750bda97.

- **The tier ran in full:** Mars-mcp3 build (from mcp3.llms.md, order AS1→AS2→AS3→AS7→AS4→AS6→AS5) → Mars-mcp3-2 second context (independent DoD re-run, verdict CLEAN, zero changes) → Director gate re-run (GOWORK=off build + vet + test -race, 4 packages, green; hermetic selftest PASS at 18 tools with exact-code GATE_Z_REQUIRES_D + PATH_ESCAPE) → the Operator's commit 750bda97.
- **The increment:** internal/gates/ is the single vocabulary home — exactly the sixteen §9 codes in canon order, append-only pinned by TestClosedCodeSet; Errorf renders `aaw: <CODE>: <detail>`, Code extracts, Contained carries separator-boundary semantics. The refusal sweep is total: eleven emittable codes verified at their sites; the three non-gates constructors are the renderer itself, the lock.go:44 INSTANCE_LOCKED boot fold (single `aaw: ` prefix via the main.go:496 boot render — the correct realization, not drift), and the documented ledger.go:192 unknown-stream exemption. The §8 EBNF lives verbatim in ledger.go:22-50 beside ReservedPrefixes; lenient parse / strict emit pinned by goldens replaying BOTH committed exemplars byte-preserved; ParseHealth surfaces unknown_prefixes additively and a hand `### ADR-3` is tolerated, reported, never gating. Both PATH_ESCAPE faces ship: the init/spawn doors refuse before any side effect; emitContainment gives signals.CodeContainment its one call site with dedup. Surface stays 18; apps/mcp-go untouched (the companion 1ddce14f touched one AGENTS.md prose line).
- **Director verification:** test names present (gates_test.go, store/mcp3_test.go), goldens byte-unchanged across 514d4768..750bda97, tree clean at HEAD.
- **Two observations surfaced (no fix; dispositions open):** (1) the live :8905 server still serves the pre-MCP1 17-tool surface — a restart from HEAD activates the new gates + 18 tools; restart timing is the Operator's call (the session-loss trade is recorded in the transport discussion — stateless lands at mcp8). (2) The L-5 flags-first quirk's usage doc-comment still reads `aaw serve [-addr …]` while flag.Parse() requires flags BEFORE the mode word — the natural home is mcp4 (the config rung already re-pinned the usage line at main.go:48); surfaced for the Operator: a one-line usage-doc fix riding mcp4-D5, or a parse restructure (scope growth, not recommended).
- The dashboard advances mcp3 → shipped: M2 standing = mcp3 shipped · mcp4 build-grade (D-18) · mcp5 specced (D-16). Two upfront rungs remain before the mcp6 measurement (D-17).

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

### Z-2 — MCP1 COMPLETE (settled-tier close; the LAW-4 trigger)

Exit criteria: all five deliverables built and gate-proven (Y-2 carries the evidence chain — Mars build + harden, Director independent re-run green this turn); every MCP1-INV1…INV5 pinned by a running test; the parse-compat golden holds over both live ledgers; the 17-tool surface unchanged; `apps/mcp-go` untouched; the diff inside the declared boundary. Decisions locked this rung: D-10 (the Operator's tiered-formation calibration; the settled-tier close it mandates is this Z's shape). The one LAW-4 pathspec commit follows this entry immediately — pathspec per the runbook + the two calibration files; the staged Operator out-of-band content (bcs work, ledgers/registries) is excluded by pathspec and left staged/untracked for the Operator.

### Z-3 — The aaw-mcp Design Phase is CLOSED: design canon (D-11), build open, ladder running

The §12 formation ran end-to-end: Venus-1 ∥ Venus-2 (D1) → cross-reviews (D2) → Apollo DESIGN-GRADE (D3, C-1) → synthesis (D4: aaw.mcp.design.md + aaw.mcp.roadmap.md by Venus-3; design/x-mode.design.md by the Director per D-9) → Operator approval ENACTED (D-11: pair ratified canon; build opened; mcp1 closed at 7972859f with an independent gate re-run green). Process corrections earned and locked en route: D-7 (no standing Apollo stage in Design Phases), D-8 (real venus type for system-spec synthesis), D-10 (tiered build ceremony), D-11 (ceremony at the lawful minimum). Decisions D-1…D-11 locked; the formation evidence is the registry; no git by peers or the Director throughout (operator commits out-of-band). The scope stays open for the build ladder (mcp2 next, standard tier).

### Z-4

Z-n — MCP2 COMPLETE (D-12 formation close)

Venus iteration (post-build reconcile, BUILD-GRADE, triad re-pinned to HEAD) → Mars-1 build (shipped f44f0539) → Mars-2 refine (the wire-test deferral pin — wire_contract omitted until mcp4; committed 514d4768) → Director Solo review: independent gate at HEAD 514d4768 GREEN (GOWORK=off go build + vet clean; go test -race -count=1 ./... ok — signals 1.8s, store 14.8s incl. TestMCP2WireGateConsole). Triad wire_contract over-claim fixed at 4 sites (deferral marked, spec gates re-PASS; committed 02bf00b5). Surface = 18 tools. Open for the Operator: the two canon calibration forks (AD-4 model field unminted; verdict vocabulary active|quiet-declared|stale + winning_source vs the canon's active|quiet|silent + liveness_source). Commits Operator-made out-of-band; no git this session. Next rung: mcp3 (error vocabulary + grammar), triad just-in-time at the Venus step.

## {aaw-mcp-report} Report

### Y-1 — Final report: the full aaw MCP server v2 is designed, consolidated, and gate-verified — one approval gates the build

WHAT EXISTS: a complete, build-facing design system under docs/aaw/mcp/ — the requirements (aaw.mcp.proposal.md), the design of record (aaw.mcp.design.md: master invariant, framework→server map, trust model, AD-1…AD-12, the 22-tool catalog with schemas + per-tool error codes, the EBNF ledger grammar with the preservation invariant, the closed 16-code error vocabulary, the aaw audit CLI, four-tier conformance, the D-5 SDK policy, a 30-row donor-pointer decision record, the foreclosure list), the delivery plan (aaw.mcp.roadmap.md: MCP-1…MCP-8 thin rungs, M1 floor / M2 contract / M3 evidence engine / M4 proof, per-rung Ships·Demo·Harness·Feedback + diff boundary), the protocol record (design/x-mode.design.md), and the full evidence base (two designs, two cross-reviews, one evaluation, this ledger, the live registry).

HOW IT WAS PROVEN: every stage closed on tree evidence; the synthesis re-derived (not inherited); the Director's gate re-ran voice/fences/links/D-3/tool-count independently; load-bearing cites re-verified in the tree; the phase's own ceremony produced live evidence for two design decisions (the hot-ledger growth → hot-ledger discipline; the CCL re-mint 5→6 → AD-3/MCP-2).

RESIDUALS FOR THE OPERATOR AT APPROVAL: (1) approve/amend the pair as canon; (2) the C-1 probe-as-decider conditional rides MCP-4 (only rejecting probe-as-decider re-opens the transport fork); (3) the protocol-doc edits (x.md §12 formation rewrite per D-7, SKILL §2b, the F-2 line, apollo.md narrowing) are Operator-fenced and land only under the standing grant — itemized in design/x-mode.design.md; (4) policy defaults W=45/K=3/cap=240 are tunable policy. Build entry point: MCP-1 (goldens + parse-compat gate, zero production lines).

### Y-2 — MCP1 final report (settled-tier close per D-10)

**Shipped:** the single-writer store discipline over the live PoC, 17-tool surface unchanged, `apps/mcp-go` untouched. D1 per-scope serialization domain (scopeLocks over ledger+registry+messages; `saveRegistry` unexported so an unlocked registry write is impossible by construction; store lock = index only). D2 persisted `next_ccl` mint + re-spawn identity continuity + the legacy-registry seed (max existing suffix +1 — test-pinned against the live duplicate-ccl-6 shape). D3 `writeFileAtomic` (tmp+fsync+rename) across index/registry/ledger including the 4th in-place site the grounding table missed (InitScope ledger-head). D4 pure read-through index — the L-2 fix; out-of-band edits honored, deletions never resurrected; corrupt-index mid-serve = typed refusal, no panic, restore heals without restart. D5 boot flock guard (`.aaw/aaw.lock`, INSTANCE_LOCKED, holder id+pid in probe over the real wire).

**Evidence:** Mars build pass + harden pass (test-only delta; REMEDIATE 1/3 — US4-AC2 pinned by an MCP-client probe assertion) + the Director's independent gate re-run this turn: `go build`/`go vet` clean, `go test -race -count=1` 14/14 green (11.2s); earlier: 10× determinism loop, two-process flock ×2, parse-compat golden over both live ledgers, hermetic 17-tool selftest, boundary greps empty, gofmt clean. Every US1–US5 acceptance criterion discharged by a named check.

**Process:** ran at full Flat-L2 first; the Operator recalibrated mid-rung (D-10) — separate harden checklist descoped (Mars's pass crossed the descope and is kept), separate Apollo verify cancelled; the tiered formation rule now lives in `aaw.mcp.roadmap.md` "How the roadmap runs", `mcp1.prompt.md` (as-run record), `mcp2.specs.md` (standard tier).

**Residual, routed forward:** ScopeNames swallows index errors → probe reads ok:true/scopes:[] during corruption (error-vocabulary rung); stale `.tmp` accumulation is inert, unswept (config rung / runbook); writeFileAtomic fsyncs the file not the parent dir — process-crash atomicity full, power-loss durability is an Operator-promotable contract question; the LIVE server still runs the pre-rung binary — the new discipline takes effect at its next restart (the Operator's call; this session never touches the running process). L-5 CLI flags-after-mode no-op stands surfaced, out of boundary.
