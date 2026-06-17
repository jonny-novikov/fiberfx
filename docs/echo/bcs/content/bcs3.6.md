# BCS · Chapter 3.6 — Conformance and the rival's numbers

<show-structure depth="2"/>

Part III ends at the referee's table. Three things are delivered and gated here (`bcs_rung_3_6_check.exs`, committed record ending `PASS 6/6`): the tower's behavior packaged as a portable artifact — fourteen wire-level conformance scenarios that any port can drive to the same verdicts; the referee habit performed in the open — every measurement in the committed record is preceded by the derivation that predicted it; and the rival, stood up whole in this container — Oban 2.18.3 on PostgreSQL 16.14 — measured on the same core as the bus, with its advantage printed not as a concession in prose but as a gated row of its own. The record states the asymmetry before any number: `the rival's enqueue is durable and transactional (a WAL flush per commit); the bus's enqueue is volatile by decision D-2 and pays no fsync -- every number below carries that trade`.

## Why

A benchmark without a derivation is a vibe with digits, and a rival measured without its advantage is a strawman with a latency chart. The desk deserves better on both counts, because choosing the bus is a money decision with two columns: the column where the bus wins — wake latency, wire throughput, drain rate — and the column where the rival wins — an enqueue that is atomic with the business write and durable the moment it returns. A chapter that shows only the first column is marketing. And the conformance half answers a debt five chapters old: every gate so far certifies *this Elixir client* against *this server*; the Go port the series has promised since Part I needs the contract as a runnable artifact, not as a memory of what the rungs once asserted. The scripts already travel — same bytes, same SHA, any runtime — so the missing piece was the verdict list that says what driving them correctly looks like.

## What

**The committed harness.** `EchoMQ.Conformance` is fourteen scenarios over the public surface and, where the contract *is* the wire, over raw commands: the fence, the row shape, idempotent admission, the kind law, the lex law, the token discipline, the schedule, the morgue, the reaper, rotation, pause, and the ceiling. Each prints its contract as one line — `enqueue admits a JOB name and writes the three-field row: state pending, attempts 0, payload`; `a stale token's completion is refused EMQSTALE; the live token still settles`; `the pending set walked REV BYLEX answers newest-first by name alone` — and the full run sits inside the rung's committed record: `fourteen of fourteen contracts hold against the live server`. The scenarios are wire-level on purpose: a Go client that drives the same scripts to the same fourteen verdicts conforms, and the harness ports by translation, not by faith. Scenarios run on per-scenario sub-queues and purge what they mint, under the same fixture-ownership policy the part's rungs follow.

**The harness drew blood on day one.** Running it on this session's cold server caught a real connector defect that five rungs of green had never seen: `eval`'s load-on-NOSCRIPT retry returned the retried reply *raw*, skipping the mapping that turns a script's error reply into the typed `{:error, {:server, msg}}` verdict. On a warm script cache the path never executes; on the first-ever transition after a server start, a legitimate `EMQSTALE` refusal came back wearing the wrong shape. The fix is four lines — both attempts now speak one verdict language — and the harness keeps the catch forever: the stale scenario now issues `SCRIPT FLUSH` first, so every future run exercises the cold path on purpose. A conformance suite that has never caught anything is decoration; this one paid rent before it shipped.

**The referee habit, performed.** The committed record interleaves `derive` lines with measured ones, in that order, so the prediction is on the page before the number is. The bus's bands came from Appendix A's committed baselines — 29,456 sequential and 454,483 pipelined round trips per second — discounted for script work; the rival's from its substrate's own documentation: a synchronous commit waits for the transaction's WAL records to reach disk, and for short transactions that wait is the major component of the time [2]. The habit also includes confessing its misses: the first run's derivation for the rival's batched insert (20,000 to 80,000 per second) ignored the per-row cost of jsonb argument encoding and index maintenance on `oban_jobs`, and the measurement landed below it. The band was re-derived from that reasoning — `expect 8,000 to 40,000 per second` — before the committed run, and the miss is recorded in the ledger rather than smoothed over. Bands adjusted after the fact are not derivations unless the adjustment is itself derived and confessed.

**The rival's numbers.** One core, one container, both stacks in one VM, versions in the record's header. The committed line: `sequential enqueue 11422/s bus vs 619/s rival; batched 78980/s bus vs 13716/s rival (7000 rival rows landed); end-to-end median 0.3 ms bus vs 8.8 ms rival; drain of 3000: 6092/s bus vs 944/s rival -- the derived order holds, and the rival's slower row is the durable one`. Every gap traces to one structural fact, and naming it is the point. Sequential, eighteen to one: the rival pays a WAL flush per commit and the bus pays none [2]. Batched, five-point-eight to one: the flush amortizes across the statement, leaving jsonb encoding and index maintenance as the per-row cost. Median latency, twenty-nine to one: the rival's wake is `NOTIFY`, delivered only at commit and in commit order [3], followed by a fetch query — the bus's wake is a list push answered by a parked `BLPOP`. Drain, six-and-a-half to one: acknowledging a job on the rival is an UPDATE and its own commit, one flush per job; completing on the bus is one EVALSHA. The rival is not slow; the rival is *durable per row*, and the table prices exactly that.

**The advantage in its own row.** Gate C6 stages what the bus cannot do. One Ecto transaction inserts the fill and its job through the documented `Ecto.Multi` pattern [1]; a rollback erases both, a commit lands both — the committed line reads: `enqueue is atomic with the business write -- one transaction carries the fill and its job, rollback erases both, commit lands both; the bus cannot say this sentence -- its enqueue and its store write are two systems, the torn window of Chapter 3.5 is the price, and the provenance guard is the mitigation, not the cure`. That row is a gate with assertions, not a paragraph of fairness theater: the rung counts the rows after the rollback and after the commit, and the chapter's claim is exactly as strong as those counts.

## Who

Desks choosing a substrate, who now hold the two-column page the decision needs: a sub-millisecond wake and six thousand completions per second per core, volatile by D-2 and guarded by 3.5's provenance — against nine milliseconds and nine hundred durable, transactional rows per second at the rival's defaults. Platform teams carrying the Go port, for whom the harness is the acceptance test: fourteen verdicts over the same scripts, no Elixir required to know what correct looks like. Operators, for whom the referee header is the runbook's first line — the numbers a healthy system should show, derived before measured, so an anomaly is a *deviation from a stated band* rather than a feeling. And the composition case both columns license: the rival as the durable, transactional intake where the enqueue must commit with the order, the bus as the hot path behind it — Chapter 3.5's consumer is precisely the bridge that lets one system's durable fact become the other system's fast work.

## When

Reach for the bus when latency, fan-out, and per-core drain rule, and the effects behind it carry their provenance guards. Reach for the rival when the sentence *the job exists if and only if the business row exists* is a requirement rather than a preference — no amount of wire speed buys that sentence on two systems. Run both when the workload splits that way, and let the advantage row decide which work lands where. And when benchmarking anything: state the asymmetry first, derive before measuring, pin every version into the record's header, run both sides on the same silicon, and let the rival keep its defaults unless the chapter says otherwise — a tuned rival is a different chapter, and `synchronous_commit off` would close much of the sequential gap at the price of the very guarantee being measured [2].

## Where

The harness at `runtimes/elixir/lib/echo_mq/conformance.ex`; batch admission grown into `lib/echo_mq/jobs.ex` (`enqueue_many/3` — one pipeline flush, per-item verdicts, the same script and idempotency as `enqueue/4`); the connector fix in `lib/echo_mq/connector.ex` with the cold-path regression pinned in the harness. The rival lives in its own Mix project at `/home/claude/oban_bench` — Oban 2.18.3, Ecto, Postgrex, vendored and compiled in this container — and the rung runs under it so both stacks share one VM: `cd /home/claude/oban_bench && mix run /home/claude/echo_data/runtimes/elixir/bcs_rung_3_6_check.exs`. The committed record sits with the part's others, and the whole tower — 3.1 through 3.5 plus both Appendix B connector rungs — was re-run green against the grown modules this session.

## How — the harness as the port's contract

**Driving the harness** is two lines from any Elixir session, and the same two verdicts from anywhere:

```elixir
{:ok, c} = EchoMQ.Connector.start_link(port: 6390)
{:ok, 14} = EchoMQ.Conformance.run(c, "conf")
```

**Batch admission**, the chapter's one surface addition, is the enqueue script flushed once:

```elixir
pairs = for _ <- 1..5_000, do: {BrandedId.generate!("JOB"), payload}
{:ok, verdicts} = Jobs.enqueue_many(conn, queue, pairs)
# verdicts :: [:enqueued | :duplicate | {:error, :kind}], input order
```

**The rival's advantage**, in its documented form [1] — the sentence the bus cannot say:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:fill, fill_changeset)
|> Oban.insert(:job, fn %{fill: fill} -> Worker.new(%{fill_id: fill.id}) end)
|> Repo.transaction()
```

**Go.** The port's path is now mechanical: translate the fourteen scenarios, drive the same scripts over the same wire, and stop when the verdicts match. The harness is deliberately free of process semantics — no supervisors, no consumers — so nothing in it assumes the BEAM.

## Decisions

**Conformance is scenarios over the wire, not tests over the code.** A contract that lives in unit tests certifies an implementation; one that lives in wire verdicts certifies every implementation that can hold a socket.

**Every catch becomes a pin.** The cold-cache defect the harness found is now a path the harness forces (`SCRIPT FLUSH` before the stale scenario); a regression caught once and left to chance is a regression scheduled.

**Derivations print into the record, and repairs confess.** The derive lines are committed beside the measurements they predicted; the one band this chapter re-derived is named in the ledger with its reasoning, because a silently widened band is a measurement wearing a derivation's clothes.

**The rival runs whole, local, and at its defaults.** No published benchmark is cited as a measurement; no tuning flatters either side; the engine, queue limit, and commit mode are in the record's header.

**The advantage is a gate.** Rollback-erases-both and commit-lands-both are assertions with counts, which is what keeps the fairness from being decorative.

**One surface addition, one fix.** `enqueue_many/3` because the wire-fairness benchmark and bulk producers share a real need; `map_script_reply/1` because both eval attempts must speak one verdict language. `lanes.ex`, the consumer, and every Part II store are untouched.

## Boundaries

One core, loopback, one container: the ratios travel better than the absolutes, and the header's asymmetry line is part of every figure quoted from this record. The rival is measured at its defaults — `synchronous_commit on`, the Basic engine, queue limit 10 — and a tuned rival narrows gaps this chapter does not narrow for it; equally, the bus's volatile enqueue is the default this series chose by D-2, and a persistent bus would pay its own new rows. The drains run trivial handlers, so the gap is the machinery's, not the workload's — real work flattens both sides toward each other. Conformance covers the bus contract, not the consumer's process semantics: 3.5's tree drills stay where supervisors live. And the rival is pinned — Oban 2.18.3, Basic engine, PostgreSQL 16.14 — with its Lite and MySQL engines and its commercial tier out of scope; the row that matters here is the one its open core states best.

## Companion files

`runtimes/elixir/lib/echo_mq/conformance.ex`, the grown `lib/echo_mq/jobs.ex`, the fixed `lib/echo_mq/connector.ex`; `bcs_rung_3_6_check.exs` and its committed record `bcs_rung_3_6_check.out`; the rival's project under `/home/claude/oban_bench` (application, worker, migration, vendored dependency tree).

## References

1. Oban documentation — `Oban` module (insert and insert_all composed into `Ecto.Multi`: the transactional enqueue-with-data pattern the advantage row stages; pause and resume semantics the drain uses): [hexdocs.pm/oban/Oban.html](https://hexdocs.pm/oban/Oban.html)
2. PostgreSQL documentation — Asynchronous Commit (commit is normally synchronous: the server waits for the transaction's WAL records to reach permanent storage, and for short transactions that wait dominates — the derivation behind the sequential and drain bands, and the knob that would trade the guarantee away): [postgresql.org/docs/current/wal-async-commit.html](https://www.postgresql.org/docs/current/wal-async-commit.html)
3. PostgreSQL documentation — NOTIFY (notifications deliver only at transaction commit and in commit order — the structural floor under the rival's wake latency): [postgresql.org/docs/current/sql-notify.html](https://www.postgresql.org/docs/current/sql-notify.html)
