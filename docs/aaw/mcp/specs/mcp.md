# MCP · the aaw MCP server v2 — the build ladder

> The chapter index of the v2 build: the **file-backed process engine for the AAW framework**, shipping the
> approved design ([`../aaw.mcp.design.md`](../aaw.mcp.design.md)) as **eight thin rungs** over the as-built
> PoC (`apps/aaw`, `2.0.0-min`) — the single-file scope ledger factory, the team registry with three-source
> liveness, the machine gates, the formation signals, message channels, deterministic resonance, the
> `aaw audit` integrity CLI, and the 22-tool surface, with the 17 v1 tool names preserved verbatim and every
> evolution additive. The design defines; the roadmap ([`../aaw.mcp.roadmap.md`](../aaw.mcp.roadmap.md))
> plans; the rung triads under this directory prove, each following
> [the specs approach](../../../elixir/specs/specs.approach.md). Status: mcp1 **shipped** (`7972859f`,
> settled tier — D-10), mcp2 **shipped** (`f44f0539` · `514d4768`), mcp3 **shipped** (`750bda97`,
> standard tier — close P-9), mcp4 **build-grade** (D-18), mcp5 **specced** (the Reconcile tool —
> D-14/D-16; the displaced transport posture + C-1 probe ride mcp8), mcp6 **specced** (interactive aaw —
> the Bubble Tea console; the displaced message channels ride mcp7; mcp6 stays the measurement rung —
> D-17), mcp7–mcp8 **planned**.

This index is the map. Each rung carries its three artifacts — the spec (`mcpN.md`), the user stories
(`mcpN.stories.md`), and the agent brief (`mcpN.llms.md`) — derived from the design and reconciled against
the as-built tree before build; mcp1 additionally carries an as-run runbook (`mcp1.prompt.md`).

## Where the ladder starts and ends

**Start (the live PoC).** `apps/aaw` (`2.0.0-min`) serves the live formation today: 17 tools, a working
ledger factory, and the recorded defect classes the v2 design resolves — the unlocked registry
read-modify-write, the read-once index (L-2), the partial-bind family split, the frozen-liveness false
positive, and the live CCL re-mint (L-3). The approved design is the contract; every rung derives from it.

**End (after mcp8).** The v2 server live on `localhost:8905`, every design AD realized, the four-tier
conformance suite green, the 22-tool selftest pinned over a hermetic workspace, and the live formation
re-registered against it — with no v1 tool name or shape broken (additive evolution throughout).

## The master invariant

> **Files are truth; no loss by construction.** Every rung leaves every durable fact in a plain file, every
> write atomic (whole-or-old), history append-only, and the server rebuildable from the tree at any
> instant. No rung introduces server state that cannot be re-derived by re-reading the files, and no rung
> breaks a v1 tool name or shape (additive-only evolution).

This is the roadmap's restatement of the design §3 invariant, and it holds at every rung, no exceptions.

## The closed error vocabulary

The chapter's refusal surface is one closed, append-only set — the design §9 sixteen codes, named verbatim:

`SLUG_INVALID` · `NOT_INITIALIZED` · `LEDGER_DIR_REQUIRED` · `LEDGER_DIR_CONFLICT` · `PATH_ESCAPE` ·
`PARENT_NOT_FOUND` · `AGENT_UNKNOWN` · `NOT_REGISTERED` · `GATE_Z_REQUIRES_D` · `ARCHIVED` ·
`ARG_MISSING` · `ARTIFACTS_REQUIRED` · `CORRUPT_STATE` · `INSTANCE_LOCKED` · `PORT_BUSY` · `WIRE_MISMATCH`

Every domain refusal renders `aaw: <CODE>: <detail>` in an `IsError` tool result (design AD-7);
protocol-level failures (malformed JSON-RPC, unknown tool) stay the SDK's. The set is the chapter's closed
error vocabulary: **no rung adds a code silently** — a new code is a named, append-only addition in the
rung's spec, and no code is ever renamed, retyped, or removed. mcp3 implements the vocabulary as the single
home; `INSTANCE_LOCKED` ships at mcp1 (a boot refusal), `PORT_BUSY` and `WIRE_MISMATCH` are emitted by
mcp4's boot, and `ARTIFACTS_REQUIRED` by mcp7's resonance tool.

## The value ladder

| Rung | Feature | Value it adds | Design grounding | Status |
| --- | --- | --- | --- | --- |
| **mcp1** | [The single-writer store discipline](mcp1.md) | the per-scope serialization domain over ledger + registry + messages, the persisted `next_ccl` mint with re-spawn identity continuity, atomic temp+fsync+rename for every whole-file write, the pure read-through index (the L-2 fix), and the boot flock single-instance guard — the correctness foundation every later rung writes through, with the committed exemplar-ledger goldens as the standing regression floor | AD-2 · AD-3 | **shipped — 7972859f** |
| **mcp2** | [Attribution, liveness & the status gate console](mcp2.md) | the opt-in `actor` parameter recorded registry-side only, `agent_heartbeat` plus the three-source liveness fusion that never false-positives a long-authoring peer, `aaw_status` grown into the one-call gate console (`gates.z_eligible`), and the advisory FAKE-N / two-clause V-SOLO-1 signal emission to `.claude/audit.log` (+1 tool, 18) | AD-4 · AD-5 | **shipped — f44f0539 · 514d4768** |
| **mcp3** | [The error vocabulary + the ledger-grammar formalization](mcp3.md) | every domain refusal a named code from the closed sixteen-code set rendered `aaw: <CODE>: <detail>`, the `created` → `scope_created` + `ledger_created` alias resolution, the §8 EBNF as the implemented single grammar authority (lenient parse, strict emit, the reserved prefix vocabulary, unknown-prefix reporting in parse-health), and exact-code verification in the selftest plus a new in-process tier | AD-6 · AD-7 · §8 · §9 | **shipped — 750bda97** |
| **mcp4** | [Config, ports & the wire contract](mcp4.md) | identity flags plus the `.aaw/config.json` policy read-through (no environment layer, no per-knob flags), the all-or-nothing dual-stack bind with diagnosed `PORT_BUSY`, the three-state `-wire-check` (strict default) with the computed `wire_contract` verdict the mcp2 console deliberately omitted, the `model` deferral closed, the boot banner, and the W-3 `.gitignore` + F-2 doc edits as named tasks | AD-8 · AD-9 · AD-11 | **build-grade — D-18** |
| **mcp5** | [The Reconcile tool](mcp5.md) | the `aaw reconcile` CLI subcommand (zero MCP-tool change — the §10 `aaw audit` pattern, the D-3 tool-fatigue precedent): the documented claim grammar (`file:line` cites, relative links, backticked workspace paths), the read-only tree probe, the MATCH / STALE / MISSING delta table with tallies and the embedded limit line, `-json`, gate-able exit codes, flags-first invocation (L-5), workspace containment — the pre-build reconcile stage, mechanized | §10 · AD-12 | **specced** |
| **mcp6** | [Interactive aaw — the Bubble Tea console](mcp6.md) | `aaw tui`, the interactive READ-ONLY terminal console (zero MCP-tool change — the third §10 CLI application): the master invariant made visible — the server is rebuildable from the tree at any instant, so a `tea.Tick` mtime-guarded re-read of the file plane renders the whole formation live without touching the server — the scope list + the scope detail (liveness table · gates panel · live-follow ledger tail · parse-health line), lock-free reads that never block a writer, the charm trio (bubbletea · bubbles · lipgloss) as the ladder's first named UI-dependency seam, the `tui` mode word flags-first — the D-17 coordination rendered as it happens | §3 · §10 · AD-12 · D-17 | **specced** |
| **mcp7** | Message channels, resonance, archival & the `aaw audit` CLI | the `<scope>.messages.jsonl` split with v1 `messages`-array migration, `channel_publish` / `channel_poll` / `channel_list` (21 tools), seq cursors stable forever, polling that touches liveness, then `tool_x_resonance` completing the 22-tool surface (deterministic shingle + citation Jaccard with the standing baseline caveat), lazy reversible TTL archival, and the `aaw audit` corpus-integrity CLI with the §4.3-2 tally recount — the 18 → 22 jump in one rung (absorbing the channels mcp6's promotion displaced) | AD-2 · §7.3 · §7.2 · AD-10 · §10 | **planned** |
| **mcp8** | The transport posture, conformance closure + live cutover | the stateless posture (Stateless + JSONResponse + no session id) settled by the C-1 probe — one live harness dial whose restart-invisibility transcript is the cutover demo (probe failure flips to stateful, zero-loss either way; absorbed from the displaced transport rung per D-14); the four-tier suite complete, the 22-tool selftest pinned over a hermetic workspace, the golden `tools/list` schema snapshot (the additive-only tripwire), and the live cutover with the in-flight scope ledgers continuing their numbering | AD-1 · §11 | **planned** |

The rungs depend only downward: mcp1 is the substrate every later rung writes through (its committed
goldens are the regression floor every rung runs against); mcp2 stands on mcp1's locks and fixes the
attributed write order whose recount detector mcp7 ships; mcp3 hardens the contract surfaces (codes,
grammar) the evidence rungs report through; mcp4 fixes the boot surface whose C-1 probe rides mcp8's
cutover; mcp5's reconcile instrument guards every later rung's pre-build sharpen (in code it depends only
on the tree); mcp6 renders the file plane mcp1's discipline keeps whole (read-only, lock-free — a torn
read is impossible); mcp7 absorbs the message channels (polling touches liveness — mcp2) and completes
the 22-tool surface; mcp8 settles the transport posture and proves all of it at cutover. The milestones
group them: **M1 · The floor** (mcp1–mcp2), **M2 · The contract** (mcp3–mcp5), **M3 · The 22-tool
surface** (mcp6–mcp7), **M4 · The proof** (mcp8). mcp7–mcp8 are roadmap rows only — their triads are
authored when each rung approaches build.

## How to read a rung

Read the spec (`mcpN.md`) first — Goal, Rationale (5W), Scope, Deliverables, Invariants, Definition of Done
— and its footer, which points at the rest of the triad and this index. Then the user stories
(`mcpN.stories.md`) for the acceptance criteria and the Coverage closure. Then the agent brief
(`mcpN.llms.md`) when ready to implement: its references, traced requirements, execution topology (runtime
shape + task DAG + touched files), agent stories, and the comprehensive prompt an agent runs to build and
self-check the increment. mcp1 additionally carries [`mcp1.prompt.md`](mcp1.prompt.md) — the as-run build
runbook (the persistent design pack the settled-tier build executed from).

## Conventions

- **Build formations are tiered** (the roadmap's "How the roadmap runs", D-10 — ceremony scales with risk,
  never the reverse): **settled** (one implementor pass carrying the full gate + the Director's independent
  gate re-run — mcp1's tier), **standard** (build + one second context, harden OR verify — mcp2's tier),
  **full** (the complete lead-team pipeline, for an open Operator fork or a system-spec deliverable). The
  ceremony minimum (D-11) holds at every tier: at least one executable gate per rung, and one ledger close
  entry.
- **Grounding.** Every cited surface is verified in the tree at authoring time; future surfaces are written
  forward-looking ("mcpN builds …"), never asserted present; the closed error vocabulary is used verbatim,
  codes append-only.
- **Story audiences (from mcp4 on).** Each rung's user stories are split by audience — `MCPn-US-D[N]` the
  developer (the human who boots, configures, audits, and commits) and `MCPn-US-A[N]` the agent (the
  session peers who dial the tools and run the instruments); mcp1–mcp3 keep their as-shipped `US[N]`
  numbering — history is not rewritten.
- **Commit rules.** One LAW-4 pathspec commit per rung, made by the Operator/Director at rung close; never
  `git add -A`; the diff stays inside the rung's named boundary; agents never run git.
- **Voice.** Plain, specific, impersonal: no first person, no exclamation, none of the banned hype tokens
  (revolutionary, blazing fast, magical, simply, just, obviously, effortless), and no perceptual or
  interior-state verb applied to software or agents — propagated into every derived spec, story, and brief
  (LAW-3.1).

## Map

- The design of record (the authority every rung derives from): [`../aaw.mcp.design.md`](../aaw.mcp.design.md).
- The delivery roadmap (binding for rung composition): [`../aaw.mcp.roadmap.md`](../aaw.mcp.roadmap.md).
- The requirements source: `aaw.mcp.proposal.md` — retired from the tree post-canon (the
  pragmatic-delivery cleanup); it remains the requirements record via git history
  (`git show 74d8a899:docs/aaw/mcp/aaw.mcp.proposal.md`); the design §15 carries its R-/Q-ids.
- The run ledger (binding decisions, findings, the as-executed record): [`../aaw.mcp.progress.md`](../aaw.mcp.progress.md).
- The implementation dashboard (per-rung stage + the ladder rollup): [`mcp.progress.md`](mcp.progress.md).
- The normative framework the server enforces and records for: [`../../aaw.framework.md`](../../aaw.framework.md).
- The spec-system contract the triads follow: [`../../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md).
- The root-index exemplar this file follows: [`../../../echo_mq/echo_mq.md`](../../../echo_mq/echo_mq.md).

---

> Part of the AAW program. Files are truth; the index maps, the roadmap plans, the design defines, the
> triads prove.
