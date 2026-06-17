# EMQ.1-D1 · The A-1-compatible scheduler design — ADOPTED-AS-BUILT

> **Status: ADOPTED-AS-BUILT.**

## 0 · Context — the problem, the constraint, the as-built floor

**The §11.10 problem.** The design canon defers the scheduler family typed-never-silent because the v1
family's forms "root key operands in data values, structurally inexpressible under the declared-keys
invariant"; "an A-1-compatible flow design is real design work for the family rungs"
([`../emq.design.md`](../../emq.design.md) §11.10). This document is that design work for the scheduler
half (the flow half is the program ladder's emq.3, out of scope).

**Design constraint:** mint-ordered ids stay the sort key; a delay is a visibility fence, not a new queue." Also
from the same row: the retry vocabulary is "attempts-with-backoff on the lease/reap base; the
max-attempts blind spot … closes here, gated by a poison-job drill", and "Connector auto-resubscribe
after reconnect (today the table's restart is the resubscription)".

**The as-built floor.** Much of the substrate already exists:

- **The schedule set exists.** `emq:{q}:schedule` is live, run-at-scored in server-clock milliseconds:
  the retry script parks into it (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:153-154`, keys at `:245`;
  every later `jobs.ex` cite names this file) and the promote script sweeps it
  due-first (`ZRANGEBYSCORE '-inf', now LIMIT 0 batch` — script at `jobs.ex:158-185`).
- **The wire half of retry exists.** `EchoMQ.Jobs.retry/7` (`jobs.ex:242`) takes a LITERAL `delay_ms` +
  `max_attempts`, answers `{:ok, :scheduled} | {:ok, :dead}`, keeps `last_error`, dead-letters into
  `emq:{q}:dead` at the cap. What is missing is the host-side policy computing `delay_ms` (ADR-3).
- **The release verb exists.** `EchoMQ.Jobs.promote/3` (`jobs.ex:268`) moves due scheduled jobs to
  pending (group-aware: a grouped job re-enters its lane). What is missing is the cadence process that
  calls it (ADR-4).
- **The state vocabulary already carries `scheduled`** (`jobs.ex:153` writes `state, 'scheduled'`), so
  scheduled-at-admission introduces no new row state.
- **The connector holds no subscription registry.** `subscribe/2`
  (`echo/apps/echo_wire/lib/echo_mq/connector.ex:104` — the wire trio's post-extraction home; every
  later `connector.ex` cite names this file) rides
  `push_command` (RESP3); the init state map (`connector.ex:129-158`) carries `push_to`/`pushes` but no
  subscription set; the `:reconnect` success arm (`connector.ex:284-287`, after `do_connect`
  re-negotiates the protocol) re-issues nothing — the 2.1 gap, verified at the exact seam. No
  unsubscribe verb exists. A `[:emq, :connector, :reconnect]` telemetry event already fires
  (`connector.ex:286`).
- **The script convention is inline.** Scripts are `Script.new/2` module attributes
  (`echo_wire/lib/echo_mq/script.ex`; e.g. `@enqueue` at `jobs.ex:14-24`), not `priv/` files. The
  triad's "new Lua under `priv/`" line was therefore flagged for reconcile, and the Stage-4 reconcile
  CORRECTED it: emq.1 follows the as-built inline convention (`@schedule` in `jobs.ex`,
  `@register`/`@cancel`/`@advance` in `repeat.ex`); no `echo_mq/priv/` directory exists.
- **The key-construction convention as-built:** every script declares its structure keys in `KEYS[]`;
  the queue base travels as an ARGV; per-job and lane keys derive in-script from that base plus set
  members (`base .. 'job:' .. id`, `base .. 'g:' .. g .. ':pending'` — the claim/promote/retry/reap
  precedent). §7 takes this up — it is the heart of the A-1 question.

## 1 · Design input — the carried Keyspace seam (D-10)

The dependency-free `echo_wire`'s connector reads `EchoMQ.Keyspace.version_key/0` at fence time across
the app boundary (the emq-0 run's ratified deviation; the run ledger D-10 carries the resolution to
exactly this gate). The arms, with consequences — **not decided here**:

- **Arm A — inline the constant.** `"{emq}:version"` lands beside `@wire_version` in `connector.ex`;
  the `no_warn_undefined` entry in `echo_wire/mix.exs` retires; the wire app becomes self-contained
  (and the per-app wire-suite placement deviation may also resolve). Cost: the literal exists in two
  modules — guarded by one cross-app test asserting equality.
- **Arm B — move `version_key/0` into `echo_wire`.** The fence fact lives where the fence runs; the
  `EchoMQ.*` namespace is frozen either way. Cost: `echo_mq`-side callers (the conformance fence
  scenario, the rung scripts' loaders) re-point — a larger diff than A for the same property.
- **Arm C — do nothing.** Keep the cross-app runtime read + the annotation (the ratified Stage-2
  as-built). Honest and shipped; the wire app's "depends on nothing" stays nominal rather than literal.

Interaction noted: ADR-5 edits the same `connector.ex`; whichever arm rules, the diffs compose.

## 2 · ADR-1 — scheduled enqueue (run-at / run-in) as a visibility fence

**Alternatives.** (a) *Do nothing* — callers enqueue when due: the intent is not durable (a crashed
caller loses it), client clocks order the work, and the 2.1 row stays empty. Rejected. (b) *A delayed
queue* — a second pending structure per delay class: rejected by the constraint verbatim ("a delay is a
visibility fence, not a new queue"). (c) **Chosen-proposed: park-on-schedule at admission.**

**The proposed shape (all forward — emq.1 builds it).** New verbs `enqueue_in(conn, queue, id, payload,
delay_ms)` and `enqueue_at(conn, queue, id, payload, run_at_ms)` over ONE new script: kind law as the
first act (the `@enqueue` precedent verbatim, `jobs.ex:15-17`), duplicate refusal, the three-field row
written with `state = 'scheduled'`, and `ZADD emq:{q}:schedule` with the run-at score. For run-in the
score is computed wire-side from `TIME` (the DQ-2c server-clock law, the `@claim`/`@retry` precedent);
for run-at the caller passes absolute ms — a documented client-clock surface for the SCORE only (the
sub-fork in §8: settlement and end-of-day work are calendar-anchored, so run-at is the consumer's named
need; the fence and lease laws are untouched by it). Keys: `KEYS[1]` = the job key, `KEYS[2]` = the
schedule set — both declared. The release path is the EXISTING promote sweep; scheduled enqueue adds no
release machinery.

**The order theorem under the fence, stated explicitly.** The id mints fresh at admission; the schedule
score is only visibility. When promoted, the member enters pending at score zero, where same-score lex
order = byte order = MINT order — so a job minted earlier but scheduled later sorts, once visible, by
its mint. That is the constraint's meaning: ordering claims attach to the mint instant, never to the
visibility instant.

## 3 · ADR-2 — repeatable jobs: a registration, a fresh mint per occurrence

**Alternatives.** (a) *Do nothing* — callers run their own cron and enqueue: the platform's named need
(EOD reporting, the periodic reconciliation sweep) stays caller-side, unrecorded by the bus. Rejected
as the row's answer. (b) *Re-enqueue a template job by reusing its id* — rejected on the identity law:
completion-deletes retire the row, and id reuse breaks both the order theorem and the dedup semantics.
(c) **Chosen-proposed: a registration surface swept by the pump, minting a FRESH branded `JOB` id per
occurrence** (EMQ.1-INV3; the mint is host-side — ids are producer-minted, §11.2 B′; the wire never
mints).

**The proposed shape (PROPOSED keys — a registry extension, additive minor, registered with probes).**
`emq:{q}:repeat` — a sorted set scored by next-run ms, members = registration names; per-registration
record at `emq:{q}:repeat:<name>` — a hash carrying `every_ms` and the payload template. The pump's
sweep reads due registrations (`ZRANGEBYSCORE` on the declared registry key), mints fresh ids
host-side, enqueues each occurrence through the ADR-1 script (or directly to pending when due now), and
advances the registration's score. Registration and cancellation verbs write/remove the pair with both
keys declared. The exact key spelling extends §6's closed registry — the extension is spelled against
the grammar and sits in §8 for approval (key shape = fork 3).

## 4 · ADR-3 — the backoff vocabulary, host-side

**Alternatives.** (a) *Do nothing* — every caller computes `delay_ms`: the max-attempts blind spot
stays open (policy has no home; the cap is a bare per-call argument). (b) *Wire-side backoff* — the
script computes the delay from `attempts`: rejected by the standing HOLD ([`../emq.design.md`](../../emq.design.md)
§4 row 30 — backoff above the wire; the wire takes literal delays; the as-built `@retry` confirms:
`ARGV[3]` is a literal). (c) **Chosen-proposed: `EchoMQ.Backoff` — a pure module** (no process, no
clock): policy values (fixed · exponential with base and cap · jitter as a wrap), one function from
(policy, attempts) to `delay_ms`, feeding `Jobs.retry/7` unchanged. Max attempts lives in the consumer
configuration beside the policy. **The poison-job drill** closes the blind spot as a recorded check: a
persistently raising handler dead-letters after exactly max attempts with `last_error` browsable in the
morgue (the `dead` conformance scenario already pins that shape; the drill extends it under the
additive law).

## 5 · ADR-4 — the promote pump: supervised, opt-in, pure-cored

**Alternatives.** (a) *Do nothing* — promote stays a manual/consumer-loop call: scheduled work has no
standing release cadence; a consumer's run-at work would depend on incidental traffic.
(b) *Engine-side eventing* (keyspace notifications waking the sweep): a cadence improvement candidate,
but fire-and-forget delivery and engine-posture configuration make it an augmentation to evaluate at a
later rung, not the baseline. (c) **Chosen-proposed: a supervised, OPT-IN cadence process** — the
Consumer is the process-shape precedent (`consumer.ex` — `child_spec` `:18`, `start_link` `:35`,
`stop/2` `:78`, the loop at `:91`): a pure decision core (next-tick and batch arithmetic as plain
functions) under a thin shell that calls `Jobs.promote/3` and the ADR-2 repeat sweep on each tick;
tick interval and batch size are configuration; restart semantics stated in the child spec. A worker
started without the pump is the v2 core worker, unchanged (EMQ.1-INV5). Whether one pump carries both
sweeps (promote + repeat) or two processes split them is fork 5 — one process, one cadence is the
recommended arm.

## 6 · ADR-5 — connector auto-resubscribe at the `:reconnect` seam

**Alternatives.** (a) *Do nothing* — "today the table's restart is the resubscription" (the 2.1 row
verbatim): the Table self-heals by restart, but every new claims-bus subscriber the platform adds would
inherit restart-as-recovery. (b) *Caller-side re-subscribe* — the connector already emits
`[:emq, :connector, :reconnect]` telemetry (`connector.ex:286`); each subscriber hooks it and
re-issues. Steelman: the connector stays stateless; cost: every subscriber re-implements the same
recovery, and a missed hook is silent message loss. (c) **Chosen-proposed: the connector records its
subscription set** — a set in the connector state, added on `subscribe/2` success — **and re-issues
each `SUBSCRIBE` in the `:reconnect` success arm** (`connector.ex:284-287`, after `do_connect` has
re-negotiated RESP3, so the push channel is live). No unsubscribe verb exists as-built; a companion
`unsubscribe/2` keeps the recorded set truthful (fork 6 — small). The honest gap, stated: pub/sub is
fire-and-forget, so messages during the disconnect are lost either way — at-most-once on the push
channel; the cache's versioned claims + staleness fence already tolerate exactly this (the design's
§12.3 ground). The `EchoWire` facade grows by at most the companion verb.

## 7 · The A-1 compatibility argument — every key declared or grammar-derived

**The v1 flaw, restated.** v1 scripts build operand keys from an `ARGV` prefix inside the body with no
closed grammar, so no static analysis can enumerate what a transition touches
([`../emq.design.md`](../../emq.design.md) §0).

**The as-built v2 convention (the ground emq.1 inherits).** Every script declares its structure keys in
`KEYS[]`. The queue base travels as an ARGV, and the only in-script constructions are the registered
shapes derived from that base plus a set member: the per-job key (`base .. 'job:' .. id` — claim,
promote, retry, reap) and the lane family (`base .. 'g:' .. g .. ':pending'`, `gactive`, `glimit`,
`paused`, `ring`, `wake`). Every derived key carries the same `{q}` hashtag (slot-sound, the
co-location law) and only the registered shapes are derivable (§11.9's registered derivation grammar;
§4 row 28's sanctioned construction).

**The letter-vs-form nuance, flagged for this gate.** S-6's letter says "derived in-script only from a
declared `KEYS[n]` root"; the as-built form derives from an ARGV-carried base while declaring at least
one `KEYS[n]` of the same queue. Two readings exist: bind the ARGV base to the declared root (hashtag
equality — the lint can check it mechanically), or read strictly (roots must be `KEYS` entries, and the
scripts respell). emq.1's new scripts introduce NO new derivation power either way — they follow the
existing convention — but the A-1 lint that emq.8's proof stack ships needs the reading fixed. Fork 2,
for the Operator.

**The new surface, spelled against §6.** The scheduled-enqueue script declares `[job key, schedule]`
and constructs nothing. The repeat sweep is host-orchestrated: registry reads on declared keys, the
record key derived from the declared registry root by the registered convention, the mint host-side,
each occurrence entering through the ADR-1 script. No script roots any key in a payload or data value;
scores are data, and data never becomes a key.

**Conformance additions (the additive-minor law, [`../emq.design.md`](../../emq.design.md) §5).** Each
addition registers its probe in the same change; the prior 14 scenarios (`conformance.ex` — fence,
mint, duplicate, kind, order, claim, stale, complete, retry, dead, reap, rotate, pause, limit) pass
byte-unchanged (EMQ.1-INV1). Proposed scenario names: `schedule` (run-in parks; the promote sweep
releases; the row reads scheduled), `repeat` (one registration, two occurrences, two DISTINCT branded
ids), `backoff` (the drill: dead at exactly max attempts with `last_error` kept), `resubscribe` (a
subscribed connector loses its socket; after reconnect the channel answers without a caller restart).

## 8 · The six forks — ADOPTED (the relocated EMQ.1-D1 gate's decisions, run ledger D-2..D-7)

Each fork is settled; the arm it took is recorded here and built as named (the as-built surface is in the
triad's reconciled body, [`./emq.1.md`](emq.1.md), and the run ledger Y-1/Y-4). One fork (2) is
DEFERRED, not resolved here.

1. **The D-10 Keyspace seam arm** → **Arm C — keep the annotated cross-app read** (run ledger D-2). The
   `echo_wire` connector keeps reading `EchoMQ.Keyspace.version_key/0` across the app boundary at fence
   time (the emq.0 as-built); the `no_warn_undefined` annotation stays. Arms A/B are a later dedicated
   seam pass, not this rung. §1 carries the consequences.
2. **The A-1 lint's binding rule** → **DEFERRED** (run ledger D-3) — to the canon / the emq.8 proof
   stack. emq.1's new scripts add NO new derivation power (they follow the as-built ARGV-base +
   declared-structure-key convention), so the strict-`KEYS`-root-vs-hashtag-equality reading is not an
   emq.1 blocker. Recorded, decided nowhere; the emq.8 lint forces the reading. §7.
3. **The repeat registry's key shape** → **ADOPTED the proposed spelling** (run ledger D-4):
   `emq:{q}:repeat` (the registry zset) + `emq:{q}:repeat:<name>` (the per-registration record hash),
   both `{q}`-hashtagged, both declared in `KEYS[]`, registered with the `repeat` conformance probe.
   Built in `EchoMQ.Repeat`.
4. **run-at admission** → **ADMIT both** (run ledger D-5): `enqueue_at/5` (the caller's absolute run-at ms
   prices only the schedule score) AND `enqueue_in/5` (the score computed wire-side from `TIME`). The
   consumer's settlement/EOD work is calendar-anchored, so run-at is its named need; the fence and lease
   laws are untouched. Realized as ONE inline `@schedule` script with an `ARGV` mode flag (Director-
   ratified realization-over-literal — Y-1).
5. **The pump's shape** → **ONE opt-in pump carrying both sweeps** (run ledger D-6): `EchoMQ.Pump`, a
   `:transient` supervised child with a pure decision core (`EchoMQ.Pump.Core`), sweeping promote + the
   repeat registry on each tick. A worker without it is the v2 core worker, unchanged (EMQ.1-INV5).
6. **The `unsubscribe/2` companion verb** → **ADDED** (run ledger D-7), beside the recorded subscription
   set, so the set stays truthful (an unsubscribed channel is not re-issued on reconnect). One
   `defdelegate` on the `EchoWire` facade.

## 9 · Out of scope (the triad's fences, carried)

Per-lane stream lanes (a downstream consumer's recorded dependency; the 3.x tier), batches (emq.5), the
parent/flow family (emq.3 — §11.10's other half), any wire break (additions ride protocol minors), any
edit to the frozen v1 line.

---

The triad this design opens: [`./emq.1.md`](emq.1.md) · [`./emq.1.stories.md`](../../epics/emq.epic.1/emq.1.stories.md) ·
[`./emq.1.llms.md`](emq.1.llms.md). The canon: [`../emq.design.md`](../../emq.design.md) (§11.10, §4
rows 28/30, S-6, §5, §6). The program: [`../emq.roadmap.md`](../../emq.roadmap.md) ·
[`../echo_mq.md`](../../echo_mq.md). The 2.1 row: `../../echo/code/ROADMAP.md`. The consumer:
`echo/apps/codemoji` (the worked game consumer).
