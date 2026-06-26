# The door to persistence — the Bus, module 05, dive 03

> Route: `/echomq/bus/retention-and-archive/the-door-to-persistence`. The durability dial in depth; the door
> to `/echo-persistence` + `/bcs/persistence`. Surface: `EchoStore.StreamArchive` + `EchoStore.Graft`. Real
> `echo/apps/echo_store` code; no Lua.

## The frame

The archive is one rung of a larger structure: the **persistence floor**, the durable substrate beneath the
volatile tiers. Above it sit the fast, droppable tiers — the in-heap window, the Valkey bus and warm L2.
Beneath it sits durable, replicated storage — the native `EchoStore.Graft` engine on CubDB, on to Tigris
object storage. Durability is not a switch; it is a **dial** a system turns, per surface, for the guarantee
that surface needs. The Bus's stream archive is one position on that dial; this dive opens the door to the
whole of it.

## The durability dial

Three positions, in order of how much each costs and how much it keeps:

1. **Hold nothing.** The data is derived and droppable — recompute it. The cheapest position; no durable
   write at all. (The ETS head cache that fronts a read.)
2. **A bounded window + a checkpoint per K.** Keep a bounded slice in heap and checkpoint it to disk every K
   records. The middle position; bounded memory, bounded loss on a crash, cheap steady state. (The stream's
   live tail bounded by retention, folded to the floor per beat.)
3. **Commit-per-record + replicate off-box.** Commit every record durably and replicate it off the machine.
   The most durable position; every record survives the box. (The Graft engine committing pages, the streamer
   shipping them to Tigris.)

The stream tier sits across positions 2 and 3: the live log holds a bounded window (retention), and the
archive commits each trimmed record to the floor and on to the remote. The hot enqueue path touches only the
small, mostly-idle outbox beside the bus — never a database on the path of every dequeue or ack. You turn the
dial up where you need durability and pay for it; you turn it down where the data is cheap to recompute and
keep the hot path fast.

## Deep history without resident memory

The merge-read is what makes the dial pay off: the deep feed survives **without resident memory of it**.
`merge_read/5` serves *archived ∪ live* as one mint-ordered stream — the archive read from the engine's
reserved page range below the watermark `W`, the live tail read from the stream above it. A reader queries a
stream's whole past beside its present, and the past costs no live memory: it is on the floor, page-ordered
by the branded id, fetched only when a read reaches for it. A stream is bounded in RAM and deep in history at
the same time — the two used to be a trade; here they are not.

In the words of the manuscript: *"the stream archive folds trimmed `EchoMQ.Stream` segments into the same
floor — deep history without resident memory,"* and *"what a system trims is kept, not lost."* The figure home
is `bcs.5.md` §B5.3, the portable remote.

## The comparison — Oban

The contrast that names the trade is **Oban**. Oban keeps jobs in the **same** Postgres as the application
data, so a job and a row commit in **one transaction** — you cannot enqueue work and forget to do it, because
the enqueue and the state change are atomic together. That coupling is real and valuable. Echo **gives it up**:
it separates the bus from the store, so the enqueue and the data write are not one transaction. What it buys
for that is an **in-memory hot path** (the enqueue touches the bus, not a database) and the **dial** (each
surface picks its own durability). State the trade beside the win — Echo does not have Oban's
one-transaction coupling; it has a fast path and a per-surface dial instead. Neither is free.

## The door

The whole floor — the single-writer Graft engine, the lazy partial reader at a snapshot, the portable Tigris
remote, the commit-LSN cursor a replica reads from, and the stream archive that folds trimmed segments into
the same engine — is taught in full at [Echo Persistence](/echo-persistence). The manuscript narrates the same
substrate at [The Branded Component System · the persistence floor](/bcs/persistence). The Bus's archive is
one rung of that floor; walk through this door for the rest of it.

## Pattern & implementation

- **The pattern (Redis Patterns Applied).** A durable log archives its history off the hot store and serves
  deep reads from it, so the live store stays small. [Streams & Events](/redis-patterns/streams-events) teaches
  the durable, replayable log; the durability dial is the floor beneath it.
- **The implementation (echo_store).** `EchoStore.StreamArchive` folds trimmed `EVT` segments into the native
  `EchoStore.Graft` engine (CubDB → Tigris), and the merge-read serves archived ∪ live as one mint-ordered
  stream — deep history without resident memory, the durability dial turned to keep-and-replicate.

## Recap

The archive is one rung of the persistence floor, and durability is a dial — hold nothing, a bounded window +
a checkpoint, or commit-per-record + replicate off-box. The stream tier sits across the last two: a bounded
live log and an archive on the durable floor, with the merge-read serving deep history without resident
memory. The comparison is Oban — Echo gives up the one-transaction coupling for an in-memory hot path and the
dial. The whole floor is one door away: Echo Persistence.

## References

### Sources
- [orbitinghail — Graft](https://github.com/orbitinghail/graft) — the lazy, partial, strongly-consistent page-replication engine `EchoStore.Graft` builds natively on the BEAM.
- [Tigris — conditional object operations](https://www.tigrisdata.com/docs/objects/conditionals/) — the create-only commit fence that makes object storage a transactional remote at the dial's top position.
- [Sorin et al. — Oban](https://hexdocs.pm/oban/Oban.html) — the same-Postgres job coupling Echo gives up for an in-memory hot path and the durability dial.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — entities made durable and addressed by identity across a boundary, the floor's frame.

### Related in this course
- [Retention & the archive](/echomq/bus/retention-and-archive) — the module this dive belongs to.
- [Nothing is lost](/echomq/bus/retention-and-archive/nothing-is-lost) — the fold this dive opens the floor behind.
- [Retention is a policy](/echomq/bus/retention-and-archive/retention-is-a-policy) — the trim the fold runs before.
- [The Bus](/echomq/bus) — the pillar landing.
- [Echo Persistence](/echo-persistence) — the durable floor in full.
- [The Branded Component System · the persistence floor](/bcs/persistence) — the manuscript chapter this floor realizes.
