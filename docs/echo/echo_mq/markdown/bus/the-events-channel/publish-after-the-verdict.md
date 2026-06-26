# Publish after the verdict — EchoMQ, In Depth (route mirror: `/echomq/bus/the-events-channel/publish-after-the-verdict`)

> Route-mirror md for dive 02 of module 01. The HTML at
> `html/echomq/bus/the-events-channel/publish-after-the-verdict.html` reflects this. All grounding is **real
> code** in `echo/apps/echo_mq/lib/echo_mq/events.ex`. No `[RECONCILE]` markers — every surface is real.

## Lede

An event is published **after** a transition decides, from the host — not inside the script that decides. That
one placement choice is what keeps the bus from ever changing the byte-frozen transition scripts.

## Where the publish lives — and why it is host-side

A queue transition (`complete`, `retry`, the stalled reaper) is an atomic Lua script. The publish does **not**
go inside it. Instead, the calling code runs the transition, reads its verdict, and then — host-side, in Elixir
— calls `publish/5` to announce what happened. The reason is a hard invariant of this bus: the transition
scripts are **byte-frozen**. Adding a `PUBLISH` to a script would change its bytes (and its SHA), which is
exactly what the freeze forbids. Publishing from the host keeps every script byte-for-byte identical to what
shipped, while still letting the bus broadcast the outcome.

(There is one event that is published inline because its transition already does so: `progress`. The
`@update_progress` seam established the `emq:{q}:events` channel and the cjson payload shape; every *other*
lifecycle event reuses that channel from the host.)

`publish/5` is direct: it issues one `PUBLISH emq:{q}:events <payload>` through `EchoMQ.Connector.command/3`.
There is no new script and no Lua — the events channel is a command surface, not a scripted transition.

```elixir
# echo_mq — EchoMQ.Events.publish/5 (host-side, after the verdict)
# Announce a lifecycle event AFTER its transition has decided. The transition
# scripts are byte-frozen, so the publish lives here in the host, not in the
# script — the scripts stay byte-unchanged. One PUBLISH, issued DIRECT (no Lua).
def publish(conn, queue, event, job_id, extra \\ []) do
  # gate the id at the key builder (INV5) — raises on an ill-formed id BEFORE the wire,
  # so a malformed JOB id can never reach a PUBLISH
  _ = Keyspace.job_key(queue, job_id)
  payload = encode_event(event, job_id, extra)

  case Connector.command(conn, ["PUBLISH", channel(queue), payload]) do
    {:ok, _n} -> :ok                  # best-effort — n is the count of receivers (may be 0)
    other -> other
  end
end

# the channel — emq:{q}:events, the SAME suffix the @update_progress seam publishes on
def channel(queue), do: Keyspace.queue_key(queue, "events")
```

Two facts in that function carry weight. First, the id is **gated at the key builder** before anything is sent:
`Keyspace.job_key(queue, job_id)` raises if the job id is ill-formed, so a malformed branded id cannot reach a
`PUBLISH`. The return value of `job_key/2` is discarded — it is called purely for its gate. Second, the publish
is **best-effort**: `PUBLISH` answers the number of receivers, which the function throws away and maps to `:ok`.
Zero receivers is success, not error — the channel makes no delivery promise (the next dive).

## The payload — flat cjson, built by hand

The payload is a tiny JSON object of flat string fields: the event name, the job id, and any `extra` keyword
pairs (e.g. `[progress: "50"]`). The bus carries **no JSON dependency**, so the object is built by string
concatenation, with the two JSON-significant characters escaped.

```elixir
# echo_mq — EchoMQ.Events.encode_event/3 (the flat cjson payload, built by hand)
# {"event":"<name>","job":"<id>", …extra} — flat string fields only. No JSON
# library on the bus; the object is concatenated, with \ and " escaped.
defp encode_event(event, job_id, extra) do
  fields =
    [{"event", to_string(event)}, {"job", job_id}] ++
      Enum.map(extra, fn {k, v} -> {to_string(k), to_string(v)} end)

  body =
    fields
    |> Enum.map(fn {k, v} -> ~s("#{k}":"#{escape(v)}") end)
    |> Enum.join(",")

  "{" <> body <> "}"
end

defp escape(v) do
  v
  |> String.replace("\\", "\\\\")   # backslash first
  |> String.replace("\"", "\\\"")   # then the quote
end
```

## Reading the name back — a scan, not a parser

On the receive side, the consumer needs the event name. It does **not** parse the JSON. Because the payload is
hand-built and cjson key order is not guaranteed, the name is read by a **substring scan** for the `event`
field, and the matched string is resolved with `String.to_existing_atom/1`. That last choice is the safety one:
an unknown name answers `:unknown` rather than **minting an atom from the wire**. Atoms are not garbage
collected; turning arbitrary wire bytes into atoms is an unbounded-memory hazard, so the function only ever
returns an atom that already exists.

```elixir
# echo_mq — EchoMQ.Events.event_name/1 (read the name by scan; never mint an atom)
# The bus has no JSON parser and cjson key order is not guaranteed — so read the
# "event" field by substring scan. Resolve with to_existing_atom: an UNKNOWN
# name answers :unknown, never minting an atom from the wire (atoms aren't GC'd).
def event_name(payload) when is_binary(payload) do
  case Regex.run(~r/"event"\s*:\s*"([^"]+)"/, payload) do
    [_, name] ->
      try do
        String.to_existing_atom(name)     # only an atom that already exists
      rescue
        ArgumentError -> :unknown          # unknown name → :unknown, not a new atom
      end

    _ ->
      :unknown
  end
end
```

## The interactives — the round trip

The first figure is the publish round trip: pick a verdict (`completed`, `failed`, `progress`, `stalled`),
watch `publish/5` gate the id, build the cjson payload, and issue `PUBLISH emq:{q}:events`, then watch
`event_name/1` scan the same payload back to the atom — including an injected unknown name that resolves to
`:unknown`. The payload string the figure shows is exactly what `encode_event/3` produces.

The second figure is the freeze argument: a side-by-side of "publish inside the script" (the script bytes
change → the SHA changes → the freeze breaks) versus "publish from the host after the verdict" (the script
bytes are untouched). It makes concrete why the publish is where it is.

## Bridge — pattern and implementation

- **The pattern (Redis Patterns Applied).** Emit a domain event when state changes, so other parts of the
  system can react without coupling to the writer. The pattern says emit on the transition.
- **The implementation (echo_mq).** `publish/5` emits **after** the transition's verdict, host-side, gating the
  id at the key builder and issuing one `PUBLISH emq:{q}:events` direct — so the byte-frozen transition scripts
  stay byte-unchanged.

Takeaway: the verdict belongs to the script; the announcement belongs to the host. Splitting them is what lets
the bus broadcast every outcome without ever editing a transition.

## Recap

A lifecycle event is published **host-side**, after a transition's verdict, by `publish/5` — one
`PUBLISH emq:{q}:events` through `EchoMQ.Connector.command/3`, no Lua. The id is gated at the key builder before
the wire; the cjson payload is built by hand (no JSON dependency); the receiver reads the name by substring
scan and resolves it with `String.to_existing_atom/1`, answering `:unknown` rather than minting an atom. The
next dive: the guarantee the channel makes — at-most-once — and its control-plane sibling, `EchoMQ.Cancel`.

## References

### Sources
- Valkey — PUBLISH (`https://valkey.io/commands/publish/`) — the single command `publish/5` issues; its reply is
  the receiver count, discarded for best-effort.
- Valkey — Introduction to Streams (`https://valkey.io/topics/streams-intro/`) — the bus surfaces this pillar
  builds on.
- Valkey — Cluster specification (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hashtag keeps the events
  channel on the queue's slot.

### Related in this course
- The events channel (`/echomq/bus/the-events-channel`) — the module hub.
- Subscribe and handle (`/echomq/bus/the-events-channel/subscribe-and-handle`) — the receive side that reads
  these payloads.
- Fire-and-forget (`/echomq/bus/the-events-channel/fire-and-forget`) — the at-most-once guarantee of this
  publish.
- The Lua layer (`/echomq/protocol/the-lua-layer`) — the byte-frozen transition scripts the publish stays out
  of.
- redis-patterns · Streams & Events (`/redis-patterns/streams-events`) — the events pattern.
