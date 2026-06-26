# R8.06.2 · Prometheus and OpenTelemetry

> Dive · `/redis-patterns/production-operations/operating-echomq/prometheus-and-opentelemetry`
> `EchoMQ.Meter` — a zero-cost `[:emq, …]` telemetry tree a standard exporter attaches to.

A bus you cannot see is a bus you cannot operate. The operator needs three numbers — throughput, latency,
and failure — and needs them through the tools already running, not a bus-specific agent. `EchoMQ.Meter` is
that surface: a `:telemetry` tree rooted `[:emq, …]` that a Prometheus exporter or an OpenTelemetry bridge
attaches to the standard Elixir way, and that costs nothing when no telemetry library is loaded.

## The event tree

`EchoMQ.Meter` re-roots every event under `[:emq | suffix]` — one tree for the whole bus. The lifecycle
events are fixed, and the connector already fires its own under the same root, so an operator attaches one
handler set and sees the whole bus:

- `[:emq, :job, :add]` · `[:emq, :job, :start]` · `[:emq, :job, :complete]` · `[:emq, :job, :fail]` ·
  `[:emq, :job, :retry]` — a job's life;
- `[:emq, :worker, :start]` · `[:emq, :worker, :stop]` — a worker's life;
- `[:emq, :rate_limit, :hit]` — a rate limit fired;
- `[:emq, :connector, …]` — the wire's own events, already on the tree.

`emit/3` takes an atom name or a suffix list and executes it rooted `[:emq | …]`. Every emission is guarded:
it runs only when `:erlang.function_exported(:telemetry, :execute, 3)` is true, so a deployment without
`:telemetry` pays nothing — the event never fires and the handler is harmless.

```elixir
# echo/apps/echo_mq/lib/echo_mq/meter.ex
@root :emq
defp loaded?, do: :erlang.function_exported(:telemetry, :execute, 3)

def attach(handler_id, event_suffix, handler_fn, config \\ nil) do
  if loaded?() do
    apply(:telemetry, :attach, [handler_id, [@root | event_suffix], handler_fn, config])
  else
    :ok
  end
end

def emit(event_suffix, measurements, metadata) when is_list(event_suffix) do
  if loaded?(), do: apply(:telemetry, :execute, [[@root | event_suffix], measurements, metadata])
  :ok
end
```

## The span shape — OpenTelemetry

`span/3` wraps a function call in start, stop, and exception events around it — the standard
`:telemetry.span` shape, which is exactly the shape an OpenTelemetry bridge maps to a span. The wrapped
function always runs; only the events are guarded zero-cost. On a normal return the stop event carries the
duration; on an exception the exception event carries the duration plus the reason and stacktrace, and the
error re-raises. Attach an OpenTelemetry bridge to the `[:emq, …]` tree and each `span/3` becomes a span
with its timing and its error attached — the standard distributed-tracing read of a job's execution.

## Attaching an exporter

Because the surface is plain `:telemetry`, the exporters are the standard Elixir ones. Attach
`telemetry_metrics_prometheus` to the `[:emq, …]` tree and the bus exposes a `/metrics` endpoint Prometheus
scrapes: counts off `[:emq, :job, :complete]` and `[:emq, :job, :fail]`, latency off the `:duration`
measurement, rate-limit pressure off `[:emq, :rate_limit, :hit]`. Attach an OpenTelemetry bridge and the
`span/3` events become traces. The bus needs no custom agent — it speaks the same telemetry every other
Elixir library does.

For a quick read at the terminal there is `EchoMQ.Dashboard`: a cat-able ANSI operator view, read-only over
the `EchoMQ.Metrics` pure-read plane. It reimplements no read and opens no new wire — operator tooling,
not a bus surface, and the right tool when the answer is "what is the queue doing right now" rather than a
scraped time series.

## The bridge

| The pattern — instrument a system through a standard telemetry surface | Its EchoMQ application |
|---|---|
| Emit named events with measurements and metadata; let standard exporters map them to metrics and traces | `EchoMQ.Meter` re-roots every event `[:emq, …]`, guarded zero-cost when `:telemetry` is absent; a Prometheus exporter or an OpenTelemetry bridge attaches to the tree, and `span/3` is the OpenTelemetry span shape |

The take: observability is a surface, not an agent. The bus emits a fixed `[:emq, …]` event tree the
standard Elixir exporters already understand, so throughput, latency, and failure are visible through
Prometheus and OpenTelemetry with no bus-specific tooling.

## The production angle

In production the operator attaches the exporters at boot and reads the bus through the same Grafana and
tracing tools the rest of the system uses. For codemojex, the bot workers draining the `cm` queue fire the
same `[:emq, :job, …]` events, so a notify job's throughput and failure are on the same dashboard as every
other queue — no special case for the game's workers. The deeper proof surface — the conformance suite and
the production evidence — is the dedicated EchoMQ course's Proof pillar.

## References

### Sources

- [OpenTelemetry — *Traces*](https://opentelemetry.io/docs/concepts/signals/traces/) — the span model
  `span/3`'s start/stop/exception events follow.
- [Prometheus — *Documentation*](https://prometheus.io/docs/) — the metrics model an exporter maps the
  `[:emq, …]` telemetry tree onto.
- [Redis — *Documentation*](https://redis.io/docs/) — the server-side metrics (`INFO`, latency) that
  complement the application telemetry the bus emits.

### Related in this course

- [R8.06 · Operating EchoMQ](/redis-patterns/production-operations/operating-echomq) — the module hub.
- [R8.06.1 · Cluster colocation](/redis-patterns/production-operations/operating-echomq/cluster-colocation) — placing the bus the exporter observes.
- [R8.06.3 · The polyglot fleet](/redis-patterns/production-operations/operating-echomq/the-polyglot-fleet) — the fleet whose work this surface meters.
- [/echomq · the Proof pillar](/echomq/proof) — conformance, telemetry, and the production evidence the bus carries.
- [/bcs · Production on Fly](/bcs/fly) — where the metered bus runs.
