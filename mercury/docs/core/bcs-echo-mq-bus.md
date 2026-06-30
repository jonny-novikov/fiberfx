# Mercury · BCS and the Elixir contract, the ground a @echo/mq bus stands on
<show-structure depth="2"/>

The branded-identity contract is wire-portable — a fourteen-byte string gated by format, not by a language enum — and the Elixir echo_mq stores that string as a stream entry's id field. This article reads the contract on both sides, the boundary gate that admits one namespace, the ValKey stream substrate, and the claims-only stream record that lets a proposed `@echo/mq` ride the same streams as a bus without re-encoding a single id.

## The contract, on both sides

`EchoData.BrandedId` is the codec the Elixir umbrella owns. An id is fourteen bytes: a three-letter uppercase namespace, then the width-11 base62 of a 63-bit Snowflake. The namespace is a parameter — `encode(ns, snow)`, `generate!(ns)` — and validity is a matter of format: the internal shape check is three uppercase letters, and parsing slices the first three bytes and base62-decodes the rest. The routing hash is the first half of MurmurHash3's fmix64 truncated to 32 bits, pinned to a contract vector. No namespace set lives in the core; the module's own documentation says consuming apps wrap this core to mint and decode their own three-letter-namespaced ids.

`@echo/core` mirrors this for TypeScript. `BrandedId<NS extends string>` is the same fourteen-character string carried as a nominal type; the format regex is the same shape; `namespaceOf` slices the first three characters; and the registry constructor `defineNamespaces` is where an application declares its set. The codec authority on the TypeScript side is `@echo/fx` (Rust compiled to wasm), held at parity with the Elixir hash — that routing hash is parity-pending against the contract vector.

The hinge of the whole arrangement is that both sides agree on bytes. A `GAM`-namespaced id minted in Elixir is the same fourteen characters a TypeScript reader sees. Neither side needs the other's struct; each needs only the string.

## The boundary gate, one namespace, error as value

`EchoData.Bcs.gate(id, ns)` is the boundary discipline. It admits an id of one namespace and refuses everything else, and it adds no second parser: classification beyond the namespace collapses to invalid, exactly as the codec's own parse reports it. It returns `{:ok, snow}` or `{:error, :namespace | :invalid}`.

`@echo/core`'s gate is the same shape, expressed as a result: `gate(value, ns)` returns `Eff<BrandedId<NS>, "namespace" | "invalid">`. Core has no wasm, so it returns the branded string rather than the decoded Snowflake; the decode is `@echo/fx`'s job. The discipline is identical — one namespace admitted, the rest refused as values, no second parser. A boundary on either runtime declares the namespace it accepts at the call site, rather than the core hardcoding a fixed set. That symmetry is what makes the two implementations one contract instead of two look-alikes.

## The stream substrate

ValKey Streams are the wire a bus rides. A stream is an append-only log; a producer appends with XADD and the server assigns each entry a time-ordered id of the form millisecond and sequence, strictly monotonic, so ordering is intrinsic to the data structure rather than something the application maintains. Consumers either tail a stream with XREAD or join a consumer group and read with XREADGROUP, where each entry is handed to exactly one consumer in the group, tracked in a per-consumer pending-entries list until it is acknowledged with XACK, and reassignable to a healthy consumer with XCLAIM or XAUTOCLAIM after an idle timeout. That is at-least-once delivery across a fleet of workers, and it is distinct from pub/sub, which is at-most-once transport with no history.

A stream is not partitioned inside core Redis: one stream is one key on one shard. On a cluster the key is sharded with a hash tag — the braces in a key route every key sharing the tag to the same slot, so a related set of streams stays co-located.

## The claims-only contract

This is where echo_mq's stream tier and the BCS contract meet, and it is the reason a polyglot bus is feasible at all. The writer mints an `EVT`-branded record id host-side, derives the explicit XADD id by field correspondence, and issues an append that stores the fourteen-byte branded string as the entry's `id` field; the branded id is the receipt the append returns. Two properties follow. The writer owns the mint, so there is nothing for a client to spoof. And a reader in any language gets the canonical id straight from the `id` field without re-encoding it — the claims-only contract, where the stored claim is already the portable id.

The keyspace grammar composes with the same identity canon. Per-queue keys take the form `emq:{q}:<type>`, hash-tagged so every key of one queue lands on one slot; the branded payload is the long part of a job key by design, and it is gated before it is used. Append order is mint order, so the stream preserves the order in which ids were minted.

## What @echo/mq builds

A `@echo/mq` package is the proposed TypeScript bus, and the contract above is the ground it stands on. The real echo_mq is built on two umbrella apps — echo_data for the identity core and echo_wire for the wire — so the TypeScript bus mirrors that split. It builds on `@echo/core` for the identity contract, which is in place, and on a proposed `@echo/wire` RESP connector that speaks the protocol the Elixir connector speaks. Reading and writing the same streams then needs no new id format and no re-encoding: the bus appends branded ids as the `id` field the Elixir writer uses, and reads them back through the gate at the keyspace boundary.

The shapes the bus carries over are echo_mq's own. Fair lanes rotate a claim one step before each serve, so fairness between identities is constructed rather than hashed. Consumers park on a wake key rather than poll, so an idle consumer costs the wire nothing and a release pushes a wake. Parent-child flows land atomically and release the parent only when the last child completes. This article writes these as the chapter the surface builds toward, not as code that ships today. The named horizon for the connector and the job runtime is in `docs/codemojex-admin-roadmap.md`.

## Boundaries

Compliance here is about identity and the wire, and the claims are scoped to that. A TypeScript reader and writer can share the same streams because they share the byte-exact id format and the claims-only record; that is verified for the format and the gate, and grounded in the real echo_mq stream tier. It does not claim `@echo/mq` or `@echo/wire` exist yet — both are proposed surfaces. It does not claim the TypeScript side reimplements echo_mq's atomic server-side scripts; the bus would ride the same streams and honor the same keyspace, while the transactional job machinery remains the Elixir umbrella's. And the hash parity is pending: `@echo/fx` asserts the contract vector but is not yet certified against the Elixir routing hash in the build.

## References

- ValKey and Redis Streams: XADD append, server-assigned time-ordered ids, append-only log: `https://redis.io/docs/latest/develop/data-types/streams/`
- Consumer groups: XREADGROUP and XACK at-least-once delivery, per-consumer pending entries, XCLAIM recovery, and the contrast with pub/sub: `https://redis.io/docs/latest/develop/use-cases/streaming/`
- A single stream is one key on one shard; shard a stream on a cluster with a hash tag: `https://stackharbor.com/en/knowledge-base/redis-streams-xadd-xread/`
