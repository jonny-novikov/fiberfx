# Branded Component System — companion TOC

> The architecture law and its identity contract, taught chapter by chapter and grounded in shipped source. Systems own their state and behaviour; only identities — the 14-character branded snowflake — and messages about them cross boundaries. This index maps the nine companion documents (B0–B8) and links each specific topic to its place in the markdown.

**How to read this.** Each chapter is one markdown file (`bcs.N.md`), served in the course at the route shown; the bullets under it link to the specific topic inside that file. The volatile half of the substrate is EchoMQ on Valkey, the durable half is the persistence floor, and the worked project is Codemojex — deployed on Fly in B8.

## B0 — Overview — [`bcs.0.md`](bcs.0.md) · `/bcs/overview`

> The law in three clauses, the 14-byte id, the evidence ethic, and the map.

- [B0.1 · The one relocation](bcs.0.md#b01--the-one-relocation)
- [B0.2 · Identity as a contract](bcs.0.md#b02--identity-as-a-contract)
- [B0.3 · The stack and the floor](bcs.0.md#b03--the-stack-and-the-floor)

## B1 — Ideas Behind — [`bcs.1.md`](bcs.1.md) · `/bcs/ideas`

> The conceptual floor: the smallest faithful system, the identity contract read as architecture, ECS to BCS.

- [B1.1 · The system substrate](bcs.1.md#b11--the-system-substrate)
- [B1.2 · The identity contract](bcs.1.md#b12--the-identity-contract)
- [B1.3 · From ECS to BCS](bcs.1.md#b13--from-ecs-to-bcs)

## B2 — The Elixir BCS Core — [`bcs.2.md`](bcs.2.md) · `/bcs/elixir-core`

> The law landed on OTP: one application per system, property stores on ETS, the CHAMP forest, archetypes, relations, the gate.

- [B2.1 · A System Is an OTP Application](bcs.2.md#b21--a-system-is-an-otp-application)
- [B2.2 · Property Stores on ETS](bcs.2.md#b22--property-stores-on-ets)
- [B2.3 · The CHAMP Property Database](bcs.2.md#b23--the-champ-property-database)
- [B2.4 · Archetypes and Composition](bcs.2.md#b24--archetypes-and-composition)
- [B2.5 · Relations Are Systems](bcs.2.md#b25--relations-are-systems)
- [B2.6 · Gates and Acceleration at the Boundary](bcs.2.md#b26--gates-and-acceleration-at-the-boundary)

## B3 — The Bus — [`bcs.3.md`](bcs.3.md) · `/bcs/bus`

> EchoMQ, Valkey-native: the keyspace, jobs and lanes, the stream tier.

- [B3.1 · The keyspace](bcs.3.md#b31--the-keyspace)
- [B3.2 · Jobs and lanes](bcs.3.md#b32--jobs-and-lanes)
- [B3.3 · The Stream Tier](bcs.3.md#b33--the-stream-tier)

## B4 — EchoStore — [`bcs.4.md`](bcs.4.md) · `/bcs/store`

> The near-cache: the declared directory, one fill per herd, coherence by mint time.

- [B4.1 · The declared near-cache](bcs.4.md#b41--the-declared-near-cache)
- [B4.2 · One fill per herd](bcs.4.md#b42--one-fill-per-herd)
- [B4.3 · Coherence](bcs.4.md#b43--coherence)

## B5 — The Persistence Floor — [`bcs.5.md`](bcs.5.md) · `/bcs/persistence`

> Durable state beneath the bus: the single-writer engine, the lazy reader, the portable remote.

- [B5.1 · The single-writer engine](bcs.5.md#b51--the-single-writer-engine)
- [B5.2 · The lazy reader](bcs.5.md#b52--the-lazy-reader)
- [B5.3 · The portable remote](bcs.5.md#b53--the-portable-remote)

## B6 — Putting It All Together — [`bcs.6.md`](bcs.6.md) · `/bcs/together`

> The four libraries as one umbrella, a write all the way down, a read all the way up.

- [B6.1 · One umbrella, four systems](bcs.6.md#b61--one-umbrella-four-systems)
- [B6.2 · One write, all the way down](bcs.6.md#b62--one-write-all-the-way-down)
- [B6.3 · One read, all the way up](bcs.6.md#b63--one-read-all-the-way-up)

## B7 — Codemojex — [`bcs.7.md`](bcs.7.md) · `/bcs/codemojex`

> The worked project: branded systems, rooms and modes, fair-lane guesses, scoring and settlement, the economy, the live surface.

- [B7.1 · Branded systems](bcs.7.md#b71--branded-systems)
- [B7.2 · Rooms and modes](bcs.7.md#b72--rooms-and-modes)
- [B7.3 · Guesses on fair lanes](bcs.7.md#b73--guesses-on-fair-lanes)
- [B7.4 · Scoring, tiers, and settlement](bcs.7.md#b74--scoring-tiers-and-settlement)
- [B7.5 · The economy and the bank](bcs.7.md#b75--the-economy-and-the-bank)
- [B7.6 · The live surface on Phoenix](bcs.7.md#b76--the-live-surface-on-phoenix)

## B8 — Production on Fly — [`bcs.8.md`](bcs.8.md) · `/bcs/fly`

> From a compiled umbrella to a running service: the release image, Valkey on a Fly machine, EchoMQ setup and monitoring, the fly.toml and the local stack.

- [B8.1 · The release and the image](bcs.8.md#b81--the-release-and-the-image)
- [B8.2 · Valkey on a Fly machine](bcs.8.md#b82--valkey-on-a-fly-machine)
- [B8.3 · EchoMQ setup and monitoring](bcs.8.md#b83--echomq-setup-and-monitoring)
- [B8.4 · The fly.toml and the local stack](bcs.8.md#b84--the-flytoml-and-the-local-stack)

## The doors

- **`/echomq`** — the bus protocol in depth: the `emq:{q}:` keyspace, the Lua inventory, the conformance suite on Valkey. B3 is the narrative of the same system.
- **`/redis-patterns`** — the substrate patterns applied: sorted sets, atomic Lua moves, locks, streams.
- **`/echo-persistence`** — the durable floor in full: the durability spectrum, the page engines, the remote and the fence. B5 is the narrative of the same substrate.
- **`/elixir`** — the Functional Programming in Elixir course and the umbrella where `echo_data` and the store engines live.

## Tally

Nine chapters, **B0–B8, all built** — overview, ideas, the Elixir core (six modules), the bus, the store, the persistence floor, putting it together, Codemojex (six modules), and production on Fly (four dives). B2 and B7 are three-level (a landing, six modules, three dives each); the rest are a landing with three or four dives. Identity canon: the branded snowflake, a 3-character uppercase namespace + 11 Base62 characters carrying `ts(41) | node(10) | seq(12)`, epoch `1704067200000`.

---

> The TOC maps; the [progress ledger](bcs.progress.md) tracks; the [preface](bcs.preface.md) frames. Branded id format: `BCS` + Base62(snowflake), e.g. `BCS0NtBpC9oGGW`.
