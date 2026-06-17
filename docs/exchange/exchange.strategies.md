# TRD · Patterns for Trading Strategies — In Depth

<show-structure depth="2"/>

[`exchange.patterns.md`](exchange.patterns.md) argued the two patterns under the *engine*: the Decider that decides and
the Ring that admits. This article is the companion in depth for the layer above — the patterns by which trading
**strategies** are expressed, hosted, gated, evaluated, and retired on this platform. Posture, stated once: this is
an engineering article. It explains the established strategy archetypes as *workloads* — what each demands from the
platform — and then the software patterns that serve any of them; it prescribes no parameters, promises no returns,
and claims no number that a rung's harness has not produced. The one external reference it leans on is the
mathematics of why backtests lie [1], because that failure is an engineering failure with an engineering fix.

## The archetypes, as workloads

Six families cover most of what runs on platforms like this one. Each line is the textbook description plus the
engineering demand it places — the demand is what the rest of this article serves.

| Archetype | What it does (one line) | What it demands from the platform |
|---|---|---|
| Market making | quotes both sides, earns the spread, manages inventory | the tightest loop: react to every book delta; inventory as live state; cancel/replace storms; hard kill switch |
| Momentum / trend | enters in the direction of persistent moves | bar/window aggregation over event time; modest latency; position held across sessions — durable strategy state |
| Mean reversion | bets that stretched moves retrace | rolling statistics over event time; regime guards; the same windowing machinery as momentum with opposite sign |
| Pairs / stat-arb | trades the spread between related instruments | synchronized multi-instrument views; the cross-aggregate problem named in the engine patterns arrives here |
| Execution algos (TWAP/VWAP/POV) | works a parent order into the market over time to bound impact | a schedule as a state machine; child-order lifecycle; strict budget enforcement; no alpha, all plumbing |
| Event-driven | acts on discrete facts (prints, halts, releases) | low-latency fan-in from the claims bus; idempotent reaction to at-least-once delivery |

The point of the table is its third column: six different trade ideas, one short list of engineering demands —
event-time windows, durable foldable state, multi-instrument views, lifecycle state machines, budgets, idempotency,
and a kill switch. The patterns below are that list, served.

## Pattern I — the strategy is a Decider that emits intents

The same shape that runs the book ([`exchange.patterns.md`](exchange.patterns.md)) runs the strategy, one level up and
with one sharpened output type:

```
decide : MarketEvent | TimerEvent | OwnFill -> StrategyState -> Intent list
evolve : StrategyState -> (Event | Intent ack) -> StrategyState
```

Two deliberate choices live in those signatures. First, the strategy emits **intents, never orders**: an intent is
the strategy's pure statement — instrument, side, quantity, constraint — carrying a branded intent id minted at
emission; turning intents into exchange orders is the OMS's job (Pattern IV), which keeps broker mechanics,
throttles, and retries out of the function you property-test. Second, the inputs are **events including the
strategy's own fills** — a strategy that cannot see its fills cannot manage inventory, and feeding fills back through
`decide` rather than mutating state out-of-band keeps the fold law intact: strategy state is reconstructable from the
event stream plus the intent acknowledgements, nothing else.

What purity buys here is larger than testability. It buys **backtest-live identity** (Pattern VI): the same compiled
`decide` runs over a recorded stream and over the live one, so there is no second implementation to drift. It buys
**explainability**: every intent is `decide(event, state_at_seq)` at a well-defined sequence point, because sequence
is mint order platform-wide. And it buys cheap **property tests** on strategy invariants — never quote through your
own resting order, never exceed the inventory band, always cancel before re-quoting — as predicates over pure calls.

## Pattern II — the four-stage pipeline: signal, sizing, risk, execution

Collapsing a strategy into one function that goes from tick to order is the blob anti-pattern of this domain. The
load-bearing separation — long established in practice, including the side-versus-size split the quantitative
literature formalized — is a pipeline of four pure stages, composed by events:

**Signal** — direction and conviction only; its output is a desired exposure, not a quantity. **Sizing /
portfolio** — turns desired exposure into quantity under capital and concentration rules; the classic families
(fixed-fractional, volatility-targeted) are pure functions of state, and which one, with what numbers, is a product
decision this article does not make. **Risk gates** — pre-trade checks as gating deciders (Pattern V); a gate's only
verbs are pass, clamp, refuse. **Execution** — turns the surviving intent into child orders over time; the
execution-algo archetype is this stage promoted to a strategy of its own.

Each stage is a Decider; each boundary is an event; any stage can be replayed, swapped, or shadowed alone. The
pipeline is also where the cross-aggregate rule from the engine patterns lands for pairs trading: the *signal* stage
may read a multi-instrument projection (a fold over several streams), but intents still target one book each, and any
multi-leg atomicity is a saga over the event log — compensating intents — never a distributed lock.

## Pattern III — the strategy host

The shell around the pure core, on as-built parts. One supervised process per (strategy, scope) — scope being an
instrument for making and reversion, an instrument set for pairs — holding `StrategyState` and nothing else worth
mourning. Its inputs arrive three ways, all as events: **market data** from the claims bus — 29-byte
`(id, version)` claims resolved through the immutable term cache (`bcsG.md`), so a strategy reading the
same delta as forty others costs the platform one decode; **own fills**, consumed from the event log like any other
projection; and **time**, which deserves its own paragraph.

**Event time, not wall time.** Bars close, windows roll, and schedules tick on the time *inside* the events — the
mint instant carried by every branded id — not on the host's clock. The host synthesizes `TimerEvent`s (bar
boundaries, schedule slots) and feeds them through `decide` like any other event, which makes time-driven behavior
replayable: in a backtest the same timers fire at the same sequence points because they are derived from the same
ids. A strategy that reads the wall clock inside `decide` has smuggled an effect into a pure function and broken
replay; the harness should make that mistake loud.

**Recovery is replay.** Strategy state is a fold, so a crashed host rebuilds by folding its inputs — the Chapter 4.4
posture, inherited rather than reinvented. Long-lived strategies checkpoint the fold (a snapshot event carrying a
branded version) so recovery is snapshot-plus-tail, and the snapshot is itself replay-verifiable.

## Pattern IV — the OMS: an intent's lifecycle is a state machine

Between a strategy's intent and an exchange's fill sits the order-management state machine, and its transitions are
the platform's at-least-once truth made explicit:

```
intent -> submitted -> acked -> (partial*)
       -> filled | cancelled | rejected | expired
```

Three rules make it robust. **Idempotent submission**: the branded intent id is the dedup key end to end — a resend
after a crash collides on the id and becomes a no-op, the same admission-dedup mechanic the bus already gates.
**Exactly-once intent over at-least-once transport**: the strategy may emit once and the plumbing may deliver twice;
the state machine absorbs the difference, and the harness proves it by replaying deliveries. **Reconciliation as a
consumer**: a periodic sweep folds the venue's view against the machine's view and emits correction events — never
in-place fixes — so even disagreement is on the log. Cancel/replace storms (the market-making demand) are this
machine under load, and its budget is Pattern V's business.

## Pattern V — risk as gating deciders, and the kill switch that already exists

Pre-trade risk is a chain of pure gates between sizing and execution: per-instrument and aggregate exposure caps,
fat-finger bounds (quantity and notional sanity), rate budgets (intents per window — the Ring's lesson applied at
this door: a counted refusal beats a discovered queue), and self-match prevention. Each gate is
`gate(Intent, RiskState) -> pass | clamp | refuse`, each refusal is an event with a reason, and the chain is
property-tested as a unit: no sequence of inputs may produce an intent that violates a cap.

Two as-built mechanics do the operational half. **Positions and exposure read from Tables** — projections folded
from fills, served at hit speed with newer-wins versions, so a gate's view is fast and fenced rather than fast and
stale. And **the kill switch is a lane verb**: route a strategy's intents through its own EchoMQ group and the
committed pause/resume/limit controls of Chapter 3.4 *are* the kill switch, the throttle, and the slow-restart — per
strategy, behind one identity, with depth observable. No new machinery; the fairness rung built the safety rung.

## Pattern VI — evaluation: one implementation, replayed; and why backtests lie

The parity law first, because everything else depends on it: **the backtest is the live system replayed**, not a
second system. The same `decide`, the same pipeline, the same OMS machine, fed from a recorded stream instead of the
live one; the only swapped part is the fill model (live venue versus simulated fills), and that seam is one module
with two implementations, stated. Anything less — a vectorized research harness over here, a production engine over
there — is the two-implementation drift this whole architecture exists to delete.

Then the trap with mathematics behind it. Run enough parameter variants over the same history and the best one's
performance is partly an artifact of the search itself — selection bias under multiple testing — and the standard
summary statistics inflate accordingly; this is the failure mode Bailey, Borwein, López de Prado, and Zhu formalized,
with deflation procedures that account for the number of trials [1]. The engineering consequences this platform
adopts, without prescribing anyone's statistics: **every trial is a record** — a backtest run gets a branded run id,
its config version, and its committed result, because deflating for the number of trials requires knowing the number
of trials; **selection happens out of sample** — walk-forward splits where parameters chosen on one window are judged
on the next, with the split a property of the harness, not the researcher's mood; and **survivors graduate through
shadow** — a strategy that wins the harness runs next on live events with intents routed to a sink lane (paper mode:
the full pipeline, the OMS machine, zero venue orders), then to a canary lane with a small budget, then to its full
lane — promotion as lane wiring, demotion as the same wiring reversed, every stage observable by group depth.

## Pattern VII — parameterization, identity, and versions

A strategy in production is code plus configuration plus a lineage, and all three are first-class. The strategy gets
a branded id (its kind is its kind law — gates refuse intents whose strategy id is unknown or paused); its
configuration is a versioned object on the claim-check bus — change the config, mint a new version, and every host
resolves the new claim with the staleness law doing the rollout fencing; and its lineage — which config version,
which code release, which evaluation records — is a fold over those versions, queryable because every piece carries
mint-ordered ids. Two strategies A/B by running as two strategy ids on two lanes over the same signals; the
comparison harness reads two event streams and needs nothing invented.

## Anti-patterns, named

**Lookahead leakage** — any read of information minted after the decision's sequence point (the close inside its own
bar, the fill inside its own intent). The event-time discipline makes it structurally awkward; the replay harness
makes it loud, because a leaky strategy replays differently than it ran. **The indicator cache shared by mutation** —
rolling statistics updated in place by many readers; the cure is indicators as projections, folded and versioned like
every other read model. **The strategy that touches the book** — strategies emit intents; only the engine mutates a
ladder; any shortcut is a second writer and the invariant's end. **Unbounded emission** — a strategy with no intent
budget can spam the OMS into the ground; the budget gate is not optional equipment. **The bespoke backtester** — the
drift machine; if the research harness cannot run the production `decide` unchanged, the harness is the bug.
**Wall-clock decisions** — covered above, smuggled effects break replay. And **the silent parameter sweep** — trials
that leave no record make every reported result undeflatable [1]; the run-id discipline is the cure.

## The final table

| Pattern | Solves | As-built seat | Becomes a gate when |
|---|---|---|---|
| Strategy-as-Decider, intents out | testability, replay, explainability | pure core under a supervised host | its rung property-tests the strategy invariants |
| Four-stage pipeline | the tick-to-order blob; pairs without locks | Deciders composed by events | stage-swap and shadow tests |
| The host | fan-in, event time, recovery | claims bus + term cache, snowflake time, fold recovery | crash-and-replay equals live |
| OMS state machine | at-least-once made survivable | branded-id dedup, log-recorded corrections | duplicate-delivery and reconcile drills |
| Risk gates + lane kill switch | caps, budgets, the off button | gating deciders; Chapter 3.4 lane verbs per strategy | cap properties; pause-under-storm drill |
| Replay evaluation | two-implementation drift; inflated discoveries [1] | one `decide`, recorded streams, run-id records, shadow→canary lanes | walk-forward harness; promotion drill |
| Identity & versions | rollout, rollback, lineage | branded strategy ids; config as versioned claims | staleness-fenced config rollout test |

One sentence the Exchange Platform can hold: *strategies are pure deciders over event time, wrapped in supervised hosts, gated by
pure risk, executed through an idempotent machine, evaluated by replaying themselves, and promoted by wiring lanes —
and every claim any of them makes is a committed record or it is not made.*

## References

1. Bailey, D. H., Borwein, J. M., López de Prado, M., Zhu, Q. J. — Pseudo-Mathematics and Financial Charlatanism:
   The Effects of Backtest Overfitting on Out-of-Sample Performance, Notices of the AMS, Vol. 61 No. 5 (2014) — the
   formal case that selection under multiple trials inflates backtested performance, and the deflation that corrects
   for it: [www.ams.org/notices/201405/rnoti-p458.pdf](https://www.ams.org/notices/201405/rnoti-p458.pdf)
