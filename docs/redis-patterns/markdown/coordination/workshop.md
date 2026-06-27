# R2.06 · Workshop — A guess submission, made atomic

> R2 · Coordination & Consistency. The capstone of the chapter: fold the five coordination
> patterns into one codemojex guess submission that either lands completely or not at
> all — the validate-then-admit door (`Codemojex.Guesses.submit/3`) charges the wallet, mints a
> branded `JOB`, and hands the guess to one atomic admission script (`EchoMQ.Lanes.enqueue`;
> `EchoMQ.Jobs.enqueue` → `@enqueue`), all over co-located `emq:{cm}:*` keys.

Make a codemojex guess submission atomic: validate untrusted input, charge the wallet, mint a
branded `JOB` at acceptance, then admit that guess onto the `cm` lane in one Lua script that
either records the guess completely or changes nothing — so a retried submission is a no-op and a
half-written guess never exists.

The chapter taught five patterns: atomic updates (R2.01), distributed locking (R2.02), the
Redlock contrast (R2.03), cross-shard detection (R2.04), and hash-tag co-location (R2.05). This
workshop is the one example that needs all of them at once, and shows why the lightest of them —
a single co-located atomic script — makes the heavier machinery unnecessary here. It needs no
lock and no Redlock because the script is the serialization.

## Two steps: validate-and-mint, then admit-as-one-script

A guess submission is two moves, and the chapter's patterns govern the second.

First, the door. `Codemojex.Guesses.submit/3` (`echo/apps/codemojex/lib/codemojex/game.ex`)
turns an untrusted six-emoji guess into either an admitted job or one member of a closed error
set — `:no_round | :closed | :expired | :bad_guess`, plus a wallet `:insufficient`. No exception
escapes; nothing is half done. It validates against the round (open? not expired? valid emojis?),
charges the wallet atomically, mints a branded `JOB` id at the instant of acceptance, and admits
the guess onto the player's lane:

```elixir
# Codemojex.Guesses.submit/3 — the success branch (game.ex:21)
true ->
  guess = Locks.merge(round, player, emojis)          # overlay the player's locked positions
  case Wallet.charge_guess(player, r, round) do        # Repo.transaction + SELECT … FOR UPDATE
    {:ok, _balance} ->
      job = EchoData.BrandedId.generate!("JOB")        # minted at acceptance, success branch only
      payload = :erlang.term_to_binary({:guess, round, player, guess})
      Lanes.enqueue(Bus.conn(), "cm", player, job, payload)   # one atomic admission onto the cm lane
    {:error, reason} -> {:error, reason}
  end
```

Second, admission. The validated guess is recorded onto the `cm` lane as one atomic Lua script.
The branded `JOB` id is the job key and the idempotency key (`echo/apps/codemojex/game.ex`), so
admitting the guess onto the lane and refusing a duplicate are the same indivisible step.

## The keys that must move together

Admission touches two co-located keys, declared in the script's `KEYS` (the v2 law — every key
a script touches is named in `KEYS`; `ARGV` carries values only):

```
emq:{cm}:job:<branded>   # Hash: the guess's row — state, attempts, payload
emq:{cm}:pending         # Sorted set: the pending queue, member = the branded id, score 0
```

`EchoMQ.Keyspace.queue_key(q, type)` always braces the queue name —
`"emq:{" <> q <> "}:" <> type` — and `job_key(q, branded)` returns `emq:{q}:job:<branded>` after
gating the id with `EchoData.BrandedId.valid?/1`. The row and the pending entry are one fact: a
guess on the pending set with no row, or a row with no pending entry, is a half-written guess.
They must change as one.

## One Lua script — the whole admission, all-or-nothing

`EchoMQ.Jobs.enqueue/4` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:27`) runs the admission as a
single declared-keys script, `@enqueue` (jobs.ex:14), through `EchoMQ.Connector.eval/5`
(`echo/apps/echo_wire/lib/echo_mq/connector.ex:63`), EVALSHA-first with a load-on-`NOSCRIPT`
fallback:

```lua
-- @enqueue  KEYS[1] = emq:{cm}:job:<id>   KEYS[2] = emq:{cm}:pending
--           ARGV[1] = the branded id      ARGV[2] = the payload
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

- **Admit by kind.** The first line checks the id's three-byte namespace; the lane admits jobs,
  so a non-`JOB` id is refused with `EMQKIND` before any write. The guess's `JOB`-namespaced
  work-item id is the branded id minted at acceptance — the same id treated as the idempotency
  key.
- **Idempotent on retry.** The `EXISTS` check returns `0` for an id already on the lane, writing
  nothing. A dropped reply that triggers a client retry never double-admits the guess — the
  branded id is the idempotency key (R2.01's idempotency-key technique).
- **Never a torn write.** The `HSET` row and the `ZADD` pending entry run inside one script, so
  the guess's row and its pending position land together or not at all — the atomic precondition
  R2.01 is built to hold.

## Why the heavier machinery is unnecessary here

The script is the serialization. Because Valkey runs one Lua script to completion before the
next command, the admission is already mutually exclusive without a separate lock:

- **No per-guess distributed lock (R2.02).** A `SET NX PX` lock with a fencing token exists to
  serialize a read-modify-write that spans several round trips. Admission is one round trip; the
  script already serializes it, so a lock would only add a lease to renew and a failure mode to
  handle. EchoMQ's lease and `attempts` fence belong to the *claim* of a pending job, not its
  admission — they are R2.02's worked form, not this one.
- **No multi-master Redlock (R2.03).** Redlock buys mutual exclusion across N independent Redis
  masters. EchoMQ reads one server clock inside one atomic script over one `EchoMQ.Connector`;
  its atomicity comes from the single server running the script, not from a majority of masters.
  Reaching for Redlock here would trade a real guarantee for a weaker, more expensive one.
- **No torn-write detection (R2.04).** Cross-shard detection — version tokens, commit markers —
  is the fallback when keys cannot share a slot. The `{cm}` hash tag co-locates the row and
  the pending set, so the torn write the detection guards against cannot occur.

The chapter's lightest pattern is the one that holds: co-locate the keys, run one script, and
the three heavier coordination tools are not needed for this admission.

## The hash tag keeps the multi-key script legal

On a cluster the two keys must share one slot, or a script touching both raises `CROSSSLOT`
(R2.05). The `{cm}` hash tag arranges that: Valkey hashes only the substring inside the
first non-empty `{...}`, so `emq:{cm}:job:<id>` and `emq:{cm}:pending` both hash
`cm` and land on one slot. `EchoMQ.Keyspace.slot/1` computes this client-side —
CRC16-XMODEM over the hash tag modulo 16384 — so the connector routes without a server round
trip (known vector: `slot("123456789") == 12739`).

```
emq:{cm}:job:JOB0NgWEfAEJfs   # hashes "cm" -> one slot
emq:{cm}:pending              # hashes "cm" -> the same slot
```

Drop the tag and the two keys scatter to two slots, and the admission cannot be one script at
all. The tag is the precondition for the atomic admission.

## Grounded in the real EchoMQ admission

This is not an illustration of a generic queue — it is the real admission path. The guess's row
is the three-field hash (`state, attempts, payload`); the pending set is a same-score sorted set
whose members are the branded ids themselves, so byte order is mint order and the queue carries
no second index. `enqueue/4` is one of EchoMQ's eight script verbs (enqueue, browse,
pending_size, claim, complete, retry, promote, reap); the next verb, `claim`, leases a pending
job on the server clock and takes `attempts` as its fencing token — R2.02's worked form, the
move beyond this admission.

The full script bundle, the EVALSHA / `NOSCRIPT` dispatch, the lease-and-fence claim plane, and
the `echomq:3.0.0` protocol version fence are the subject of the dedicated EchoMQ course. This
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
- [R2.05 · Hash-tag co-location](/redis-patterns/coordination/hash-tag-colocation) — the `{cm}` tag that keeps the multi-key `EVAL` legal.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol that teaches the full script bundle behind this admission.

## The door

The admission model — one Lua script per state transition, the full script bundle (enqueue,
browse, pending_size, claim, complete, retry, promote, reap), the EVALSHA / `NOSCRIPT` dispatch
in `EchoMQ.Connector.eval/5`, and the lease-and-fence claim plane — is the subject of the
dedicated **[EchoMQ course](/echomq)**, the companion depth course that teaches the protocol in
full. Return to the [Coordination chapter](/redis-patterns/coordination) to continue, and see
the [Overview](/redis-patterns/overview) for where Valkey sits under codemojex.
