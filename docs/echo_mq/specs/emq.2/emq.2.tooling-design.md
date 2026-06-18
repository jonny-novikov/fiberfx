# emq-2 — the agent-tooling design (Venus-2)

> **What this is.** The build spec the Director writes the real `.claude` files FROM. It DESIGNS three
> echo_mq dev skills (`.claude/skills/<name>/SKILL.md`) and the additive tuning of the three build-team
> charters (`.claude/agents/{venus,mars,apollo}.md`). Venus-2 designs; **the Director writes** the skill
> and charter files — Venus-2 creates no `.claude` file and edits no charter here. Grounded in the locked
> decisions D-1..D-8 (`emq-2.progress.md`), the emq canon (`emq.design.md`, `emq.roadmap.md`,
> `echo_mq.md`), the `.claude/skills/<name>/SKILL.md` convention (x-mode + bcs-course-writer), the three
> charters as-built, and the craft the emq.1 build already earned (`emq-1.progress.md`).
>
> **Framing (propagated into every block this file emits).** Third person for any agent reference; no
> gendered pronouns for agents; no perceptual/interior-state verbs for agents or software — components
> read, compute, refuse, return.

---

## 0 · The shape, in one screen

The build team (Venus / Mars / Apollo) must become **echo_mq-specialized + roadmap-aware** without losing
its cross-program service (portal / mercury / redis / elixir). The mechanism (D-5):

- **THREE per-role dev skills** (D-7) — `echo-mq-architect`, `echo-mq-implementor`, `echo-mq-evaluator` —
  each a focused role-craft manual loaded only when the role is on an `emq.*` rung.
- **ONE shared references file** (D-7) — `.claude/skills/echo-mq-program.md` — the common program law
  (the v2 laws, the gate ladder, the roadmap awareness, the NO-INVENT grounding map, the process locks).
  All three SKILL.md files link it by relative path, so the common law is single-source.
- **ONE additive charter block per role** (D-8) — a `## echo_mq program` section added to each of
  `venus.md` / `mars.md` / `apollo.md`, **additive diff only** — every existing cross-program line preserved.

The recommendation, stated once and argued in §5: **three role skills (not one shared skill)** and
**additive charter blocks (not dedicated `*-echomq` charter variants)**.

```
.claude/
  skills/
    echo-mq-program.md            ← NEW · the shared program-law reference (one file)
    echo-mq-architect/SKILL.md    ← NEW · venus loads on an emq.* rung
    echo-mq-implementor/SKILL.md  ← NEW · mars loads on an emq.* rung
    echo-mq-evaluator/SKILL.md    ← NEW · apollo loads on an emq.* rung
  agents/
    venus.md   ← EDIT · + "## echo_mq program" block (additive)
    mars.md    ← EDIT · + "## echo_mq program" block (additive)
    apollo.md  ← EDIT · + "## echo_mq program" block (additive)
```

> **A convention note for the Director.** The existing skills are dir-form (`<name>/SKILL.md` +
> optional `references/`). The shared `echo-mq-program.md` is designed as a **flat sibling file** under
> `.claude/skills/` (not a `references/` subdir of any one skill) precisely because all three skills share
> it — a `references/` subdir belongs to one skill. If the Director prefers each skill to be wholly
> self-contained, the alternative is to copy the shared file into each `<name>/references/echo-mq-program.md`;
> the single-file form is recommended (single-source — a v2-law correction lands once). Either way the
> SKILL.md links resolve by relative path.

---

## 1 · The shared program-law reference — `.claude/skills/echo-mq-program.md`

This is the common law all three skills cite. Content the Director writes verbatim (tighten freely; the
facts are load-bearing and grounded):

````markdown
# echo_mq — the program law (shared reference)

The common law every echo_mq dev skill cites. The role-specific craft lives in the three skills
(`echo-mq-architect`, `echo-mq-implementor`, `echo-mq-evaluator`); this file is the program-wide floor
all three stand on. Read it once per `emq.*` rung; the role skill points back here.

**Framing.** Third person for any agent reference; no gendered pronouns for agents; no perceptual or
interior-state verbs for agents or software — components read, compute, refuse, return.

## The canon (read-first, NO-INVENT)
- **The design canon** — [`docs/echo_mq/emq.design.md`](../../docs/echo_mq/emq.design.md): Operator-approved,
  reconcile-only, never redesigned. The S-1..S-7 locks; the ADRs (§2 branded-id, §3 fence merge, §5
  wire-class registry); the grammar restated total for braces (§6); the seams (§10); the founding
  decisions (§11); the engine-feature ADRs on Valkey 8+ (§12).
- **The engineering roadmap** — [`docs/echo_mq/emq.roadmap.md`](../../docs/echo_mq/emq.roadmap.md): the
  three movements, the rung ladder emq.0–emq.8, the master invariant, seams 1–9.
- **The program front door** — [`docs/echo_mq/echo_mq.md`](../../docs/echo_mq/echo_mq.md): the milestone
  layer (M0/M1/M2) binding each Movement to a consumer ship.
- **The bibliography** — [`docs/echo_mq/emq.references.md`](../../docs/echo_mq/emq.references.md).

## The v2 laws (the protocol's load-bearing properties — S-1..S-7)
A surface a rung builds must satisfy every one; an invariant that asserts one is a check, not prose.

| Law | What it binds | Source |
|---|---|---|
| **Braced keyspace** | Keys are `emq:{q}:<type>` (per-queue, closed registry) or `{emq}:<unit>` (the four-member deployment reserve `version`/`locks`/`bundle`/`migration:<q>`); first-byte disjoint (`emq:{` vs `{emq}:`); the queue name is the span between the first `{` and `}`, charset `^[A-Za-z0-9._-]{1,128}$`, and `q ≠ "emq"`. The grammar is total (§6). | S-1; §6 |
| **Branded JOB ids** | The job position is `emq:{q}:job:<branded-id>`; the key builder gates `EchoData.BrandedId.valid?/1` and raises before any wire (wellformedness only); the kind law (`JOB`-only) is the enqueue script's FIRST act, a typed `EMQKIND` wire refusal. The 14-byte branded form is the wire form; byte order IS mint order (the order theorem — REV BYLEX browse, no second index). Custom ids retire from the job position (idempotency rides `emq:{q}:de:<dedupId>`). | S-2; §2 |
| **Declared keys** | Every Lua key is in `KEYS[]`, or derived in-script only from a declared `KEYS[n]` root by the registered grammar (the A-1 rule). Slot-sound under braces (every derivable key shares the declared root's slot). | S-6 |
| **Server clock where leases are touched** | From emq.2 the lease/fence transitions read `TIME` inside the script (sound under effects replication); the no-clock lint retires at emq.2 and only there — one corpus, one direction. ARGV-time held until then. | §4 row 26; §10 DQ-2c; §12.6 |
| **Honest-row reporting** | Claims are phrased against **Valkey, current stable line**, enforced as a gate; a host without Valkey runs the probes on Redis and reports them as the historical row, never the truth row. | S-4 |
| **One-time fork / additive minor** | The wire broke exactly once (at the founding); after it, additive registration is a protocol minor (registered WITH its conformance probe in the same change); a wire break or a computed-floor raise is a major. The closed wire-class registry (`EMQKIND`, `EMQSTALE`) grows by additive minor; the five-code fence union stands unextended. | S-3; §5; §6 |

## The roadmap awareness (where the rung sits)
- **The ladder (confirmed, Stage-1b).** emq.0 (Movement 0 — land + prove the BCS drop; **shipped** 2026-06-13)
  · emq.1 (Movement I — the scheduler + retry vocabulary; **shipped**) · **emq.2** (Movement I — the full
  echomq→echo_mq feature-parity rewrite, decomposed emq.2.1/2.2/2.3) · emq.3 (parent/flow family) ·
  emq.4–emq.8 (Movement II — groups deepened, batches, lifecycle controls, the cache deepened, the proof stack).
- **The master invariant.** The fork happened once — the v2 key universe is grammar-total (braced
  `emq:{q}:`, the first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
  declared-or-rooted, the version record (`{emq}:version` = `echomq:2.0.0`) monotone behind the five-code
  fence — and **no later rung re-breaks the wire**.
- **The consumer.** codemojex (`echo/apps/codemojex`) is the worked consumer — a six-emoji code-breaking
  game standing on `EchoMQ.Jobs` drained by `EchoMQ.Consumer`, shaped by `EchoMQ.Lanes`. Forward, echo_bot
  (`echo/apps/echo_bot`) is the headline-planned consumer (Telegram notifications at scale). echo_mq is the
  substrate; the consumer is the ship.
- **The frozen v1 line.** `echo/apps/echomq` (frozen at `1.3.0`) is the **push source / feature
  reference** — a capability list to port, never a thing migrated-FROM, never edited. **Zero
  "1.3.1"/"old"/"legacy"/"migrate-from-v1" framing** in the new documentation: echo_mq is the single
  source of truth (D-2).

## The gate ladder (run before reporting — the craft emq.1 earned)
- **Toolchain re-probe.** `asdf current erlang` (do not hardcode a version — roadmap seam 6); a switch
  implies a full rebuild before gates. `redis-cli -p 6390 ping` → `PONG` (the live engine is Valkey on
  **6390**, not the default 6379).
- **Per-app compile, warnings-as-errors.** `TMPDIR=/tmp mix compile --warnings-as-errors` per touched app
  — never an umbrella-wide build.
- **Per-app suites only.** `TMPDIR=/tmp mix test` inside the touched app's dir. **Umbrella-wide `mix test`
  is BANNED** (the migration record's D7; master invariant). The `:valkey`-tagged wire suites are excluded
  by default (`ExUnit.start(exclude: [:valkey])` in `test_helper.exs`); include them explicitly for a wire
  rung (`--include valkey`).
- **The conformance run.** `EchoMQ.Conformance.run/2` over a live connection prints one `CONF` line per
  scenario and returns `{:ok, n}`. The pure registry test (`conformance_scenarios_test.exs`) and the wire
  run test (`conformance_run_test.exs`) both pin the count.
- **The ≥100 determinism loop** (for Store / engine / process / id-minting suites):
  `for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done`. One green run is NOT proof and 20 is too
  few — a same-millisecond branded-id mint collision flakes only across runs (the emq.0/emq.1 arc hit it).
  The loop must OWN the machine (no concurrent liveness server, no sibling heavy I/O — a load-gated
  pre-existing test forges a failure the rung did not cause).

## The conformance additive-minor law (S-3 / §5, the mechanism)
The conformance scenario set grows ONLY by additive minor: extend `EchoMQ.Conformance.scenarios/0` with
the new scenario, **register its probe in the same change**, and keep **every prior scenario
byte-unchanged** (name + contract + verdict-body identical, git-verified). The count is the live total;
the prior set is the unchanged contract. As-built today the set is **18** (`conformance.ex:20-41`): the
14 founding scenarios (fence, mint, duplicate, kind, order, claim, stale, complete, retry, dead, reap,
rotate, pause, limit) byte-unchanged + emq.1's four (schedule, repeat, backoff, resubscribe). A rung that
adds a capability adds its scenario(s) here and re-pins the count in both pinning tests.

## NO-INVENT grounding — cite the real surface
Every EchoMQ reference is a real module or file; every BCS requirement cites its chapter; every engine
capability cites the official docs (`valkey.io`), never memory. A surface a rung BUILDS (not yet on disk)
is written forward-tense — "emq.N builds …" — never asserted-as-shipped. The as-built surface map
(the real module / Lua / key names to cite) is in [`./echo-mq-surface.md`](./echo-mq-surface.md).

## Process locks (every rung, this repo)
- **Agents run NO git.** The Director commits once, at the rung's close, by pathspec (`git commit -F
  <msg> -- <paths>`; never `git add -A`, never a bare `git commit`). The Operator commits out-of-band
  mid-flight — watch for `AM`-status files.
- **The boundary.** The diff stays inside the architecture's facade — for the bus, `echo_mq` (+ the one
  named `echo_wire` connector seam where a rung touches it). A change that reaches a third app is a diff
  no one can review.
- **Escalate, do not invent (§11.12).** A spec⇄design / spec⇄spec / spec⇄as-built contradiction STOPS and
  escalates to the Director; the design is the authority; hygiene (a deterministic re-grep/probe) closes
  every escalation.
````

> **An adjunct reference (recommended, optional).** The Director may also place
> `.claude/skills/echo-mq-surface.md` — the as-built module / Lua / key map the NO-INVENT section points
> at — so the skills cite real names without re-probing each rung. Its content is §1a below. If the
> Director prefers, the surface map can fold into `echo-mq-program.md` as a final `## The as-built surface`
> section; the separate-file form keeps the program-law file scannable.

### 1a · `.claude/skills/echo-mq-surface.md` (the as-built map — content)

````markdown
# echo_mq — the as-built surface (NO-INVENT anchors)

The real module / Lua / key names a rung cites. Re-probe at the rung's reconcile (line numbers drift —
treat them as hints, not contract; the master invariant is per-app testing, so the surface here is the
floor, not the ceiling). Probe with `grep`/`Read` against the tree, never assert from this list alone.

## `echo/apps/echo_mq/lib/echo_mq/` — the bus
| Module | Role | Real surface (cite by re-probe) |
|---|---|---|
| `EchoMQ.Keyspace` | the braced grammar | `queue_key/2` → `emq:{q}:<type>`; `job_key/2` gates `BrandedId.valid?`; `version_key/0` → `{emq}:version` |
| `EchoMQ.Jobs` | the state machine | `enqueue` · `claim` · `complete` · `retry/7` · `promote/3` · `enqueue_at/5` · `enqueue_in/5`; inline `@enqueue`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule` `Script.new/2` attrs |
| `EchoMQ.Lanes` | fair groups | the `g:`-segment family — `@genqueue`/`@gclaim`/… inline scripts |
| `EchoMQ.Consumer` | the drain loop | `child_spec` · `start_link` (a `spawn_link` loop, NOT a GenServer) · `stop/2`; the loop calls `Jobs.promote/3` |
| `EchoMQ.Pool` | connection pool | (probe) |
| `EchoMQ.Backoff` | host-side policy | `delay_ms/2`; `{:fixed,ms}`/`{:exponential,base,cap}`/`{:jitter,inner}`; full-jitter the only random arm; handed to `retry/7` as a literal |
| `EchoMQ.Repeat` | the repeat registry | `register`/`cancel`/`due`/`advance`/`count` over `emq:{q}:repeat` (zset) + `emq:{q}:repeat:<name>` (hash); host-side fresh mint per occurrence |
| `EchoMQ.Pump` + `EchoMQ.Pump.Core` | the opt-in cadence | a `:transient` opt-in child; pure tick/batch decision core; `sweep/1` = promote + fire_repeats; owner-started, no `mod:` |
| `EchoMQ.Conformance` | the gate | `scenarios/0` (18, see the program-law file) · `run/2` → `{:ok, n}` |

## `echo/apps/echo_wire/lib/` — the wire layer (under the `EchoWire` facade)
| Module | Role | Real surface |
|---|---|---|
| `EchoMQ.Connector` | the RESP3 connection + fence | `subscribe/2` · `unsubscribe/2` · `fence/2` (reads `version_key/0`, claims `SET NX` + read-back, refuses `{:error, {:version_fence, got}}`); `@wire_version "echomq:2.0.0"`; the recorded subscription `MapSet` re-issued in `resubscribe/1` at the `:reconnect` success arm; `down/1` keeps the set |
| `EchoMQ.RESP` | the protocol codec | `encode`/decode |
| `EchoMQ.Script` | `Script.new/2` | the inline-script primitive (NO `priv/` exists) |
| `EchoWire` (`echo_wire.ex`) | the facade | the `defdelegate` surface (subscribe/unsubscribe/script/…) |

## `echo/apps/echomq/lib/` — the FROZEN v1 push source (1.3.0) — FEATURE REFERENCE ONLY
The capability list to port (NEVER edited, NEVER migrated-from): `EchoMQ.Migration.migrate/4` (the
copy-verify-DELETE mechanism precedent + the typed-refusal vocabulary) · `EchoMQ.Version` ·
`EchoMQ.Fence.preflight/3` · `flow_producer` · `lock_manager` · `job_scheduler` · `queue_events` ·
`stalled_checker` · `telemetry` · `worker` · priorities · rate-limiting · metrics · pause/resume ·
obliterate/drain · the 26 `.lua` scripts. These NAME what to port under the v2 laws; they are not the
target surface.

## The substrate
`EchoData.BrandedId.valid?/1` + `encode/2` (`echo/apps/echo_data`, the in-umbrella dep — the branded-id
gate costs no dependency edge). `EchoData.Snowflake` (the mint; must be started — `BrandedId.generate!`
needs it). Engine: **Valkey on port 6390** (`redis-cli -p 6390 ping` → `PONG`).
````

---

## 2 · `echo-mq-architect` — the Venus skill

### Frontmatter

```yaml
---
name: echo-mq-architect
description: >-
  Use this skill when Venus (the architect) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the architect's
  echo_mq craft: the lag-1 pre-build reconcile against the as-built echo_mq/echo_wire tree, authoring the
  rung's spec triad (emq.N.md / .stories.md / .llms.md) to the v2 laws, carving a parity surface from the
  frozen v1 feature reference, surfacing (never deciding) the seam forks, and the design-phase formation
  for a SYSTEM founding. The program-wide law (the v2 laws, the gate ladder, the NO-INVENT grounding, the
  roadmap awareness) lives in the shared reference echo-mq-program.md, which this skill cites. Do NOT use
  for the course-authoring skills (*-course-writer), for a non-echo_mq rung (the generic venus charter
  covers portal/mercury/redis/elixir), or to write production code (that is Mars / echo-mq-implementor).
---
```

### Body (content the Director writes)

````markdown
# echo-mq-architect — the spec half of the Author, on the EchoMQ bus

You are Venus on an `emq.*` rung. The generic architect discipline still governs (`.claude/agents/venus.md`
— the single source of truth, the Given/When/Then derivation, surface-forks-never-decide, edit-only-the-
triad). This skill adds the **echo_mq craft** the program earned. The program-wide law — the v2 laws, the
gate ladder, the conformance additive-minor law, the NO-INVENT grounding, the roadmap awareness — is the
shared reference **[`../echo-mq-program.md`](../echo-mq-program.md)**; read it first, then this.

## 1 · The lag-1 pre-build reconcile (your step 1, every rung)
Before briefing, diff the rung's triad against the as-built tree it depends on — `/reconcile <rung>`
(`.claude/commands/reconcile.md`), or by hand. The echo_mq specifics:
- **Probe the real surface**, never assert from the surface map. Extract every `EchoMQ.*.fun/arity`,
  return shape, key name, Lua script attr, and code-asserting invariant; grep/read it in
  `echo/apps/echo_mq` + `echo/apps/echo_wire`. Classify MATCH / STALE / INVENTED / MISSING / DEFERRED.
- **The conformance count is a claim.** A triad that says "14 scenarios" when the as-built
  `scenarios/0` is 18 is STALE — re-pin it: the prior N is the byte-unchanged contract, the new total is
  the live count (the emq.1 reconcile's S-2 fix).
- **The fence is already connect-scoped.** The as-built `echo_wire` connector runs the
  `{emq}:version` claim/read-back/refuse on every connect (landed at emq.0). A triad that says a later
  rung "moves the fence to connect" is STALE against as-built — the design §3 clause pre-dates emq.0
  (the emq.1 L-2 finding). Ground the triad against as-built reality; flag a canon-sync as the Operator's
  call (the design is reconcile-only — never edit its body).
- **Inline scripts, not `priv/`.** No `echo/apps/echo_mq/priv/` exists; scripts are inline `Script.new/2`
  module attributes. A triad that says "new Lua under `priv/`" is STALE (the emq.1 S-1 fix).
- **A "no new dependency" claim is a per-app DEP-GRAPH-VISIBILITY fact** — read the consuming app's
  `mix.exs` `deps/0`, never `mix.lock` alone. `echo_data` is already an in-umbrella dep of `echo_mq`.

The rung is build-grade iff every claim is MATCH or an explicit `[RECONCILE]`-DEFERRED.

## 2 · Author the triad to the v2 laws
The triad shape is the program's: `emq.N.md` (the contract — Goal · 5W · Scope · D-n · INV-n · DoD), `.stories.md`
(US-n in Connextra form + the standing `EMQ.N-US-GATE` Valkey gate story + a Coverage map), `.llms.md` (the
Mars brief — References · Requirements · Execution topology · Agent stories), built to
`docs/elixir/specs/specs.approach.md` (the six quality gates). For echo_mq:
- **Every deliverable traces to the v2 laws as checks.** An invariant that asserts a v2 law is a runnable
  check (INV: "every new Lua key is in `KEYS[]` or grammar-derived" — a grep over the new scripts; INV:
  "the prior conformance scenarios are byte-unchanged, the new ones probe-registered" — the count + a
  git-diff; INV: "fresh branded `JOB` mint per occurrence" — the order theorem, two distinct ids).
- **Forward-tense for what the rung builds.** A surface the rung adds is "emq.N builds …", never
  asserted-as-shipped. Ground a built-already surface against the as-built `file`/`Module.fun`; ground a
  to-be-built surface against the design § and the v1 feature reference as the mechanism precedent.
- **Mechanism words are claims.** Name the primitive the invariant rides (the set is a `ZSET` scored by
  X; the mint is host-side; the clock is `TIME` server-side from emq.2). A brief at odds with its own
  invariant's primitive mis-directs the build.
- **The conformance additive-minor law** (shared reference): the triad names the new scenario(s), the
  count growth (prior N byte-unchanged → new total), and the probe registration — in the same rung.

## 3 · Carve the parity surface (the emq.2.x cluster, D-4)
emq.2 is the full echomq→echo_mq feature-parity rewrite decomposed into emq.2.1 / emq.2.2 / emq.2.3. When
authoring a parity rung:
- **The v1 line is the FEATURE REFERENCE, not the target.** `echo/apps/echomq` (frozen `1.3.0`) names the
  capability to port — flows, locks, events, stalled-recovery, telemetry/metrics, priorities,
  rate-limiting, lifecycle (pause/cancel/obliterate/checkpoints), the worker abstraction. Port each
  **rewritten to the v2 laws** (braced + branded + declared-keys + server-clock); never lift the v1 form
  (its scripts root key operands in data values — structurally inexpressible under declared-keys, §11.10).
- **Zero migration-from-v1 framing.** echo_mq is the single source of truth (D-1/D-2); no
  "1.3.1"/"old"/"legacy" language in the new triad. The frozen line is a thing to PORT FROM as a
  reference, never a thing MIGRATED FROM.
- **Coherent, dependency-ordered, one-increment-one-run.** Each emq.2.N is a full triad + an
  `emq.2.N.prompt.md` runbook; the carve is the architect's (Venus-1 fixes the exact split from the real
  v1 inventory of 25 `.ex` + 26 `.lua` and the design canon).

## 4 · Surface the forks — never decide them
The open seams live in `emq.roadmap.md` §Seams + `emq.design.md` §10. STOP and report each with the
options and the trade-off; do not pick one and proceed:
- **The in-place v2→v2 migration treatment** (design §10 seam 1) — drain-precondition (the cheap honest
  default) vs an in-place converter, plus the wire-semver call; the likely ground is the no-release
  precondition (§11.11). An Operator ruling before any such build.
- **The wire-app ↔ `Keyspace` fence-time seam** (roadmap seam 1) — inline the fence-key constant vs move
  `version_key/0` into `echo_wire`. Carried to a rung's opening design gate.
- An architecture / API-contract / new-dependency / identity fork is the Operator's call — report, do not rule.

## 5 · The Design Phase (a SYSTEM founding)
When a rung founds or re-founds a SYSTEM spec (not a rung-level design), the §12 formation applies — the
architectural design + ADR set comes first, the triad derives from the approved design. For echo_mq this
is the dual-Venus independence the program already ran (the founding 2.0 design phase; the V-SOLO-4
violation it exists to prevent): author independently, read the locked constraints + the as-built code +
the official engine docs, never the sibling's draft. An engine capability is cited to `valkey.io`, never
asserted from memory (§12's verified citations are the model).

## Report
End with a `SendMessage` to the Director: the reconcile delta table + the BUILD-GRADE / BLOCKED verdict;
the brief (references / requirements / topology / agent stories); any fork surfaced for the Operator; the
triad files edited, one line each. Edit ONLY the spec triad — no `.ex`/`.heex`/`.exs`. No git.
````

---

## 3 · `echo-mq-implementor` — the Mars skill

### Frontmatter

```yaml
---
name: echo-mq-implementor
description: >-
  Use this skill when Mars (the implementor) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the implementor's
  echo_mq craft: building the increment to the Venus brief inside the echo_mq (+ one echo_wire seam)
  boundary, citing the spec line for every public call, the inline Script.new/2 law (NEVER priv/), the
  declared-keys / branded-JOB-id / server-clock Lua laws, the conformance additive-minor mechanics, and
  the per-app gate ladder (TMPDIR=/tmp, Valkey 6390, warnings-as-errors, the ≥100 determinism loop) run
  before reporting. The program-wide law lives in the shared reference echo-mq-program.md, which this skill
  cites. Do NOT use for the course-authoring skills (*-course-writer), for a non-echo_mq rung (the generic
  mars charter covers portal/mercury/redis/elixir), or to edit the spec triad (that is Venus / echo-mq-architect).
---
```

### Body (content the Director writes)

````markdown
# echo-mq-implementor — the production half of the Author, on the EchoMQ bus

You are Mars on an `emq.*` rung. The generic implementor discipline still governs (`.claude/agents/mars.md`
— build to the brief slice by slice, cite-do-not-invent, realization-over-literal, done-is-a-closure,
edit-code-and-tests-never-the-spec). This skill adds the **echo_mq craft**. The program-wide law — the v2
laws, the gate ladder, the conformance additive-minor law, the NO-INVENT grounding, the roadmap awareness
— is the shared reference **[`../echo-mq-program.md`](../echo-mq-program.md)**; read it first, then this.

## 1 · Build inside the boundary
The diff stays inside `echo/apps/echo_mq` (the bus) plus, where the brief names it, the **one**
`echo/apps/echo_wire` connector seam a rung touches (the emq.1 resubscribe seam is the precedent — one
`connector.ex` change + one `echo_wire.ex` `defdelegate`). A change that reaches a third app is a diff no
one can review. `apps/echomq` (the frozen v1 line) is **UNTOUCHED** — it is a feature reference, never an
edit target.

## 2 · Cite, do not invent — the echo_mq surfaces
For every public call, the `EchoMQ.*` module / function / arity / return must already exist in the tree
or be named in the brief. The as-built surface map is in
[`../echo-mq-surface.md`](../echo-mq-surface.md). If the brief is silent or wrong, STOP and report — do
not invent a key, a Lua script, a struct field, or a return, and do not redefine an existing surface
(this repo's API has been silently redefined by build agents past green gates — the drift you exist to
prevent). **Realization-over-literal**: build to the contract's intent; if the literal text would breach
an invariant, build the behavior-identical realization and flag it with its citing `file:line` (the emq.1
ONE-@schedule-script-with-an-ARGV-mode-flag realization is the model — Director-ratified).

## 3 · The Lua laws (every script you write)
- **Inline `Script.new/2`, NEVER `priv/`.** No `echo/apps/echo_mq/priv/` exists; scripts are inline module
  attributes (`@enqueue`, `@claim`, `@schedule`, `@register`, …). Follow the convention; a brief that says
  `priv/` is a STALE the architect owes — flag it.
- **Declared keys (S-6).** Every key the script touches is in `KEYS[]`, or derived in-script only from a
  declared `KEYS[n]` root by the registered grammar (e.g. the per-job key `base..'job:'..id`, the lane
  family `base..'g:'..g..':pending'`). A new key derives from `Keyspace.queue_key(q, "<type>")` and is
  declared. Slot-sound under braces — every derivable key shares the declared root's slot.
- **Branded `JOB` ids (S-2).** A job id on the wire is the 14-byte branded form; the key builder gates
  `EchoData.BrandedId.valid?/1`; the enqueue/add script's FIRST act refuses a non-`JOB` namespace with the
  `EMQKIND` first-word wire class (policy before existence before write). The mint is host-side
  (`BrandedId.generate!`, Snowflake started); the wire never mints. The order theorem holds — byte order is
  mint order; a repeatable's two occurrences mint two DISTINCT, lexically-ordered ids.
- **The server clock (§10 DQ-2c).** From emq.2, a lease/fence transition reads `TIME` inside the script
  (sound under effects replication). A run-in score computes wire-side from `TIME` (`t[1]*1000 +
  floor(t[2]/1000) + delay`); a run-at score takes the caller's absolute ms (the documented client-clock
  surface for the score ONLY — the fence + lease laws are untouched).
- **The wire-class registry (S-3 / §5).** Typed refusals lead with their class word (`EMQKIND`,
  `EMQSTALE`) via `redis.error_reply`, never the generic `ERR`. Adding a class is an additive minor,
  registered with its conformance probe in the same change. The five-code fence union stands unextended.

## 4 · The conformance additive-minor mechanics
A capability rung extends `EchoMQ.Conformance.scenarios/0` with the new scenario, **registers its probe
body in the same change**, and keeps **every prior scenario byte-unchanged** (name + contract +
verdict-body identical — git-verify it). Re-pin the count in both pinning tests
(`conformance_scenarios_test.exs` pins the names; `conformance_run_test.exs` pins `{:ok, n}`). The full
`Conformance.run/2` is its own gate beyond the unit suites — it caught two scenario-harness bugs the
standalone suites missed (emq.1 L-1: an inverted mint-order guard, a too-early promote). A check counts
only if it RUNS — a doctest is inert until a test file invokes `doctest <Module>`.

## 5 · The gate ladder — run BEFORE reporting (the craft emq.1 earned)
Per the shared reference's gate ladder, every item:
- `asdf current erlang` (re-probe; never hardcode); `redis-cli -p 6390 ping` → `PONG`.
- `TMPDIR=/tmp mix compile --warnings-as-errors` per touched app — clean.
- `TMPDIR=/tmp mix test` inside each touched app's dir (NEVER umbrella-wide — BANNED); include `--include
  valkey` for a wire rung.
- `Conformance.run/2` → `{:ok, n}` with the prior set byte-unchanged.
- The **≥100 determinism loop** for any id-minting / process / engine suite —
  `for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done` — the loop OWNS the machine (no
  concurrent server, no sibling heavy I/O). One green run is not proof; the same-ms mint collision flakes
  only across runs.
- **"Pre-existing" is two facts** (emq.1 L-6): an environment-gated-cannot-run check (e.g. an Oban/Postgres
  benchmark rung) is a documented carry; a this-change-staled-it check (e.g. a hardcoded conformance count
  the rung's additive-minor growth supersedes) is **the rung's own debt to close in the same change**.
  Distinguish them in the report.

## Report
End with a `SendMessage` to the Director: a file-by-file change list (NEW / REWRITE / EDIT / DELETE); any
realization-over-literal with its citing `file:line`; the gate result (compile + per-app pass counts +
`Conformance.run/2` + the determinism-loop result); the INV checks; any brief gap. Edit code + tests only
— never the spec triad. **No git** — leave the work in the tree for the Director to ratify.
````

---

## 4 · `echo-mq-evaluator` — the Apollo skill

### Frontmatter

```yaml
---
name: echo-mq-evaluator
description: >-
  Use this skill when Apollo (the evaluator) is on a rung of the EchoMQ bus program — any rung whose slug
  matches emq.* (emq.1, emq.2, emq.2.1, … through emq.8), the program whose canon is
  docs/echo_mq/emq.design.md and whose ladder is docs/echo_mq/emq.roadmap.md. It encodes the evaluator's
  echo_mq craft: the post-build reconcile (does the as-built code satisfy the spec's promises?), the
  §11.2-charter adversarial verification applied to echo_mq (the order-theorem / declared-keys /
  destructive-act probes), re-running the per-app gate ladder + the ≥100 determinism loop independently,
  re-verifying the conformance count is byte-unchanged with each new scenario probe-registered, syncing the
  spec to what shipped, and the mentoring loop into the architect/implementor skills + charters. The
  program-wide law lives in the shared reference echo-mq-program.md, which this skill cites. Do NOT use for
  the course-authoring skills (*-course-writer), for a non-echo_mq rung (the generic apollo charter covers
  portal/mercury/redis/elixir), or to write production code (a needed change routes through the Director to Mars).
---
```

### Body (content the Director writes)

````markdown
# echo-mq-evaluator — the verifier in the Author/Operator loop, on the EchoMQ bus

You are Apollo on an `emq.*` rung. The generic evaluator discipline still governs
(`.claude/agents/apollo.md` — the post-build reconcile, adversarially-verify-do-not-bless, re-run-the-gate-
yourself, sync-the-spec-to-what-shipped, the mentoring loop, the verdict bends to neither duty). This skill
adds the **echo_mq craft**. The program-wide law — the v2 laws, the gate ladder, the conformance
additive-minor law, the NO-INVENT grounding, the roadmap awareness — is the shared reference
**[`../echo-mq-program.md`](../echo-mq-program.md)**; read it first, then this.

## 1 · The post-build reconcile (your core job)
Run `/reconcile <rung> post` (or by hand, in reverse: does the as-built code satisfy what the spec
promised?). Take every Deliverable, Invariant, and Given/When/Then in the `.stories.md` and probe the real
tree. Classify MATCH / STALE / INVENTED / MISSING / DEFERRED; emit the delta table (promise → as-built
`file:line` → verdict). BUILD-GRADE iff every promise is MATCH or an explicit `[RECONCILE]`-DEFERRED; any
STALE / INVENTED / MISSING **BLOCKS** until corrected. Post-build the shipped code is the fact — sync the
spec body to match it (record what shipped, never redesign); an intent divergence is a STALE you report,
not a sync you apply.

## 2 · Adversarially verify — the echo_mq probes (the §11.2 charter)
A green run is one piece of evidence. Probe the failure modes a passing suite hides; name the uncertainty
AND its cost. The echo_mq-specific attacks:
- **The order theorem (byte = mint).** Verify a repeatable's two occurrences mint two DISTINCT branded ids
  in lexical (mint) order, and the pending set walked REV BYLEX answers newest-first by name alone. The
  emq.1 conformance run caught an inverted guard here — re-verify, do not trust the suite.
- **Declared keys (S-6).** Grep every NEW Lua script: every key in `KEYS[]` or derived from a declared
  `KEYS[n]` root. An undeclared key is a defect even when every test is green.
- **No invented surface.** Every public call the build added resolves to a real `EchoMQ.*` `@spec`/function;
  no key, Lua script, struct field, or return was redefined past the gate.
- **The destructive / fence / at-most-once probes.** For a fence rung: the `{emq}:version` claim path is
  byte-unchanged in logic (it landed at emq.0 — emq.1 L-2). For a migration rung: numeric ids brand
  order-preserving, non-numeric custom ids refuse through the typed lane (`{:unmigratable_job_ids, ids}`)
  — drain first, never a silent drop. For pub/sub: at-most-once across a disconnect is documented, not
  silently lost. For a non-atomic read race (a registration cancelled between `ZRANGEBYSCORE` and `HMGET`):
  the sweep handles the dangling member rather than minting on nil (the emq.1 fire_one fallthrough).
- **No catch-all where the contract forbids one** — an error mapper with a final `_ ->` lets a new reason
  leak untyped; the wire-class seam maps `EMQKIND`/`EMQSTALE` explicitly and passes an unrecognized `EMQ*`
  through untyped (forward-compatible) — read for it.

## 3 · Re-run the gate yourself
Reproduce, do not take the build's word. Per the shared reference: `redis-cli -p 6390 ping` → `PONG`;
`TMPDIR=/tmp mix compile --warnings-as-errors` per app; `TMPDIR=/tmp mix test` per app (NEVER
umbrella-wide); `Conformance.run/2` → `{:ok, n}`. The **conformance count is a re-verify**: confirm the
prior scenarios are byte-unchanged (git-diff name + contract + verdict-body) and each new one is
probe-registered — a hardcoded count drifted by the rung's additive-minor growth is a STALE the rung owes
(emq.1 L-6). The **≥100 determinism loop must OWN the machine** — run it uncontended; a load-gated
pre-existing test forges a failure the rung did not cause (the emq.0 endpoint-storm / id-skew breaks).
When the build + harden passes already ran ≥2 green 100/100 uncontended, reproduce with ONE confirming run
+ a SCOPED loop over the rung's own id-minting tests — a third full loop is waste that times out your turn.

## 4 · Sync the spec + mentor
- **Sync** the `emq.N.md` (and the derived `.stories.md`/`.llms.md`) to the as-built surface — record what
  shipped; the design canon (`emq.design.md`) is **reconcile-only**, never edited (a canon-sync is the
  Operator's call, flagged not applied — emq.1's §11.10 scheduler-discharged flag is the model).
- **Mentor** on craft + contract-fidelity, by peer: **Mars** earns build-fidelity lessons (cited every
  call, invented no surface, honored the law, left a check that runs); **Venus** earns brief-fidelity
  lessons (pinned the contract, traced every requirement, marked each `[RECONCILE]`, let no STALE reach the
  build). A recurring finding folds forward — into the **echo-mq-implementor / echo-mq-architect skill** (the
  program-craft home) or the role charter — as a one-line guardrail cited to the rung, Director-ratified,
  one guardrail per recurring finding (sharpen the existing line, never stack a second). WHAT-to-build is
  the Operator's — an intent divergence is a STALE you report, never a lesson you encode.

## Report
End with a `SendMessage` to the Director: the post-build delta table (promise → as-built `file:line` →
verdict); the BUILD-GRADE / BLOCKED verdict with the blocking deltas named; the gate result you reproduced
(compile + per-app pass counts + `Conformance.run/2` + the determinism-loop result); the adversarial checks
run and what each found; the spec files synced; the mentoring routed (each finding, its channel — in-loop
`SendMessage` to the named peer vs a durable guardrail in a skill/charter — and any agent-def/skill edit
you PROPOSE for Director ratification, with the exact diff). Edit the spec triad, the `.operator.md` guide,
the retrospective, and — Director-ratified — a peer skill/charter; never production code. **No git.**
````

---

## 5 · The three additive charter tunings (the EXACT inserts the Director writes)

Each block is **additive** — it inserts a new `## echo_mq program` section, removing nothing. Every
existing cross-program line (the portal/mercury/redis/elixir F6.x craft, the design phase, the mentoring
loop) is preserved verbatim.

**Placement (all three):** insert the `## echo_mq program` section **immediately before the final
`## Scope + framing` section** — after the role's last craft section, so the program tuning reads as one
more discipline the role carries, and the universal scope/framing rules stay last.

### 5.1 · Insert into `.claude/agents/venus.md`

> Insert AFTER `## The Design Phase — when the deliverable IS the system spec` and BEFORE
> `## Discipline (inviolable)`.

```markdown
## echo_mq program
On any rung whose slug matches `emq.*` — the EchoMQ bus program (canon
`docs/echo_mq/emq.design.md`, roadmap `docs/echo_mq/emq.roadmap.md`) — **load the `echo-mq-architect`
skill**: it carries the architect's program craft (the lag-1 reconcile against the as-built
`echo_mq`/`echo_wire` tree, the triad-to-the-v2-laws, carving the parity surface, the seam forks), and
points at the shared `echo-mq-program.md` (the v2 laws, the gate ladder, the conformance additive-minor
law, the NO-INVENT grounding, the roadmap awareness).
- **The ladder + the master invariant.** emq.0 (land+prove) · emq.1 (scheduler+retry) · **emq.2** (the
  full echomq→echo_mq feature-parity rewrite, decomposed emq.2.1/2.2/2.3) · emq.3 (parent/flow) ·
  emq.4–emq.8 (Movement II family depth). The fork happened ONCE — the v2 key universe is grammar-total
  (braced `emq:{q}:`, the first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every
  Lua key declared-or-rooted, the version record monotone behind the five-code fence; **no later rung
  re-breaks the wire** (additive registration is a minor, a wire break is a major).
- **The forks are yours to surface, never decide** — `emq.roadmap.md` §Seams + design §10 (the in-place
  v2→v2 migration treatment; the wire-app↔`Keyspace` fence-time seam). Report the options and the
  trade-off; the Operator rules.
- **Program guardrails.** Ground every reference in a real `echo_mq`/`echo_wire` module or a design § —
  the design canon is reconcile-only, never redesigned. `apps/echomq` (frozen `1.3.0`) is a FEATURE
  REFERENCE to port from, never a thing migrated-from — **zero "1.3.1"/"old"/"legacy"/"migrate-from-v1"
  framing** (echo_mq is the single source of truth). Per-app testing only; agents run no git, the
  Director commits by pathspec.
```

### 5.2 · Insert into `.claude/agents/mars.md`

> Insert AFTER `## Done is a closure over checks, not a feeling` and BEFORE `## Scope + framing`.

```markdown
## echo_mq program
On any rung whose slug matches `emq.*` — the EchoMQ bus program (canon
`docs/echo_mq/emq.design.md`, roadmap `docs/echo_mq/emq.roadmap.md`) — **load the `echo-mq-implementor`
skill**: it carries the implementor's program craft (the spec-cited build inside the `echo_mq` + one
`echo_wire` seam boundary, the inline-script / declared-keys / branded-`JOB`-id / server-clock Lua laws,
the conformance additive-minor mechanics), and points at the shared `echo-mq-program.md`.
- **The boundary.** The diff stays inside `echo/apps/echo_mq` plus the one named `echo/apps/echo_wire`
  connector seam a rung touches; `apps/echomq` (frozen `1.3.0`) is UNTOUCHED — a feature reference, never
  an edit target.
- **The Lua laws.** Inline `Script.new/2`, **never `priv/`** (no `echo_mq/priv/` exists); every Lua key
  in `KEYS[]` or derived from a declared `KEYS[n]` root; branded `JOB` ids gated at the key builder, the
  `EMQKIND` kind-refusal the script's first act; `TIME` server-side from emq.2 where leases are touched;
  typed refusals lead with the wire class (`EMQKIND`/`EMQSTALE`).
- **The gate ladder, run before reporting.** `asdf current erlang` (re-probe, never hardcode);
  `redis-cli -p 6390 ping` → `PONG` (Valkey on **6390**); `TMPDIR=/tmp mix compile --warnings-as-errors`
  per app; `TMPDIR=/tmp mix test` per app (umbrella-wide `mix test` BANNED; `--include valkey` for a wire
  rung); `Conformance.run/2` → `{:ok, n}` with the prior scenarios byte-unchanged + the new one
  probe-registered; the ≥100 determinism loop (it OWNS the machine) for any id-minting/process/engine
  suite. "Pre-existing" is two facts — an env-gated-cannot-run carry vs a this-change-staled-it debt the
  rung closes in the same change. Agents run no git.
```

### 5.3 · Insert into `.claude/agents/apollo.md`

> Insert AFTER `## Mentor Venus + Mars — fold the finding forward, do not re-critique the spawn` and
> BEFORE `## Scope + framing`.

```markdown
## echo_mq program
On any rung whose slug matches `emq.*` — the EchoMQ bus program (canon
`docs/echo_mq/emq.design.md`, roadmap `docs/echo_mq/emq.roadmap.md`) — **load the `echo-mq-evaluator`
skill**: it carries the evaluator's program craft (the post-build reconcile against the as-built tree, the
§11.2-charter adversarial echo_mq probes, re-running the per-app gate ladder + the ≥100 determinism loop,
the conformance count-byte-unchanged re-verify, the spec-sync + the mentoring loop into the
architect/implementor skills), and points at the shared `echo-mq-program.md`.
- **The adversarial probes.** The order theorem (byte = mint; two distinct ids in mint order; REV BYLEX
  browse); declared keys (grep every new Lua script); no invented `EchoMQ.*` surface; the
  destructive/fence/at-most-once/non-atomic-read probes; no catch-all where the wire-class seam forbids one.
- **Re-run the gate yourself.** Per-app compile + suites (never umbrella-wide); `Conformance.run/2` →
  `{:ok, n}` re-verifying the prior set is byte-unchanged (git-diff) + each new scenario probe-registered
  (a hardcoded count the rung's additive-minor growth staled is a STALE the rung owes); the ≥100 loop
  uncontended (a load-gated pre-existing test forges a failure the rung did not cause — run it owning the
  machine, and a SCOPED loop when the build+harden already ran ≥2 green 100/100).
- **Sync + mentor.** Sync the triad to what shipped; the design canon is reconcile-only (a canon-sync is
  the Operator's call, flagged not applied). Fold a recurring finding forward — into the
  `echo-mq-implementor`/`echo-mq-architect` skill (the program-craft home) or the role charter — one
  guardrail per recurring finding, Director-ratified. Agents run no git; the verdict bends to neither the
  documentation nor the mentoring duty.
```

---

## 6 · The recommendation (the two shape calls, argued)

**Three per-role skills, not one shared skill (V-1 → D-7).** The role-distinct craft is genuinely
distinct — the architect's triad/reconcile/carve, the implementor's spec-cited-build-inside-the-boundary +
the Lua laws, the evaluator's §11.2 adversarial-verify — and a single shared skill would force each spawn
to read past two-thirds irrelevant craft, the bloat the Apollo charter's own "keep the definitions lean"
rule warns against. The **common program law** (the v2 laws, the gate ladder, the roadmap, NO-INVENT,
no-git) is shared, so it lives once in `echo-mq-program.md` (+ the optional `echo-mq-surface.md`) that all
three SKILL.md files cite — single-source-correct: a v2-law correction lands once. This is the DRY split:
distinct-by-role in three bodies, common-by-program in one reference.

**Additive charter blocks, not dedicated `*-echomq` charter variants (V-2 → D-8).** The shared
program-NEUTRAL discipline the charters already carry (reconcile, cite-don't-invent, done-is-a-closure, the
design phase, the mentoring loop) IS the echo_mq discipline too — a dedicated variant would FORK that
shared craft, forcing every future portal/redis lesson to be applied twice (the maintenance debt the
team's single-source discipline exists to prevent). The program-specific delta is small and bolts on as
one `## echo_mq program` section per role, preserving every cross-program line — exactly the additive
shape D-5 names, and matching the Operator's grant for the peer-def edits (the explicit instruction is the
governance grant — `portal-leadteam-governance`).

**What the Director writes (the work-list).**
1. `.claude/skills/echo-mq-program.md` — §1 content (the shared program law).
2. `.claude/skills/echo-mq-surface.md` — §1a content (the as-built map; optional, recommended — or fold
   into §1 as a final section).
3. `.claude/skills/echo-mq-architect/SKILL.md` — §2 (frontmatter + body).
4. `.claude/skills/echo-mq-implementor/SKILL.md` — §3 (frontmatter + body).
5. `.claude/skills/echo-mq-evaluator/SKILL.md` — §4 (frontmatter + body).
6. `.claude/agents/venus.md` — insert §5.1 (additive).
7. `.claude/agents/mars.md` — insert §5.2 (additive).
8. `.claude/agents/apollo.md` — insert §5.3 (additive).

The tuned skills + charters are read from disk at session start — a **restart** reloads them with no
commit required (D-6); the Operator commits out-of-band.
````
