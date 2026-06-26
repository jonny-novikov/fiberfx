# Zero cost when absent

> Route: `/echomq/proof/telemetry-and-the-read-plane/zero-cost-when-absent` · Module 02 · dive 02.
> Grounds in `EchoMQ.Meter` — the `loaded?/0` guard, `emit/3`, and the no-op `attach/4` branch
> (`echo/apps/echo_mq`). No Lua — the guard is a runtime function-export check.

A library that meters itself faces a choice: either it **depends on** the telemetry library — and forces that
dependency on every host, metered or not — or it makes the dependency **optional** and pays nothing when the
host has not opted in. `EchoMQ.Meter` takes the second path, and the mechanism is a single guard. The result
is a property worth stating plainly: **the bus carries no `:telemetry` dependency edge.** A host that wants
metering adds `:telemetry` itself; a host that does not is never charged for the emitter calls sitting in the
lifecycle.

## The guard — `:erlang.function_exported(:telemetry, :execute, 3)`

Before any emission, the meter asks one question: **is `:telemetry` actually loaded?** It answers it with a
runtime check — `:erlang.function_exported(:telemetry, :execute, 3)` — which is `true` only if the module is
present and that function is exported. If the dependency was never added, the check is `false`, and:

- **`emit/3`** does nothing and answers `:ok` — a no-op.
- **`attach/4`** does nothing and answers `:ok` — the handler is never registered, and that is harmless,
  because the event it would have caught never fires either.

So an `emit` in a hot lifecycle path is, when telemetry is absent, a branch on a boolean and a return — no
event constructed, no handler list walked, no dependency loaded. The cost is a function-export lookup, not a
metering pipeline.

```elixir
# echo_mq — EchoMQ.Meter
# The single guard: is :telemetry actually loaded? Answered at runtime by the
# function-export check — true only if the module is present and execute/3 is
# exported. If the dependency was never added, this is false, so every emission
# is a no-op. The bus carries NO :telemetry dependency edge — a host opts in by
# adding :telemetry itself.
defp loaded?, do: :erlang.function_exported(:telemetry, :execute, 3)

# emit/3: with :telemetry loaded, fire the rooted event; without it, do nothing
# and answer :ok. An emit in a hot path is a branch on a boolean, never a
# metering pipeline.
def emit(event_suffix, measurements, metadata) when is_list(event_suffix) do
  if loaded?() do
    apply(:telemetry, :execute, [[@root | event_suffix], measurements, metadata])
  end

  :ok
end
```

The same guard wraps `attach/4` and `attach_many/4` (the no-op branch in the previous dive) and `span/3`. The
one careful asymmetry is in `span/3`: the guard protects only the **events**, never the **work**. With
telemetry absent, `span/3` runs the wrapped function directly and returns its result — the metering vanishes,
the computation does not. A block you wrapped to measure is never skipped because nobody is listening.

## The name is collision-avoidance, not decoration

There is a second reason the module is called `EchoMQ.Meter` and not the obvious telemetry name, and it is a
load-bearing one. The frozen first-generation reference already defines a module under the obvious name, and
**both load on one code path**. A same-named module would shadow the bus's telemetry surface
non-deterministically — whichever loaded last would win, and the answer would depend on load order. The
capability is the same metering surface re-derived; the **name is chosen to be collision-free** so the bus's
meter and the frozen reference never contend for the same module name. Teaching the surface, the name to reach
for is `EchoMQ.Meter`.

## Why this is the right default for a library

A queue/bus is infrastructure — it sits beneath an application that has its own opinions about observability.
Forcing a telemetry dependency on every consumer is exactly the kind of coupling a system built on the BCS law
avoids: a surface should not drag its neighbours in to hold it up. The opt-in guard makes metering a
**decision the host makes**, not a tax the library levies. A host that adds `:telemetry` gets the full event
tree the previous dive describes; a host that does not gets a bus that is byte-for-byte as cheap as if the
emitters were not there. The cost of the feature, to a host that does not use it, is zero — and that is the
claim the guard makes literally true.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** instrument the system, but do not make instrumentation mandatory —
  a library's observability should be the host's choice. `/redis-patterns/production-operations` teaches
  running the tier.
- **The implementation (echo_mq):** every emission guards
  `:erlang.function_exported(:telemetry, :execute, 3)`, so with no `:telemetry` loaded an emit is a no-op and
  an attach answers `:ok` — the bus carries no `:telemetry` dependency edge, and the module name is chosen
  collision-free so it never shadows the frozen reference on the shared code path.

## References

### Sources
- [Erlang/OTP — `:erlang.function_exported/3`](https://www.erlang.org/doc/man/erlang.html#function_exported-3) — the runtime check the zero-cost guard is built on.
- [Elixir — the `:telemetry` library](https://hexdocs.pm/telemetry/readme.html) — the optional dependency a host opts into.
- [Erlang/OTP — `:telemetry.execute/3`](https://hexdocs.pm/telemetry/telemetry.html) — the execute the guard gates.

### Related in this course
- `/echomq/proof/telemetry-and-the-read-plane` — the module this dive belongs to.
- `/echomq/proof/telemetry-and-the-read-plane/the-telemetry-surface` — the events the guard protects.
- `/echomq/proof/telemetry-and-the-read-plane/the-read-plane` — the pull side, which has no dependency to guard.
- `/echomq/protocol` — the owned wire the connector meters on the same `[:emq, …]` tree.
- `/redis-patterns/production-operations` — the production-operations pattern that doors here.
- `/bcs/together` — the manuscript chapter (B6) where the four libraries are one umbrella.
