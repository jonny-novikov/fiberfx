# aaw MCP server v2 — the design of record

> **D4 synthesis of the `aaw-mcp` Design Phase.** Consolidated by Venus-3, Senior Consolidator
> (CCL-id `ccl-aaw-mcp-5`), from the two independent D1 designs (`venus-1.md`, `venus-2.md`), the
> two D2 cross-reviews, the D3 adjudication (`apollo.evaluation.md`), and the binding decisions
> in the run ledger ([aaw.mcp.progress.md](aaw.mcp.progress.md), D-1…D-9). The donor corpus was
> retired from the tree at `f44f0539` and remains the decision record via git history
> (`git show 9d145486:docs/aaw/mcp/design/<file>`). Base = venus-1's
> protocol spine; fourteen grafts from venus-2 per the evaluation §7.1; every Director pick from
> ledger D-6 applied verbatim. The build specs (the rung triads of
> [aaw.mcp.roadmap.md](aaw.mcp.roadmap.md)) derive from this document. Status: **CANON** —
> ratified by the Operator (ledger D-11, 2026-06-11); amended only through the Operator.

---

## 1 · Context

The v1 aaw server was lost on 2026-06-10 (`apps/aaw/` emptied; no source survived). Two lead-team
runs executed the same day without it under the rules' Formation-availability provision and
produced the requirement set, recorded in [aaw.mcp.proposal.md](aaw.mcp.proposal.md) (R-1…R-10,
Q-1…Q-5, as amended by ledger D-2/D-3). A minimal PoC (`apps/aaw`, version `2.0.0-min`) shipped
2026-06-10 and served this very Design Phase — the first fully-registered AAW formation ran
against it. Live operation produced findings the design resolves: the read-once index
(`emq-design` L-2), the unlocked registry read-modify-write (`apps/aaw/cmd/aaw/main.go:155-184`,
ledger L-1), the `len(r.Agents)+1` CCL mint (`main.go:173`), the continue-on-one-family
dual-stack bind (`main.go:322-330`, fatal only at zero listeners `:338-340`, ledger L-2), and the
Q-4 frozen-liveness false positive. Every cite in this paragraph was re-verified in the tree at
consolidation time.

The server is **the machine for the framework** ([aaw.framework.md](../aaw.framework.md),
[aaw.rules.md](../aaw.rules.md)): an enforcer and recorder of process — never an actor in the
work. It runs no agents, edits no specs or code, makes no commits (proposal §7).

## 2 · The locked decisions (designed around, never re-litigated)

The six locks from the proposal, plus the Operator decisions recorded in the ledger:

1. **The single-file ledger model** (R-2). One `<scope>.progress.md` per scope; channel sections
   tagged `{<scope>-<channel>}`; entries `### <PREFIX>-<n> — <title>`; hand-written entries
   first-class; parse leniently, emit strictly. Live exemplars:
   EchoMQ `echo/apps/echo_mq` → [`../echo_mq/emq.progress.md`](../echo_mq/specs/emq*.md),
   AAW [`aaw.mcp.progress.md`](aaw.mcp.progress.md).
2. **The namespace** is `mcp__aaw__*`; init/spawn/status are `aaw_init` / `aaw_spawn` /
   `aaw_status` (R-9). No legacy v1 name survives; the 17 v1 tool names are preserved verbatim.
3. **The wire contract** is Streamable HTTP at `localhost:8905` — the committed `.mcp.json`
   `aaw` entry is the contract (R-6).
4. **Files are truth** (R-1), including a real fix for the L-2 index finding: out-of-band edits
   to `.aaw/scopes.json` are honored, never resurrected by server memory.
5. **Go on the vendored SDK** `apps/mcp-go` (module `github.com/fiberfx/mcp-go/v2`), which is
   **first-party and free to modify** (ledger D-5): every SDK change is designed and
   ADR-recorded, never an ad-hoc patch; upstream pulls become merges (§12).
6. **Tokenless v2** (ledger D-4, resolving fork F-1): loopback bind + the SDK's built-in
   protections + workspace containment; the `auth.RequireBearerToken` seam in `apps/mcp-go`
   stays documented for a later major, never wired in v2.

Director picks, locked in ledger D-6/D-8 and applied throughout this document:

- **Liveness tool name = `agent_heartbeat`** `(scope, name, note?, quiet_for_minutes?)` — the
  bare attributed touch is the dominant call shape; "lease" misdescribes a touch with no window.
- **Channel read tool name = `channel_poll`** — names the incremental primary use; the history
  read is the degenerate `after_seq: 0` call.
- **Configuration**: no environment layer anywhere; no per-knob policy flag overrides. Identity =
  boot flags; policy = the tree-visible `.aaw/config.json`. **W-3 fix**: the `.gitignore` ignore
  converts from the directory form `.aaw/` to the glob pair `.aaw/*` + `!.aaw/config.json`
  (a bare negation under a directory-form ignore is a git no-op — ledger D-9 precision). The
  edit itself is a named build-rung task, not made by this phase.
- **Transport (C-1)**: stateless as design intent, with **one live harness-dial probe at the
  build gate**; probe failure flips to the stateful configuration — both are zero-loss because
  durability lives in files.
- **F-2**: the `.claude/commands/x.md:123` bootstrap signature gains a `ledger_dir` argument —
  a named build-rung documentation task (the server stays strict; no default directory).
- **§4.3-2 (cross-file coupling)**: the attributed write order is fixed — ledger append, then
  registry counter; the drift detector is the `aaw audit` tally recount (§10).
- **§4.3-3 (retry duplicates)**: a retry after an ambiguous failure may append a duplicate entry
  under the next `n` — accepted and documented as visible, inspectable history.
- **W-1**: V-SOLO-2 stays **evidence-only** (venus-2's self-correction, overriding venus-1's
  review G-4): the proposal's own R-4 narrative records a legitimate degraded run in which only
  the Director wrote ledger entries; an emitter would flag the framework's own past.
- **Policy defaults** (Operator-tunable policy, not architecture): liveness window W = 45 min;
  director-activity threshold K = 3; quiet-window cap = 240 min.

## 3 · The master invariant

> **Files are truth; no loss by construction.** Every durable fact lives in a plain file in the
> repository tree, and the files win: the server holds no state that cannot be rebuilt by
> re-reading them, honors out-of-band edits on the next call, writes every file atomically
> (whole-or-old, never torn), and never rewrites, renumbers, compacts, or deletes recorded
> history. A crash, restart, or disconnect at any instant loses at most the in-flight call —
> never a recorded fact, never a session.

Every architecture decision below either enforces this invariant or is constrained by it.

## 4 · The framework → server map

Carried as a design section per the synthesis (venus-2 §2.1, condensed; the rulings' full
steelmen live in the donor ADRs, cited in §13). "Evidence" = the server records and reports;
"enforcement" = the server refuses; "out" = deliberately out of scope, with reasons on record.

| Framework concept | Server surface | Ruling |
| --- | --- | --- |
| Transparency — plain-text tree artifacts | the file plane (§6 AD-2): index, ledger, registry, messages, audit log — all greppable files; the index made read-through so files win over memory | enforcement |
| Inspection — gates run, not asserted | the gate plane (§6 AD-5): boundary + process gates refuse; formation signals record; `aaw audit` re-verifies the corpus on demand (§10); the four-tier conformance suite (§11) | enforcement + evidence |
| Adaptation — feedback edits the spec | recorded (D-n, L-n, E-n channels) and greppable in the file plane; the editing itself is agent/human work — the server edits no specs | evidence |
| Roles and fences | registry rows carry `role`/`archetype`/`model`; fence enforcement is the harness's (file edits are invisible to the server) | evidence |
| The two-layer model; the four artifacts | out: the server manages neither roadmaps nor triads; the scope ledger is the one server-written instrument | out |
| The six-stage Author/Agent loop | carried by convention over the channels (P-n stage records, D-n gate decisions, Z-n close), not by a server-side state machine | convention |
| The two formations + the Design Phase | one uniform tool surface; the registry's `parent_id` topology records the formation | evidence |
| The delta taxonomy | out of the tool surface: delta tables live beside the claims they grade; summaries land in P-n/D-n; the lenient parser preserves hand-written delta sections | out |
| LAW-1 / FAKE-N | `aaw_spawn` + `agent_register` + the spawn-vs-register tally signal | detection |
| LAW-1a / V-SOLO-3 | out as a sensor (harness tool calls invisible); the registry is the roster audited against | evidence |
| LAW-2 | record-only `model` field on spawn/register rows | evidence |
| LAW-3 | advisory voice lint on ledger bodies — warnings, never refusal, never mutation | advisory |
| LAW-4 | the Z-requires-D refusal + `aaw_status.gates` as the one-call pre-commit check; the commit is the Director's act, outside the server | enforcement |
| V-SOLO-1 | detected: three-source liveness (§6 AD-4) + director-only ledger growth, both clauses required | detection |
| V-SOLO-2 | **evidence-only** (W-1): attribution tallies in the registry; no signal emission | evidence |
| V-SOLO-4 | evidence-only: a system-spec scope with no registered architect is a post-hoc registry read, not a runtime signal | evidence |

## 5 · The trust and evidence model

A fact the PoC never stated and this design must (venus-2 §2.3, adopted): **every agent —
Director and peers — reaches the server over one shared MCP client connection.** Tool calls
carry no transport-level caller identity. Three consequences:

1. **Caller identity is in-band and self-declared.** One optional `actor` parameter on every
   writing tool attributes the call to a registered codename. The liveness and activity evidence
   is exactly as honest as the declarations — the same trust grade as the framework's other
   self-reported artifacts, which is why every liveness-derived signal stays advisory.
2. **The registry is evidence, not proof.** FAKE-N and V-SOLO signals are computed from registry
   and ledger evidence and emitted to `.claude/audit.log`; the REJECT-EXECUTION action belongs to
   the protocol layer and the humans reading the log. The server never blocks a run on a
   liveness inference; the only blocking gates are deterministic (§6 AD-5).
3. **Artifacts outrank timestamps.** Where self-declared liveness and tree evidence disagree, the
   tree wins; the three-source liveness fusion (§6 AD-4) encodes this ordering.

**Terminology fence** (used consistently in every schema and doc): the ledger's tagged sections
are **channel sections**; the `channel_*` family's topics are **message channels**. The two are
never conflated.

## 6 · The architecture, stated as decisions

### AD-1 — One process, one endpoint, stateless sessions (probe-conditional)

One Go binary (`apps/aaw`) serving MCP over Streamable HTTP at `http://localhost:8905/`, built on
`mcp.NewServer` + `mcp.NewStreamableHTTPHandler`. The handler runs **stateless**
(`StreamableHTTPOptions.Stateless`, `apps/mcp-go/mcp/streamable_server.go:281`) with **JSON
responses** (`JSONResponse`, `:289`) and **no session id issued** (empty `GetSessionID`,
`apps/mcp-go/mcp/server.go:138-146`): every request is self-contained, a server restart is
invisible, no session state exists to lose. The C-1 condition rides the build gate: one live
harness-dial probe (real `.mcp.json` client + deferred `ToolSearch` load + one tool round-trip);
probe failure flips to the stateful configuration — zero-loss either way, because durability is
in files. SDK modification is the sanctioned fallback if the probe demands it (D-5). The stdio
transport remains a development convenience, not a contract. Authority: venus-1 ADR-5, conceded
in venus-2's review (a); D-6.

### AD-2 — The file plane: six file kinds, one writer discipline

| File | Location | Mutation discipline |
| --- | --- | --- |
| Workspace index | `<workspace>/.aaw/scopes.json` | **pure read-through** — read on every access under the store lock, no resident cache, no mtime keying; mutations are read-modify-write + atomic rename |
| Instance lock | `<workspace>/.aaw/aaw.lock` | advisory flock held for the process lifetime; second instance refused (`INSTANCE_LOCKED`) |
| Policy config | `<workspace>/.aaw/config.json` | Operator-edited, **never written by the server**; the same pure read-through as the index, so a policy edit applies on the next call |
| Scope ledger | `<ledger_dir>/<scope>.progress.md` | whole-file read-splice-write under the per-scope lock; temp + fsync + rename; append-only at the entry level |
| Scope registry | `<ledger_dir>/<scope>.registry.json` | read-modify-write under the same per-scope lock; temp + fsync + rename |
| Scope messages | `<ledger_dir>/<scope>.messages.jsonl` | `O_APPEND` single-line appends under the per-scope lock |
| Signal log | `.claude/audit.log` (workspace-relative) | `O_APPEND`, deduplicated per (scope, code, evidence window) |

`ledger_dir` is fixed at first `aaw_init` and must resolve under the `-workspace` root with a
separator boundary, symlinks resolved first (the `resolveUnder` discipline). **Legacy
hydration**: existing index rows whose `ledger_dir` sits outside the workspace hydrate
read-only — status reports them with a `CONTAINMENT` warning; writes refuse. A registry holding
a v1 `messages` array migrates it into the jsonl on the first write; `next_ccl` hydrates as
`len(agents)+1` once. Authority: venus-2 ADR-1 (read-through, per apollo row 1), venus-1
ADR-2/4/8, venus-2 ADR-5/11.

### AD-3 — One serialization domain per scope; one instance per workspace

All mutations of a scope's three files serialize through one per-scope writer lock — the R-4
single-writer guarantee, broadened from the PoC's ledger-only mutex to close the unlocked
registry read-modify-write (`main.go:155-184`) and the `len(r.Agents)+1` mint (`:173`); CCL-ids
mint from a persisted monotonic `next_ccl` counter. Distinct scopes never contend. The workspace
index has its own store-level lock; no locks nest except store→scope. A second server process on
the same workspace is excluded by the boot-time flock, holder identity exposed by `probe`.
Authority: venus-1 ADR-2/3/22 ≡ venus-2 ADR-2 (apollo rows 2, 20).

### AD-4 — Identity, attribution, liveness

Registry rows carry identity (`name`, `role`, `archetype`, `ccl_id`, `parent_id`, `model`),
ceremony state (`spawned`/`registered` + timestamps), per-prefix activity counters, and three
liveness sources fused per row:

1. **attributed call** — any writing tool carrying `actor` (or `agent_heartbeat` by `name`)
   touches `last_seen_at`;
2. **declared quiet window** — `agent_heartbeat(quiet_for_minutes)` records `quiet_until`
   (capped at the policy cap; renewable; a peer declares for itself, or the Director declares at
   dispatch — lease-at-dispatch);
3. **deliverable artifact** — the `deliverable` path declared at spawn; its file mtime testifies
   to silent work (files-are-truth applied to liveness).

Effective liveness = the most recent of the three; the status verdict per row is
`active | quiet | silent` **with a `liveness_source` field naming the winning source** — the
artifact source's blind spot (a single write at authoring's end leaves mtime frozen for the
interval) is thereby weighable by the reader, not hidden. Attribution is **registry-side only**:
the entry header stays the locked `### <PREFIX>-<n> — <title>` form; no attribution term enters
the grammar (the §8 EBNF has no production for one, and append-only would make a spoofed claim
permanent). An `actor` naming no registry row proceeds and emits the `UNREGISTERED-ATTRIBUTION`
advisory; no silent row creation. The attributed write order is fixed: ledger append, then
registry counter; the `aaw audit` tally recount detects drift between the two (§10). Authority:
venus-2 ADR-7 + venus-1 ADR-9/10/20/22 as adjudicated (apollo rows 7, 8, 19); D-6.

### AD-5 — The gate plane and the signal contract

Three gate classes, all machine checks:

- **Boundary gates** (refuse): slug form `^[a-z0-9][a-z0-9-]*$` for scopes and message channels;
  scope-not-initialized; `ledger_dir` required at first init / conflict on re-init; parent
  CCL-id must exist (director exempt); recipient registered; path containment; archived-scope
  writes.
- **Process gates** (refuse): `tool_x_complete` refused while the scope ledger holds zero `D-n`
  (`GATE_Z_REQUIRES_D` — the LAW-4 trigger). Edge semantics fixed: **any** `D-<n>` entry in the
  file satisfies the gate, hand-written or tool-written; `Z-n` is repeatable; nothing locks at Z.
- **Formation signals** (record, never refuse): one line per signal appended to
  `.claude/audit.log`, format `<RFC3339> aaw <CODE> scope=<scope> <key>=<value>… msg="<evidence>"`,
  deduplicated per (scope, code, evidence window). The closed signal vocabulary:

| Signal | Evidence | Evaluated at |
| --- | --- | --- |
| `FAKE-N` | registered > spawned tallies | every `agent_register` |
| `V-SOLO-1` | all non-director rows `silent` (AD-4 fusion) **and** ≥K director-attributed ledger entries within window W — both clauses required | `aaw_status`, `tool_x_complete` |
| `UNREGISTERED-ATTRIBUTION` | `actor` names no registry row | any attributed write |
| `CONTAINMENT` | a write touches a legacy out-of-tree scope | the write |
| `INTEGRITY` | corpus lint violation | `aaw audit` (§10) |

V-SOLO-2 is **evidence-only** (W-1); V-SOLO-3/4 are not server-detected — the registry and
attribution tallies are the evidence base the harness, Director, and verifier audit against. A
quiet audit log is not a clean bill for the undetectable classes. Authority: venus-1 ADR-11/27/28
+ venus-2 ADR-9 as adjudicated (apollo rows 17, 26).

### AD-6 — The tool surface: 22 tools, additive-only evolution

The catalog (§7) is the 17 v1 names preserved verbatim (R-9) plus `tool_x_resonance`,
`channel_publish`, `channel_poll`, `channel_list`, and `agent_heartbeat`. Input schemas are
inferred from Go structs (`mcp.AddTool[In, Out]`), deterministic per build; the compatibility
contract is **additive-only evolution**: new fields optional-only; never rename, retype, or
re-require an existing field; tool renames forbidden; a breaking change costs a new tool name.
The tool set is fixed at boot, so deferred-schema clients (`ToolSearch`) stay valid across
restarts and upgrades (R-7). The one v1 output-shape question (the `created` flag) resolves with
no break: `scope_created` + `ledger_created` are added, and `created` is kept as a documented
alias of `scope_created` (its v1 meaning). Authority: venus-1 ADR-6, ADR-21-as-amended (apollo
row 18).

### AD-7 — The error contract

Every domain refusal returns a tool-result error (`IsError: true`) whose text is
`aaw: <CODE>: <detail>` from the closed vocabulary in §9; codes are append-only. Protocol-level
failures (malformed JSON-RPC, unknown tool) remain the SDK's domain. Authority: venus-1 ADR-24.

### AD-8 — Configuration: identity by flags, policy by the tree-visible file, no env

**Boot identity** is flags-only — `-addr` (default `localhost:8905`), `-workspace` (default
`.`), `-log-level`, `-stdio`, `-wire-check` — these locate the workspace and listener before any
file plane exists. **Runtime policy** — liveness window W, director-activity K, quiet cap,
default `ttl_days`, audit dedup window, the lint token list — lives in
`<workspace>/.aaw/config.json`: Operator-edited, never server-written, read through on every
evaluation so an edit applies with no restart. **No environment layer exists; no per-knob policy
flag overrides exist** (D-6: the strictest one-authority composition, the one both architects'
concessions co-sign). Precedence: file > built-in default, reported per knob with its winning
source in `probe.effective_config`. The W-3 `.gitignore` conversion (`.aaw/*` +
`!.aaw/config.json`) makes the policy file committable — a named build-rung task. Authority:
venus-1 ADR-31 as composed by apollo §6-c; D-6; D-9.

### AD-9 — Port and wire contract: all-or-nothing bind, diagnosed refusal, validate-never-generate

For host `localhost` the server binds **both** loopback families or refuses (`PORT_BUSY`) — the
PoC's continue-on-one-family lenience (`main.go:322-330`) is redesigned away, closing the
family-split defect (two instances each holding one family behind one URL). On refusal the
server makes one capped (~500 ms) MCP probe against the occupied port — refusal-path only, never
a pre-bind check — and names the holder (an aaw instance's workspace + version, or a foreign
process with `lsof` guidance). No automatic port hunting: a server that silently moves breaks
its own wire contract. At boot the server validates the workspace `.mcp.json` `aaw` entry
against the bound address. The `-wire-check` flag is three-state, **`strict` by default**:
`strict` refuses to boot on `mismatch` or `unparseable` (printing the fix in both directions);
`warn` proceeds loudly; `skip` opts out, reported as `skipped`. The verdict — `agree | mismatch | absent | unparseable |
skipped` — is reported by `probe` and `aaw_status` (`mismatch` is reachable only under `warn`).
The server **never generates or edits** `.mcp.json`: the wire contract is Operator-committed
input the server serves under. Multi-workspace operation is N explicit (workspace, port,
`.mcp.json`) triples. Authority: venus-1 ADR-32/33 with venus-2's guards and flag shape (apollo
rows 11, 12).

### AD-10 — TTL and archival: lazy, write-refusing, reversible, nothing deleted

Archival is a computed property (`created_at + ttl_days < now`; 0 = never), evaluated lazily at
access — no background janitor. Expired: writes refuse (`ARCHIVED`) with the named remedy, reads
work forever, files never move; `aaw_init` re-opens (stamps `reopened_at`). Authority: venus-1
ADR-23 ≡ venus-2 ADR-20 (apollo row 13 — independently convergent).

### AD-11 — Observability

`slog` to stderr wired into both layers (`ServerOptions.Logger`,
`StreamableHTTPOptions.Logger`); one boot banner per listener plus the wire verdict and the
resolved absolute workspace; `probe` carries `started_at`, the listener addresses, the instance
id, per-scope `reopened_at`, `effective_config` with winning sources, and the wire verdict.
Signals go only to `.claude/audit.log` — one channel, one tail. Authority: venus-2 ADR-21
(apollo graft 8).

### AD-12 — Package layout

```
apps/aaw/
  cmd/aaw/main.go        # flags, tool registration; subcommands: serve · selftest · audit
  internal/config/       # boot flags + .aaw/config.json read-through; effective-config report
  internal/index/        # workspace index (pure read-through) + the flock instance guard
  internal/registry/     # identity / attribution / liveness rows; next_ccl; activity counters
  internal/ledger/       # the R-2 factory: parse / number / splice / tallies (§8)
  internal/channels/     # <scope>.messages.jsonl: publish / poll / list
  internal/gates/        # slug, containment, Z-requires-D, liveness + signal evaluation
  internal/audit/        # .claude/audit.log emitter with dedup
  internal/integrity/    # the corpus lint behind the `aaw audit` subcommand (§10)
```

Packages materialize when their rung needs the seam (the roadmap's refactor rule); the layout is
the end state. Authority: venus-1 ADR-30, extended by the CLI adoption (apollo §7.3).

## 7 · The v2 tool catalog (22 tools)

Conventions: **req** = required; all other parameters optional. "Channel section" names the
ledger section a tool writes (`{<scope>-<channel>} → <PREFIX>-n`); "—" = no ledger write. Error
codes refer to §9. Every writing tool accepts `actor`; a registered `actor` touches
`last_seen_at` and increments that row's activity counters (registry-side only — AD-4).

### 7.1 Registry and lifecycle (7 tools)

**`aaw_init`** — create or idempotently re-open a scope.
Params: `scope` req · `operator` · `workspace` (informational) · `ledger_dir` (**required on
first init**; resolves against and must be contained under the workspace) · `ttl_days`.
Output: `{ok, scope, ledger_path, scope_created, ledger_created, created}` — `scope_created` =
the index row was new; `ledger_created` = the file was absent and a header was written;
`created` is kept as a documented alias of `scope_created` (its v1 meaning — no break). Re-init
never forks a second ledger; a differing `ledger_dir` refuses; a pre-existing hand-written
ledger is never touched; re-init of an archived scope re-opens it.
Errors: `SLUG_INVALID`, `LEDGER_DIR_REQUIRED`, `LEDGER_DIR_CONFLICT`, `PATH_ESCAPE`. Channel: —.

**`aaw_spawn`** — record a spawned agent, mint its CCL-id.
Params: `scope` req · `role` req · `name` req · `archetype` · `parent_id` (omit only for the
director) · `model` (LAW-2 evidence, record-only) · `deliverable` (workspace-relative artifact
path; its mtime is the third liveness source).
Output: `{ok, ccl_id}` — minted `ccl-<scope>-<n>` from the persisted `next_ccl` counter;
re-spawn of an existing name keeps its CCL-id and refreshes `spawned_at` (identity continuity —
the resumed-pass pattern; a fresh identity requires a new name).
Errors: `NOT_INITIALIZED`, `ARG_MISSING`, `PARENT_NOT_FOUND`, `PATH_ESCAPE`, `ARCHIVED`.
Channel: —.

**`agent_register`** — register an identity (LAW-1).
Params: `scope` req · `name` req · `role` req · `ccl_id` · `model`.
Output: `{ok, spawned, registered, fake_n_signal}` — the FAKE-N evaluation (registered > spawned)
runs on every call; a raised signal appends an audit-log line.
Errors: `NOT_INITIALIZED`, `ARG_MISSING`, `ARCHIVED`. Channel: —.

**`agent_heartbeat`** — attributed liveness touch; optionally declare a quiet window.
Params: `scope` req · `name` req · `note` (what the silence covers) · `quiet_for_minutes`
(capped at the policy cap, default 240; renewable by repeat call; the Director may declare for a
peer at dispatch).
Output: `{ok, last_seen_at, quiet_until}`. A live quiet window suppresses the V-SOLO-1 silence
clause for that agent. No ledger write.
Errors: `NOT_INITIALIZED`, `AGENT_UNKNOWN`, `ARG_MISSING`, `ARCHIVED`. Channel: —.

**`agent_send`** — durable point-to-point message record.
Params: `scope` req · `to` req · `body` req · `actor`.
Output: `{ok, seq}` — the message lands in `<scope>.messages.jsonl` with a monotonic per-scope
`seq` (delivery is the harness's job; the server records).
Errors: `NOT_INITIALIZED`, `NOT_REGISTERED`, `ARCHIVED`. Channel: — (the message log is traffic,
not audit narrative).

**`aaw_status`** — the one-call scope report and gate console (Q-1: yes). Read-only.

```text
{ scope, ledger_path, archived, reopened_at,
  ledger_health: {parse_ok, entries, unknown_prefixes: [..], malformed_sections: n},
  agents: [{name, role, archetype, ccl_id, parent_id, model,
            spawned, registered, spawned_at, registered_at,
            last_seen_at, quiet_until, deliverable, deliverable_mtime,
            activity: {<PREFIX>: n, ...},
            liveness: "active" | "quiet" | "silent",
            liveness_source: "call" | "window" | "artifact"}],
  tallies:  {<PREFIX>: n, ...},          // closed prefixes; unknown hand prefixes separate
  gates:    {z_eligible: bool, d_count, z_count},
  messages: {count, last_seq, channels: n},
  signals:  [{code, since, evidence}],   // unexpired only; the log is history
  wire_contract: "agree" | "mismatch" | "absent" | "unparseable" | "skipped" }
```

The Director's pre-commit check (Z-n exists, ≥1 D-n) is the `gates` object — one call, no greps.
V-SOLO-1 evaluation runs here and at `tool_x_complete`. Errors: `NOT_INITIALIZED`.

**`probe`** — health and instance diagnostics. Read-only, no scope required.
Output: `{ok, name, version, started_at, workspace, listeners, instance_id, scopes,
effective_config, wire_contract, at}`. Probing is the x-mode D0 preflight — availability is
point-in-time. Errors: none.

### 7.2 The twelve ledger writers (`tool_x_*`)

All twelve share one parameter shape and one output shape; each writes one entry to its channel
section of `<scope>.progress.md` under the per-scope lock, numbering per §8.

Shared params: `task_id` req (the cardinal rule — use the scope slug) · `slug` req (must equal
an initialized scope) · `body` req (a first line `<PREFIX>-<k> — <title>` lifts the title into
the header; the duplicate line is dropped) · `actor` (registry-side attribution — AD-4).
Shared output: `{ok, entry: "<PREFIX>-<n>", path, warnings: []}` — `warnings` carries the LAW-3
advisory lint (fixed token list + the interior-state-verb family; warn-only, no refusal, no
mutation, no audit line) and gate notes.
Shared errors: `ARG_MISSING`, `SLUG_INVALID`, `NOT_INITIALIZED`, `ARCHIVED`.

| Tool | Channel section → prefix | Extra behavior |
| --- | --- | --- |
| `tool_x_trace` | `{<scope>-thinking}` → T-n | — |
| `tool_x_analyze` | `{<scope>-analysis}` → A-n | `draft` (bool) recorded as a `(draft)` marker — recorder-only, permanently; server-side sampling is foreclosed by the stateless transport |
| `tool_x_alternative` | `{<scope>-alternatives}` → V-n | — |
| `tool_x_decision` | `{<scope>-decisions}` → D-n | — |
| `tool_x_learning` | `{<scope>-learnings}` → L-n | — |
| `tool_x_nxm_synthesize` | `{<scope>-nxm}` → S-n | — |
| `tool_x_consensus` | `{<scope>-consensus}` → C-n | — |
| `tool_x_escalation` | `{<scope>-escalations}` → E-n | — |
| `tool_x_progress` | `{<scope>-progress}` → P-n | — |
| `tool_x_complete` | `{<scope>-complete}` → Z-n | **refused while d_count = 0** (`GATE_Z_REQUIRES_D`); V-SOLO-1 evaluation runs, results land in `warnings` + audit.log |
| `tool_x_report` | `{<scope>-report}` → Y-n | — |
| `tool_x_resonance` | `{<scope>-resonance}` → R-n | extended schema below |

**`tool_x_resonance`** — deterministic echo-chamber measurement over peer artifacts.
Extended params: `artifacts` req (≥2 workspace-relative file paths, containment-gated) ·
`baseline_note` (the caller names shared inputs — same brief, same locks, one corpus) · `score`
(0..1 — the evaluator's recorded judgment, distinct from and beside the measured table).
Computation per unordered pair: k=5 word-shingle Jaccard over normalized text (copy-shaped
convergence) + Jaccard over extracted citation sets (URLs + `path:line` tokens).
Output: `{ok, entry, path, pairs: [{a, b, shingle_jaccard, citation_overlap}], method:
"k5-shingle-jaccard+citation-set", warnings}`. The same table, the method string, the
`baseline_note`, and the standing caveat — **shared-input peers carry a guaranteed similarity
floor; lexical resonance detects copy-shaped convergence and scores low for independent semantic
agreement** — are embedded in the R-n entry body, **required content of every emitted entry,
server-supplied when the caller omits the field**, so a future reader cannot mistake the number
for semantic truth. Thresholds are not enforced; the consumer judges.
Extra errors: `ARTIFACTS_REQUIRED`, `PATH_ESCAPE`.

### 7.3 Message channels (3 tools)

Scope-wide named topics for the formations, durable in `<scope>.messages.jsonl`. MCP tool
servers have no push path; the family is publish + poll. Message-channel traffic is never
mirrored into the ledger (the ledger is curated audit narrative; the log is operational
traffic). Delivery remains the harness's; the log is the durable, replayable record.

**`channel_publish`** — params: `scope` req · `channel` req (slug rule) · `body` req · `actor`.
Output: `{ok, seq}`. Topics are implicit on first publish.
Errors: `NOT_INITIALIZED`, `SLUG_INVALID`, `ARCHIVED`.

**`channel_poll`** — params: `scope` req · `channel` (omit = all) · `after_seq` (default 0 — the
history read) · `limit` (default 100) · `actor` (touches liveness — a polling loop heartbeats as
a side effect). Output: `{ok, entries: [{seq, channel, from, to, body, at}], last_seq}` —
`agent_send` records share the log, distinguished by `to` vs `channel`. Cursors are stable
forever (append-only log). Read-only; an empty log is not an error.
Errors: `NOT_INITIALIZED`.

**`channel_list`** — params: `scope` req. Output:
`{ok, channels: [{name, count, last_seq, last_at}]}`. Read-only. Errors: `NOT_INITIALIZED`.

## 8 · The ledger factory — formal semantics

**Grammar (EBNF; parse-lenient, emit-strict):**

```ebnf
ledger    = [preamble], {section} ;
preamble  = {line} ;                        (* bytes before the first section heading; preserved verbatim *)
section   = sec_head, {entry | prose_line} ;
sec_head  = ("#" | "##"), " ", tag, [" ", title], NL ;          (* emit: "##" only *)
tag       = "{", scope, "-", channel, "}" ;
entry     = ent_head, NL, blank, body ;
ent_head  = ("##" | "###"), " ", prefix, "-", nat, [" — ", title], NL ;   (* emit: "###" only *)
prefix    = "T"|"A"|"V"|"D"|"L"|"S"|"C"|"E"|"P"|"Z"|"Y"|"R" ;   (* the closed v2 set *)
```

Canonical greps: sections `^#{1,2} \{<scope>-`, entries `^### [A-Z]+-[0-9]+\b` (parse accepts
`^#{2,3}`). The entry header carries **no attribution term** — attribution is registry-side
(AD-4).

**Numbering.** `next(prefix) = 1 + max{n : "<prefix>-<n>" appears as an entry head anywhere in
the file}` — the domain is the whole file, so hand-written entries are first-class and never
collided with. The prefix vocabulary is **reserved**: a hand heading matching
`^#{2,3} [A-Z]+-[0-9]+` is an entry by definition; unknown prefixes (a hand `### ADR-3`) are
tolerated, reported separately by `aaw_status`, and never gate.

**Emission.** A missing channel section is created at EOF on first write; an existing section
receives the entry at its end, before the next non-entry heading, with all bytes outside the
splice preserved verbatim — **the preservation invariant**: every previously-existing entry's
bytes survive any append. Entries are append-only: no tool rewrites, renumbers, or deletes a
prior entry, ever.

**Concurrency.** One writer per scope (AD-3): read whole file → compute `n` → splice → write
`<file>.tmp` → fsync → rename. A torn ledger is impossible; lost updates are impossible;
distinct scopes proceed in parallel; a second process is excluded by the flock. Tool-vs-human
concurrent edits remain last-writer-wins at file granularity — accepted and documented (short
writes, md-first discipline). **Retry duplicates accepted** (D-6 / §4.3-3): a client retry after
an ambiguous failure may append a duplicate entry under the next `n` — visible, inspectable
history; never auto-deduplicated.

## 9 · The closed error vocabulary

`aaw: <CODE>: <detail>` in an `IsError` tool result (AD-7); codes append-only:

| Code | Raised by | Meaning |
| --- | --- | --- |
| `SLUG_INVALID` | init, ledger writers, channel_publish | scope/message-channel violates `^[a-z0-9][a-z0-9-]*$` |
| `NOT_INITIALIZED` | every scope-bound tool | scope unknown — call `aaw_init` first |
| `LEDGER_DIR_REQUIRED` | aaw_init | first init without `ledger_dir` |
| `LEDGER_DIR_CONFLICT` | aaw_init | re-init names a different `ledger_dir` |
| `PATH_ESCAPE` | aaw_init, aaw_spawn, tool_x_resonance | a path resolves outside the workspace root |
| `PARENT_NOT_FOUND` | aaw_spawn | `parent_id` matches no registry row |
| `AGENT_UNKNOWN` | agent_heartbeat | named agent has no registry row |
| `NOT_REGISTERED` | agent_send | recipient absent or never registered |
| `GATE_Z_REQUIRES_D` | tool_x_complete | zero D-n in the ledger (the LAW-4 trigger) |
| `ARCHIVED` | every writing tool | scope past TTL and not re-opened |
| `ARG_MISSING` | several | a required parameter is empty (incl. the cardinal task_id + slug rule) |
| `ARTIFACTS_REQUIRED` | tool_x_resonance | fewer than two artifact paths |
| `CORRUPT_STATE` | any | an index/registry file failed to parse — refuse rather than overwrite |
| `INSTANCE_LOCKED` | boot, not a tool error | a second instance attempted the same workspace |
| `PORT_BUSY` | boot, not a tool error | a loopback family could not be bound; the refusal names the holder when the port answers as an aaw instance |
| `WIRE_MISMATCH` | boot, not a tool error | `.mcp.json` disagrees with the bound address under `-wire-check strict` |

## 10 · The `aaw audit` CLI subcommand

The zero-MCP-tool home of the corpus integrity duties (apollo §7.3, adopted): a read-only CLI
face (`aaw audit [scope...]`) that re-derives the server's entire recorded state from disk and
reports divergences —

- **the L-2 regression check**: an out-of-band index edit followed by `aaw audit` must report
  the truth on disk;
- **corpus lint**: per scope — index↔file existence (`present | orphan-file | missing-file`),
  ledger parse health against the §8 grammar, duplicate entry ids, per-prefix numbering gaps,
  malformed section tags, registry parse + FAKE-N state, containment violations;
- **the cross-file drift recount** (D-6 / §4.3-2): per-prefix ledger tallies recounted against
  the registry's attributed activity counters — the named detector for a crash between the
  ledger append and the counter update.

Violations emit `INTEGRITY` audit-log lines. No fix mode exists: rewriting history files would
forge the record; findings are for a human. The L-2 regression assertion also lands in the
conformance suite (tier 2), so the check runs even when no one runs the CLI. `aaw_status`
carries the per-scope `ledger_health` summary in-band (§7.1).

## 11 · Conformance — four tiers, the server inspected by its own standard

1. **Unit/property over the ledger engine** — numbering, title-lift, section insertion, the
   preservation invariant, the Z-gate; table-driven plus a fuzz pass on the splice.
2. **Golden parse-compat over the committed exemplars** — copies of both hand-written ledgers
   under `apps/aaw/internal/ledger/testdata/`, refreshed deliberately; parse, append, assert
   numbering continuation and byte-preservation of every prior entry (the §8 gate, promoted
   from a live one-off to a committed test).
3. **In-process protocol round-trips** — `mcp.NewInMemoryTransports` connects a real client to
   the real server with no TCP; every tool exercised; every gate refused at least once with its
   exact §9 code asserted.
4. **`aaw selftest` over real HTTP** — kept from the PoC, extended to the 22-tool count pin and
   exact-code assertions, run against a **hermetic temp workspace** (not a temp ledger_dir
   inside the real one, which containment now refuses), plus a golden `tools/list` schema
   snapshot guarding additive-only evolution.

The build rung's verifier owes the anti-rubber-stamp charter over this suite: a mutation
kill-rate, not a pass/fail. Authority: venus-2 ADR-22 with venus-1's exemplar gate and
exact-code selftest slotted in (apollo row 21, graft 5).

## 12 · The SDK-modification policy (D-5)

`apps/mcp-go` is a first-party fork, free to modify for aaw needs. The policy:

- every SDK change is **designed and ADR-recorded** before it lands — never an ad-hoc patch;
- a build rung that touches the SDK names `apps/mcp-go` in its diff boundary (pathspec and
  review scope extend accordingly — the roadmap's per-rung boundaries name the extension);
- SDK changes carry the same no-invent/cite discipline as server code;
- any "the SDK forces X" claim is a default, not a constraint: stock configuration is preferred
  first, modification is the sanctioned fallback (the AD-1 probe is the worked example);
- upstream pulls become merges — the lineage fork is accepted by the lock.

The standing note for future build agents is already in place at the fork's root
(`apps/mcp-go/AGENTS.md`, top note — verified in the tree at consolidation time).

## 13 · The decision record (one authority per decision, cited by pointer)

Each architecture decision above is owned by exactly one donor ADR (context → ≥2 steelmanned
alternatives including a do-nothing/keep-PoC baseline → decision → consequences), as adjudicated
by the evaluation. The bodies are not copied here — the donors are the authority.

| Decision | Authority (by pointer) |
| --- | --- |
| Stateless transport + JSONResponse + no session id, probe-conditional | venus-1 ADR-5; conceded in venus-2's review (a); apollo row 5; D-6 |
| Pure read-through index (and policy file) — the L-2 fix | venus-2 ADR-1; venus-1's G-1 concession; apollo row 1 |
| Per-scope serialization domain + persisted `next_ccl` | venus-1 ADR-3/22 ≡ venus-2 ADR-2; apollo rows 2/19 |
| Atomic temp+fsync+rename; O_APPEND for line-logs | venus-1 ADR-4 ≡ venus-2 ADR-3; apollo row 3 |
| Flock single-instance guard | venus-1 ADR-2; apollo row 20 (the gap venus-2's own review filled) |
| Ledger grammar: EBNF + whole-file numbering + preservation invariant + goldens | venus-1 ADR-25/§3.13 + venus-2 ADR-4; apollo row 4 |
| Attribution: one `actor` param, registry-side only, advisory codes | venus-2 ADR-7; venus-1 ADR-9 as amended by venus-2's §2.2 challenge; apollo row 8 |
| Liveness: three-source fusion + `agent_heartbeat` + winning source | venus-1 ADR-10 + venus-2 ADR-8; apollo row 7; name per D-6(a) |
| Signals: advisory-only, dedup line format, honest sensory horizon | venus-1 ADR-11/27 ≡ venus-2 ADR-9/§2.3; apollo row 17; W-1 per D-6 |
| `aaw_status` gate console (Q-1 = yes) + parse-health fields | venus-1 ADR-12 ≡ venus-2 ADR-10; apollo rows 27/13-graft |
| Per-scope registry beside the ledger (Q-2); messages → jsonl | venus-1 ADR-13/14 ≡ venus-2 ADR-11; apollo row 16 |
| Message channels: publish + poll(seq cursor) + list; no push | venus-1 ADR-15; venus-2's review (e) concession; apollo row 9; name per D-6(b) |
| Resonance: deterministic measurement + `baseline_note` + judgment slot | venus-1 ADR-18 + venus-2 §2.5/C-5 merge; apollo row 10 |
| LAW-3 advisory lint (warn, never refuse) | venus-1 ADR-19; venus-2's G15 concession; apollo row 24 |
| LAW-2 `model` field (record-only) | venus-1 ADR-20; apollo row 25 |
| `created` alias + `ledger_created` (no break) | venus-1 ADR-21 as amended (G-8 ≡ venus-2 §2.3); apollo row 18 |
| TTL/archival: lazy, reversible, nothing deleted | venus-1 ADR-23 ≡ venus-2 ADR-20; apollo row 13 |
| Closed error vocabulary | venus-1 ADR-24; apollo row 22 |
| Out-of-scope set (stage machine, delta taxonomy, artifact mgmt, fences) | venus-1 ADR-26/27 ≡ venus-2 ADR-15/16/17; apollo row 28 |
| Z-gate edge semantics (any D counts; Z repeatable) | venus-1 ADR-28; apollo row 26 |
| `draft` recorder-only | venus-1 ADR-29; apollo row 23 |
| Config: identity flags / policy file, no env, no per-knob overrides | venus-1 ADR-31 as composed by apollo §6-c; D-6(c); W-3 per D-9 |
| Ports: all-or-nothing bind + diagnosed `PORT_BUSY` | venus-1 ADR-32 + venus-2 ADR-24 guards; apollo rows 11/14 |
| Wire contract: validate, strict default, three-state flag, never generate | venus-1 ADR-33 + venus-2 ADR-25 flag shape + `unparseable`; apollo row 12 |
| Tokenless v2; `RequireBearerToken` seam named | venus-1 ADR-7 ≡ venus-2 ADR-19; apollo row 15 + §5; **Operator D-4** |
| Conformance: four tiers + exemplar gate + hermetic workspace | venus-2 ADR-22 + venus-1 §3.13/exact-codes; apollo row 21 |
| `aaw audit` CLI | venus-2 §2.0/ADR-14-CLI-face; apollo §7.3; D-6 |
| SDK free to modify | **Operator D-5** |
| Ship-set amendment | **Operator D-3** ([aaw.mcp.progress.md](aaw.mcp.progress.md)) — the catalog in §7 is complete as enumerated |
| Framework map + trust model as design sections | venus-2 §2.1/§2.3; venus-1's G-11 adoption; apollo graft 1 |

## 14 · Consequences — what this design forecloses

- **No server push, ever, on this transport.** Stateless + tools-only forecloses server→client
  requests: no push subscriptions, no server-side sampling, no streamed progress. Every future
  interaction is request-shaped. (Flipping to stateful at the AD-1 probe restores none of these
  by itself; they would each be new design.)
- **One server instance per workspace; the workspace is the world.** Multi-process HA is out;
  no ledger, deliverable, or resonance artifact outside `-workspace`; multi-repo programs split
  into per-workspace instances with their own ports and contracts.
- **Deterministic-only intelligence.** Resonance is lexical/citation; the voice lint is a token
  list. Semantic judgment stays with agents and humans — the server never becomes an oracle
  whose verdicts cannot be reproduced from the files.
- **Append-only history.** No tool or CLI rewrites, renumbers, compacts, deletes, or "fixes"
  ledger entries, messages, or audit lines. Corruption repair is a human act on files, visible
  in git.
- **Names are forever.** Tool names and error codes only grow; schema evolution is
  additive-only; a breaking change costs a new name by design.
- **Client configuration is never generated.** `.mcp.json` stays Operator-owned and read-only
  to the server; configuration consults flags and the workspace policy file only — no
  environment layer exists to drift.
- **Undetectable violations stay undetected by the server.** V-SOLO-2/3/4 enforcement remains
  with the harness, Director, and verifier; the audit log will never carry them, and a quiet
  log must not be read as their absence.
- **The PoC's wire-visible surface survives.** 17 tool names preserved, shapes additively
  extended, `created` kept by alias — the running formation's runbooks survive the upgrade.

## 15 · Sources and map

Full line-level sourcing lives in the donor designs and is not duplicated here (one authority):
`venus-1.md` §8 and `venus-2.md` §5 carry the verified PoC, SDK, and protocol cites;
`apollo.evaluation.md` §8 carries the independent re-verification log — all three retired from
the tree at `f44f0539`, readable via `git show 9d145486:docs/aaw/mcp/design/<file>`. Verified afresh for this consolidation: the unlocked registry
RMW (`apps/aaw/cmd/aaw/main.go:155-184`), the `len(r.Agents)+1` mint (`:173`), the per-family
bind `continue` + zero-listener fatal (`:322-330`, `:338-340`), the SDK `Stateless` / 
`JSONResponse` / empty-`GetSessionID` surfaces (`apps/mcp-go/mcp/streamable_server.go:281,289`,
`apps/mcp-go/mcp/server.go:138-146`), the `.mcp.json` `aaw` entry, the `.gitignore` directory-form
`.aaw/` ignore, and the exemplar ledger's numbering state (next T-2 / D-5 / P-3 / L-3; the
`#`-level section heading at `:83`).

- Requirements: [aaw.mcp.proposal.md](aaw.mcp.proposal.md) (R-1…R-10, Q-1…Q-5, as amended).
- Normative: [aaw.framework.md](../aaw.framework.md) · [aaw.rules.md](../aaw.rules.md) ·
  `.claude/commands/x.md`.
- The run ledger (binding decisions D-1…D-9, findings L-1/L-2, consensus C-1):
  [aaw.mcp.progress.md](aaw.mcp.progress.md).
- The delivery plan this design ships through: [aaw.mcp.roadmap.md](aaw.mcp.roadmap.md).
- The spec-system contract the build triads follow:
  [specs.approach.md](../../elixir/specs/specs.approach.md).
- MCP Streamable HTTP transport:
  <https://modelcontextprotocol.io/specification/2025-06-18/basic/transports>.

---

*Venus-3 · `ccl-aaw-mcp-5` · stage D4 · framing per LAW-3.1, propagated: any spec, brief, or
prompt derived from this design carries the same rules — no gendered pronouns for agents, no
perceptual or interior-state verbs applied to software or agents, no first-person narration,
none of the banned-voice words.*
