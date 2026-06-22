# EchoMQ.Stream.trim/4 + EchoMQ.StreamRetention — retention as policy

Retention is the third behaviour of EchoMQ 3.0's Stream Tier (emq3.4, S2 the readers
part 2): bounding a per-key event stream to a **declared window** — the compliance
window and memory truth. It is a dedicated, **destructive** verb
(`EchoMQ.Stream.trim/4`) plus a named, **opt-in** driver (`EchoMQ.StreamRetention`)
that re-applies a declared window on its own beat. It rides the shipped
`EchoMQ.Connector` generic command path — `XTRIM` is issued **direct**, with no new
Lua and no `echo_wire` change.

The load-bearing property is that retention is a destructive op whose **blast radius
is bounded by the declared window**: a trim removes ONLY entries OUTSIDE the window
and can **never** delete an entry inside it. Over-deletion (removing an in-window
entry) is silent data loss — so the conformance and `:valkey` proofs are *positive*:
they append entries inside AND below a window, trim, and assert in-window survival +
below-window deletion in the same verdict. A trim that deletes nothing proves nothing.

## The verb — `trim/4`

```elixir
# keep the 1000 newest entries (approximate, the safe default)
{:ok, removed} = EchoMQ.Stream.trim(conn, "orders", "events", {:maxlen, 1000, true})

# remove every entry minted before a horizon (exact, a hard compliance cap)
horizon = DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)   # 30 days ago
{:ok, removed} = EchoMQ.Stream.trim(conn, "orders", "events", {:minid, horizon, false})
```

`trim(conn, queue, name, window)` addresses the stream `emq:{queue}:stream:<name>`
(via the shipped `EchoMQ.Stream.stream_key/2`, no grammar edit) and answers
`{:ok, removed_count}` (the integer `XTRIM` returns) or `{:error, term}` (any
connector/server fault verbatim — a `WRONGTYPE` against a non-stream key is
**surfaced, not swallowed**). It **raises** before any wire on a malformed
queue/stream name (policy before existence, the `append_id/5` precedent).

The `window` is a tagged tuple — the **same** shape the driver's declared policy
holds, so a policy entry passes straight through to the verb:

| Window | Wire form | Meaning |
|---|---|---|
| `{:maxlen, count, approx?}` | `XTRIM <key> MAXLEN [~\|=] <count>` | keep the `count` newest entries, remove the older |
| `{:minid, %DateTime{}, approx?}` | `XTRIM <key> MINID [~\|=] "<ms>-0"` | remove every entry minted strictly **before** the instant |

`approx?` selects the trim mode (the third tuple element):

- `true` → `~` (**approximate**, the safe default): `XTRIM` trims in whole macro-nodes,
  so it may keep slightly MORE than the window — it can **under-trim** but can **never
  over-trim**. The destructive op's error direction is toward *keeping* data.
- `false` → `=` (**exact**, the opt-in): removes precisely to the window edge (a hard
  compliance cap), at higher cost. Even `=` removes only to the edge — it cannot delete
  inside the window.

## The trim-honors-the-window table

For both forms, post-trim:

| | The `MAXLEN` window | The `MINID` window |
|---|---|---|
| **Kept (inside the window)** | the N newest entries (under `~`, at-least-N) — every one still reads back | every entry minted at or after the instant |
| **Removed (outside the window)** | entries older than the N newest | every entry minted strictly before the instant |
| **The blast radius (bounded)** | a `MAXLEN N` can never remove one of the N newest; `~` may keep more, never fewer | a `MINID <floor>` can never remove an entry at or above the floor — the floor *is* the window edge |
| **A read inside the window** | never misses — every kept entry is readable | never misses |
| **A read of a trimmed range** | answers truthfully — what survives, never a phantom, never an error masking a deletion (an emptied range reads `[]`) | the same |

## The `MINID` floor — derived from `Snowflake.min_for/1`

The mint-instant window's floor handed to `XTRIM MINID` is a **stream id in the
writer's A1 form** (`"<ms>-<tail>"`), because that is the form `EchoMQ.Stream.append/4`
stores. For a horizon `DateTime` `dt`, the floor is:

```elixir
EchoMQ.Stream.minid_floor(dt)
#=> "<ms>-0"   where   ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt))
#                         == DateTime.to_unix(dt, :millisecond)
```

`"<ms>-0"` is the **smallest** entry id at or after the instant (the tail `-0` is the
lowest sequence at that ms), so `XTRIM MINID "<ms>-0"` removes every entry whose
`ms-seq` id is strictly below it — every entry minted in an *earlier* millisecond. The
edge is the exact **half-open `[dt, ∞)`** retention: an entry minted at `dt − 1ms` is
trimmed, an entry minted at `dt` survives (its ms equals the floor ms, and any tail is
`≥ 0 ≥ -0`). The floor is **derived from `min_for/1`** — never hand-rolled epoch
arithmetic, and never `min_for/1`'s raw 63-bit snowflake integer handed to the wire
(the wire wants `ms-seq`, not an integer).

## The named, opt-in driver — `EchoMQ.StreamRetention`

A one-shot `trim/4` bounds memory once; the driver bounds it **continuously**, by
re-applying a declared window on its own beat. It is the mint-instant analogue of
`EchoMQ.Pump`: a thin GenServer shell over a **pure decision core**
(`EchoMQ.StreamRetention.Core`).

```elixir
{:ok, pid} =
  EchoMQ.StreamRetention.start_link(
    connector: [port: 6390],                              # the driver's OWN lane (or :conn)
    policy: [
      {"orders", "events", {:maxlen, 1000, true}},        # keep the 1000 newest
      {"audit",  "log",    {:minid, {:ago, 30 * 86_400_000}, false}}  # keep the last 30 days
    ],
    tick_ms: 60_000                                        # the beat (default 1_000)
  )
```

| Option | Required | Default | Meaning |
|---|---|---|---|
| `:policy` | no | `[]` | a list of `{queue, name, window}` declared retention policies; an empty policy ticks but trims nothing |
| `:tick_ms` | no | `1_000` | the beat; a non-positive value **raises at start** (a driver that does not advance is a configuration error) |
| `:conn` / `:connector` | one | — | `:conn` a connector to drive, or `:connector` opts to start one linked to the loop |
| `:clock` | no | `&DateTime.utc_now/0` | a 0-arity fn returning the tick instant — **injected** so the decision core is a pure function of the clock in test |
| `:name` | no | — | an optional registered name |

`start_link/1` returns `{:ok, pid}`; `stop/2` settles the current tick and stops;
`sweep/1` applies the declared policy once (exposed for a direct-drive test);
`child_spec/1` is a `:transient` child (a normal stop is final, a crash restarts the
cadence whole — the trim is idempotent over the stream, so a restart over-deletes
nothing).

### Why opt-in, and why decoupled from consumers (D-2)

Retention is a property of the **stream**, not of whether a consumer runs. The driver
is **opt-in** (owner-started, no auto-start `mod:`) because forcing a default-on
destructive sweep on every stream is the coupling the design refused — a stream the
operator wants UNBOUNDED (e.g. a short-lived run replayed in full) must not be silently
trimmed. And it is **decoupled from consumer liveness**: a stream **nobody drains
still trims** if its policy is declared, and the `EchoMQ.StreamConsumer` loop is never
touched. Coupling a *safety* property (bounded memory) to a *liveness* fact (a consumer
is up) is exactly the silent-no-op class the steward refuses.

A manual `trim/4` call is the **equally-supported** cadence — the driver is sugar over
the verb, never the only path.

## The policy is BEAM-side (D-3)

The per-stream policy is held **BEAM-side** — the driver's own config (the `:policy`
option), re-applied at start. There is **no keyspace subkey**
(`emq:{queue}:stream:<name>:policy` is never written), **no at-rest cleanup
obligation** (the policy is process state, retired when the driver stops), and **no
reader-visible policy** — a polyglot reader reads ENTRIES; it does not enforce
retention. A malformed declared window **raises at decision time** (in the pure core),
never a silent skip. Keyspace-visible policy (a mirror a cross-runtime reader could
introspect) is a later additive upgrade reachable without a wire break — surfaced, not
built at this rung.

## The pure decision core — `EchoMQ.StreamRetention.Core`

The tick decision is a pure value, not a buried IO `defp` (the verdict-surface law,
the `EchoMQ.Pump.Core` / `EchoMQ.BatchShaper.Core` precedent): given the declared
policy and an injected clock, `decide/2` answers which `trim/4` call to make for each
stream (or `:noop` when nothing is declared), exhaustive and disjoint over the window
forms. So the cadence is testable WITHOUT a live process, and a relative horizon is a
pure function of the clock:

```elixir
# absolute and relative horizons both resolve against the injected clock:
EchoMQ.StreamRetention.Core.decide(
  [{"audit", "log", {:minid, {:ago, 60_000}, true}}],   # keep the last 60s
  ~U[2025-05-01 12:00:00.000Z]
)
#=> [{"audit", "log", {:minid, ~U[2025-05-01 11:59:00.000Z], true}}]
```

## Acceptance criteria & conformance

The behaviour above is proven by the BDD story catalogue
([`docs/echo_mq/stories/stream-retention.stories.md`](../../../docs/echo_mq/stories/stream-retention.stories.md),
generated from `test/stories/stream_retention_story_test.exs`) and the exhaustive
`:valkey` suite (`test/stream_retention_test.exs` — both window forms, the half-open
`MINID` edge, the truthful-read-after-trim, the pure decision core, a sweep with no
consumer present). The `stream_retention` conformance scenario (`EchoMQ.Conformance`)
is a **positive blast-radius proof**: entries are appended inside AND below a window
over BOTH forms, trimmed, and the in-window entries must survive while the below-window
entries are gone, the removed-count exact — a no-op that deletes nothing is a loud
failure.

> Built on the shipped `EchoMQ.Connector` generic command path — `XTRIM` is issued
> directly, with no new Lua, no `echo_wire` change, no new wire class, and no keyspace
> subkey (the policy is BEAM-side). The trim mints no branded id and opens no lease.
