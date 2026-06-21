# emq.4.3 — FORK A-MECH, the final architecture decision: MECH-(ii), the metronome-as-system { id="emq-4-3-metronome-fork-decision" }

> _The Director's synthesis of the two-architect consultation, and the Operator's ruling. **FORK A-MECH is
> ruled MECH-(ii) — a dedicated, supervised metronome system per queue.** The two architects argued the same
> arms from divergent lenses and converged on everything except the **axis**: venus-1 (spec-steward) founds the
> new primitive on the **wire** by relocating selection — MECH-(iv-b), block on the ring, rotate in place, which
> re-grades the safety-critical `@gclaim`; venus-2 (consumer-steward) founds it on the **BEAM** as a system —
> MECH-(ii), one blocker fanning out to a consumer pool over BEAM messages, `@gclaim` byte-frozen. Both reject
> MECH-(iii); both name the multi-consumer proof + the ≥100 loop as the load-bearing work; both agree §12.2 binds
> the **claim**, not the **selection**, so a genuine new primitive is reachable in canon. The decision is (ii)
> over (iv-b) for one reason that dominates on a HIGH-risk frozen-surface rung: **(ii) buys (iv-b)'s entire
> multi-consumer benefit reversibly — delete a supervisor child — where (iv-b) buys it by re-founding the
> hottest script. The found-new charter (D-1) is honored on the process axis, where the cost is removable, not on
> the wire axis, where it is frozen by committed records.** This doc records the decision; the build re-derives
> the triad to it at the ship's Stage-0/1._

Companions in this folder: [`metronome-fork-venus-1.md`](metronome-fork-venus-1.md) (the spec-steward answer, the
selection-is-not-claim spine, recommends (iv-b)) · [`metronome-fork-venus-2.md`](metronome-fork-venus-2.md) (the
consumer-steward answer, the BEAM-process axis, recommends (ii)). The consultation brief that opened the wave:
[`../emq-4-3-metronome-design.md`](../emq-4-3-metronome-design.md). The ruling on the prior fork (D-1, found-new):
[`../../specs/progress/emq-4-3.progress.md`](../../specs/progress/emq-4-3.progress.md). The rung triad:
[`../../specs/emq2/emq.4/emq.4.rungs/emq.4.3.md`](../../specs/emq2/emq.4/emq.4.rungs/emq.4.3.md).

## The board in one paragraph

D-1 ruled FORK A = **Arm B**: emq.4.3 must *found a new blocking-claim primitive* that subsumes the shipped
two-step (a consumer parks on `BLPOP emq:{q}:wake`, is woken by a wake-push baked into every serviceable
transition, then exhaustively `drain`s the ring with rotating atomic `@gclaim`s). FORK A-MECH asked *which*
primitive. Five arms reached the table: **(i)** `BLMOVE wake→sink` (a recoverable park); **(ii)** a dedicated
metronome *process*; **(iii)** a per-lane `wake:<group>` LIST (a new §6 grammar member); **(iv)** block on the
**ring** — refined by venus-1 into **(iv-b)** `BLMOVE ring ring` (rotate in place, no sink); **(v)** per-consumer
wake lists (a keyspace consumer-registry). Two architects answered the brief from opposite vantages. This is the
synthesis and the ruling.

## What the two answers agree on (the consensus floor)

Before the divergence, the floor both architects stand on — none of it is in dispute, and the build inherits all
of it:

1. **§12.2 binds the *claim*, not the *selection*.** venus-1 drew the distinction explicitly; venus-2 accepted
   it as "the right insight." `@gclaim` fuses two things — `LMOVE ring ring` (selection: rotate to the next
   serviceable lane) and `ZPOPMIN` + server-clock lease + attempts token (the claim). §12.2 forbids a
   client-side pop *substituting for the claim*; it does not forbid relocating *selection*. So "found a new
   primitive within the canon" **is achievable** — the §12.2 collapse the brief flagged dissolves once the arm
   tested is not MECH-(i) (which changes neither half).
2. **MECH-(iii) is rejected.** Both price its new §6 `type` member as the single highest reversal cost on the
   board (a CLOSED-registry grammar contract removable only by a wire *major*), and both note it pre-empts
   emq.4.4's lane-fairness (INV8) for a property the other arms deliver without it.
3. **The proof is the rung.** A "fair across consumers, no lost wakeup" charter requires a genuine
   **multi-consumer harness the 55-scenario suite does not have**, and the **≥100-iteration determinism loop** is
   where the lost-wakeup race and the same-millisecond branded-`JOB` mint (cross-run hazards one green run cannot
   surface) are caught. Building that harness is the load-bearing work *whichever* arm ships.
4. **The touch-set is bounded.** Both (ii) and (iv-b) fit a standard **Flat-L2** pass; only MECH-(iii) would have
   forced the wide divide-and-conquer formation — itself a reason both disfavor it.
5. **The wire is not broken.** Every arm rides the shipped `Connector.command/3` (the frozen records are
   untouched); the only wire-level move is the version climb `echomq:2.4.2 → 2.4.3`.

The decision, then, is narrow: **(ii) or (iv-b)** — the two arms that genuinely found a new primitive.

## The argument: (ii) vs (iv-b)

Each arm is given its strongest form (its own architect's), then the deciding comparison.

### MECH-(iv-b) — block on the ring, rotate in place (venus-1's recommendation), steelmanned

The consumer stops blocking on the proxy `wake` token and blocks on the **ring itself** — the structure that
*is* the set of serviceable lanes — with `BLMOVE ring ring LEFT RIGHT <beat>`. `src == dst == ring` rotates the
head lane to the tail and *returns* it, so the consumer wakes **holding a specific serviceable lane**, and the
lane is never consumed, only advanced. Then `@gclaim(lane)` claims it. This is the genuine new *selection*
primitive, and it is the cleanest piece of wire design on the board:

- **Lost-wakeup closed by construction, no sink.** You wake holding a lane that is still on the ring, or you do
  not wake — there is no separate token to miss and nothing to orphan (the refinement over the brief's sink-based
  (iv-a), which carried a lane-orphan recovery burden).
- **Cross-lane herd eliminated.** Valkey serves blockers on `ring` FIFO; N parked consumers wake on N *distinct*
  rotated lanes instead of stampeding one shared token.
- **§12.2-legal.** Selection moves to the client; the claim — `ZPOPMIN` + lease + attempts — stays one atomic
  script. "Claim is one atomic script" is preserved; only "select-*and*-claim is one script" is given up, which
  §12.2 does not require.

**Its price, named:** it forces a **bounded `@gclaim` edit** — `@gclaim` drops its `LMOVE ring ring` (the
consumer's `BLMOVE` did the rotate) and takes the selected lane as an argument, plus a new conditional
`LREM lane from ring iff lane now empty` to keep "the ring holds exactly the serviceable lanes" true. And it
**couples 4.3↔4.4**: it relocates the rotation-fairness seam from inside `@gclaim` to ring-membership discipline,
which emq.4.4's weighted rotation (Fork B) must then build on.

### MECH-(ii) — the metronome-as-system (venus-2's recommendation), steelmanned

The brief and venus-1 both argued every arm on **one axis** — *which Valkey structure does the consumer block
on?* venus-2's contribution is the axis they omitted: the BCS law the whole stack is built to — *a system is an
OTP process that owns its data privately and shares only messages* — names a second axis: **where does the beat
live as a process?** Today it is fused into each `EchoMQ.Consumer`'s `spawn_link` loop; every consumer is its own
metronome. MECH-(ii) makes the beat a **system in its own right**:

- A **new supervised process per queue** owns the beat and the **single** Valkey block — `BLPOP emq:{q}:wake`,
  the *shipped* verb on the *shipped* token — plus a **registry of idle consumers**.
- On a wake it pokes the *k* registered-idle consumers over **BEAM messages**; **each runs the byte-frozen
  `@gclaim` exactly once.** The herd is gone because only one connection blocks; consumer-fairness is exact
  because the metronome hands out one claim per idle consumer per wake; lane-fairness is unchanged because each
  `@gclaim` still does the atomic `LMOVE ring ring` rotate inside it.
- **`@gclaim` is byte-frozen. §12.2 is not approached. The §6 grammar is not edited** (the fan-out is BEAM
  messages, not a keyspace registry). The claim — the safety-critical script — is *untouched*.

It delivers (iv-b)'s entire multi-consumer envelope — herd-elimination, distinct-target wakeups,
consumer-fairness — on the BEAM, where the platform gives liveness for free (a dead consumer is a monitor signal,
not a manufactured keyspace heartbeat) and a crashed metronome is *restarted* with its in-flight claims already
protected by the server-clock lease and the `reap`/stalled path. It is the **most BCS-idiomatic** arm: the
metronome becomes a system that owns the beat, which is the law the stack is built to, and which the program's
own "thin but robust — every new process supervised with a pure decision core" discipline (`emq.roadmap.md`)
already prescribes.

**Its price, named:** a **serialization point** (one process per queue gates wakeups; a slow metronome throttles
the queue; the process count a deployment holds roughly doubles), a **registration contract** (consumers must
register/deregister idle state and the `stop/2`/`:shutdown` drain must compose with it; getting it wrong
re-introduces a missed wake on the BEAM side), and **genuinely new operational surface** (restart semantics, the
beat as a tunable owned by a separate system). Every one of these is a **BEAM** cost — the category the runtime is
designed to absorb, and the category that is **removable**.

### The deciding comparison

Both arms found a new primitive; both eliminate the herd; both are §12.2-legal; both are bounded. They differ on
exactly one axis that matters on a **HIGH-risk, frozen-surface** rung — **reversibility on the hot path** — and
it orders them decisively:

| | MECH-(iv-b) | MECH-(ii) |
|---|---|---|
| Founds the new primitive on | the **wire** (relocated selection) | the **BEAM** (the beat becomes a system) |
| Touches `@gclaim` (the safety-critical claim) | **yes** — re-grade + new `LREM`-if-empty on the hot path | **no** — byte-frozen |
| §6 grammar | clean | clean |
| Reversal class | **wire-script re-founding** (a script revert is bounded, but the hot-path `LREM` obligation and the 4.3↔4.4 coupling are cheap to add, expensive to remove) | **delete a supervisor child** — the wire and the claim are byte-for-byte where they started |
| Couples 4.3↔4.4 | **yes** — moves the rotation-fairness seam to ring-membership | **no** — leaves the seam inside `@gclaim` for 4.4's Fork B |
| New failure surface | a new `LREM`-if-empty hot-path bug class (busy-spin on an empty-but-ringed lane, or a `LREM`'d-but-serviceable lost lane) | a serialization point + a registration contract (BEAM-supervised, monitor-detected) |

**The ruling: MECH-(ii).** On a rung graded HIGH precisely because it reshapes a fairness-critical surface, the
decision variable is *what happens when we are wrong*. A bug in (iv-b) lives in the hottest script, paid forever;
a bug in (ii) lives in a supervised process you can delete, with the claim and the wire untouched beneath it. The
found-new charter (D-1) asked for a structurally distinct surface — (ii) is that surface, on the axis where the
stack's own law puts it and where the cost is removable.

## The pivot, resolved

venus-2's recommendation was explicitly conditional on one fact NO-INVENT forbade either architect to assume:
*will the pooled consumer run as a **pool of parked consumers on a shared queue**, or as **consumer-per-lane**?*
The pool answer makes the herd real and selects a multi-consumer founding; the consumer-per-lane answer leaves
the present profile intact and would select MECH-(i) or the do-nothing baseline.

The Operator resolved it: **pool.** The roadmap's headline-planned consumer is **echo_bot** — "Telegram
notifications at scale; the seam is `EchoBot.Platform.Telegram.send_reply/3`" (`emq.roadmap.md` §The epic / Who),
and a notification fan-out is naturally a pool (many sends, few queues). **codemojex** (one-lane-per-player today)
is the degenerate one-consumer case — it does not *need* the metronome and is **not harmed** by it (a
one-consumer pool is the trivial degenerate). So the founding is justified by the near consumer without taxing
the present one.

## What MECH-(ii) is — the build shape (forward-tense; re-probed at the ship's Stage-0)

The triad re-derives to this at Stage-0/1; the shapes below are the design intent the build grounds against, not
a committed surface.

- **A new `EchoMQ.Metronome` (forward name) — a supervised process per queue.** Modeled on the shipped
  `EchoMQ.Consumer` `spawn_link`-loop discipline (`consumer.ex:40` — traps exits, owns a **dedicated connector
  lane** for the blocking verb, `consumer.ex:43-51`): a loop that drains its registration mailbox at a settle
  point, holds the single `BLPOP emq:{q}:wake <beat>` block, and on a wake pokes the registered-idle consumers.
  It carries a **pure decision core** (which idle consumers to poke, how many claims to authorize) testable
  without Valkey — the program's "thin but robust" law.
- **The dispatch contract: one `@gclaim` per idle consumer per wake.** The genuine concession venus-2 named —
  poking one consumer to *exhaustive-drain* would be consumer-*unfair* (one worker hogs the beat). When work
  remains after a round, the metronome re-pokes promptly (it does not wait a full beat), so throughput is
  preserved while fairness is exact.
- **`EchoMQ.Consumer` rewired.** It loses its private `park/1` (`consumer.ex:144-149`, the `BLPOP`) and gains a
  **registration**: register idle with the metronome → receive `:claim_once` → run the byte-frozen `@gclaim` once
  → re-register. The beat cadence (today each consumer's `reap → promote` on its own loop, `consumer.ex:91-97`)
  most likely **migrates to the metronome** (one beat per queue) — a build seam the Stage-0 reconcile pins.
- **Ownership: host-started, no auto-start.** `echo_mq` is a library with no OTP application callback
  (`mix.exs:20` is `extra_applications: [:logger]` only — no `mod:`); consumers are started by the host
  (codemojex / echo_bot). The metronome follows the same law (the library law, `emq4.roadmap.md` cross-cutting
  mitigation 6): the host starts a metronome + its N consumers under the host's supervisor — likely via a small
  `EchoMQ.start_queue/…`-style helper the build shapes, never a hidden `mod:` boot.
- **No wire / no Lua / no §6 edit.** The block rides `Connector.command/3` (the FROZEN-WIRE verdict holds — the
  shipped park's `BLPOP` is the proof, `consumer.ex:147`); `@gclaim` and the seven wake-push scripts are
  byte-frozen; `keyspace.ex`'s CLOSED §6 `type` registry is untouched. The **only** wire-level change is the
  version climb `2.4.2 → 2.4.3` (the `mix.exs` label + the `@wire_version` constant at
  `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` in lockstep, D-3) — an **additive minor** because the
  conformance count climbs, **not a floor-raise** (`BLPOP` is already in the shipped inventory).

## The other arms, consolidated (the full board, dispositioned)

- **MECH-(i) — `BLMOVE wake→sink`.** venus-1: "Arm A with a recoverability bolt-on" — changes neither selection
  nor claim, so it fails D-1 *as written*. venus-2: "the smallest honest step," ship it *labelled as
  recoverable-sink, not smuggled as Arm B* if the profile were single-consumer. **Disposition: not chosen** — the
  pivot resolved to pool, where (i)'s herd persists; superseded by (ii).
- **MECH-(iii) — per-lane `wake:<group>` + a §6 member.** Both architects reject it: the **highest reversal cost
  on the board** (a permanent CLOSED-registry grammar contract), it pre-empts emq.4.4 (INV8), it touches all
  seven frozen wake-push scripts, and no named consumer needs per-lane wake *targeting* at 4.3. **Disposition:
  rejected** (and the earlier T-5 strategic check agrees: per-lane wake is absent from both roadmaps).
- **MECH-(iv-a) — `BLMOVE ring→sink`.** venus-1's own steelman retires it in favor of (iv-b): the sink orphans a
  *whole lane* on a crash between pop and re-ring and needs a recovery path. **Disposition: dominated by (iv-b).**
- **MECH-(iv-b) — block on the ring, rotate in place.** The strong alternative; **chosen-against** on
  reversibility (see the deciding comparison). Kept on the record as the wire-axis founding; if a future rung
  ever needs selection relocated to the wire, this is the design — but not at a HIGH-risk rung that can reach the
  same benefit reversibly.
- **MECH-(v) — per-consumer wake lists.** venus-1 surfaced it (the missed arm); venus-2 named it "a degenerate
  (ii) with the registry on the wire instead of the BEAM" — and liveness is exactly what the BEAM gives for free
  (monitors) and Valkey makes you build (heartbeat keys, TTLs, a reaper). **Disposition: dominated by (ii).**
- **The do-nothing baseline.** The shipped `BLPOP wake` loop is *already correct* for a single consumer
  (sub-beat on the happy path, beat-bounded on a lost token, no lost work). It is the floor (ii) must beat — and
  for a *pool* it does not suffice (the herd and the cross-consumer fairness gap are real). **Disposition: the
  floor, beaten by the pool requirement.**

## The §12.2 collapse, resolved

The brief flagged a collapse: since §12.2 forecloses a block-*and*-claim, every arm is *block-on-signal then
atomic `@gclaim`*, which is Arm A's shape — so MECH-(i) (BLMOVE on the wake token) may be the rejected Arm A
relabelled, and "found-new" might be unreachable in canon. **Both architects dissolved it the same way:** §12.2
binds the *claim*, not the *selection*, so a genuinely new primitive **is** reachable — venus-1 by relocating
selection to the wire ((iv-b)), venus-2 by relocating the *beat* to a BEAM system ((ii)). The collapse was an
artifact of testing only the arm that changes neither half. **The ruling does not re-open §12.2** — (ii) needs no
canon revision: it leaves the claim atomic and the selection inside `@gclaim`, and founds the new surface one
axis over, on the BEAM.

## Risk posture and the proof that gates it

**HIGH** — but the risk relocates with the axis. It is **not** a wire floor-raise (`BLPOP` is shipped); it
concentrates on (a) the **BEAM process/lease surface** (the metronome's serialization point + the registration
contract) and (b) the **consumer-fairness proof** the suite lacks. The gates, per the prompt's HIGH-risk posture:

1. **No lost wakeup (the load-bearing proof).** A concurrent *admit-then-park* (now *admit-then-register*)
   scenario asserting service **well before the beat elapses**, not "eventually" — plus the
   crash-between-signal-and-claim case asserting no orphaned work and no leaked registration state.
2. **Fair across consumers.** The N-registered-consumer scenario asserting distinct service and bounded
   starvation — the harness the 55-scenario suite does not have. This is where (ii)'s "one `@gclaim` per idle
   consumer per wake" is differentiated, and where the **≥100-iteration determinism loop owns the machine** (the
   lost-wakeup race and the same-millisecond branded-`JOB` mint are cross-run hazards).
3. **§12.2 no-bypass + FROZEN-WIRE + byte-frozen `@gclaim`.** The Director's probes: the lane/ring pop is inside
   `@gclaim` only; `@gclaim` + the seven wake-push scripts `grep redis.call`-unchanged in the lib diff;
   `echo_wire/lib/` byte-unchanged but the `@wire_version` constant moved to `2.4.3`.
4. **Apollo MANDATORY** — the dedicated evaluator re-runs the whole ladder + the ≥100 loop independently and
   renders the BUILD-GRADE / BLOCKED verdict the Director ratifies.

## Build topology

A standard **Flat-L2** pass (Venus re-derive → Mars build → Director deepened-verify → Mars-2 harden → **Apollo
MANDATORY** → Director ship + one LAW-4 pathspec commit), **not** a divide-and-conquer fan-out — both architects
confirm (ii) is a bounded touch-set; only MECH-(iii) would have forced the wide formation. The Operator's
divide-and-conquer / no-overload directive is honored *within* the pipeline: **Mars's build divides across its
two passes** so no single agent holds the whole load — pass 1 the **core primitive** (the `Metronome` process +
the consumer rewire + the host-wiring helper), pass 2 the **proof** (the multi-consumer `:valkey` harness + the
conformance scenario(s) + the version bump + the count re-pin `55 → N`). Sequential, because the proof depends on
the primitive's API; divided, so neither pass overloads.

## What this decision does not decide (deliberately left open)

- **The 4.4 coupling — left clean by construction.** (ii) leaves the rotation-fairness seam *inside* `@gclaim`,
  so emq.4.4 (weighted/deficit, Fork B) inherits the seam where the carve already puts it (`emq.4.md` INV7/INV8)
  — *not* pre-constrained client-side as (iv-b) would have left it. FORK B settles before 4.4, unforeclosed.
- **Per-lane wake — deferred, not founded.** The thundering-herd-by-lane refinement (MECH-(iii)'s per-lane LIST)
  is *not* part of this rung; (ii) eliminates the herd at the connection level (one blocker) without it. If a
  future need for per-*lane* targeting is ever proven present, it layers on the metronome then.
- **The reap/promote migration + the `start_queue` helper shape — build seams.** Pinned at the ship's Stage-0
  reconcile against the as-built tree (the lag-1 law); the shapes above are intent, not a committed surface.

---

_Method: the Director's synthesis over the two-architect debate (Rationale · 5W · Steelman · Steward, turned on
the arms), per [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) — architects
argue, the Director synthesizes, the Operator rules. Grounded on the verified as-built floor (the `BLPOP wake`
park loop `consumer.ex:144-149`, the dedicated connector lane `:43-51`, the exhaustive `drain` `:114-142`, the
atomic `@gclaim` `lanes.ex:37-61`, the seven wake-pushers, the frozen wire `echo_wire.ex:12-14`). Forward-tense
throughout for the founding, which does not yet exist. Consumers cited as the real ones — codemojex
(single-consumer-per-lane today), echo_bot (the planned Telegram pool that makes the pivot live) — never an
invented one. The ruling: **MECH-(ii), the metronome-as-system.** Recorded as D-2 in
[`../../specs/progress/emq-4-3.progress.md`](../../specs/progress/emq-4-3.progress.md)._
