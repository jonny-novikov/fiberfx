# The auth tie-in

> Route: `/redis-patterns/caching/session-management/auth-session` · Module R1.06 · dive 3 · Source:
> `content/community/session-management.md.txt` (the *Session Creation Flow*, *Logout Operations*, *Multi-Device
> Session Tracking*, *Real-Time Session Invalidation*, and *Security Considerations* sections) · Grounding:
> `EchoStore.Table` — a `SES`-keyed row via `put/3`, dropped by `invalidate/3`, refused by the kind gate `gate/2`
> (`echo/apps/echo_store/lib/echo_store/table.ex`); the per-player lock hash `cm:{round}:lock:{player}`
> (`Codemojex.Locks`, `echo/apps/codemojex/lib/codemojex/locks.ex`).

A session is born at sign-in, ended by a logout, and refused at the door when its id is the wrong kind — so a session
key can only ever be a session.

## Mint at login, drop at logout

The session's life runs alongside the login. At **sign-in**, the application verifies the credentials, mints a session
record under a fresh random id, and returns that id to the browser as a cookie. The session id must be
cryptographically random; the password is never stored in the session — only the user id and a token go in.

On **each request**, the application reads the cookie's id, loads the session, and resolves the user from it. A loaded
session means signed in; a missing one means signed out. At **logout**, the application removes the session with `DEL
session:abc123`. The next request loads an absent session, so the gate **fails closed** — it treats the request as
anonymous and redirects to sign in. Logout is one delete, and its effect is immediate and total.

## One device, or all of them

A learner signs in on a laptop, a phone, and a library computer — three sessions, three ids, one user. The
single-device logout is the `DEL` above: remove the one session id this browser holds. "Sign out everywhere" needs to
find every session a user owns, so each sign-in records the new id in a Set:

```
SADD user:1:sessions abc123            # on sign-in, add the new session id to the roster
SMEMBERS user:1:sessions               # list the user's active sessions
SREM user:1:sessions abc123            # single-device logout drops one id from the roster
```

To sign out everywhere, delete each session key the Set names, then delete the Set. To make the invalidation reach
every application server at once, a Pub/Sub broadcast — `PUBLISH session:invalidate abc123` — tells every server to
drop its local copy.

## On EchoStore

EchoStore holds a session as a branded-id-keyed row with no auth surface of its own — there is no sign or verify call in
the cache. Sign-in keys the row to a branded `SES` id and stores it with `EchoStore.Table.put/3`, which sets both layers
under the declared TTL — `SET ecc:{sessions}:<id> (version<>value) PX ttl_ms` (`table.ex:290`), the value framed with
the write's mint-time version (`put/3` mints `BrandedId.generate!(spec.kind)`, `table.ex:90`). A re-auth re-`put`s with
a fresh version, the sliding move. Logout is `EchoStore.Table.invalidate/3` (`table.ex:171` — `DEL` L2 + `:ets.delete`,
the admin verb): the next read finds nothing and the gate fails closed.

```
# A session as an EchoStore row — keyed by a branded SES id, framed and TTL'd.
# put/3 writes L2 and L1 in one synchronous call; there is no sign/verify in the cache.
SET ecc:{sessions}:SES0KH... <version<>value> PX 1800000   # EchoStore.Table.put/3 — table.ex:290
GET ecc:{sessions}:SES0KH...                                # the read splits version<>value back apart
DEL ecc:{sessions}:SES0KH...                                # EchoStore.Table.invalidate/3 — logout, table.ex:171
```

The tie to a player is the **kind gate**, not a credential check. Before either layer is touched, `gate/2`
(`table.ex:495`) requires `byte_size(id) == 14 and binary_part(id, 0, 3) == kind and BrandedId.valid?(id)`, returning
`{:error, :kind}` otherwise — so a `USR` id can never be used as a `SES` key, and a wrong-namespace id is refused with
zero keys on the wire. codemojex holds the same shape one level down: a player's per-round state is a per-player hash
`cm:{round}:lock:{player}` (`Codemojex.Locks`, `locks.ex` — field = position, value = code, written with `HSET`), so a
locked position persists across guesses with no client state to lose, keyed by the player's `USR` brand. How a
credential is verified and a `SES` id is minted is the functional-Elixir and OTP craft of the [`/elixir`](/elixir)
course; this dive is the session the store holds and the kind law that guards it.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — set a key with `PX`; the framed-and-TTL'd row `EchoStore.Table.put` writes for a session.
- [Redis — DEL](https://redis.io/commands/del) — remove a key; the logout `EchoStore.Table.invalidate` runs against L2.
- [Redis — SADD](https://redis.io/commands/sadd) — add a member to a Set; the per-user roster that records each device's session id.
- [Redis — SMEMBERS](https://redis.io/commands/smembers) — list a Set's members; the active-session list behind "sign out everywhere".

### Related in this course
- [R1.06 · Session management](/redis-patterns/caching/session-management) — the module hub.
- [R1.06.2 · TTL expiry](/redis-patterns/caching/session-management/ttl-expiry) — the previous dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — the EchoStore near-cache behind a session read, in depth.
- [/bcs](/bcs) — the EchoStore manuscript, Part IV.
