# EMQ.4.2 · user stories — group-aware recovery (the group-scoped stalled-sweep)

> Who wants group-scoped recovery, what they need, and how we know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements line;
> the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing **`EMQ.4.2-US-GATE`** carries
> the Valkey gate (design §7) — a structural gate. emq.4.2 is the SECOND sub-rung of the groups-deepened family
> (Movement II): **group-aware recovery** — recover **one named group's** lapsed leases on demand, returning each
> expired-lease member to **its own lane** (`emq:{q}:g:<group>:pending`, not a global pool), respecting the ring, on
> the **server clock** — over the **shipped** `EchoMQ.Jobs.@reap` / `EchoMQ.Stalled` group-aware recovery pattern, with
> **no** shipped-recovery-script edit (the build choice is **additive-beside**, the reconcile's ruling). Forward-tense:
> every emq.4.2 surface is PROPOSED, NOT shipped. The spec **body** [`./emq.4.2.md`](emq.4.2.md) (and the family
> [`../emq.4.md`](../emq.4.md)) is authoritative — when a derived artifact disagrees with the body, the body wins.
> **Risk: NORMAL** — it deepens a proven group-aware recovery pattern; the genuine delta is the **group-SCOPED** entry,
> not a new recovery shape; the sweep touches a lease (server clock — INV2) but mints no id and starts no process →
> the proof is a multi-seed sweep + an honest determinism statement, NOT the ≥100 loop.

## EMQ.4.2-US1 — an operator recovers one tenant's lapsed leases on demand (the headline group-scoped sweep)

As a **multi-tenant bus operator**, I want to recover the expired-lease members of **one named group** on demand, so
that when a tenant's worker fleet crashes I can return its in-flight work to **that tenant's** lane immediately —
without a queue-wide scan, and without its work jumping the ring ahead of other tenants.

Acceptance criteria
- Given a **named branded group** `g` with one or more **expired-lease** members in `active`, when
  `EchoMQ.Lanes.reap_group(conn, queue, group)` is called, then **only** the expired-lease members **whose row
  `group` field equals `g`** are recovered: each leaves `active`, returns to **`emq:{q}:g:<g>:pending`** at score 0
  (its mint-ordered place kept), the group's `gactive` is decremented (`HINCRBY <gactive> g -1`, `HDEL` at zero), the
  lane is **re-rung if serviceable** (unpaused, below its `glimit`, not already on the ring) with a **wake** pushed for
  any parked consumer — the call answers `{:ok, n}`, the count recovered. The expiry is computed from the **server
  clock** (`redis.call('TIME')` inside the script), never a host timestamp.
- Given a **second group** `h` whose members **also** have expired leases in the same `active` set, when
  `reap_group(conn, queue, g)` runs, then `h`'s expired members are **left in `active`** (not recovered) — the sweep is
  **scoped to `g`** by the `HGET <row> 'group' == g` filter; a subsequent `reap_group(conn, queue, h)` recovers `h`'s
  members into `g:<h>:pending`. This group-scoping is the **delta** over the shipped queue-wide `@reap`/`Stalled.check/3`,
  which recover **every** expired lease in one pass.
- Given an **ill-formed** group id, when `reap_group/3` is called, then it **raises** before any wire (the group is
  gated `EchoData.BrandedId.valid?/1` at the lane-key builder `lane_key!/2`, `lanes.ex`); a **well-formed group with no
  expired members** answers `{:ok, 0}` (nothing to recover), changing nothing.

INVEST — independent (the family's group-scoped recovery verb); testable by the `reap_group` `:valkey` scenario (two
groups both lapse → recover ONE → only that group's members on its lane, the other still in `active`; `gactive`
decremented; the lane re-rung; `{:ok, 0}` on a group with no expiry); encodes EMQ.4.2-INV2 (server clock),
EMQ.4.2-INV3 (no new key family, ring-respecting), EMQ.4.2-INV4 (branded group, recovered to its own lane). Priority:
must · Size: 3 · Implements: EMQ.4.2-D2.

## EMQ.4.2-US2 — the recovered member is served in its own lane's rotation, the ceiling stays honest

As a **bus consumer running per-tenant lanes**, I want a group-scoped-recovered member to be claimed as part of **its
own** lane's fair rotation and to leave the group's `gactive` correct, so that recovery is complete — fairness and the
concurrency accounting follow the member back to its lane, with no stale `gactive` left behind.

Acceptance criteria
- Given a member recovered by `reap_group/3` into `g:<g>:pending`, when the ring is rotated and `g` is served
  (`EchoMQ.Lanes.claim/3`), then the member is returned **with `group = g`** (the shipped `@gclaim` reads the lane head
  and the row's group — **unchanged**, the sweep does **not** rewrite `group`), and a subsequent completion decrements
  **`gactive[g]`** correctly — because the sweep **decremented `gactive[g]` by 1** when it returned the lease to the
  lane (mirroring the shipped `@reap` group branch `jobs.ex`), so the in-flight count is honest at every step. The
  `group` field is a **pure read** for the sweep (the recovered member's lane is unchanged — it returns to **its own**
  `g:<g>:pending`), so no read-site of `group` drifts (the `@complete`/`@retry`/`@promote`/`@reap` readers see the same
  value).
- Given a member whose lease has **not** expired (still in `active`, lease live), when `reap_group/3` runs for its
  group, then it is **not** recovered (the `ZRANGEBYSCORE active -inf now` window excludes a live lease, the shipped
  `@reap` expiry test) — only lapsed leases are swept; a live token still settles normally.
- Given the recovered lane was **paused** or **at its ceiling**, when the member is returned to it, then the member
  enters `g:<g>:pending` but `g` is **not** added to the ring (the re-ring guard `SISMEMBER paused == 0` and
  `gactive < glimit`, the shipped `@reap`/`@sweep_stalled` guard, byte-modelled into the new script) — recovery
  respects the lane's serviceability exactly as the shipped reaper does.

INVEST — independent (the recovery's correctness past the lane-return); testable by the `reap_group` scenario claiming
the recovered member from its lane (group = `g`) and a completion decrementing `gactive[g]`, plus the live-lease
exclusion and the paused-lane no-re-ring; encodes EMQ.4.2-INV3 (ring-respecting, `gactive` honest), EMQ.4.2-INV4 (the
member returns to its own lane). Priority: must · Size: 3 · Implements: EMQ.4.2-D2.

## EMQ.4.2-US3 — the non-group recovery path is byte-unchanged; the new behavior is additive; the prior set is untouched

As a **protocol maintainer**, I want the group-scoped sweep to ride the shipped lane keyspace under the declared-keys
law, to edit **no** shipped recovery script, and to grow conformance only additively, so that group-aware recovery
costs the wire nothing — no new key family, no broken scenario, no lease-critical-script edit, no new wire class.

Acceptance criteria
- Given the **additive-beside** build choice (the reconcile's ruling — a NEW inline script + NEW host verb), when
  emq.4.2 lands, then the shipped per-job `@reap` (`jobs.ex`) and the queue-wide `@sweep_stalled` (`stalled.ex`) are
  **byte-identical to HEAD** (`grep redis.call` on those scripts in the lib diff = 0), and a job with **no group**
  flows through them exactly as before — the **non-group recovery path is byte-unchanged** (INV1). The group-scoped
  sweep is reached **only** through the new `reap_group/3` verb; it never alters the queue-wide reaper or the stall
  sweep.
- Given the new `@greap_group` script, when the A-1 lint scans it, then **every** key is a shipped `g:`-segment lane
  key (`g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake`) plus the declared `active` set and the
  job row — each in `KEYS[]` or derived from a declared `KEYS[n]` root by the registered grammar (the job row + the
  lane derive from the declared queue-base root `KEYS[2]`, the `@gdrain` KEYS-rooted convention) — and **no** key is a
  new family, **no** key is read out of a data value, and the script returns a **count** (no `error_reply`, so the
  closed wire-class registry stays unextended).
- Given the prior conformance set, when `reap_group` is added, then the **54** prior scenarios pass **byte-unchanged**
  (name + contract + verdict body, git-verified), the new scenario is registered **with its probe in the same change**
  (`conformance.ex`), and the count re-pins **54 → 55** in **both** pinning tests (`conformance_scenarios_test.exs` +
  `conformance_run_test.exs` `{:ok, 55}`); `EchoMQ.Conformance.run/2` prints 55 lines.

INVEST — independent (the wire-cost contract); testable by the byte-freeze grep on `@reap` + `@sweep_stalled` + the
A-1 lint on `@greap_group` + the git-verified byte-unchanged 54 + the re-pinned 55; encodes EMQ.4.2-INV1,
EMQ.4.2-INV3, EMQ.4.2-INV5. Priority: must · Size: 2 · Implements: EMQ.4.2-D5.

## EMQ.4.2-US4 — group-aware recovery is proven; the determinism posture is honest; no regression

As a **program Director**, I want the group-scoped recovery suites proven on the certified wire, the determinism
posture stated honestly, and the shipped surface unregressed, so that emq.4.2 closes on a proven recovery surface, not
a false-green.

Acceptance criteria
- Given the `reap_group` + the group-scoped recovery `:valkey` suites, when they run per-app inside
  `echo/apps/echo_mq` (`TMPDIR=/tmp`, `--include valkey`), then they are green against **Valkey on port 6390** (the
  truth row), and `EchoMQ.Conformance.run/2` over a live connection prints `{:ok, 55}` with the prior 54 byte-unchanged.
- Given the sweep **touches a lease** (it reads `TIME` to compute expiry) but **mints no branded id**, **starts no
  process**, and **does not contend on a same-millisecond mint**, when the rung is verified, then the proof is a
  **multi-seed sweep** + an **honest determinism-posture statement** (the **≥100-iteration loop is NOT run** — there is
  no id-mint/process hazard the loop guards; the lease read is a pure `redis.call('TIME')` with no host clock, so the
  loop would forge load rather than catch a real hazard), and that posture is recorded. The rung grades **NORMAL** —
  no shipped-script edit, no destructive at-rest op (the sweep **moves** a lease back to a lane, it does **not**
  delete), no new process/lease surface.
- Given the shipped surface, when emq.4.2 lands, then the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4,5} + emq.4.1 suites
  + `Conformance.run/2` pass **unchanged** (no regression — INV1), the diff stays inside `echo/apps/echo_mq`
  (no `echo_wire`, no `keyspace.ex` grammar edit, no `apps/echomq`), and the boundary grep is empty.

INVEST — independent (the proof + the honest NORMAL-risk posture); testable by the `:valkey` suites green + the stated
determinism posture (multi-seed sweep, no ≥100 loop) + the prior suites unchanged + the boundary grep empty; encodes
EMQ.4.2-INV1, EMQ.4.2-INV2. Priority: must · Size: 2 · Implements: EMQ.4.2-D6.

## EMQ.4.2-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the group-scoped recovery proven on the certified wire under honest-row reporting, so
that the v2 laws bind at the wire and a host without Valkey reports its row honestly (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the recovery suites run, then they run
  against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey runs the
  probes elsewhere and reports them as that row, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns the connector's current wire version
  (`Connector.wire_version/0` — `echomq:2.4.2` at this rung); the fence **climbs per rung** (D-3, the reopened
  Fork-2), so the gate asserts the live key **tracks the constant**, never a frozen literal — the `:fence`
  conformance scenario reads `== Connector.wire_version()`. emq.4.2 leaves the fence **logic** untouched and the
  five-code error union stands unextended (INV3).
- Given grammar totality, when a lane key is parsed, then it classifies under the §6 grammar (the `g:<group>:pending`
  / `ring` / `paused` / `glimit` / `gactive` / `wake` members + the `job:<id>` row + the `active` set), the queue name
  extracts as the `{q}` hashtag, and `q ≠ "emq"` keeps the slot families disjoint — emq.4.2 edits the grammar's shape
  **not at all** (INV3).
- Given the conformance run, when `EchoMQ.Conformance.run/2` executes over a live connection, then it prints one line
  per scenario, the prior **54** are byte-unchanged, and `reap_group` is present (the count re-pinned 54 → 55 in both
  pinning tests — the additive-minor law).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` + grammar
totality + the additive-minor conformance; encodes EMQ.4.2-INV3, EMQ.4.2-INV5. Priority: must · Size: 1 · Implements:
design §7, S-4 (the structural gate).

## Coverage

| Deliverable | Story |
|---|---|
| EMQ.4.2-D2 — `Lanes.reap_group/3` + `@greap_group` (a named group's expired-lease members recovered into `g:<g>:pending`, score 0, `gactive` decremented, the lane re-rung if serviceable + a wake, server clock; the group-scoping filter `HGET <row> 'group' == g`; the count returned) | US1, US2 |
| EMQ.4.2-D5 — the non-group path byte-unchanged (`@reap` + `@sweep_stalled` byte-frozen) + the `reap_group` conformance (additive minor; 54 → 55; no new key family; A-1 declared-keys) | US2, US3 |
| EMQ.4.2-D6 — the proof (the `:valkey` suites; NORMAL-risk; the honest multi-seed-sweep / no-≥100-loop posture; no regression; the boundary clean) | US4 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | US-GATE |

Spec body: [`./emq.4.2.md`](emq.4.2.md) (authoritative) · Family: [`../emq.4.md`](../emq.4.md) (the contract + the carve + the forks) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US2 — group-aware recovery).
