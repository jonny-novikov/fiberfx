# The group door

> Route: `/echomq/bus/the-consumer-group/the-group-door` · Module 03 · dive 01.
> Grounds in `EchoMQ.StreamConsumer.ensure_group!/2` + `start_position!/1` (`echo/apps/echo_mq`).
> No Lua — `XGROUP CREATE` is issued direct through `EchoMQ.Connector.command/3`.

A consumer group has to exist before anyone reads through it, and the same group is shared by every consumer
that joins. So creating it can't be a one-time setup step a deployment runs by hand — every consumer that
starts (or restarts) has to be able to **ensure** the group is there without caring whether it already is.
That is the **group door**: a single `XGROUP CREATE … MKSTREAM` on `start_link`, with exactly one reply
swallowed and everything else loud.

## Create the group and the stream in one verb

`XGROUP CREATE <key> <group> <start> MKSTREAM` creates the consumer group, and — because of `MKSTREAM` — the
stream key too, if it does not yet exist. A consumer can start before a single entry has ever been appended;
the door does not depend on the writer having run first.

The one reply the door swallows is **`BUSYGROUP`** — Valkey's way of saying "that group already exists." That
is not an error here: it is the **idempotent** outcome. The second consumer to start, and the same consumer
after a restart, both hit `BUSYGROUP`, and both treat it as success. A restart-storm — every consumer in a
group bouncing at once — never produces an error from the door.

Every other reply is **loud**. A `WRONGTYPE` (the key exists but is a string or a hash, not a stream — a key
collision) raises; any other `error_reply` raises; a transport failure raises. The consumer **fails to
start**. This is the gate-liveness discipline: a door that quietly swallowed `WRONGTYPE` would leave a
consumer alive but reading nothing, the worst kind of silent failure. The door swallows the one reply that
means "fine, already done," and surfaces everything else.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# The lazy-ensure group door: XGROUP CREATE <key> <group> <start> MKSTREAM creates
# the group (and the stream, if absent). The ONLY swallowed reply is BUSYGROUP (the
# group already exists — an idempotent start). A WRONGTYPE (a non-stream key
# collision) or ANY other error_reply is LOUD: the consumer fails to start.
defp ensure_group!(s, start) do
  case Connector.command(s.conn, ["XGROUP", "CREATE", s.key, s.group, start, "MKSTREAM"]) do
    {:ok, "OK"} ->
      :ok

    {:ok, {:error_reply, <<@busygroup_prefix, _::binary>>}} ->
      :ok

    {:ok, {:error_reply, msg}} ->
      raise RuntimeError, "EchoMQ.StreamConsumer: XGROUP CREATE refused (not BUSYGROUP): #{msg}"

    {:error, reason} ->
      raise RuntimeError, "EchoMQ.StreamConsumer: XGROUP CREATE failed: #{inspect(reason)}"
  end
end
```

The matched `@busygroup_prefix` is the literal `"BUSYGROUP"`; the connector surfaces a Valkey error as an
`{:error_reply, msg}` value, so the door pattern-matches on the prefix rather than catching an exception.

## The start position is declared, never defaulted

When you create a group you make one correctness decision that can never be taken back: **where does the group
begin reading?** Two answers:

- `:new` → `$` — only entries appended **after** the group is created. The group ignores all existing history.
- `:head` → `0` — from the **head** of the stream. The group replays everything already there.

`EchoMQ.StreamConsumer` makes `:group_start` a **required** option with **no default**. A missing or
malformed value **raises at start** — on the caller's process, before the loop ever spawns. The replay-vs-tail
decision is forced into the open. There is no quiet default that silently picks one and surprises an operator
later, and no second verb (`XGROUP SETID`) needed to fix a guess.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# The declared start position: :new -> "$" (only NEW entries), :head -> "0" (from
# the stream head). Any other value RAISES (never defaulted) — the replay-vs-tail
# correctness decision is forced into the open, without a second verb.
defp start_position!(:new), do: "$"
defp start_position!(:head), do: "0"

defp start_position!(other) do
  raise ArgumentError,
        "EchoMQ.StreamConsumer requires a declared :group_start of :new (-> $) or :head (-> 0); got: #{inspect(other)}"
end
```

`start_position!/1` runs inside `start_link`, on the calling process — so a bad `:group_start` is a
start-time crash the caller sees, not a silent mis-start the loop swallows.

## The door creates; it never destroys

At this rung there is **no destructive group-tear-down verb**. The door creates and swallows-on-exists — it
never deletes a group, never drops a stream. The at-rest removal surface (tearing a group down, trimming the
stream out from under it) stays **unfrozen** for the retention and archive family, where removing data at rest
is the whole point and gets the deliberate, declared treatment it deserves. A reader's door is a *create*
door, full stop.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** a consumer group is created once with `XGROUP CREATE` and shared
  by all consumers; the start id picks the replay point. `/redis-patterns/streams-events` teaches the group.
- **The implementation (echo_mq):** every consumer ensures the group lazily on start — `MKSTREAM` so the
  stream need not pre-exist, `BUSYGROUP` swallowed so restarts are idempotent, everything else loud so a
  mis-start is never silent, and `:group_start` declared so the replay decision is explicit.

## References

### Sources
- [Valkey — XGROUP](https://valkey.io/commands/xgroup/) — `CREATE … MKSTREAM`, the `BUSYGROUP` reply, the start id.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — consumer groups and where a group begins.
- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — the read the door makes possible once the group exists.

### Related in this course
- `/echomq/bus/the-consumer-group` — the module this dive belongs to.
- `/echomq/bus/the-consumer-group/recover-self-then-peers` — what the loop does once the door is open.
- `/echomq/bus/the-stream-log` — the writer whose stream the group reads.
- `/echomq/protocol` — the braced keyspace the stream key is born to.
- `/redis-patterns/streams-events` — the streams pattern that doors here.
