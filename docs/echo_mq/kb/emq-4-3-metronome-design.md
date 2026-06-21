# EchoMQ 4.3 — The Metronome Mechanism: Consultation Questions for the Architect

> **Purpose.** A consultation brief. It frames the **single open fork of emq.4.3** — *which mechanism founds
> the new blocking-claim primitive* (FORK A-MECH) — as comprehensive open questions for an independent
> architect to answer *before* the Operator rules. The questions are organized by the four-part lens of the
> architect's approach — **Rationale · 5W · Steelman · Steward**
> ([`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)) — turned from an instrument of argument
> into an instrument of interrogation. The design team's current recommendation is stated per arm **so the
> architect tests it rather than defers to it**. This fork is a **high-stakes, frozen-surface founding** (a new
> primitive on the park/claim hot path); the multi-architect debate the approach reserves for exactly this case
> is the reason this brief exists.
>
> **How to answer.** Rank the arms; name the single decision whose reversal would cost the most; flag any arm
> resting on a false premise (the brief names its own best candidate — the §12.2 collapse below); and — most
> valuable from an outside vantage — say whether the brief has surfaced the *right* arms or missed one.
> Grounding holds: every module and line below was verified at source for this brief; an answer resting on an
> invented surface is the most expensive kind of wrong.

## 0 · The decision under consultation

**What emq.4.3 must deliver.** The park-don't-poll metronome, **founded as a new blocking-claim primitive**
(not a deepening of the shipped loop). A parked consumer must be served *within the beat* when its lane becomes
serviceable, with **no lost wakeup** under a concurrent admit-then-park, and wakes **fair** across parked
consumers — and the founding must be a genuinely new primitive, because the Operator ruled **Arm B**
(found-new) over **Arm A** (deepen-the-shipped-loop) at FORK A (D-1).

**The reframe the reconcile forces (binding — the architect should treat this as the central fact).** The
seed's Arm-B vision was "a server-side blocking grouped *claim* beyond `BLPOP wake`." The design canon forbids
that literal shape: **§12.2** ([`emq.design.md`](../emq.design.md):457–463) rejects a client-side pop because
it "would BYPASS the script layer's event and bookkeeping path… claim **IS** `ZPOPMIN` inside the claim
script." So no mechanism may block-and-claim in one step. **Every achievable mechanism is therefore
*block-on-a-readiness-signal, then run the atomic `@gclaim`*** — which is the *shape* the shipped loop already
has (`BLPOP wake`, then claim). The fork is thus not "what new claim primitive" but **"what does the consumer
block *on*, and is the result a genuine new primitive or the rejected Arm A relabelled."**

**The fixed constraints (not under consultation — binding):**

- **D-1 — Arm B ruled.** emq.4.3 founds a new blocking-claim primitive; "deepen the shipped loop" (Arm A) is
  chosen-against. An arm that is merely Arm A under a new name must be flagged as such, not smuggled in.
- **§12.2 — the claim stays atomic.** `@gclaim` (rotate → `ZPOPMIN` → server-clock lease → attempts token) is
  inviolable; no client-side pop substitutes for it. Block on a *signal*; claim with `@gclaim`.
- **The frozen wire — no `echo_wire` edit.** `EchoMQ.Connector`/`RESP`/`Script` are frozen by committed
  records ([`echo_wire.ex`](../../../echo/apps/echo_wire/lib/echo_wire.ex):12–14); `Connector.command/3` carries
  an arbitrary command with a custom timeout, so a blocking `BLMOVE`/`BLMPOP` rides the **same verb** park's
  `BLPOP` rides today. No arm may add a connector verb or a wire class; the only wire-level change is the
  `@wire_version` constant climbing **`echomq:2.4.2 → 2.4.3`** (the lockstep 4.1/4.2 already made).
- **The v2 master invariant.** Braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder · every
  Lua key in `KEYS[]` or a declared `KEYS[n]` root · server clock (`TIME`) on any lease · inline
  `Script.new/2`. Additive registration is a protocol minor; a wire break is a major.
- **The family law (EMQ.4-INV1/INV7/INV8, [`emq.4.md`](../specs/emq2/emq.4/emq.4.md)).** emq.4 adds **no new
  lane key family** and leaves the **§6 grammar unedited**; emq.4.3 owns **wake soundness** (no lost wakeup;
  fair across *consumers*) while emq.4.4 owns **lane fairness** ("which lane is served, and in what share"); a
  rung **does not pre-empt** a later family rung.
- **Additive-minor conformance.** The prior **55** scenarios pass byte-unchanged (the live pin is
  `run/2 → {:ok, 55}`); the new metronome scenario(s) register with their probe in the same change; the count
  re-pins **55 → N** in both pinning tests.
- **HIGH-risk posture.** Apollo MANDATORY at the build; the Director's verify deepens to the **≥100-iteration
  determinism loop** (a lost-wakeup race and a same-millisecond branded-id mint are cross-run hazards one green
  run cannot surface).

## 1 · The as-built floor (verified — the architect may rely on these)

The founding builds on shipped surface and replaces none of it. Line numbers drift; the modules and arities
below were confirmed at source for this brief.

- **The park-don't-poll core is shipped.** `EchoMQ.Consumer`
  ([`consumer.ex`](../../../echo/apps/echo_mq/lib/echo_mq/consumer.ex)) is a `spawn_link`'d loop (`:40`, traps
  exits, **not** a GenServer), `beat_ms` default 1000 (`:58`), beating
  `check_control → reap → promote → drain → park` (`:91–98`); `drain/1` claims until `Lanes.claim → :empty`
  (`:114–142`, exhaustive); `park/1` is `Connector.command(conn, ["BLPOP", wake, secs], beat_ms+2000)`
  (`:144–149`). The consumer owns a **dedicated connector lane** for blocking verbs (`:43–51`), so a blocking
  command starves no other caller.
- **The wake is a token LIST, pushed by every serviceable transition.** `LPUSH …'wake' '1'` + `LTRIM …'wake'
  0 63` appears in **7 scripts** — `lanes.ex` `@genqueue`/`@gresume`/`@glimit`/`@greassign`/`@greap_group`,
  `jobs.ex` `@complete`/`@retry`/`@promote`/`@reap`, `stalled.ex` `@sweep_stalled` (a single per-queue
  `emq:{q}:wake` LIST, capped 64, shared across all lanes and parked consumers). Because the wake persists and
  `BLPOP` consumes it and `drain` is exhaustive, **one token triggers full service** — the shipped design is
  already lost-wakeup-resistant on the single-consumer happy path.
- **The claim is atomic and rotation-fair.** `@gclaim` ([`lanes.ex`](../../../echo/apps/echo_mq/lib/echo_mq/lanes.ex))
  rotates the ring one step (`LMOVE ring ring LEFT RIGHT`, `:38`), `ZPOPMIN`s the lane head (`:41`), leases on
  the **server clock** (`redis.call('TIME')`, `:50–51`), and returns the group beside the job. The ring
  (`emq:{q}:ring`, a LIST) holds exactly the lanes serviceable now.
- **The wire carries blocking commands today.** `EchoWire`/`Connector.command/3`
  ([`echo_wire.ex`](../../../echo/apps/echo_wire/lib/echo_wire.ex):20) takes an arbitrary `[binary|integer|atom]`
  command with a custom timeout; park's `BLPOP` is the live precedent. `BLMOVE`/`BLMPOP` (Valkey 6.2) ride it
  unchanged — **no `echo_wire` edit for any arm**.
- **The contract is pinned at 55.** `EchoMQ.Conformance.run/2 → {:ok, 55}` (`conformance_run_test.exs:48`);
  `{emq}:version` reads `echomq:2.4.2` (`connector.ex`, the climbing fence; 4.1→2.4.1, 4.2→2.4.2).

**The surface emq.4.3 builds (forward tense — none of this exists yet):** a new blocking primitive in
`EchoMQ.Consumer`'s park/claim path (the precise shape is FORK A-MECH), the metronome conformance scenario(s),
and the `@wire_version`/`{emq}:version`/`mix.exs` climb to `echomq:2.4.3`.

---

## 2 · FORK A-MECH — what the consumer blocks on (the primitive)

Given §12.2, every arm is *block-on-a-signal, then `@gclaim`*. The arms differ in **what readiness structure
the consumer blocks on**, and that difference is the whole decision.

- **MECH-(i) — `BLMOVE` on the shipped `wake`.** Replace `BLPOP wake` with `BLMOVE wake <sink> LEFT RIGHT`
  (the blocking sibling of `LMOVE`), then `@gclaim`. The wake stays the existing `emq:{q}:wake` token LIST;
  `BLMOVE` atomically moves the consumed token to a per-consumer sink, so a signal is recoverable on crash, not
  fire-and-forget. `@gclaim` and all 7 wake-push scripts byte-frozen; no §6 grammar edit.
- **MECH-(ii) — a dedicated metronome process.** A new supervised process distinct from `EchoMQ.Consumer`
  owns the beat/notify; consumers wait on it. Still block-then-`@gclaim` internally (§12.2). Largest touch-set
  (new module + consumer rewire + supervisor).
- **MECH-(iii) — a per-lane `wake:<group>` LIST.** Each lane carries its own wake list so a wake targets one
  lane (true multi-lane wake fairness). Requires a **new `§6` `type` member** in the CLOSED registry and
  re-addressing all 7 wake-push scripts. Widest touch-set; intersects EMQ.4-INV1 and emq.4.4's scope.

**Design team's current recommendation: MECH-(i)**, on the single reason that it is the smallest founding that
closes the lost-wakeup window *by construction* (an atomically-stashed signal) while honoring §12.2,
EMQ.4-INV1, and INV8. **The design team flags its own recommendation as the brief's weakest premise** (the
§12.2 collapse, below): MECH-(i) may be Arm A relabelled.

### Rationale — does each arm credibly answer the need, and what *is* the need?

- Given §12.2 forecloses a block-and-claim, is "found a *new* primitive" (Arm B) a coherent requirement at
  all, or did the reconcile reveal that Arm B and Arm A converge once the claim must stay `@gclaim`? If they
  converge, the honest answer may be that the *mechanism* fork is small and the **proof** (the ≥100 loop, the
  scenarios) is the rung's real content.
- What concrete defect in the shipped wake protocol does each arm *fix*? On the single-consumer happy path the
  token-LIST is already lost-wakeup-resistant; the real gaps are (a) a consumed-but-undrained signal lost to a
  crash between `BLPOP` and the claim, and (b) cross-lane/thundering-herd wake on the shared list. Which arm
  answers which gap, and is either gap a *present* need of a named consumer (codemojex one-lane-per-player) or
  an anticipated one?

### 5W — Why · What · Who · When · Where

- **Why** does the rung need a *new primitive* rather than the proven loop — what failure has been observed or
  is provably reachable that the shipped `BLPOP wake` + exhaustive `drain` does not already handle?
- **What**, precisely, is the new wire-level behavior each arm introduces — `BLMOVE`'s atomic move-to-sink
  (i), a new process's notify discipline (ii), a new per-lane key and its 7 re-addressed pushers (iii)?
- **Who** consumes the difference: do the named consumers run **multiple parked consumers per queue** (the only
  configuration in which wake *fairness* and per-lane *targeting* matter), or a single consumer per queue
  (where MECH-(i)'s robustness is the only live benefit)?
- **When** on the ladder is per-lane wake (iii) actually needed — and is that need emq.4.4's (lane fairness),
  not emq.4.3's (wake soundness)? INV7 splits them; does iii cross the line?
- **Where** does the blocking call live and what does it hold — `Connector.command/3` on the consumer's
  dedicated lane (i/iii) or a new process's mailbox (ii) — and does any arm hold a connector for longer than the
  beat in a way that interacts with `stop/2`'s drain latency?

### Steelman — argue each arm at its best

- **MECH-(i):** the strongest case that `BLMOVE`-on-wake is a *genuine* new primitive and not a renamed
  `BLPOP` — that move-to-sink recoverability changes the correctness contract (a crash mid-claim re-finds the
  signal) and is therefore a new guarantee, not a cosmetic verb swap.
- **MECH-(ii):** the strongest case that a dedicated process is the *right* founding even though it
  block-then-`@gclaim`s internally — does separating the beat from the drain loop unlock supervised
  multi-consumer fan-out or backpressure that the in-loop park cannot express, justifying the largest
  touch-set?
- **MECH-(iii):** the strongest case that per-lane wake belongs at **4.3** despite INV7/INV8 — is wake
  *targeting* a soundness property (4.3) rather than a fairness property (4.4), such that the shared list is an
  actual correctness bug (a wake for lane X consumed by a consumer that then serves nothing) and not merely an
  efficiency loss?

### Steward — what does each arm cost to keep for years?

- **MECH-(i):** a per-consumer sink list is new standing state — how is it reclaimed when a consumer dies
  without draining it, and does the sink become a slow leak under churn? `BLMOVE` recoverability is only as good
  as the recovery path that reads the sink.
- **MECH-(ii):** a per-queue (or per-consumer) supervised process is a permanent operational surface —
  supervision, restart semantics, the beat as a tunable. How does it compose with the shipped consumer's
  `stop/2`/`:shutdown` drain contract, and does it double the process count a deployment must reason about?
- **MECH-(iii):** a new `§6` member is a **permanent wire-grammar contract**; re-addressing 7 frozen scripts
  is 7 chances to break byte-freeze; and it **promotes lane fairness into 4.3**, pre-empting 4.4 (INV8). Does
  paying a permanent grammar cost now, for a fairness property the carve assigns to the next rung, age well — or
  does it foreclose emq.4.4's Fork B Arm 3 ("a per-lane budget refreshed by the metronome"), which is the
  carve's own home for exactly this machinery?

### The hard question — is the fork well-posed, and is there a MECH-(iv)?

Two candidates the framing above hides:

1. **The §12.2 collapse (the false-premise flag).** If every arm is block-then-`@gclaim`, is MECH-(i)
   *materially* different from the Arm-A deepening the Operator chose against — or does ruling MECH-(i) quietly
   re-instate Arm A? If so, the well-posed decision is not "(i) vs (ii) vs (iii)" but **"is Arm B achievable as
   anything but a relabel, and if not, does the Operator prefer to (a) accept MECH-(i) as the canon-legal best,
   (b) take the genuinely-distinct MECH-(ii), or (c) re-open §12.2 — a design-canon revision, a larger rung?"**
2. **MECH-(iv) — block on the *ring*, not a proxy token.** No arm above blocks on the actual work-readiness
   structure. `BLMOVE emq:{q}:ring <sink> LEFT RIGHT` blocks until a *serviceable lane id* appears on the ring,
   atomically stashes it, and the consumer then `@gclaim`s **that lane**. This blocks on the truth (the ring
   holds exactly the serviceable lanes) rather than a signal that proxies it — arguably the *most* genuine "new
   blocking-claim primitive," and it eliminates the thundering herd (a consumer wakes holding a specific lane,
   not a generic token). The cost the brief must price: the shipped `@gclaim` *rotates the ring itself*
   (`LMOVE ring ring`), so a consumer popping the ring outside the script changes who owns ring membership —
   does MECH-(iv) force an `@gclaim` edit (re-grading risk and breaking the "claim is one atomic script"
   model), or can the block-pop and the rotate compose without a double-serve or a lost lane? **This is the
   question most worth an independent architect's time.**

---

## 3 · Cross-cutting questions (the whole, not the parts)

- **The proof is the rung, not the primitive.** If the mechanism fork is small (the §12.2 collapse), the
  rung's real risk and value live in the **conformance scenarios + the ≥100 determinism loop** that gate the
  lost-wakeup and fairness properties. Is the brief under-weighting the proof by foregrounding the mechanism?
  What is the *minimal* scenario set that actually gates "no lost wakeup" and "fair across consumers" — and does
  it require a genuine multi-consumer harness the suite does not yet have?
- **The §6 grammar sub-fork (only if MECH-(iii)).** A per-lane `wake:<group>` member edits the CLOSED `§6` type
  registry — a protocol minor that must register with its probe. Is that grammar cost ever worth paying *before*
  emq.4.4 needs it, given INV8?
- **The build topology (the Operator's "divide-and-conquer, no overload/freeze").** Each arm implies a
  different formation. MECH-(i)/(iv) are bounded → standard Flat-L2 (Mars build → Director verify with the ≥100
  loop → Mars-2 harden → Apollo). MECH-(iii) is wide → it must divide (one agent for the 7-script
  re-addressing, one for the primitive, one for conformance + the `.stories.md`) so no single agent is
  overloaded. Does the chosen arm's touch-set fit a single bounded build pass, or does it *require* the
  divide-and-conquer wave — and is that a reason to prefer a bounded arm?
- **The interdependency with emq.4.4.** Forks couple: MECH-(iii) pre-empts 4.4's lane fairness; MECH-(iv)'s
  ring interaction may constrain 4.4's weighted-rotation mechanism (Fork B). Should the metronome mechanism be
  ruled with one eye on 4.4's Fork B, or are they cleanly separable?
- **What a "new primitive" is worth.** The Operator chose Arm B over Arm A deliberately. If §12.2 makes the two
  converge, the most useful outside judgment is whether the *intent* behind choosing Arm B (a structurally
  distinct surface) is better served by MECH-(ii)/(iv) at higher cost, or whether the intent is already honored
  by MECH-(i)'s changed correctness contract at the lowest cost.

## 4 · What a useful answer looks like

1. **Ranks the arms** (i / ii / iii / iv), with the one reason that carries each ranking, and says plainly
   whether MECH-(i) is or is not a genuine departure from Arm A.
2. **Resolves the §12.2 collapse:** states whether "found a new primitive" is achievable within the canon, and
   if not, which of accept-(i) / take-(ii or iv) / re-open-§12.2 best honors the Operator's Arm-B intent.
3. **Prices MECH-(iv)** — the ring-block — concretely: does it force an `@gclaim` edit, and can block-pop +
   rotate compose safely?
4. **Names the highest reversal-cost decision** (a frozen `§6` member under MECH-(iii); an `@gclaim` edit under
   MECH-(iv); a permanent process surface under MECH-(ii)) so the Operator prices irreversibility before ruling.

---

## References

- The method this brief applies: [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md) (the
  four-part arm; the surfaced-fork discipline; the multi-architect debate for a high-stakes frozen contract).
- The sibling exemplar (the pattern this brief follows): [`emq-durability-design.md`](emq-durability-design.md).
- The canon constraint: [`emq.design.md`](../emq.design.md) §12.2 (client-side pops rejected; the claim is
  `ZPOPMIN` inside `@gclaim`), the v2 master invariant, the frozen-wire records.
- The family carve and its laws: [`emq.4.md`](../specs/emq2/emq.4/emq.4.md) (EMQ.4-INV1 no new key family;
  INV7 the 4.3/4.4 fairness split; INV8 no pre-emption; FORK A / FORK B); the rung seed
  [`emq.4.3.md`](../specs/emq2/emq.4/emq.4.rungs/emq.4.3.md).
- The strategic framing checked for MECH-(iii): [`emq.roadmap.md`](../emq.roadmap.md) (the emq.4 row; lane
  fairness → emq.4.4) and [`emq4.roadmap.md`](../emq4.roadmap.md) (the Oban-Pro-parity roadmap; lane strategy =
  the rotating ring + limits + global counters, Phase 4; per-lane wake absent).
- The as-built anchors (re-probe at the build): `EchoMQ.Consumer`
  ([`consumer.ex`](../../../echo/apps/echo_mq/lib/echo_mq/consumer.ex)), `EchoMQ.Lanes` `@gclaim`
  ([`lanes.ex`](../../../echo/apps/echo_mq/lib/echo_mq/lanes.ex)), the wake pushers in
  [`jobs.ex`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex), the frozen facade
  ([`echo_wire.ex`](../../../echo/apps/echo_wire/lib/echo_wire.ex)).
