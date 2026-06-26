# Subscribe and handle — EchoMQ, In Depth (route mirror: `/echomq/bus/the-events-channel/subscribe-and-handle`)

> Route-mirror md for dive 01 of module 01. The HTML at
> `html/echomq/bus/the-events-channel/subscribe-and-handle.html` reflects this. All grounding is **real code** in
> `echo/apps/echo_mq/lib/echo_mq/events.ex`. No `[RECONCILE]` markers — every surface is real.

## Lede

A listener subscribes once, on one connection, and the bus pushes every event to it from then on — delivered two
ways: to subscriber pids, and to a handler module.

## The one-time subscribe

`EchoMQ.Events` is a `GenServer` that owns one subscription. On `init/1` it takes a connector — either a
caller-supplied `:conn` (which **must** be `protocol: 3` and `push_to` the listener) or a `:connector` options
list it starts linked, with `protocol: 3` and `push_to: self()` set for you — and it issues exactly one
`Connector.subscribe(conn, channel(queue))`. `channel(queue)` is `emq:{q}:events` (built by
`Keyspace.queue_key(queue, "events")`). That single subscribe is the whole wire cost: every later subscriber
rides it.

Why `protocol: 3`? Pub/sub pushes are out-of-band server messages. RESP3 carries them on a separate push
channel the connector routes to the `push_to` process as `{:emq_push, frame}`, so a published message does not
collide with a command reply on the same socket. The listener subscribes on a connection dedicated to receiving
those pushes.

```elixir
# echo_mq — EchoMQ.Events.init/1 (the one-time subscribe)
# The listener owns ONE subscription to emq:{q}:events. The connector MUST be
# RESP3 (protocol: 3) and MUST push_to this process — so pub/sub pushes arrive
# as {:emq_push, …} out-of-band, never colliding with a command reply.
def init(opts) do
  Process.flag(:trap_exit, true)
  queue = Keyword.fetch!(opts, :queue)

  conn =
    case Keyword.fetch(opts, :conn) do
      {:ok, c} ->
        c                                    # a caller-supplied RESP3 + push_to connector
      :error ->
        conn_opts =
          opts
          |> Keyword.fetch!(:connector)
          |> Keyword.put_new(:protocol, 3)   # RESP3 — push frames on their own channel
          |> Keyword.put(:push_to, self())   # route every push to this listener
        {:ok, c} = Connector.start_link(conn_opts)
        c
    end

  chan = channel(queue)                       # emq:{q}:events

  case Connector.subscribe(conn, chan) do     # the SINGLE SUBSCRIBE — every subscriber rides it
    :ok ->
      {:ok, %{conn: conn, queue: queue, channel: chan,
              handler: Keyword.get(opts, :handler),
              handler_state: Keyword.get(opts, :handler_state),
              subscribers: MapSet.new()}}
    {:error, reason} ->
      {:stop, {:subscribe_failed, reason}}
  end
end
```

The feed stays live across a reconnect because of work done one layer down. The connector keeps the set of
channels it is subscribed to in a `MapSet`; when the socket drops and reconnects, it re-issues `SUBSCRIBE` for
every channel in that set. The listener never re-subscribes — it does not even learn that the socket bounced.
That resubscribe `MapSet` is what makes "subscribe once" safe in a long-lived process.

## The two deliveries

A published message arrives at the listener as `{:emq_push, ["message", channel, payload]}`. The listener
matches on its own channel, reads the event name, and dispatches **both** ways in one pass: a `send/2` to every
registered subscriber pid, and a call into the handler module if one is configured.

```elixir
# echo_mq — EchoMQ.Events.handle_info/2 (the dispatch)
# A published message arrives as {:emq_push, ["message", channel, payload]}.
# (The connector's "subscribe"/"unsubscribe" confirmation frames are ignored.)
# Each message dispatches TWO ways off the one subscription:
def handle_info({:emq_push, ["message", chan, payload]}, %{channel: chan} = s)
    when is_binary(payload) do
  event = event_name(payload)                              # the name, by scan (next dive)
  # 1) every subscriber pid gets {:emq_event, name, raw_payload}
  Enum.each(s.subscribers, fn pid -> send(pid, {:emq_event, event, payload}) end)
  # 2) the optional handler module folds the event into its state
  {:noreply, dispatch_handler(s, event, payload)}
end

def handle_info({:emq_push, _frame}, s), do: {:noreply, s}  # ignore non-message frames
```

**Subscriber pids.** `subscribe(server, pid \\ self())` registers a pid (idempotent, defaults to the caller);
`unsubscribe/2` removes it. A registered pid receives `{:emq_event, event_name, raw_payload}` for **every**
event the channel carries, and pattern-matches the ones it cares about in its own `handle_info`. This is the
loose-coupling shape: a LiveView, a metrics collector, a test process — each subscribes independently.

```elixir
# echo_mq — EchoMQ.Events.subscribe/2 + unsubscribe/2 (the pid registry)
# Register a pid to receive every event as {:emq_event, name, payload}.
# Idempotent (a MapSet); defaults to the caller. unsubscribe/2 is the inverse.
def subscribe(server, pid \\ self()), do: GenServer.call(server, {:subscribe, pid})
def unsubscribe(server, pid \\ self()), do: GenServer.call(server, {:unsubscribe, pid})

# the owner side: add/remove the pid in the subscribers MapSet
def handle_call({:subscribe, pid}, _from, s),
  do: {:reply, :ok, %{s | subscribers: MapSet.put(s.subscribers, pid)}}
def handle_call({:unsubscribe, pid}, _from, s),
  do: {:reply, :ok, %{s | subscribers: MapSet.delete(s.subscribers, pid)}}
```

**The handler module.** An optional `:handler` implementing `handle_event/3` is invoked per event with the
handler's state and answers `{:ok, new_state}`. `use EchoMQ.Events` derives a no-op `handle_event/3` that just
keeps the state, so a real handler overrides only the events of interest. This is the stateful-reducer shape:
fold the event stream into a running state without writing a `receive` loop.

```elixir
# echo_mq — the handle_event/3 behaviour + the no-op default from `use EchoMQ.Events`
@callback handle_event(event :: atom(), payload :: binary(), state :: term()) ::
            {:ok, state :: term()}

# `use EchoMQ.Events` derives this no-op — override only the events you care about:
defmacro __using__(_opts) do
  quote do
    @behaviour EchoMQ.Events
    @impl EchoMQ.Events
    def handle_event(_event, _payload, state), do: {:ok, state}   # keep state by default
    defoverridable handle_event: 3
  end
end
```

## The interactive — one push, both deliveries

The first figure traces a single `{:emq_push, ["message", "emq:orders:events", payload]}` through the
dispatch: the name is read, then it fans to N subscriber pids and (optionally) the handler. Toggle subscribers
and the handler on the fixed payload and read exactly what is sent.

The second figure is the lifecycle of one subscriber: `subscribe → receive events → unsubscribe`, showing the
`MapSet` membership at each step and that a removed pid stops receiving — the registry is a plain set, add and
delete, nothing more.

## Bridge — pattern and implementation

- **The pattern (Redis Patterns Applied).** Publish/subscribe lets a producer broadcast to many consumers
  without knowing them; a consumer reacts to events instead of polling. R5 · Streams & Events teaches the
  pub/sub side.
- **The implementation (echo_mq).** `EchoMQ.Events` holds one RESP3 subscription to `emq:{q}:events` and
  dispatches each push two ways — to subscriber pids and to a `handle_event/3` handler — with the connector's
  resubscribe `MapSet` keeping the feed live across a reconnect.

Takeaway: one subscription, two delivery shapes, zero per-subscriber wire cost. The bus pushes; the listener
fans.

## Recap

`EchoMQ.Events` subscribes **once** to `emq:{q}:events` on a `protocol: 3` + `push_to` connector. Each pushed
message is delivered to every registered subscriber pid as `{:emq_event, name, payload}` and to an optional
`handle_event/3` handler. The connector's resubscribe `MapSet` re-issues the `SUBSCRIBE` across a reconnect, so
the feed stays live. The next dive: where the events come from — the host-side publish after a verdict.

## References

### Sources
- Valkey — SUBSCRIBE (`https://valkey.io/commands/subscribe/`) — the one-time subscription the listener holds.
- Valkey — Introduction to Streams (`https://valkey.io/topics/streams-intro/`) — the bus surfaces this pillar
  builds on; here, the pub/sub half.
- Valkey — Cluster specification (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hashtag co-locates the
  events channel with the queue on one slot.

### Related in this course
- The events channel (`/echomq/bus/the-events-channel`) — the module hub.
- Publish after the verdict (`/echomq/bus/the-events-channel/publish-after-the-verdict`) — where the events the
  listener receives come from.
- Fire-and-forget (`/echomq/bus/the-events-channel/fire-and-forget`) — what happens when no one is subscribed.
- The Protocol (`/echomq/protocol`) — the keyspace `emq:{q}:events` is built from.
- redis-patterns · Streams & Events (`/redis-patterns/streams-events`) — the pub/sub pattern.
