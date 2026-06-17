# BCS · Chapter 3.4 — Fair lanes

<show-structure depth="2"/>

The bus learns fairness, and learns it the way this series learns everything: as a construction, not a hope. A lane is a per-group pending set named by an identity; the ring is the rota — a list holding exactly the lanes that can be served right now — and every claim rotates it one step before serving, so no lane's storm can bury another lane's trickle. The rung (`bcs_rung_3_4_check.exs`, committed record ending `PASS 8/8`) gates the surface, the rotation, the concurrency ceiling, pause and resume, the parked consumer's zero-cost idle, the loop that drives 3.3's pumps — and, as the table of contents promised, the starvation refusal sits in the record as a gate, not a paragraph: `the quiet lane's last job is served at position 40 of 420 while the flat queue, fed the same arrival order, serves its first quiet job at position 401`.

## Why

A shared queue is a shared fate. The moment two tenants ride one pending set, the busier one owns the latency of both — head-of-line blocking across identities, the oldest unfairness in queueing — and on the trading desk the stakes are concrete: one portfolio rebalancing with four hundred fills must not delay another portfolio's single stop-loss by four hundred positions. The cure the networking literature settled on decades ago is round-robin service across per-flow queues, fair by construction and O(1) per decision [3], and the part's preface adopted it as law: fairness across groups is constructed — round-robin lanes by assignment — never hashed. This chapter builds that law into the machine, prices idle consumers at zero while it is at it, and gives operators the two verbs every incident eventually needs: pause one lane, cap one lane, touch nothing else.

## What

**The lanes, and the ring invariant.** A group's lane is `emq:{q}:g:<group>:pending` — a score-zero sorted set exactly like 3.2's pending, so lex order is mint order and every lane is FIFO, browsable, and range-cuttable for free. The ring at `emq:{q}:ring` is a plain list under one invariant the whole chapter rests on: *the ring contains exactly the serviceable lanes* — nonempty, unpaused, below their concurrency ceiling — *and every transition maintains it*. Enqueue inserts a lane the moment it becomes serviceable; claim removes one the moment it stops being so; complete, retry, reap, promote, resume, and limit each re-evaluate the one lane they touched. Park states are derived, not stored: a lane out of the ring with depth is parked, and the only explicit marker is the `paused` set, because pause is the one parking an operator orders rather than the machine deduces.

**The rotating claim.** `LMOVE` with the same source and destination is the engine's documented list-rotation primitive [1], and the claim script is that rotation with 3.3's token mint attached: rotate the ring one step, pop the lex-oldest id from that lane, `HINCRBY` the attempts, stamp the server-clock lease into the shared active set, count the lane's in-flight, and re-decide the lane's membership before returning. The rung stages it twice. G2 is the small proof — `twelve claims walk the ring four full turns -- three lanes, strict rotation -- and every lane serves in mint order` — and G3 is the headline: a four-hundred-job storm against a twenty-job lane, drained in one sitting, with the quiet lane's positions landing at 2, 4, ... 40 by arithmetic. The committed line carries the contrast, because the same arrival order through 3.2's flat queue serves the first quiet job at `position 401 -- rotation is the refusal`.

**The ceiling and the pause.** Per-lane concurrency lives in one hash and one rule: at the ceiling, the lane leaves the ring; below it, any transition that frees a slot puts the lane back. G4 holds the line at two — `limit 2 holds: two leases out and the third claim answers empty with the lane parked at its ceiling and gactive reading 2; one complete reopens the lane and the next claim is served`. Pause is the operator's parking: it removes the lane from rotation and touches nothing in flight, because stopping new claims and killing live work are different verbs and only the first is wanted during an incident. G5 stages the round trip — `pause removes the lane from rotation with its backlog intact at depth 3; resume returns it and the ring serves the parked three in mint order`.

**Park, don't poll.** Readiness is a key: every transition that inserts a lane into the ring also pushes a token onto `emq:{q}:wake`, and an idle consumer blocks on it with `BLPOP` — the engine parks that one client, not the server, and wakes it on the push or the timeout, whichever lands first [2]. The wake list is capped with `LTRIM` and over-delivery is harmless by design, because the consumer drains claims to empty before parking again; a spurious wake costs one empty claim, a missed wake would cost a stall, and the design buys the cheap failure. G6 prices the whole idea on the wire: `parked on the wake key the consumer spends 0 commands in a 400 ms idle window where a 10 ms poller spent 37; the wake answers an enqueue in 0 ms against a 5000 ms beat -- park, don't poll`. The parked consumer holds its `BLPOP` on a dedicated connector, exactly as Appendix B's law requires — a blocking verb on a shared pipeline would make one consumer's park everyone's head-of-line.

**The loop owns the rhythm.** Chapter 3.3 shipped reap and promote as correct beats with no metronome; this chapter is the metronome. `EchoMQ.Consumer` is a supervised process around one cycle — reap, promote, drain, park — with the `BLPOP` timeout doubling as the pump cadence, so crash recovery and schedule promotion ride the same heartbeat that wakes the worker. G7 stages both pumps through the loop alone: `a 60 ms lease left orphaned is reaped on the beat and served with token 2; a flaky job retries through the schedule and lands with token 2 -- the lane's count clears, the ring empties`.

**The reap window, closed.** Designing the lane bookkeeping surfaced a window 3.3's machine carries: a holder that finishes *after* the reaper has already returned its job to pending completes a row the queue still lists, leaving a ghost id behind. The token does not catch it — the fence increments at the next claim, not at the reap — so the transitions now catch it themselves: complete and retry detect the missing lease and retire the requeued copy wherever it sits. G8 gates the fix on both machines: `a holder completing token 1 after the reaper retires the job everywhere -- no ghost in the lane, none in pending, the ring empties and the count clears`.

## Who

Tenants — portfolios, in the worked frame — whose isolation is now structural: a lane is named by an identity, and the fairness the ring constructs is fairness between identities. Operators, for whom `pause`, `resume`, `limit`, and `depth` are the incident console: cap the noisy neighbor, freeze the suspect lane, read the backlog, all without touching any other tenant's flow. Consumers, whose whole obligation is to exist under a supervisor: the loop claims, works, settles, and parks, and the wake key does the rest. And Chapter 3.5, which takes this supervised citizen and seats it in Part II's ownership tree, where results flow back into the stores.

## When

Choose the group to be the identity whose fairness you owe — the portfolio, the tenant, the customer — not a load-balancing hash; the ring equalizes whatever you name, and naming the wrong thing constructs the wrong fairness. Set a ceiling where the work's downstream is per-identity scarce (one exchange session per portfolio admits two concurrent fills, so `limit 2` is the truth of the venue, not a tuning guess). Reach for pause during incidents and reconciliations, never for backpressure — a paused lane grows without bound, and the ceiling is the backpressure verb. And size the beat well under the lease: the beat is how late a crash is noticed, the lease is how long a crash holds a job, and the two figures should embarrass neither your monitoring nor your retry tolerance.

## Where

The lanes module at `runtimes/elixir/lib/echo_mq/lanes.ex` — six verbs, five scripts, the lane key gated by the identity contract; the loop at `lib/echo_mq/consumer.ex`; the four grown transitions inside `lib/echo_mq/jobs.ex`, ungrouped path unchanged, with the part's earlier rungs re-run green against the grown module this session. The rung and its committed record sit with the part's others.

## How — the rotation in Lua, the loop in Elixir, the same wire from Go

**The claim's heart.** Rotation, then 3.3's mint, then membership:

```lua
local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
if not g then return {} end
local lane = ARGV[1] .. 'g:' .. g .. ':pending'
local popped = redis.call('ZPOPMIN', lane)
-- token mint and lease exactly as Chapter 3.3 wrote them, then:
local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
if lim and act >= tonumber(lim) then
  redis.call('LREM', KEYS[1], 0, g)
elseif redis.call('ZCARD', lane) == 0 then
  redis.call('LREM', KEYS[1], 0, g)
end
```

**The loop.** One cycle, four verbs, a dedicated connector:

```elixir
defp loop(s) do
  {:ok, _} = Jobs.reap(s.conn, s.queue)
  {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)
  drain(s)            # rotating claims until :empty
  park(s)             # BLPOP on the wake key, beat_ms as the timeout
  loop(s)
end
```

**Go.** Nothing ports, again, because the scripts are the contract: the same bytes yield the same SHA1 and the same rotation from any runtime. A Go consumer is the same cycle around the same EVALSHA calls, parking with `BLPOP` on its own connection and reading the fourth reply element as its group.

## Decisions

**Lanes are named by identities.** The group in a lane key must parse as a branded id — wellformedness at the function, exactly where `job_key` put it — so the fairness the ring constructs is fairness between identities, and the per-portfolio lane is the worked case rather than a special one.

**The ring invariant is the design.** Membership equals serviceability, maintained by every transition that could change it; park states are derived from the structures rather than stored beside them, and `paused` is the one explicit marker because it records an operator's order.

**The constructed-key exception, second use, same sanction.** Claim and the grown transitions build lane and job keys from the queue's own prefix because the group is unknown until rotated and the id until popped; 3.1's co-location law is what makes every such key same-slot legal, and 3.3's boundary stands unchanged — a key derivable from the queue's prefix is the only construction there is.

**Pause stops claims, not flight.** In-flight work settles through its own complete or retry; an operator who needs work killed has a different problem and deserves a verb that says so.

**The wake rides every ring insert, capped and over-delivering.** A consumer drains to empty before parking, so extra tokens cost an empty claim and missing tokens cannot happen; `LTRIM` bounds the list because sixty-four pending wakes inform exactly as well as a thousand.

**The membership helper repeats in six scripts.** Each script stays a self-contained vector for behavior — same bytes, same SHA, any client — and the dozen duplicated lines are the price. A shared server-side library is the Functions evaluation's day, under its own review gate.

**One machine, not two.** Grouped and flat jobs share the active set, the schedule, the morgue, the token discipline, and the five transitions; the lanes add admission and rotation, and the ungrouped path through the grown scripts is behavior-identical — the part's earlier rungs are the regression evidence.

## Boundaries

Rotation equalizes job *counts*, not job *costs*: a lane of slow jobs still buys more wall-clock than a lane of fast ones, and the weighted or deficit variants that fix this for variable service sizes [3] are a future knob under its own gate, not a hidden feature of this one. Ring membership checks ride `LPOS` and `LREM`, linear in the ring — the design assumes lanes number in the portfolios, not the orders. Reap does not consult `max_attempts`: only a retry verdict can dead-letter, so a consumer that crashes on every attempt leaves its job cycling, and the cap on that cycle is an operator alert, not this chapter's script. The consumer ships minimal by intent — graceful drain-and-stop, handler crash isolation, and its seat in the ownership tree are Chapter 3.5's, where the loop becomes one more owner. And one consumer per dedicated connector is the law, not a default: N consumers are N lanes on the wire, and the pool stays for the non-blocking traffic it was built for.

## Companion files

`runtimes/elixir/lib/echo_mq/lanes.ex`, `lib/echo_mq/consumer.ex`, and the grown `lib/echo_mq/jobs.ex`; `bcs_rung_3_4_check.exs` and its committed record `bcs_rung_3_4_check.out`.

## References

1. Valkey documentation — LMOVE (same source and destination as the documented list-rotation primitive under the ring): [valkey.io/commands/lmove](https://valkey.io/commands/lmove/)
2. Valkey documentation — BLPOP (blocking pop with a double-precision timeout; the park that costs the wire nothing and wakes on the push): [valkey.io/commands/blpop](https://valkey.io/commands/blpop/)
3. Shreedhar, M. and Varghese, G. — Efficient Fair Queuing Using Deficit Round-Robin (round-robin service across per-flow queues as the O(1) fair-share construction, stated applicable to scheduling problems beyond packets): [openscholarship.wustl.edu](https://openscholarship.wustl.edu/cgi/viewcontent.cgi?article=1339&context=cse_research)
