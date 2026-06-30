# Echo · Vision and Purpose
<show-structure depth="2"/>

Echo exists to make one class of system tractable on the BEAM: applications that must be
real-time, must move real money, and must stay correct under concurrency, while running on
infrastructure a small team can hold in its head. The umbrella does not chase generality.
It chooses a substrate — Valkey for the live tier, Postgres for the system of record,
Tigris for cold replication — and it puts a single identity contract under every record
that crosses any of them.

## The problem it answers

A real-money game, a trading surface, or any contested multiplayer system runs into the
same wall: the moment two players act at once, the questions become who acted first,
which write wins, whether a balance can go negative, and whether one busy actor can starve
the rest. The usual answers reach for a foreign queue, a foreign cache, a foreign
replication engine, and a scattering of ad-hoc ids. Each addition is another protocol,
another failure mode, and another place where identity is reinvented.

Echo answers the wall differently. It keeps the moving parts on the BEAM, names one
transport, and derives ordering and fairness from the identity itself rather than from a
hash or an external clock. The result is a stack where the same branded id that names a
row in Postgres also names a lane on the bus, a key in the cache, and a segment in cold
storage.

## The principles

These hold across every application in the umbrella. They are the reason the parts compose
rather than merely coexist.

### Branded identity, owned by one module

Every entity is a branded snowflake: a three-letter namespace followed by the base62 of a
time-ordered 63-bit id, fourteen bytes, fixed. `EchoData.BrandedId` owns the codec and the
`hash32/1` used for routing; nothing else parses or re-derives. The id is time-ordered by
construction, so it sorts chronologically, dedupes by value, and carries its own age — no
companion timestamp column, no separate ordering key.

### Native or pure, with proved parity

The hot codec has a Rust and C core, but it is optional. When the NIF is absent the pure
Elixir path serves identical results, and `EchoData.BrandedId.self_check!/0` asserts the
equivalence at boot. Performance is a deployment choice, never a correctness one.

### Declared, not discovered

A cache in Echo announces its full specification at start and registers in a directory; a
cache absent from the directory does not exist. The operator can enumerate every cache in
a node. State is never an emergent property of whatever code happened to run — it is a
roster you can read.

### Fairness is constructed, not hashed

The bus serves identities by rotating a ring of the lanes that can be served right now,
advancing one step before each claim. Fairness between players is a property of the
rotation, not of a hash function, so no single masher can crowd out the field. Starvation
is refused by construction.

### Park, don't poll

A consumer that has nothing to do blocks on a wake key and costs the wire nothing until
readiness arrives. The same beat that wakes it also drives the periodic work — reaping
expired leases, promoting due schedules — so idleness is cheap and liveness is built in.

### One named wire

The transport is a first-class layer with a name. Every record that prices a call, sweeps
a queue, or parks a consumer refers to the same wire, so there is one place to reason about
framing, connection ownership, and the script fence.

### Self-checks at the boot, not the first order

Money scaling and identity codecs verify themselves when the node starts. A mis-scaled
currency constant fails the boot rather than the first booked order, on the same pattern
as the id self-check.

### A single scoring authority

Where a result must be trusted — a score, a settlement — one consumer computes it and the
host never does. The read surface withholds secrets and other players' moves by
construction, so integrity and privacy are structural rather than enforced after the fact.

## What Echo is for

Echo is built to carry a contested, money-bearing, real-time product end to end on a small
footprint. `codemojex` is the worked example: a competition where entities are branded
components in Postgres, every guess is a job on the guesser's own lane, scoring is a single
authority, three currencies move atomically through a wallet with a ledger, and prize pools
settle through a second queue. The same substrate is meant to carry adjacent products — a
trading surface, a tournament, any system with the same shape — without swapping the
foundation underneath.
