# Immutability & branded ids — module hub

> Route: `/echomq/protocol/immutability-and-branded-ids` · surface: **module hub** · pillar: **The Protocol**.
> Grounding: all **real code** in `echo/apps/echo_mq` + `echo/apps/echo_wire`. **No `[RECONCILE]` markers** — nothing
> on this page is ahead of the as-built code.

## The fact

The keyspace says *where* a job lives, the record says *what* it holds, the Lua scripts say *how* it moves. This
module teaches the discipline that keeps all three honest over time: **what holds the wire together.** Three things
hold it:

1. **The immutable line** — the keys and the field names are fixed. A renamed field or key prefix in one speaker makes
   the row invisible to every other speaker. So the layer below the line does not change underneath a reader.
2. **The branded-id gate** — a job's id is a 14-byte branded Snowflake (a 3-character uppercase namespace + 11 Base62)
   under the `JOB` namespace — typed, ordered, placed (`hash32`) and conformant — and the `@enqueue` script refuses any
   id that is not `JOB`-namespaced (`string.sub(ARGV[1], 1, 3) ~= 'JOB'` → `EMQKIND`). Identity is checked at the wire,
   in Lua, before a row is written.
3. **The version fence** — a single reserved key, `{emq}:version`, carries the wire's identity string. The connector
   reads it before the first command and refuses to run against a store whose value disagrees.

The first two are properties of the data and the scripts; the third is a property of the connection. Together they are
the guarantee a depth course needs to state plainly: the substrate below the line is fixed, identity is gated, and a
connection that does not match the wire is refused before it can corrupt it.

## The worked surfaces (real, verified)

- `EchoMQ.Keyspace.queue_key/2` → `emq:{q}:<type>`; `job_key/2` → `emq:{q}:job:<branded>` (gated on
  `EchoData.BrandedId.valid?/1`); `version_key/0` → `{emq}:version`; `reserve/1` → `{emq}:<suffix>`.
- `EchoMQ.Jobs.enqueue/4` → the `@enqueue` named handle; its Lua body opens with the `EMQKIND` gate
  (`string.sub(ARGV[1], 1, 3) ~= 'JOB'`). The Elixir maps `{:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}`.
- `EchoData.BrandedId`: `3 × [A-Z]` namespace ++ `base62(snowflake)` padded to 11 = **14 bytes**; the Snowflake layout
  `ts(41) << 22 | node(10) << 12 | seq(12)`, epoch `1704067200000`.
- `EchoMQ.Connector` `@wire_version "echomq:2.0.0"` (a quoted code constant, never a course label); `fence/2` reads
  `GET {emq}:version` at connect — match → run, absent → claim with `SET … NX` then confirm, mismatch →
  `{:error, {:version_fence, got}}`, fatal on reconnect.

## The framing interactive (hub)

**The three guards** — pick one of the immutable line / the branded-id gate / the version fence and read what it
holds and the real surface that carries it, over a fixed dataset. Pure lookup, live `.geo-readout`, an `<svg>` of the
three guards over one wire.

## The three dives

1. **the-immutable-line** — why L1 and L2 are fixed; change one thing below the line and read who can still find the
   row.
2. **the-branded-id-gate** — the 14-byte branded id and the `EMQKIND` Lua gate that admits only `JOB`-namespaced ids.
3. **the-version-fence** — the `{emq}:version` reserved key and the connector's claim-or-verify fence at connect.

## References

### Sources
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.
- Valkey — SET (`https://valkey.io/commands/set/`) — the `NX` claim the version fence uses.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the dispatch the gate rides on.
- llmstxt.org (`https://llmstxt.org/`) — the machine map convention.

### Related in this course
- `/echomq/protocol` — the chapter this module belongs to.
- `/echomq/protocol/the-lua-layer` — the script layer the gate lives in.
- `/echomq/overview/the-protocol-below-the-line` — the line, on a real key and script.
- `/redis-patterns/coordination` — branded-key/atomicity, the near side of the door.
