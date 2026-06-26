# Run and the verdict

> Route: `/echomq/proof/the-conformance-suite/run-and-the-verdict` · dive 02.
> Grounded in `EchoMQ.Conformance.run/2` (real code, `echo/apps/echo_mq`). No Lua.

## One loop, one verdict

`run(conn, queue)` walks `scenarios/0` once. For each `{name, contract}` it derives a **per-scenario sub-queue**
— `queue <> "." <> name` — runs the scenario there, **purges what it minted**, prints one `CONF` line, and
records pass/fail. After the loop it prints a closing tally and returns the verdict: `{:ok, n}` when every
scenario passed (`n` the live total), `{:error, failed_names}` otherwise.

## Per-scenario sub-queues — isolation by name

Each scenario gets its own queue suffix, so the braced keyspace `emq:{queue.name}:` is **disjoint** from every
other scenario's. Two scenarios never collide, and a failure is named, not smeared across the run. Because the
queue name carries the `{…}` hashtag, all of a scenario's keys still hash to one slot — the suite respects the
same placement law the bus does.

## Purge what you mint — no residue

After each scenario, `run/2` deletes everything under that sub-queue's prefix: `KEYS emq:{q}:*` then `DEL` the
matches. The suite leaves the server as it found it — you can run it against a live system and it cleans up
behind itself.

## Extract — `run/2`

The loop, annotated. The verdict is a fold over the per-scenario results.

```elixir
# echo_mq — EchoMQ.Conformance
# Run every scenario on a per-scenario sub-queue of `queue`, purge what it
# mints, print one CONF line each + a closing tally. Returns {:ok, n} when all
# pass, {:error, failed_names} otherwise. The set grows by additive minor; the
# count n is the LIVE total, re-pinned in the two pinning tests, never hardcoded here.
def run(conn, queue) when is_binary(queue) do
  results =
    for {name, contract} <- scenarios() do
      q = queue <> "." <> Atom.to_string(name)   # a disjoint braced keyspace per scenario

      verdict =
        try do
          apply_scenario(name, conn, q)            # drive the public surface / raw wire
        rescue
          e -> {:fail, Exception.message(e)}       # a raise becomes a named failure, never a crash
        end

      purge(conn, q)                               # KEYS emq:{q}:* then DEL — leave no residue
      ok = verdict == :ok
      IO.puts("CONF #{name} #{if ok, do: "ok", else: "FAIL #{inspect(verdict)}"} -- #{contract}")
      {name, ok}
    end

  failed = for {name, false} <- results, do: name
  IO.puts("CONFORMANCE #{length(results) - length(failed)}/#{length(results)}")
  if failed == [], do: {:ok, length(results)}, else: {:error, failed}
end
```

## The purge

The cleanup is a single keyspace sweep — the same braced prefix the scenario minted under:

```elixir
# echo_mq — EchoMQ.Conformance
# Delete everything under this sub-queue's braced prefix. The suite leaves the
# server as it found it, so it can run against a live system without residue.
defp purge(conn, q) do
  {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
  if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
  :ok
end
```

## Reading the output

The stream is one `CONF <name> ok -- <contract>` line per scenario, then `CONFORMANCE <passed>/<total>`. A green
run ends `{:ok, n}`; a single failing scenario yields `{:error, [name]}` — naming exactly which clause of the
contract a port (or a regression) broke, with the rest of the run already cleaned up.

## Bridge

- Pattern (Redis Patterns Applied): a coordination test must isolate each case and clean up after itself, or one
  case's residue poisons the next. `/redis-patterns/coordination` teaches the atomic primitives the suite asserts.
- Implementation (echo_mq): `run/2` gives every scenario a disjoint braced sub-queue and purges it — isolation by
  name, no residue, one named verdict.

## References

### Sources
- Kent Beck — *Test-Driven Development* — the self-contained, self-cleaning scenario.
- Valkey — *KEYS* — the prefix sweep the purge issues.
- Valkey — *DEL* — the cleanup that leaves no residue.

### Related in this course
- `/echomq/proof/the-conformance-suite` — the module this dive belongs to.
- `/echomq/proof/the-conformance-suite/the-scenarios` — the list `run/2` walks.
- `/echomq/proof/the-conformance-suite/the-additive-minor-law` — how `n` grows.
- `/echomq/protocol` — the braced keyspace per sub-queue.
