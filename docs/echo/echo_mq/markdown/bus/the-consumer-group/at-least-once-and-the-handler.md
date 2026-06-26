# At-least-once and the handler

> Route: `/echomq/bus/the-consumer-group/at-least-once-and-the-handler` · Module 03 · dive 03.
> Grounds in `EchoMQ.StreamConsumer` — `settle/2`, `delivery_count/2`, `parse_fields/1` (`echo/apps/echo_mq`).
> No Lua — `XACK` / `XPENDING` issue direct. Forward doors (time-travel, retention/archive) named, not built.

A consumer group makes one delivery guarantee and refuses to overstate it: **at-least-once**. Every entry is
delivered to a consumer at least once; under crash and reclaim, some entries are delivered **more** than once.
Exactly-once is **not** claimed. That single honest choice shapes the handler, the ack, and the one rule the
caller must obey — **be idempotent**.

## The handler is the exact mirror of the job consumer's

A stream consumer's handler has the **same shape** as the job `Consumer`'s handler — by design, so one
portable handler works across both job and stream:

```
fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}
```

- **`id`** — the **branded record id**: the `EchoMQ.Stream.append/4` receipt from module 02, recovered from
  the entry's reserved `id` field. The same 14-byte id the writer minted and handed back is the one the
  handler sees — the thread runs unbroken from append to handle.
- **`payload`** — the entry's remaining fields as a map (everything but the `id` field).
- **`group`** — the consumer-group name.
- **`attempts`** — the `XPENDING` **per-entry delivery-count**: how many times **this entry** has been
  delivered to a consumer. A fresh `>` delivery is `1`; a re-claim (via `XAUTOCLAIM`, or a PEL-drain after
  another delivery) increments it.

The `attempts` distinction is load-bearing and **specced, not assumed**: it counts **deliveries**, not
handler **failures**. A poison entry — one that crashes every handler that touches it — has its delivery-count
climb each time it is re-claimed, so a poison threshold `attempts >= N` calibrates correctly against *how many
times we've tried to deliver this*, exactly the quantity you want to threshold on.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# Settle ONE entry: the branded id is the stored "id" field (the Stream.append/4
# receipt); the payload is the remaining fields; `attempts` is the XPENDING per-entry
# delivery-count (NOT a handler-failure count). A raising handler converts to
# {:error, reason} and the loop SURVIVES. On :ok -> XACK; on {:error, _} -> LEAVE
# un-acked (it survives in the PEL, re-deliverable — the at-least-once posture).
defp settle(s, [xadd_id, kv]) when is_list(kv) do
  {branded, payload} = parse_fields(kv)
  attempts = delivery_count(s, xadd_id)

  verdict =
    try do
      s.handler.(%{id: branded, payload: payload, attempts: attempts, group: s.group})
    rescue
      e -> {:error, Exception.message(e)}
    catch
      :exit, reason -> {:error, "exit: " <> inspect(reason)}
      :throw, value -> {:error, "throw: " <> inspect(value)}
    end

  case verdict do
    :ok ->
      # the genuinely-pending entry retires from the PEL.
      _ = Connector.command(s.conn, ["XACK", s.key, s.group, xadd_id])
      :ok

    {:error, _reason} ->
      # left un-acked: it survives in the PEL, re-delivered by the XAUTOCLAIM beat
      # or the next PEL-drain (the at-least-once posture).
      :ok
  end
end
```

## :ok acks; an error or a raise leaves it un-acked

The verdict drives one decision: ack, or don't.

- **`:ok`** → the entry is **`XACK`ed**, retiring it from the PEL. It is done; no consumer will see it again.
- **`{:error, reason}`** or a **raise** → the entry is **left un-acked**. It survives in the PEL and is
  re-delivered — by the `XAUTOCLAIM` beat (to a peer) or the next PEL-drain (to this consumer on restart).

A raising handler does not take the loop down. The `try/rescue/catch` converts any raise, exit, or throw into
a typed `{:error, reason}`, and the loop **survives** to handle the next entry. A bug in one handler call
costs that entry a re-delivery, not the whole consumer. The `delivery_count` read is itself defensive — if the
`XPENDING` row is absent (a race: a peer just acked the entry), it defaults to `1` rather than minting on
`nil`.

```elixir
# echo_mq — EchoMQ.StreamConsumer
# The XPENDING per-entry delivery-count: XPENDING <key> <group> <id> <id> 1 answers
# [[id, consumer, idle, delivery_count]]; the 4th field is how many times THIS entry
# has been delivered. A fresh `>` delivery is 1; a re-claim increments it. Defaults
# to 1 if the row is absent (a race — the entry just acked by a peer), never on nil.
defp delivery_count(s, xadd_id) do
  case Connector.command(s.conn, ["XPENDING", s.key, s.group, xadd_id, xadd_id, "1"]) do
    {:ok, [[^xadd_id, _consumer, _idle, count] | _]} -> to_int(count)
    _ -> 1
  end
end
```

## The order-theorem PEL exception

Module 02 proved a theorem: **stream order == id sort == mint order**. Under a group, that theorem holds for
**new** entries — `XREADGROUP … >` hands them in mint order, the writer's guarantee untouched. But a
**re-claimed** entry breaks **real-time delivery order**: it was minted *before* entries already handled, so
when `XAUTOCLAIM` (or a PEL-drain) returns it, its branded id is **older — lower** — than ids the handler has
already seen. A newer entry was delivered; then an older one arrives.

This is the **irreducible cost of at-least-once**. There is no way to have crash-recovery *and* perfect
real-time ordering on a distributed read — recovering a dead peer's old work necessarily replays it after
newer work moved on. The writer's theorem is not violated (the *log* is still id-ordered); what a re-claim
gives up is the *delivery* being in that order.

So the rule the handler must obey: **be idempotent.** Handling the same entry twice, or an older entry after a
newer one, must be safe. The **branded id is the dedup key** — the BCS newer-wins discipline applied at the
read side: a handler that records "highest id I've applied" can recognize and skip a stale replay, the same
way `EchoStore.Coherence` decides a cache write by comparing branded ids. The id that was the writer's receipt
becomes the reader's dedup key.

## The forward doors

This module reads the live tail. Two surfaces extend it, named here and built later:

- **Time-travel** — `EchoMQ.Stream.read_window/6` / `read_since/5` read the log by a **mint instant** (a
  `%DateTime{}` becomes an id range bound). That is module 04.
- **Retention & the archive** — `EchoMQ.Stream.trim/4` bounds the log, and `EchoStore.StreamArchive.fold/3`
  folds what it trims into the durable Graft floor — deep history without resident memory. That is module 05,
  and the door to **Echo Persistence** (`/echo-persistence`).

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** a consumer group delivers at-least-once; `XACK` retires a handled
  entry; an unacked entry is re-delivered; consumers must be idempotent.
  `/redis-patterns/streams-events` teaches at-least-once delivery.
- **The implementation (echo_mq):** the exact-mirror handler returns `:ok` (ack) or `{:error, _}` (leave),
  a raise converts to an error and the loop survives, `attempts` is the delivery-count (not a failure count)
  so a poison threshold calibrates, and a re-claimed entry returns out of real-time order — which is why the
  branded id is the idempotency dedup key.

## References

### Sources
- [Valkey — XACK](https://valkey.io/commands/xack/) — the acknowledgement that retires an entry from the PEL.
- [Valkey — XPENDING](https://valkey.io/commands/xpending/) — the per-entry delivery-count `attempts` carries.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — at-least-once delivery and the PEL.
- [Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563) — the total order a re-claim necessarily disturbs.

### Related in this course
- `/echomq/bus/the-consumer-group` — the module this dive belongs to.
- `/echomq/bus/the-consumer-group/recover-self-then-peers` — the loop that re-delivers an un-acked entry.
- `/echomq/bus/the-stream-log/the-order-theorem` — the writer's theorem the PEL exception bends.
- `/echo-persistence` — the durable floor a trimmed stream history folds into.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
- `/redis-patterns/streams-events` — the streams pattern that doors here.
