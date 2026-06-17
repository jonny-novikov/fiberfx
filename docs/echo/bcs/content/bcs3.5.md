# BCS · Chapter 3.5 — The bus meets the stores

<show-structure depth="2"/>

Part III closes its loop. A command leaves a system as a message about identities, rides the fair lanes, and its result returns as a first-class property write that carries the job's own name as the receipt — and that one design move turns the bus's at-least-once delivery into exactly-once *effect*, because a row that remembers the names it has absorbed can decline a name it has seen. The rung (`bcs_rung_3_5_check.exs`, committed record ending `PASS 6/6`) gates the round trip through a live supervision tree, the torn-effect window healing by provenance, the consumer's seat as one more owner, the audit dividend, and a stop verb that drains on both the bare and the supervised path. The boundary law of the whole series performs end to end here: encapsulation boundaries are drawn around systems, and the only values that cross are identities and messages about identities.

## Why

Two industries supply the same stake from opposite ends. On the trading desk it is the double fill: Chapter 3.3 fenced the zombie *on the bus*, but at-least-once delivery is a promise to redeliver, so a consumer that dies between applying a fill and acknowledging it will see that fill again — and a position incremented twice is the same money lost politely. In the lineage this series descends from, the Dark Engine's property database under a damage system, the bug wears a different costume and the same bones: an apply-damage command redelivered after a crash kills the player twice. Helland's analysis of systems that reject distributed transactions names the shape of the cure — entities are atomically updatable within and never across, messaging is at-least-once, and idempotence means the recipient *remembers* that a message has been processed [1]. What it leaves open is what, exactly, to remember. BCS has had the answer since Part I: remember the *name*. Every job carries a branded identity; every effect can carry it too; and a row that keeps the names that wrote it is its own deduplication table, its own audit line, and its own replay guard, in fourteen bytes per memory.

## What

**The recipe.** The worked flow is the trading frame on real Part II surfaces: a fill command enqueued onto the fair lanes — grouped by portfolio, Chapter 3.4's dividend reused — whose payload is two names and two numbers, and a handler that writes two rows back through `EchoData.Bcs.PropertyStore`: the order's row (`state`, `qty`, `px`, `provenance`) and the portfolio's position, which keeps a map of every fill name it has absorbed beside the total. Each write is guarded by its own row's memory: the order declines when its `provenance` already names this job, the position declines when its fills map already holds it. B2 stages the clean pass: `a fill leaves as two names and two numbers and lands as two property writes through the tree -- the ORD row filled qty 7 at 105, the PRT position absorbing the job's name as its receipt, the row on the bus gone`. Completion still deletes, exactly as 3.3 decided — the receipt lives in the store now, which is what that deletion was waiting for.

**The torn middle.** Two writes against two owners admit no transaction, and the chapter refuses to pretend otherwise; what the recipe buys instead is indifference to where the tear lands. B3 crashes the handler *between* the writes on attempt one and lets the machine answer: the raise converts to a typed retry — `last_error: torn between writes` riding the job row, the part's vocabulary for failure since 3.3 — the same loop pid serves attempt two, the position declines the name it already absorbed, and the order completes. The committed line carries the arithmetic that matters on a desk: `qty 12 once, never 17`. Each row lands exactly once; the order of the writes stops being a correctness decision and becomes a style one.

**One more owner.** The supervision tree in the rung is three children under `one_for_one` — two property stores and the consumer — which is the whole architectural sentence: the loop that drives the bus is a peer of the stores it feeds, restarted alone when it dies, started and stopped in tree order like any owner [2]. B4 is the drill Chapter 2.1 ran for stores, run for the bus: the consumer is killed brutally mid-fill, `the one_for_one tree restores it alone -- the stores never blink and their rows survive -- the orphaned lease reaps on the new pid's beat and qty lands 15 exactly once with token 2`. Part II's law was *existence restored, data not*; this chapter adds the bus's half — unfinished work is the one thing a restart never erases, because it never lived in anyone's heap.

**The audit dividend.** Because results are rows keyed by branded names, the audit trail is not a feature, it is the store. B5 pages the order store newest-first and reads the provenance back: `five fills page newest-first by name alone, every row carrying the JOB that wrote it, the position remembering all five names for qty 18` — the order theorem's next appearance, now spanning the bus and the store in one walk. Failures browse the same way from the other side: the morgue holds them with `last_error` attached, so success and failure are both one page away, both addressed by name.

**Stop is a drain.** The consumer hardens into a citizen that can be told to leave. The loop now traps exits, so control arrives as messages and is honored at the settle points — between jobs, never inside one. A stop request drains to a `:normal` exit; the supervisor's own `:shutdown` drains the same way, which makes `Supervisor.terminate_child/2` the graceful stop under a tree; and the dedicated lane dying takes the loop with it for the tree to restart. B6 gates both paths: `the supervisor's terminate_child settles the fill in hand and never claims the next -- depth 1 remains with attempts 0 -- and a bare loop answers stop with a normal exit`. A handler that outruns the supervisor's shutdown window meets the brutal kill — and even that ending is safe, because the lease and the reap were built for exactly the consumer that never got to say goodbye.

## Who

Trading systems, where portfolio and risk are Part II systems and the bus between them moves fills, marks, and reconciliations as names — the per-portfolio lane keeping one book's storm out of another's latency, the provenance map keeping every retried fill single. Game systems, the lineage repaid: damage, loot, and aggro as consumers over the property database, where a redelivered hit declines by name instead of killing twice, and the position map's exact analogue is the hp row remembering its wounds. Operators, for whom the postmortem surface is now one vocabulary — page the store for what landed, page the morgue for what gave up, read `last_error` and the provenance and know which job did what. And Chapter 3.6, which takes this whole tower to the referee: conformance, the committed harness, and the transactional-enqueue rival with its advantage printed in its own row.

## When

Prefer effects that live in one row of one owner; reach for the per-row guard the moment an effect spans two, and let write order become style. Keep the guard a *map of names*, not a last-writer field — interleaved jobs on one position make a `last_fill` field lie, while the absorbed-names map cannot be confused by order. Use `stop/2` when you own the loop directly and `terminate_child` when a tree does; size the shutdown window above your handlers' true running time and let the lease cover the ones that lie. And when a result must outlive a store restart, remember which law owns that: durability is deferred by decision D-2, and the provenance-carrying row shape is deliberately the replay-ready one for the day it lands.

## Where

The hardened loop at `runtimes/elixir/lib/echo_mq/consumer.ex` — crash isolation, the control check, `stop/2` — with `jobs.ex` and `lanes.ex` untouched by this chapter and the Part II store modules untouched by construction: integration here is composition, not modification. The rung and its committed record sit with the part's others, and the part's earlier rungs re-run green against the hardened module this session.

## How — the guard in Elixir, the same recipe from Go

**The guard idiom.** The whole exactly-once recipe is a membership check before a write, quoted from the rung's committed handler:

```elixir
fills =
  case PropertyStore.get(:positions35, prt) do
    {:ok, %{fills: f}} -> f
    _ -> %{}
  end

unless Map.has_key?(fills, job) do
  f2 = Map.put(fills, job, qty)
  :ok = PropertyStore.put(:positions35, prt, %{fills: f2, qty: f2 |> Map.values() |> Enum.sum()})
end
```

**The isolation.** A raising handler becomes the machine's own vocabulary — one rescue, one typed retry:

```elixir
verdict =
  try do
    s.handler.(%{id: id, payload: payload, attempts: att, group: group})
  rescue
    e -> {:error, Exception.message(e)}
  catch
    :exit, reason -> {:error, "exit: " <> inspect(reason)}
    :throw, value -> {:error, "throw: " <> inspect(value)}
  end
```

**Go.** The bus side ports for free, as every chapter since 3.2 has said: same scripts, same SHA, same claims. The store side is the owner-goroutine pattern Part I designated, and the guard is the same three lines in any syntax — read the row, check the name, decline or write. A Go fill handler against its position map differs from the Elixir one only in the language of the map.

## Decisions

**Results are property writes carrying provenance.** Chapter 3.3's pre-statement collected: completion deletes on the bus because the receipt now lives in the store, a first-class row whose value names the job that produced it.

**Every row guards itself by the names it has absorbed.** Helland's recipient-remembers requirement [1], made concrete the BCS way: the memory is a branded name, the table is the row itself, and the guarantee is per-row exactly-once effect under at-least-once delivery — per entity, never across entities, exactly as the source's own scaling argument demands.

**The consumer traps exits.** Graceful stop is a protocol with the supervisor, not a courtesy flag: control lands as messages, the settle points are the only exits, and `:shutdown` drains the same way a stop request does.

**Failure converts; violation crashes.** A raise, throw, or exit inside a handler is one job's failure and becomes a typed retry with the message kept; a handler that breaks its return contract crashes the loop for the tree to restart, because a contract violation is not a job outcome.

**The lane's lifetime is the owner's choice.** A self-started connector dies and returns with the loop; a caller-provided one outlives restarts and carries the new pid's traffic. Both are lawful under Appendix B's law; the rung exercises the second so the drill could be brutal and quiet at once.

## Boundaries

No cross-store transaction exists and none is promised: the recipe yields exactly-once per row, and between a torn pair's healing there is a window in which one store shows the effect the other does not yet — readers that need a joined view need a join-owning system, which is Part II's own law pointing back at itself. Replay of completed work is not this chapter's verb: the audit row is the receipt, and full event history belongs to EMQ 3.0's Streams by decision D-3. Store durability is unchanged by decision D-2 — a store restart still loses rows, 2.1's clean slate — and what the bus preserves across that is unfinished work, with the provenance shape standing ready for the durability chapter. The absorbed-names map grows with a position's fills; compacting settled names into a baseline is an operational knob under a future gate, not a silent behavior. And the brutal-kill ending, while safe, is not free: the job in hand at the kill is redelivered whole, which is precisely the at-least-once the guards exist for.

## Companion files

`runtimes/elixir/lib/echo_mq/consumer.ex` (hardened); `bcs_rung_3_5_check.exs` and its committed record `bcs_rung_3_5_check.out`; the Part II stores at `lib/echo_data/bcs/property_store.ex` and `lib/echo_data/bcs.ex`, cited as shipped and untouched.

## References

1. Helland, P. — Life beyond Distributed Transactions: an Apostate's Opinion, CIDR 2007 (entities atomically updatable within and never across; at-least-once messaging; idempotence as the recipient remembering the message): [cidrdb.org/cidr2007/papers/cidr07p15.pdf](http://cidrdb.org/cidr2007/papers/cidr07p15.pdf)
2. Erlang/OTP stdlib — `supervisor` (one_for_one restart isolation, start and shutdown in tree order — the owner semantics the consumer joins): [erlang.org/doc/apps/stdlib/supervisor.html](https://www.erlang.org/doc/apps/stdlib/supervisor.html)
