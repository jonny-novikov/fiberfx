# EMQ.4.2 · the build orchestration runbook — ship group-aware recovery (the group-scoped stalled-sweep)

> **Status: SPECCED, the runbook ready (authored at the `emq-4-2` design run, Stage 1).** This runbook drives the
> **emq.4.2** build — the SECOND sub-rung of the groups-deepened family (group-aware recovery) — a **NORMAL-risk** rung
> that deepens a shipped, already-group-aware recovery surface. The `/echo-mq-ship` skill
> ([`.claude/skills/echo-mq-ship/SKILL.md`](../../../../../../.claude/skills/echo-mq-ship/SKILL.md)) is the binding (it is
> `/x-mode` with the echo_mq context pre-loaded: Venus loads `echo-mq-architect`, Mars loads `echo-mq-implementor`, the
> Director verifies code + invariants, Apollo — the Mentor — loads `echo-mq-evaluator` out of the per-rung pipeline on
> a NORMAL rung); the inputs are the triad ([`./emq.4.2.md`](emq.4.2.md) · [`./emq.4.2.stories.md`](emq.4.2.stories.md)), the family ([`../emq.4.md`](../emq.4.md) — the deepening contract + the
> carve + the THREE forks), and the canon ([`../../../emq.design.md`](../../../../emq.design.md) §10 seam 2 / §4 cluster 2
> / §4 / S-1/§6 / S-6 / §5).

## The family in one paragraph

emq.4 is the groups-deepened family — the shipped fair-lanes (`EchoMQ.Lanes`) mechanism taken to **production
multi-tenant depth** along four axes: a control plane (move a member between lanes; deepen pause/resume/limit/drain),
group-aware recovery (a group-scoped stalled-sweep), the park-don't-poll metronome (the wake/notify beat hardened),
and weighted/deficit rotation (fair-share beyond round-robin + a starvation drill). The basics ALREADY shipped (B3.4
"Fair Lanes", 8/8 G1–G8); emq.4 does **not** found the family — it **deepens** it, every axis **additive over the
shipped `g:`-segment keyspace**, nothing a wire break. The family carves into emq.4.1 (control plane — **SHIPPED**) ·
4.2 (group-aware recovery — **this rung**) · 4.3 (the metronome — HIGH-risk) · 4.4 (weighted/deficit + the drill — HIGH
iff `@gclaim` is edited), the Operator-ruled spine. The full deepening contract + the three forks are
[`../emq.4.md`](../emq.4.md).

## The rung in one paragraph

emq.4.2 carves **group-aware recovery** — the entry an operator uses to recover **one tenant's** lapsed leases on
demand. Today recovery is **queue-wide**: the shipped `EchoMQ.Jobs.@reap` (`jobs.ex`) scans the whole `active` set for
expired leases, and `EchoMQ.Stalled.check/3` (`stalled.ex`) does the same with a dead-letter threshold; **both already
return a grouped member to its lane** (the `stalled_group` conformance scenario is the proof). emq.4.2 adds the
**group-scoped** entry: recover the expired-lease members of a **named** group, returning each to its
`g:<group>:pending` lane (not the flat pending), decrementing `gactive`, re-ringing the lane if serviceable, waking a
parked consumer — all on the **server clock**. It builds, inside `echo/apps/echo_mq` under the v2 laws (declared keys,
branded group ids gated at the lane-key builder, the inline `Script.new/2` law, additive-minor conformance, **no
shipped-recovery-script edit**): **(1)** a **group-scoped recovery** host verb on `EchoMQ.Lanes` (Venus recommends
`reap_group/3`) + its inline `@greap_group` script (the shipped `@reap` group branch **byte-modelled** + a
`g == ARGV[group]` filter + the server clock); **(2)** the `reap_group` conformance scenario (additive minor, the
prior **54** byte-unchanged); **(3)** the `:valkey` suite + a multi-seed sweep. The shipped `@reap`/`@sweep_stalled`/
`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/`@gdrain` are **byte-frozen** (INV1/INV3); the
member returns to **its own** lane (`group` a pure read — no `HSET`). The honest **Out**: any change to the non-group
recovery path (`@reap` + `@sweep_stalled` byte-unchanged for a no-group job), a host clock on the lease (server clock
only), a new lane key family, the dead-letter policy change, the control plane (emq.4.1), the metronome (emq.4.3),
weighted rotation (emq.4.4). The contract is [`./emq.4.2.md`](emq.4.2.md) (D2/D5/D6, INV1–INV5).

## Mode

**Flat-L2** (a build + a gate + a verify), Director-supervised. **Not** the Design-Phase variant (the triad exists —
authored this design run). **NORMAL-risk.** emq.4.2 adds **one** host recovery verb + **one** new inline script over
the shipped `g:`-segment keyspace; it edits **no** shipped recovery or lane script (`@reap`/`@sweep_stalled`/`@gclaim`/
`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/`@gdrain` byte-unchanged), founds **no** process/lease surface
(the sweep mints no branded id, starts no process), and performs **no destructive at-rest op** (it **moves** a lapsed
lease back to a lane — distinct from emq.4.1's `drain/3` which **deletes**). It **touches a lease** (reads `TIME`
server-side to compute expiry — INV2). So the standard per-app gate ladder + a **multi-seed sweep + an honest
determinism-posture statement** (the **≥100-iteration loop is NOT run** — the sweep touches a lease but mints no id and
starts no process, so the same-millisecond-mint hazard the loop guards does not exist; the loop would forge load rather
than catch a real hazard). **Apollo** the Mentor may engage as a closure fast-finisher; the Director's verify is the
gate of record.

Scope slug: **`emq-4-2`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/progress/emq-4-2.progress.md` (the design
run opened it with the reconcile T-2 + the build-choice V-1; the ship run carries the build records).

## The build-choice gate — the Director's ruling (Venus recommends Arm A; the verb-name owed before the build)

The body ([`./emq.4.2.md`](emq.4.2.md) §The build choice) flags TWO ways the group-scoped sweep can land and **withholds
the choice for the reconcile**. The Venus reconcile (ledger V-1) recommends; the Director rules:

> **THE BUILD CHOICE — Venus recommends → ARM A (additive-beside).** A **NEW** inline `@greap_group` script + a **NEW**
> `reap_group/3` host verb scopes the scan to a named group (the shipped `@reap` group branch byte-modelled + a
> `g == ARGV[group]` filter), leaving the shipped `@reap` and `@sweep_stalled` **byte-unchanged** (INV1). **NORMAL-risk,
> no shipped-script edit, no Apollo mandate.** The one reason that carries it: it preserves byte-freeze on TWO
> lease-critical shipped scripts, and the as-built code **already duplicates** the group-recovery branch (`@reap` and
> `@sweep_stalled` each carry their own copy), so a third additive copy is consistent with the established pattern —
> Arm B's DRY argument is weaker than it appears.
>
> **ARM B (the alternative — edit a shipped sweep).** Thread a `:group` ARGV filter **into** the shipped `@reap` (or
> `@sweep_stalled`): a non-matching expired id is skipped (no `ZREM`, no recover), the non-group path byte-identical.
> **This re-grades the rung NORMAL→HIGH** (a frozen-line touch on a lease-critical recovery script — the crash-recovery
> `@reap` is the most lease-critical script in the bus), **mandates Apollo**, and requires a **byte-diff of the unedited
> non-group branch**. If the Director rules Arm B, **Mars STOPS and re-scopes R1/R2 before building** (the touch-set,
> the risk grade, and the gate all change).
>
> **THE VERB-NAME RULING — Venus recommends → `reap_group/3`.** `reap_group(conn, queue, group)` — arity 3, the
> `drain/3` precedent (a host-driven `Lanes` verb over an inline declared-keys script, the group gated at `lane_key!/2`
> before the wire). Confirm or re-pin before R1 builds.
>
> **VERSION — the fence climbs in lockstep (D-3, the reopened Fork-2).** emq.4.2 climbs **2.4.1 → 2.4.2** across
> BOTH the `mix.exs` label AND the connector `@wire_version` / `{emq}:version` fence — they carry the same number and
> move together per rung. The connector fence **logic** stays frozen (only the constant moves); the `:fence`
> conformance scenario + `connector_test` are version-agnostic (assert the live key `== Connector.wire_version()`), so
> they never need a per-rung edit; the bump re-seeds `{emq}:version` once via `DEL`. This is one minor step on the
> climb to `echomq:3.0.0` — the **MAJOR** ratified at emq.8 (the horizon the Director tracks), not this rung.

## The as-built floor (verified at the design run, 2026-06-18 — the build's Stage-0 RE-PROBES each; the lag-1 law)

Anchors drift; a sibling rung could move the `echo_mq` surface before emq.4.2 reads it — the build's Stage-0 reconcile
re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (the pre-build floor = **54**, ending
  `flow_grandchild_fail`; the emq.4.1 entries `reassign`/`lane_drain` present at `:118`/`:119`). **The seed's "52" is
  STALE (pre-emq.4.1 ship) — the floor is 54 → 55.** `conformance_run_test.exs:47` `{:ok, 54}`;
  `conformance_scenarios_test.exs` `@run_order` 54 names; both module docs "fifty-four".
- **`@reap` (BYTE-FROZEN — the EXACT mechanism the new sweep models on)** — `jobs.ex:341-369`: the server clock
  (`redis.call('TIME')` + `now = t[1]*1000 + math.floor(t[2]/1000)`); `ZRANGEBYSCORE active -inf now LIMIT 0 100` (the
  expired window); the group branch — `HGET jk 'group'`, `HINCRBY gactive g -1` (`HDEL` at `<=0`), `ZADD g:<g>:pending
  0 id`, the re-ring guard (`SISMEMBER paused == 0` + `act < glimit` + `not LPOS ring` → `RPUSH ring` + `LPUSH wake` +
  `LTRIM wake 0 63`), `HSET jk 'state' 'pending'`. `reap/2` host verb `jobs.ex:719`.
- **`@sweep_stalled` + `Stalled.check/3` (BYTE-FROZEN — the second group-aware recovery surface)** — `stalled.ex:50-95`
  (the group recovery into its lane at `:76-85`, the same re-ring guard) + `:106-129` (`KEYS=[active,pending,dead]`,
  `ARGV=[base,max_stalled,limit]`). The **proof the group-recovery branch is already duplicated** (V-1 steward).
- **`lane_key!/2` (the branded gate)** — `lanes.ex:337` (**`defp`**; RAISES unless `BrandedId.valid?/1` — INV4). The
  new `reap_group/3` gates `group` here before the wire.
- **`drain/3` + `@gdrain` (the host-verb structural precedent)** — `lanes.ex:319`/`:294` (`KEYS=[queue_key(""),
  lane_key!(group), queue_key("ring")]`, `ARGV=[group]`; declares `KEYS[1]`=base, derives `jk = base..'job:'..id` the
  KEYS-rooted A-1 form, no clock, `{:ok, n}`). The new `reap_group/3` is this host-verb shape with `active` in `KEYS[]`
  + the server clock inside.
- **`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/`@gdrain` (BYTE-FROZEN — INV1/INV3)** — `lanes.ex`.
- **The group-field readers the sweep keeps honest (NOT edited; the sweep does NOT `HSET 'group'`)** — `jobs.ex`
  `@complete` `HGET <row> 'group'` (**:182**), `@retry` (**:259**), `@promote` (**:320**), `@reap` (**:349**);
  `stalled.ex` (**:62**). **The sweep is a PURE READER of `group`** (reads to filter `g == target` + find the lane; the
  member returns to its own lane, `group` unchanged) — so no read-site drifts. The write→read cycle the scenario proves
  is **`gactive`** (the sweep `HINCRBY gactive g -1`, the same counter `@reap` keeps).
- **`Keyspace.queue_key/2` / `job_key/2`** — `keyspace.ex:14`/`:17` (`queue_key` → `emq:{q}:<type>`; `job_key` gates
  `BrandedId.valid?/1`, RAISES). `active` = `queue_key(queue, "active")`.
- **No existing group-scoped recovery verb** — grep-confirmed empty (`reap_group`/`sweep_group`/`group_reap`/a `:group`
  option on `reap`/`check` — none; the surface is genuinely NEW, PROPOSED).

## The pipeline — the NORMAL rung (Venus → Mars-1 → Director review → Mars-2 → Director ship; Apollo optional)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md` charter,
LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds
the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt charter → aaw ceremony →
the stage block → audit directive → propagation clause → report). **Require artifact-level checkpoints** (SendMessage a
concrete report after each pass; the Director's ground-truth verification is the gate, not the self-verdict).

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the build-choice recommendation

**(DONE this design run — Stage 1.)** Directive: author the full emq.4.2 triad (`.stories.md` /
`.prompt.md`), reconciled lag-1 against the as-built tree. Re-probe every anchor above; pin the conformance count (**54**
— reconcile the seed's stale 52); confirm the denormalized-`group`-field read-sites (the sweep is a pure reader — no
write→read corruption); state the A-1 declared-keys posture (`KEYS[2]`=base root); recommend the build choice (**Arm
A**) + the verb name/arity (`reap_group/3`). Gate: the triad authored; the reconcile delta table; the BUILD-GRADE
verdict; the build choice + the verb-name surfaced for the Director's ruling. **At the build's Stage 0, Mars RE-PROBES
the floor (the lag-1 law — a sibling rung could have moved an anchor).**

### Stage 1 — Mars-1 (implementor): build the group-scoped sweep

Directive: after the build choice (Arm A) + the verb-name/arity are ruled, build EMQ.4.2-D2 → D6 to the brief's agent
stories (AS1–AS2) and the design. The order: (1) the inline `@greap_group` script (**byte-model the `@reap` group
branch** — the server clock `redis.call('TIME')`, the `ZRANGEBYSCORE active -inf now` window, the group branch with a
`g == ARGV[1]` filter, the re-ring guard from `@reap`; **a NEW script — `@reap`/`@sweep_stalled` byte-frozen**; **no
`HSET 'group'`** — the member returns to its own lane) + the `reap_group/3` host verb (gate the `group` at
`lane_key!/2`; `KEYS=[active, queue_key("")]`, `ARGV=[group]`; map the count to `{:ok, n}`); (2) the `reap_group`
scenario in `conformance.ex` (the **two-group scoping** proof — defeats a no-op) + the count re-pin 54 → 55 in both pin
tests; (3) the `:valkey` suite; (4) the version bump `mix.exs` 2.4.1 → 2.4.2. Cite the spec/design line for every public
call; **declared keys** (every key in `@greap_group` in `KEYS[]` or rooted from `KEYS[2]` — the A-1 lint; NO key read
from a data value — INV3); **inline `Script.new/2`** (no `priv/`); **server clock** (`TIME` inside the script — INV2;
NO host timestamp); register the conformance scenario + probe **in the same change** (INV5, the additive-minor law; the
prior 54 byte-unchanged; re-pin the count in both pin tests); compile clean (`--warnings-as-errors`, per-app). **INV1
gate**: `@reap`/`@sweep_stalled` + the lane scripts byte-unchanged (`grep redis.call` on those scripts in the lib diff
= 0). Gate: per-app compiles green; D2–D6 exist; the diff stays inside `echo_mq` (no `echo_wire`, no `keyspace.ex`
grammar edit, no `jobs.ex` edit, no `stalled.ex` edit, no `apps/echomq`); the boundary grep empty.

### Stage 2 — Director: solo review (a REAL pass)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + ≥1 adversarial probe: the **declared-keys** F-1
probe on `@greap_group` (every key declared/rooted from `KEYS[2]`; no hash-field-to-key derivation; the v1
data-value-rooted form NOT lifted); the **server-clock** probe (the expiry is `redis.call('TIME')`, no host timestamp
crosses the lease — INV2; grep the new script for a host time = empty); the **byte-freeze** probe (`grep redis.call` on
`@reap`/`@sweep_stalled`/`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/`@gdrain` in the lib diff =
0; the prior recovery scenarios `reap`/`stalled`/`stalled_group` byte-identical); the **group-scoping** probe (the
load-bearing proof — **two** groups lapse, `reap_group(g)` recovers ONLY `g`'s members into `g:<g>:pending`, leaves
`h`'s members in `active`; a no-op or a missing filter is caught here); the **gactive-coherence** probe (the recovered
member's `gactive[g]` decremented by 1; a claim+complete of the recovered member charges an honest `gactive[g]`); the
**live-lease-exclusion** probe (a member whose lease has not expired is NOT swept — the `ZRANGEBYSCORE` window); the
**paused-lane** probe (a recovered member into a paused/at-ceiling lane enters `g:<g>:pending` but the lane is NOT
re-rung — the guard); the **byte-unchanged conformance** probe (`git diff` shows only additions to `scenarios/0`; the
54 prior scenarios byte-identical); a **mutation spot-check** (Edit-in a fault — e.g. drop the `g == ARGV[1]` filter →
the `reap_group` scenario catches it via `h`'s member being recovered → revert → `git diff --stat` clean, net-zero,
LAW-1a). Produce the REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain re-probe
(`asdf current erlang`) + Valkey 6390 PONG; per-app pure + `:valkey` suites (`TMPDIR=/tmp`, NEVER umbrella-wide;
`--include valkey` for the recovery suites); `Conformance.run/2 → {:ok, 55}` with the prior 54 byte-unchanged + the
`reap_group` scenario probe-registered; a **multi-seed sweep** + an **honest determinism-posture statement** (NORMAL —
the sweep touches a lease but mints no id and starts no process, **no ≥100 loop**; state it explicitly); the version
climbs to 2.4.2 in lockstep (the `mix.exs` label AND the `@wire_version` fence together — D-3; the `:fence` scenario
version-agnostic); coverage tabled with the reason for any gap. REMEDIATE loop MAX 3.
Gate: every ladder item PASS or explained; the conformance tally clean; the byte-freeze grep = 0; the boundary grep
empty.

### Stage 4 (optional) — Apollo (evaluator) — the fast-finisher (NORMAL rung)

Directive (optional on a NORMAL rung — the Mentor as a closure fast-finisher, NOT mandatory): a light post-build
reconcile (as-built ⇄ spec) + the stories closure (the Coverage map traces every D-n to a story; the determinism
posture stated honestly). If engaged, render a closure note + ≥1 mentoring observation folded forward
(Director-ratified). **Mandatory only on a high-risk rung — not this one** (the recovery + lane scripts are byte-frozen
by design, the sweep is a non-destructive lane-return, no destructive at-rest op). **If the Director rules Arm B
(edit a shipped sweep), Apollo becomes MANDATORY** (a frozen-line touch on a lease-critical recovery script).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the `EchoMQ.Lanes.reap_group` real arity; the `@greap_group` real key
declarations + the filter form; the ruled verb/arity; the final conformance N; the version 2.4.2); every triad claim
MATCH or `[RECONCILE]`-marked; fold the parity proof ([`../../../emq.features.md`](../../../../emq.features.md) Part B /
the groups feature records) to mark the group-scoped recovery axis discharged. **The backward reconcile is owed** (the
emq.4.1 lesson F6 — a forward-only reconcile lets the committed spec drift from as-built; sync the forward-tense brief
to what shipped so emq.4.3 reconciles against truth).

### Stage 6 — Director: closure + ONE LAW-4 commit + the family fold

Preconditions (x-mode §4): the gate green + the reconcile build-grade (Apollo BUILD-GRADE if engaged, else the
Director's verify is the gate); **≥1 `tool_x_decision` (D-n)** — at minimum the build-choice ruling (Arm A) + the
verb-name/arity ruling (`reap_group/3`) — + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff
--cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below; NEVER
`git add -A`, NEVER a bare commit). **Same turn:** flip the emq.4.2 row in the single roadmap
([`../../../emq.roadmap.md`](../../../../emq.roadmap.md)) and the dashboard ([`../../../emq.progress.md`](../../../../emq.progress.md));
record the group-aware-recovery axis shipped (the groups family deepening; 4.3–4.4 next); surface the **next frontier**
(emq.4.3 the metronome — HIGH, Apollo mandatory + the ≥100 loop; **Fork A settles before 4.3 builds**; then emq.4.4
weighted/deficit — HIGH iff `@gclaim` edited, **Fork B before 4.4**); under an **explicit Operator grant only**, fold
any mentoring diff into the peer charters / the echo-mq-* skills (one guardrail per finding). The message cites the
slug, the Z-n, the D-n, and the Y-n report.

## Risk tier

**NORMAL.** emq.4.2 adds **one** host recovery verb + **one** new inline script over the shipped `g:`-segment keyspace;
it edits **no** shipped recovery or lane script (the byte-freeze grep on `@reap`/`@sweep_stalled` + the lane scripts =
0), founds **no** process/lease surface (the sweep mints no branded id, starts no process), and performs **no
destructive at-rest op** (the sweep **moves** a lapsed lease back to a lane — distinct from emq.4.1's `drain/3` delete).
It **touches a lease** (reads `TIME` server-side — INV2). The mitigating gates:
1. **The group-scoping correctness (the load-bearing proof).** The sweep must recover **only** the named group's
   expired members (the `g == ARGV[1]` filter) and leave a sibling group's expired members in `active` — the Director's
   **group-scoping probe** (two groups lapse, one recovered, the other left) catches a missing filter; a scenario that
   recovered only one group's members without a sibling present would pass even with the filter absent, so the **TWO-
   group** assertion is mandatory (the gate-liveness law).
2. **The `gactive` coherence.** The sweep `HINCRBY gactive g -1` on recovery (the same counter `@reap` keeps), so a
   later claim/complete of the recovered member charges an honest `gactive[g]` — the Director's **gactive-coherence
   probe** (the recovered member claims + completes, `gactive[g]` correct) + the byte-freeze grep.

**No** id-mint / process hazard is introduced (the sweep mints no branded id, starts no process), so the **≥100
determinism loop is NOT run** — a multi-seed sweep + an honest posture statement is the proof (the lease read is a pure
`redis.call('TIME')`, so the loop would forge load rather than catch a real hazard). **Apollo** the Mentor may engage
as a closure fast-finisher; the Director's verify is the gate of record. **If the Director rules Arm B (edit a shipped
sweep), the rung re-grades HIGH + Apollo MANDATORY + a byte-diff of the unedited non-group branch.**

## The Stage-6 commit pathspec (Director-only — the emq.4.2 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what the
stages truly changed):

```text
docs/echo_mq/specs/emq.4/emq.4.md                          (the family contract + carve + forks, if Stage-5 synced it — e.g. the 52→54 INV6 count)
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.2.md            (the seed, Stage-5 synced — status → SHIPPED, the count 54→55)
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.2.stories.md
docs/echo_mq/specs/emq.4/emq.4.rungs/emq.4.2.prompt.md     (this runbook)
docs/echo_mq/specs/progress/emq-4-2.progress.md
docs/echo_mq/emq.roadmap.md                                (the emq.4.2 row → shipped)
docs/echo_mq/emq.progress.md                               (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/lanes.ex                     (the reap_group/3 verb + @greap_group)
echo/apps/echo_mq/lib/echo_mq/conformance.ex               (the reap_group scenario, additive)
echo/apps/echo_mq/mix.exs                                   (version 2.4.1 → 2.4.2, additive minor)
echo/apps/echo_mq/test/                                     (the reap_group :valkey suite + the conformance pins 54→55)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/live_svelte/**`,
`echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F# course, and any
`[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `echo/apps/echomq` (frozen v1 — the
capability reference) + `echo/apps/echo_wire` (the sweep rides the shipped connector) +
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (no grammar edit) + `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@reap`
byte-frozen — the sweep WRITES no field `jobs.ex` reads; `group` a pure read; **no `jobs.ex` edit expected**) +
`echo/apps/echo_mq/lib/echo_mq/stalled.ex` (`@sweep_stalled` byte-frozen — **no `stalled.ex` edit expected** under Arm
A) + `echo/mix.lock` (emq.4.2 adds no dep — expect `mix.lock` EXCLUDED) UNTOUCHED. **Never `git add -A`.** (Under Arm
B, `jobs.ex` or `stalled.ex` WOULD be edited — adjust the pathspec to the ruled arm.)

## Acceptance — "shipped" means

Every DoD box in [`./emq.4.2.md`](emq.4.2.md) is checkable from the run's outputs: the build choice (Arm A) +
verb-name/arity ruled before any artifact; the `reap_group/3` verb + `@greap_group` (D2 — a named group's expired-lease
members recovered into `g:<g>:pending` at score 0, branded-gated, `gactive` decremented, the lane re-rung if
serviceable + a wake, server clock; the `g == ARGV[group]` scoping filter — a sibling group left in `active`); the
non-group recovery path byte-unchanged (`@reap` + `@sweep_stalled` byte-frozen — INV1); the `reap_group` scenario
additive-minor with the prior 54 byte-unchanged + the count re-pinned 54 → 55 in both pin tests (D5); the `:valkey`
suite green + the multi-seed sweep + the honest determinism-posture statement (NORMAL, no ≥100 loop) + no regression +
the shipped recovery/lane scripts byte-frozen + the version 2.4.2 (D6). The spec body stays authoritative; Stage 5
syncs it to the as-built surface (the backward reconcile owed); the groups family deepening (emq.4.3–4.4) opens on a
proven recovery surface.

Inputs: [`./emq.4.2.md`](emq.4.2.md) · [`./emq.4.2.stories.md`](emq.4.2.stories.md) · Family: [`../emq.4.md`](../emq.4.md) (the deepening contract + the carve +
the forks) · Canon: [`../../../emq.design.md`](../../../../emq.design.md) §10 seam 2 / §4 cluster 2 / §4 / S-1/§6 / S-6 /
§5 · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md) Movement II · The feature catalog:
[`../../../emq.features.md`](../../../../emq.features.md) (the groups records) · The shape model:
[`./emq.4.1.prompt.md`](emq.4.1.prompt.md) (the sibling control-plane runbook) · Skills:
`.claude/skills/echo-mq-ship.md` (the binding) + `echo-mq-{architect,implementor,evaluator}.md` (the per-role craft) +
`echo-mq-program.md` (the program law) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
