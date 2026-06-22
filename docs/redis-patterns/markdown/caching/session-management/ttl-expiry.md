# TTL expiry

> Route: `/redis-patterns/caching/session-management/ttl-expiry` · Module R1.06 · dive 2 · Source:
> `content/community/session-management.md.txt` (the *Sliding Expiration* section + *Session Data Cleanup*) ·
> Grounding: `EchoCache.Table` — `SET … PX`, the jittered `expires_at/1`, and the `:sweep` sweeper
> (`echo/apps/echo_cache/lib/echo_cache/table.ex`).

An absolute TTL ends the session at a fixed time from sign-in. A sliding TTL refreshes the deadline on each request, so
active users stay in and idle ones fall out.

## Absolute vs sliding

Every session carries a deadline. An **absolute** deadline is set once at sign-in and never moves — the session ends at
that instant no matter how busy the user is. A **sliding** deadline is reset on each access: an `EXPIRE` after every
read pushes it a full window ahead of the last request, so it ends only after a stretch of silence.

```
HGETALL session:abc123                 # a request reads the record
EXPIRE session:abc123 1800             # and slides the deadline 1800s ahead of now
```

The sliding form is the default for a session store: it keeps an active user signed in while letting an idle one expire
on its own.

## How a key is reclaimed

Setting an `EXPIRE` does not delete the key at the deadline instant. The engine reclaims an expired key two ways.
**Lazy** (passive) eviction removes it the next time it is accessed — a `GET` on an expired key returns `nil` and drops
the key. **Active** eviction is a background cycle that samples keys with a TTL and reclaims the ones that have run out,
so a key no one ever reads again still leaves memory. `TTL session:abc123` reads the remaining life: a positive number
of seconds, `-1` for a key with no deadline, `-2` for a key already gone.

The session-id references in a user's roster Set are *not* reclaimed by the key TTL — they outlive the session keys
they name. *Session Data Cleanup* reconciles them as a low-traffic background job: walk `user:*:sessions`, and for each
id drop the reference when `session:{id}` no longer exists.

## On EchoCache

EchoCache writes its L2 row with the TTL in the same command — `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms`
(`table.ex:290`) — so value and deadline land atomically; a session is a TTL'd row and the `PX` expiry is its lifetime.
A re-`put` on the next request re-stamps the row with a fresh deadline, the sliding-window move. Above L2, the L1 ETS
copy carries its own expiry drawn from a **jittered** clock — `expires_at/1` returns `ttl ± ttl·jitter` (`table.ex:484`)
— so a cohort filled together never expires together, and a separate `:sweep` handler (`table.ex:350`) reclaims the
dead rows on a fixed tick with one `:ets.select_delete`. Two clocks, each layer sovereign over its own staleness. The
functional-Elixir and OTP craft behind the cache is the [`/elixir`](/elixir) course; this dive is the deadline the store
enforces.

## References

### Sources
- [Valkey — EXPIRE](https://valkey.io/commands/expire) — set a key's time-to-live; the command rerun on each read to slide a session's deadline, and the engine's two reclamation paths.
- [Valkey — SET](https://valkey.io/commands/set) — set a key with `PX`; value and TTL in one command, the way `EchoCache.Table.put` writes L2.
- [Redis — TTL](https://redis.io/commands/ttl) — read a key's remaining life in seconds; `-2` for a reclaimed key, `-1` for no deadline.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry sampling and the cost of background eviction.

### Related in this course
- [R1.06 · Session management](/redis-patterns/caching/session-management) — the module hub.
- [R1.06.1 · Hash, String & JSON](/redis-patterns/caching/session-management/encodings) — the previous dive.
- [R1.06.3 · The auth tie-in](/redis-patterns/caching/session-management/auth-session) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the protocol the coherence lane rides.
