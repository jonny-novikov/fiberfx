# Session management

> Route: `/redis-patterns/caching/session-management` · Module R1.06 · Source:
> `content/community/session-management.md.txt` · Grounding: `EchoStore.Table` — a TTL'd branded-id row keyed `SES`,
> stored via `SET … PX`, refused at the door by the kind gate (`echo/apps/echo_store/lib/echo_store/table.ex`).

Store user sessions in Valkey with automatic expiration using TTL, choosing between Hashes (field-level access),
Strings (serialized), or JSON (nested data) based on access patterns. Valkey is the fit for session storage because of
its speed, its built-in TTL, and its flexible data structures: the access pattern is a read on every request, and the
lifetime is bounded — a session should not outlive a logout, and an idle session should expire on its own.

## The encodings — Hash, String, JSON

A session record holds a few attributes about one signed-in user: a user id, a sign-in time, a last-seen time. It can
sit under a key three ways, and the choice is an access-pattern trade-off.

A **Hash** stores the attributes as named fields, so one field reads or updates without touching the rest:

```
HSET session:abc123 user_id "1" created_at "1706648400" last_access "1706648400"
EXPIRE session:abc123 1800
HGETALL session:abc123                 # read the full session
HSET session:abc123 last_access "1706648500"   # update a single field
```

A **String** holds the whole record as one opaque value, written and read whole. For nested data — a cart, a
preferences map — serialize to **JSON** and store the string with `SET … PX`:

```
SET session:abc123 '{"user_id":1,"cart":["item1","item2"],"prefs":{"theme":"dark"}}' PX 1800000
```

The JSON form simplifies nested data but requires reading and writing the entire session on each update. The trade-off
is **field-level access** (the Hash) against **one round trip for the whole blob** (the String/JSON). EchoStore takes
the String case one step further: it frames the value as a 14-byte branded **version** prefix followed by the bytes —
`version <> value` — so a later coherence message can compare versions newer-wins.

| Encoding | Read | A single-field update | Best for |
|---|---|---|---|
| Hash (`HSET`/`HGETALL`) | `HGETALL` or one field with `HGET` | `HSET` one field — no re-serialize | flat attributes touched independently |
| String (`SET`/`GET`) | `GET` the whole value | rewrite the whole value | a small opaque blob |
| JSON in a String | `GET` + parse | parse, edit, re-serialize, `SET` | nested structure (cart, prefs) |

## Sliding Expiration

Sessions should typically expire after a period of **inactivity**, not from creation time. The fix is to reset the TTL
on each access:

```
HGETALL session:abc123                 # the request reads the record
EXPIRE session:abc123 1800             # and slides the deadline a full window forward
```

This creates a sliding window: an active user stays signed in because each request pushes the deadline ahead, while an
inactive session runs out the clock and expires on its own — no cron job, no sweep, no application bookkeeping.

## Session Creation Flow

Creating a session is four steps:

1. Generate a unique session id — a UUID or a cryptographically secure random string. In EchoStore a session keys to a
   branded `SES` id minted at sign-in.
2. Store the session data with its initial fields.
3. Set the expiration time.
4. Return the session id to the client, typically as a cookie.

The session id must be **cryptographically random** to prevent guessing attacks; a guessable id is a way into someone
else's signed-in session.

## Logout & Real-Time Session Invalidation

Logging out a single session is two deletes — the session key and its entry in the user's roster:

```
DEL session:abc123
SREM user:1:sessions abc123
```

When a user logs out or an admin revokes access, every application server must immediately stop accepting the session.
Pub/Sub broadcasts the invalidation so a stale copy in any server's local cache is dropped at once:

```
PUBLISH session:invalidate abc123      # on logout, the publisher fans out the id
SUBSCRIBE session:invalidate           # every app server, on a message, drops its local copy
```

## Session Data Cleanup

Expired sessions are reclaimed by Valkey automatically, but the session-id references in a user's Set can go stale —
they name keys that no longer exist. A background job, run during low-traffic periods, reconciles them: iterate the
`user:*:sessions` keys, and for each id check whether `session:{id}` still exists, removing the references that point
at nothing.

## Security Considerations

A session store has a small, fixed security checklist:

- Generate session ids with a cryptographically secure random generator.
- Never store a password or any sensitive credential in the session.
- Serve session-id cookies over HTTPS only.
- Consider storing a hash of the user's IP or user-agent to detect session hijacking.
- Set the cookie flags `HttpOnly`, `Secure`, and `SameSite`.

## On EchoStore

A session is the textbook TTL'd row, and EchoStore stores one without any auth surface of its own. `EchoStore.Table.put/3`
sets both layers under the declared TTL — `SET ecc:{sessions}:<id> (version<>value) PX ttl_ms`
(`table.ex:290`) — keyed by a branded `SES` id. A re-auth re-`put`s with a fresh mint-time version
(`put/3` mints `BrandedId.generate!(spec.kind)`, `table.ex:90`); logout is `EchoStore.Table.invalidate/3`
(`table.ex:171` — `DEL` L2 + `:ets.delete`, the admin verb).

The membership tie is the **kind gate**, not a credential check EchoStore owns. Before either layer is touched, `gate/2`
(`table.ex:495`) requires `byte_size(id) == 14 and binary_part(id, 0, 3) == kind and BrandedId.valid?(id)`, returning
`{:error, :kind}` otherwise — so a `USR` id can never be used as a `SES` key, and a wrong-namespace id is refused at the
door with zero keys on the wire. codemojex carries the same shape one level down: a player's per-round state is a
per-player hash `cm:{round}:lock:{player}` (`Codemojex.Locks`, `locks.ex` — field = position, value = code), so a
locked position **persists across guesses with no client state to lose**, server-side and durable, keyed by the
player's `USR` brand. A session is that same idea — state with a deadline, keyed by an identity, held in Valkey, not
in the client. The functional-Elixir and OTP craft behind the echo data layer is taught by the
[`/elixir`](/elixir) course; this module is the session store in front of it.

## The three dives

The arc is **encode → expire → bind**: which shape holds the record, how the deadline is set and reclaimed, and how the
session's life is tied to the namespace it belongs to.

- **R1.06.1 · Hash, String & JSON** — the encoding choice and what a single-field update costs in each.
- **R1.06.2 · TTL expiry** — absolute against sliding, and the lazy and active eviction that makes an `EXPIRE` real.
- **R1.06.3 · The auth tie-in** — keyed by a branded `SES` id, dropped on logout, refused at the kind gate; grounded in
  `EchoStore.Table.put` and `gate/2`.

## References

### Sources
- [Redis — Documentation](https://redis.io/docs/) — hashes, strings, key expiry, and the data structures a session store is built from.
- [Redis — HSET](https://redis.io/commands/hset) — set one or more fields of a Hash; the field-level write a Hash session uses.
- [Valkey — SET](https://valkey.io/commands/set) — set a key to one value with `PX`; value and TTL set atomically, the way `EchoStore.Table.put` writes L2.
- [Valkey — EXPIRE](https://valkey.io/commands/expire) — set a key's time-to-live; the deadline that ends an idle session on its own.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on key expiry and how the engine reclaims keys that have run out.

### Related in this course
- [R1.06.1 · Hash, String & JSON](/redis-patterns/caching/session-management/encodings) — the encoding choice.
- [R1.06.2 · TTL expiry](/redis-patterns/caching/session-management/ttl-expiry) — absolute, sliding, and eviction.
- [R1.06.3 · The auth tie-in](/redis-patterns/caching/session-management/auth-session) — the SES key, logout, the kind gate.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — the EchoStore near-cache sessions live in, in depth.
