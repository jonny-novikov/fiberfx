# The scenarios

> Route: `/echomq/proof/the-conformance-suite/the-scenarios` · dive 01.
> Grounded in `EchoMQ.Conformance.scenarios/0` (real code, `echo/apps/echo_mq`). No Lua.

## A scenario is a name and a contract

`scenarios/0` returns a keyword list — `name: "one-line contract"` — **in run order**. Each entry names one
externally visible promise of the bus, and the contract is one sentence stating what an outside observer must
see. The names are not test labels; they are the protocol's clauses. A scenario drives the **public surface**
(`Jobs.enqueue`, `Jobs.claim`, `Metrics.get_counts`, …) or, where the contract *is* the wire, **raw commands**
(`GET emq:{q}:version`, `ZRANGE … BYLEX REV`).

## The verdict is always external

Every scenario asserts what a caller can see, never an internal detail:

- `fence` — the version fence is claimed before any work and reads the current wire version.
- `mint` — enqueue admits a `JOB` name and writes the three-field row: state pending, attempts 0, payload.
- `duplicate` — a second enqueue of the same name answers duplicate and changes nothing.
- `kind` — an `ORD` name in the job position is refused by the kind law before any write.
- `order` — the pending set walked `REV BYLEX` answers newest-first by name alone.
- `claim` — claim mints token 1, returns the payload, and moves the row to active.
- `stale` — a stale token's completion is refused `EMQSTALE`; the live token still settles.

The list runs on through `complete`, `retry`, `dead`, `reap`, the lanes (`rotate`, `pause`, `limit`), the
schedule (`schedule`, `repeat`, `backoff`), the read plane (`counts`, `state`, `metrics`, `rate`,
`lane_depth`), the operator plane (`queue_pause`, `drain`, `obliterate`, the job-mutation verbs), the watch
plane (`lock_extend`, `stalled`, `events`, `telemetry`, `cancel`), the flow family (`flow_add`, `flow_fanin`,
`flow_cross_queue`, …), and the Stream Tier (`stream_verbs`, `stream_append`, `stream_group`,
`stream_retention`, `stream_time_travel`). **No hard count** — the set grows; the page teaches the shape.

## Extract — `scenarios/0` (a representative slice)

The keyword list, annotated. The full list is longer; this is the head plus a few later clauses to show the run
order and the contract style.

```elixir
# echo_mq — EchoMQ.Conformance
# The scenario names and their one-line contracts, in run order. A port of the
# client conforms when it drives the same server to the same verdicts — the
# scenarios are wire-level on purpose, so the harness ports by translation.
def scenarios do
  [
    fence:     "the version fence is claimed before any work and reads the current wire version",
    mint:      "enqueue admits a JOB name and writes the three-field row: state pending, attempts 0, payload",
    duplicate: "a second enqueue of the same name answers duplicate and changes nothing",
    kind:      "an ORD name in the job position is refused by the kind law before any write",
    order:     "the pending set walked REV BYLEX answers newest-first by name alone",
    claim:     "claim mints token 1, returns the payload, and moves the row to active",
    stale:     "a stale token's completion is refused EMQSTALE; the live token still settles",
    complete:  "complete retires the row everywhere -- nothing remains to browse",
    # … the lanes, the schedule, the read / operator / watch planes, the flow
    # family, and the Stream Tier follow, each one clause, each in run order …
    stream_group: "a consumer group delivers at-least-once with crash re-delivery: one entry XACKed, one left, a forced XAUTOCLAIM re-delivers the SAME un-acked receipt"
  ]
end
```

## Driving the surface — or the wire

Most scenarios call the public surface and pattern-match the externally visible answer. The `mint` scenario, for
example, enqueues a branded `JOB` id and reads the row straight back with `HGETALL`, asserting the exact
three-field shape:

```elixir
# echo_mq — EchoMQ.Conformance (the :mint scenario)
# Drive the PUBLIC surface (Jobs.enqueue), then read the row with a RAW command
# (HGETALL) and assert the externally visible shape — state pending, attempts 0,
# payload as enqueued. The verdict is what an outside caller can see, nothing more.
defp apply_scenario(:mint, conn, q) do
  id = BrandedId.generate!("JOB")

  with {:ok, :enqueued} <- Jobs.enqueue(conn, q, id, "cargo"),
       {:ok, row} <- Connector.command(conn, ["HGETALL", Keyspace.job_key(q, id)]) do
    if pairs(row) == %{"state" => "pending", "attempts" => "0", "payload" => "cargo"},
      do: :ok,
      else: {:fail, row}
  end
end
```

Where the contract *is* the wire — the byte order of the pending set, the fence key's value — the scenario issues
the raw command directly (`ZRANGE … "+", "-", "BYLEX", "REV"` for `order`; `GET` the version key for `fence`), so
the assertion is on the wire-level fact a port must reproduce, not on a convenience wrapper.

## Bridge

- Pattern (Redis Patterns Applied): a coordination primitive is correct only if its externally visible behavior
  holds under contention — atomic claim, the fencing token, idempotent admission. `/redis-patterns/coordination`
  teaches the atomicity.
- Implementation (echo_mq): each clause of `scenarios/0` is one of those externally visible promises, asserted
  against a live server — the contract written as a name plus a sentence, run, not asserted.

## References

### Sources
- Kent Beck — *Test-Driven Development* — the verdict-asserting scenario as the contract.
- Valkey — *HGETALL* — the raw read a row-shape scenario asserts against.
- Valkey — *ZRANGE* — the `REV BYLEX` walk the `order` scenario asserts.

### Related in this course
- `/echomq/proof/the-conformance-suite` — the module this dive belongs to.
- `/echomq/proof/the-conformance-suite/run-and-the-verdict` — how the list is run.
- `/echomq/protocol` — the keyspace, the kind law, and the branded-id gate the scenarios assert.
- `/redis-patterns/coordination` (R2) — the atomicity the suite proves.
