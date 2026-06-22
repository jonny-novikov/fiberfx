# R2.06 · Workshop — Order placement, made atomic

> R2 · Coordination & Consistency. The capstone of the chapter: fold the five coordination
> patterns into one Exchange Platform order placement that either lands completely or not at
> all — the parse-don't-validate door (`Exchange.Gateway.parse_place/1`) hands its minted order
> to one atomic admission script (`EchoMQ.Jobs.enqueue` → `@enqueue`), all over co-located
> `emq:{orders}:*` keys.

Make an Exchange Platform order placement atomic: parse untrusted input into a typed command
with a branded id minted at acceptance, then admit that order onto the `{orders}` queue in one
Lua script that either records the order completely or changes nothing — so a retried placement
is a no-op and a half-written order never exists.

The chapter taught five patterns: atomic updates (R2.01), distributed locking (R2.02), the
Redlock contrast (R2.03), cross-shard detection (R2.04), and hash-tag co-location (R2.05). This
workshop is the one example that needs all of them at once, and shows why the lightest of them —
a single co-located atomic script — makes the heavier machinery unnecessary here. It needs no
lock and no Redlock because the script is the serialization.

## Two steps: parse-and-mint, then admit-as-one-script

An order placement is two moves, and the chapter's patterns govern the second.

First, the door. `Exchange.Gateway.parse_place/1` (`echo/apps/exchange/lib/exchange/gateway.ex`)
turns an untrusted `map()` into either a typed command or one member of the closed six-atom
error set — `:unknown_instrument | :bad_direction | :bad_order_type | :nonpositive_quantity |
:bad_price | :malformed`. No exception escapes; no partially-built command is ever returned. On
success it mints a branded id at the instant of acceptance and returns the place command:

```elixir
# Exchange.Gateway.parse_place/1 — the success branch (gateway.ex:91)
{:ok,
 {:place,
  %{
    id: EchoData.Snowflake.next_branded("ORD"),   # minted at acceptance, success branch only
    instrument: instrument,
    account: account,
    direction: direction,                          # :buy | :sell
    type: type,                                    # :limit | :market
    quantity: quantity,                            # pos_integer
    price: price                                   # {units, nano} | :market — never a float
  }}}
```

Second, admission. The parsed order is recorded onto the `{orders}` queue as one atomic Lua
script. The branded id is the job key and the venue idempotency key (`docs/exchange/trd.1.1.md`),
so admitting the order onto the queue and refusing a duplicate are the same indivisible step.

## The keys that must move together

Admission touches two co-located keys, declared in the script's `KEYS` (the v2 law — every key
a script touches is named in `KEYS`; `ARGV` carries values only):

```
emq:{orders}:job:<branded>   # Hash: the order's row — state, attempts, payload
emq:{orders}:pending         # Sorted set: the pending queue, member = the branded id, score 0
```

`EchoMQ.Keyspace.queue_key(q, type)` always braces the queue name —
`"emq:{" <> q <> "}:" <> type` — and `job_key(q, branded)` returns `emq:{q}:job:<branded>` after
gating the id with `EchoData.BrandedId.valid?/1`. The row and the pending entry are one fact: an
order on the pending set with no row, or a row with no pending entry, is a half-written order.
They must change as one.

## One Lua script — the whole admission, all-or-nothing

`EchoMQ.Jobs.enqueue/4` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:27`) runs the admission as a
single declared-keys script, `@enqueue` (jobs.ex:14), through `EchoMQ.Connector.eval/5`
(`echo/apps/echo_wire/lib/echo_mq/connector.ex:63`), EVALSHA-first with a load-on-`NOSCRIPT`
fallback:

```lua
-- @enqueue  KEYS[1] = emq:{orders}:job:<id>   KEYS[2] = emq:{orders}:pending
--           ARGV[1] = the branded id          ARGV[2] = the payload
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')   -- admit by kind
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0                                                            -- refuse duplicates
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

`enqueue/4` reads the script's integer back into a verdict in input order:

```elixir
case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
  {:ok, 1} -> {:ok, :enqueued}
  {:ok, 0} -> {:ok, :duplicate}
  {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
  other -> other
end
```

Three properties make this correct — and the interactive at the top of the page is each of them
made concrete.

- **Admit by kind.** The first line checks the id's three-byte namespace; the queue admits jobs,
  so a non-`JOB` id is refused with `EMQKIND` before any write. The order's `JOB`-namespaced
  work-item id is the branded id from the canon — the same id the venue treats as the
  idempotency key.
- **Idempotent on retry.** The `EXISTS` check returns `0` for an id already on the queue, writing
  nothing. A dropped reply that triggers a client retry never double-admits the order — the
  branded id is the idempotency key (R2.01's idempotency-key technique).
- **Never a torn write.** The `HSET` row and the `ZADD` pending entry run inside one script, so
  the order's row and its pending position land together or not at all — the atomic precondition
  R2.01 is built to hold.

## Why the heavier machinery is unnecessary here

The script is the serialization. Because Valkey runs one Lua script to completion before the
next command, the admission is already mutually exclusive without a separate lock:

- **No per-order distributed lock (R2.02).** A `SET NX PX` lock with a fencing token exists to
  serialize a read-modify-write that spans several round trips. Admission is one round trip; the
  script already serializes it, so a lock would only add a lease to renew and a failure mode to
  handle. EchoMQ's lease and `attempts` fence belong to the *claim* of a pending job, not its
  admission — they are R2.02's worked form, not this one.
- **No multi-master Redlock (R2.03).** Redlock buys mutual exclusion across N independent Redis
  masters. EchoMQ reads one server clock inside one atomic script over one `EchoMQ.Connector`;
  its atomicity comes from the single server running the script, not from a majority of masters.
  Reaching for Redlock here would trade a real guarantee for a weaker, more expensive one.
- **No torn-write detection (R2.04).** Cross-shard detection — version tokens, commit markers —
  is the fallback when keys cannot share a slot. The `{orders}` hash tag co-locates the row and
  the pending set, so the torn write the detection guards against cannot occur.

The chapter's lightest pattern is the one that holds: co-locate the keys, run one script, and
the three heavier coordination tools are not needed for this admission.

## The hash tag keeps the multi-key script legal

On a cluster the two keys must share one slot, or a script touching both raises `CROSSSLOT`
(R2.05). The `{orders}` hash tag arranges that: Valkey hashes only the substring inside the
first non-empty `{...}`, so `emq:{orders}:job:<id>` and `emq:{orders}:pending` both hash
`orders` and land on one slot. `EchoMQ.Keyspace.slot/1` computes this client-side —
CRC16-XMODEM over the hash tag modulo 16384 — so the connector routes without a server round
trip (known vector: `slot("123456789") == 12739`).

```
emq:{orders}:job:JOB0NgWEfAEJfs   # hashes "orders" -> one slot
emq:{orders}:pending              # hashes "orders" -> the same slot
```

Drop the tag and the two keys scatter to two slots, and the admission cannot be one script at
all. The tag is the precondition for the atomic admission.

## Grounded in the real EchoMQ admission

This is not an illustration of a generic queue — it is the real admission path. The order's row
is the three-field hash (`state, attempts, payload`); the pending set is a same-score sorted set
whose members are the branded ids themselves, so byte order is mint order and the queue carries
no second index. `enqueue/4` is one of EchoMQ's eight script verbs (enqueue, browse,
pending_size, claim, complete, retry, promote, reap); the next verb, `claim`, leases a pending
job on the server clock and takes `attempts` as its fencing token — R2.02's worked form, the
move beyond this admission.

The full script bundle, the EVALSHA / `NOSCRIPT` dispatch, the lease-and-fence claim plane, and
the `echomq:2.0.0` protocol version fence are the subject of the dedicated EchoMQ course. This
workshop closes R2 with one co-located, idempotent, atomic admission; that course teaches every
script behind the protocol.

## References

### Sources

- [Redis — *Programmability (EVAL intro)*](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — one Lua script as a single atomic step; `EVALSHA`/`NOSCRIPT` dispatch.
- [Valkey — *EVAL*](https://valkey.io/commands/eval/) — the command that runs the admission script as one atomic step on the engine.
- [Valkey — *Cluster specification*](https://valkey.io/topics/cluster-spec/) — hash tags, the 16384 slots, and the `CROSSSLOT` that co-location prevents.
- [Redis — *Documentation*](https://redis.io/docs/) — the sorted set, hash, and scripting commands the admission is built from.

### Related in this course

- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter this workshop closes.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-script atomic transition this admission is.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the claim lease and `attempts` fence this admission does not need.
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — the torn write the one-slot script cannot produce.
- [R2.05 · Hash-tag co-location](/redis-patterns/coordination/hash-tag-colocation) — the `{orders}` tag that keeps the multi-key `EVAL` legal.
- [/echomq](/echomq) — the EchoMQ protocol that teaches the full script bundle behind this admission.

## The door

The admission model — one Lua script per state transition, the full script bundle (enqueue,
browse, pending_size, claim, complete, retry, promote, reap), the EVALSHA / `NOSCRIPT` dispatch
in `EchoMQ.Connector.eval/5`, and the lease-and-fence claim plane — is the subject of the
dedicated **[EchoMQ course](/echomq)**, the companion depth course that teaches the protocol in
full. Return to the [Coordination chapter](/redis-patterns/coordination) to continue, and see
the [Overview](/redis-patterns/overview) for where Valkey sits under the Exchange Platform.
