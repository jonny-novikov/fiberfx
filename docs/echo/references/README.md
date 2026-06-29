# Echo · The Umbrella at a Glance
<show-structure depth="2"/>

Echo is a BEAM-native umbrella for building real-time, real-money applications on a
Valkey substrate, with a branded identity contract at the centre of everything. It is the
home of the Branded Component System (BCS): a small set of libraries that give every
entity a time-ordered branded id, run a fair message bus over Valkey, cache and replicate
that data without a foreign coordination engine, and compose into a shipping application.

This folder is the reference set for the `echo/` umbrella. It describes what Echo is for,
how it is laid out, and what each application contributes.

## The documents

- `vision-and-purpose.md` — why Echo exists, the principles that hold across every app,
  and the class of system it is built to carry.
- `architecture.md` — the umbrella shape, the layering graph, the life of a request, the
  boot order, and the deployment surfaces.
- `components.md` — a reference page for each of the seven applications: its purpose, its
  key modules, and how it fits the whole.

## The seven applications

Echo is one umbrella of seven applications. Three carry the substrate, one is the
reference product, and the rest sit between them:

- `echo_data` — the BCS foundation: the branded-id codec and hash, the lock-free
  Snowflake, the persistent CHAMP structures, the Graft segment types, and the optional
  Rust and C native core with a pure-Elixir fallback of identical results.
- `echo_wire` — the wire layer: RESP3 framing, the single-owner Valkey socket connector,
  the Lua script registry behind a version fence, and the command builder. It stands as
  its own library.
- `echo_mq` — the message bus over Valkey: fair lanes that no identity can starve, a
  consumer that parks rather than polls, batches, control flows, streams, and the
  conformance and telemetry that gate the contract.
- `echo_store` — the storage tiers: a declared L1-over-L2 near-cache with Snowflake
  coherence, and Graft, a native-BEAM lazy and partial page-based replication tier that
  ships segments to Tigris.
- `echo_bot` — a compact Telegram engine: the updater, the platform adapter, and the
  handler chain, vendored so the product needs no external bot framework.
- `echo_graft` — the reserved name for the Graft tier; the live engine lives in
  `echo_data` and `echo_store`.
- `codemojex` — the reference application: a six-emoji code-breaking competition whose
  entities are branded components in Postgres, whose guesses are jobs on per-player lanes,
  and whose currencies settle atomically through a wallet and a second queue.

## The layering, in one line

`echo_data` and `echo_wire` are the floor; `echo_mq` builds the bus on the wire;
`echo_store` builds the cache and the durable tier on the bus and the data primitives;
`codemojex` composes all of them behind a Phoenix surface, with `echo_bot` as its gateway
to Telegram.
