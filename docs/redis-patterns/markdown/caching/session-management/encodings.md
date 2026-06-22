# Hash, String & JSON

> Route: `/redis-patterns/caching/session-management/encodings` · Module R1.06 · dive 1 · Source:
> `content/community/session-management.md.txt` (the *Hash-Based Sessions* and *String-Based Sessions with JSON*
> sections + *Memory Optimization*) · Grounding: `EchoCache.Table` — the `version <> value` frame
> (`echo/apps/echo_cache/lib/echo_cache/table.ex`).

A Hash for field-level reads and writes. A string for one opaque blob. JSON when the blob has structure. The trade-off
is field access against a single round trip.

## The three shapes

The same session record — a user id, a sign-in time, a last-seen time — can sit under a key three ways.

A **Hash** holds named fields. `HSET session:abc123 user_id "1" last_access "…"` writes them; `HGETALL` reads them all;
`HGET session:abc123 last_access` reads one; `HSET session:abc123 last_access "…"` updates one field without touching
the rest.

A **String** holds the whole record as one value: `SET session:abc123 "<blob>" PX 1800000`, read with `GET`, written
whole. **JSON** is that string with nested structure inside it —
`SET session:abc123 '{"user_id":1,"cart":[…],"prefs":{…}}' PX 1800000` — read with `GET` and parsed, the natural fit for a
cart or a preferences map.

## A single-field update

The difference shows when one field changes — a `last_access` bump on every request, say.

A Hash updates that field in place: `HSET session:abc123 last_access "1706648500"` rewrites one field and leaves the
others alone. A String or JSON value must be read whole, edited, re-serialized, and written whole: `GET` → parse → edit
→ `SET`. With a frequently-touched field, the Hash saves the round trip and the re-serialize. With a session read and
written as one unit, the String's single value is simpler. *Memory Optimization* favours the lean record either way —
store minimal data, use short field names, fetch full user details from the source when needed.

## On EchoCache

EchoCache stores its values in the String shape, with one addition: it frames the bytes with a 14-byte branded
**version** prefix. `EchoCache.Table.put/3` writes `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms`
(`table.ex:290`), and a read splits the frame back apart — `<<version::binary-14, value::binary>>` (`table.ex:429`).
The framed prefix is what lets a later coherence message compare two writes newer-wins; a plain unframed `SET` is the
simpler choice when no cross-node coherence is needed. A session record is flat and few-field — a `SES` id, a user id,
an opaque token — the shape a Hash backs cleanly when the store is bare Valkey; the framed-String form is what EchoCache
itself holds. The functional-Elixir and OTP craft behind the cache is the [`/elixir`](/elixir) course; this dive is the
encoding the store holds.

## References

### Sources
- [Redis — HSET](https://redis.io/commands/hset) — set named fields of a Hash; the field-level write a Hash session uses.
- [Redis — HGETALL](https://redis.io/commands/hgetall) — read every field of a Hash in one command; the full-session read.
- [Valkey — SET](https://valkey.io/commands/set) — set a key to one value with `PX`; the framed-String encoding `EchoCache.Table.put` writes.
- [Redis — Documentation](https://redis.io/docs/) — the Hash and String types and when each fits a record.

### Related in this course
- [R1.06 · Session management](/redis-patterns/caching/session-management) — the module hub.
- [R1.06.2 · TTL expiry](/redis-patterns/caching/session-management/ttl-expiry) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under the Exchange Platform.
- [/echomq](/echomq) — the protocol the coherence lane rides.
