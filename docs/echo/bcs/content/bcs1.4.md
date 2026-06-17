# BCS · Chapter 1.4 — From ECS to BCS: what distribution changes

<show-structure depth="2"/>

Part I closes by paying the preface's oldest debt. The historical arc ended in 1998 with the entity reduced to a join key and the key itself nobody's job; the quarter-century since built the entity-component-system pattern into doctrine and the key into a refined artifact — the index-handle with a generation counter. This chapter is what happens when that artifact meets a save file, a socket, and a foreign store, with each death traced to a missing property of the identity contract. The argument is sympathetic by design: ECS discovered two of the three BCS clauses on its own, inside one process; distribution is where the undiscovered third presents its bill.

## Why

Engineers arrive at distributed systems fluent in ECS — it is the lingua franca of an entire industry — and the trading platform this series builds is the distributed case in full: positions, orders, and risk envelopes spread across processes, machines, and stores, with identities expected to outlive all three. A chapter that translates is worth more than a chapter that re-educates. The claim to be earned: BCS keeps everything ECS got right and completes the one thing it left local — so the migration is a promotion of the id, not a rejection of the pattern.

## What

**The handle, at its best.** The modern discipline is stated cleanly in Weissflog's 2018 treatment [2]: move memory management into centralized systems, "the systems being the sole owner of their memory allocations"; group same-typed items into arrays whose base pointers are system-private; and let only index-handles cross to the outside world, with the handle's spare bits carrying a generation pattern — a per-slot counter after the November update — so a stale handle is *usually* caught when the slot is reused. Read with Part I's eyes, that is clause one (systems own their state) and clause two (only identities cross) discovered independently, enforced by convention inside a single address space. Even the pattern's founding document records the pressure on clause two: West's 2007 component article [1] reports that when manager-mediated access cost five percent of CPU, "we allowed the components to store pointers to one another" — the traveling pointer, admitted under frame-rate duress, inside the very article that taught the industry components.

**The three deaths.** The handle's validity is scoped to one process's current memory layout, and each scope violation has a name. *The save file:* an index is an address into an array arrangement that no longer exists after restart, so persistence becomes a swizzling pass — every table rewritten from handles to something durable and back — and the generation pattern serializes into noise. *The socket:* entity 4117 on machine A names nothing on machine B, so replication mints a second identity scheme with bidirectional mapping tables at both ends — the dialect failure, self-inflicted before any foreign runtime is even involved. *The foreign store:* a handle cannot be a foreign key, so the database grows its own serials, `created_at` columns sprout beside them because insertion order is the only chronology left — the second clock — shard keys are invented per table — the routing table — and nothing anywhere checks that the integer arriving in the assets table was ever an asset — the silent join, at last, with no compiler in reach.

**The diagnosis, in contract terms.** A handle is placement and liveness wearing identity's clothes. The index *is* placement, leaked into the name — which is why the name dies whenever the layout does. The generation counter *is* a liveness check, and its own literature is candid that the check "isn't waterproof" [2] — it is collision *detection* over a reused slot, probabilistic by construction. The contract separates what the handle fused. Placement is derived, never embedded: hash32 computes the slot from the name (234878118 for the reference id, at 0.9586 nanoseconds in pure Go), so the name survives every layout it will ever be stored in. Liveness-by-detection becomes uniqueness-by-prevention: the minting law never reuses a name — the substrate paged two thousand mints in exact byte-sort order with no allocator and no free list — so the ABA problem the generation bits exist to catch cannot be expressed. And the kind rides in the value and the type, so the silent join dies at the gate (the measured row reads 200 / 400 / 400 / 404, wrong-kind refused before any handler) instead of surviving until an analyst notices. What remains in the name is exactly what a name should carry — kind and instant — at 65 bytes per key on the measured table, cheaper at rest than the handle's own decimal shadow.

## Who

The ECS-literate engineer onboarding to the platform, with the translation table as the Rosetta line: *entity* becomes an identity; *component* becomes a property in some system's table; *system* remains a system, now with a hard boundary; *world* becomes the supervision tree plus the bus; *archetype* becomes data composition (Chapter 2.4's subject); *query across components* becomes a message join by identity. In the trading vocabulary: the order is an `ORD` identity; its fills, its risk checks, and its book position are properties in three systems; the matching sweep is a system consuming messages about `ORD` names — and every one of those names is valid in the save file, on the socket, and in the store, because those are no longer different places to be valid.

## When

Keep classic ECS where it is the right tool: one process, a frame loop, identities that may die with the run — a renderer or an inner simulation core gains nothing from a wire-stable name per particle, and this series does not propose one. The litmus is a single question: *must this id outlive the process?* The first yes — the first save, the first socket, the first row — is the migration moment, and it arrives on day one for anything trading-shaped. Hybrids are legitimate under clause one: a system may keep handles internally as its private indexing business, provided its boundary speaks branded names and the handles never cross — which is not a compromise of the law but an application of it.

## Where

This chapter closes the arc the series preface opened: the law ([`bcs1.md`](bcs1.md)), the substrate that runs it ([`bcs1.1.md`](bcs1.1.md)), the contract read as architecture ([`bcs1.2.md`](bcs1.2.md)), the storage economics that priced it ([`bcs1.3.md`](bcs1.3.md)), and the appendix that timed it ([`bcs1.a1.md`](bcs1.a1.md)). Part II begins the reference implementation in earnest — the OTP application as the full-grown form of the skeleton.

## How — the migration, in Elixir and in Go

**Elixir.** The world is a supervision tree and the component array is the substrate's private ETS table, keyed by the name itself — at which point the allocator's whole apparatus disappears. There is no slot to allocate, no free list, no generation to bump: minting *is* allocation, and reuse is impossible by law rather than improbable by pattern.

```elixir
# handle era: {index, generation} into a system-private array, valid this run
# name era:   the key is the identity; reuse cannot be expressed
:ok = PropertyStore.put(:positions, EchoData.Snowflake.next_branded("PRT"), position)
```

**Go.** Weissflog's shape survives nearly verbatim — system-private storage, a sole owner, only identities crossing — with two edits from Chapter 1.1: the channel edge replaces the function boundary as the place the gate lives, and the branded string replaces the index-generation pair. Iteration keeps its locality through the owner's sorted key slice; the cross-component query becomes a message join by identity, and the cost is stated with its mitigation: names that must be read together can be co-placed by the same hash32 both runtimes share, and asks batch.

```go
// handle: uint32(idx) | gen<<20      -> valid in this process, this run
// name:   brandedid.MustEncode("ORD", snow) -> valid everywhere, indefinitely
```

## Decisions

**Generation counters are rejected, by subsumption.** Detection of reuse is replaced by prevention of reuse; the monotonic mint makes the ABA case unrepresentable, and a probabilistic guard for an impossible event is deleted weight.

**The index never rides in the name.** Placement is hash32's job, derived on demand; an identity that encodes its storage location dies with that location, which is the entire pathology this chapter buries.

**Internal handles are permitted strictly behind the boundary.** Clause one makes a system's private indexing nobody's business — the law forbids handles *crossing*, not handles existing.

**The ECS vocabulary is adopted with translation.** The series speaks both dialects deliberately; the table in Who is the convention of record, so that an entity-systems veteran reads Part II without a glossary.

## References

1. West, M. — Evolve Your Hierarchy: Refactoring Game Entities with Components. Cowboy Programming / Game Developer Magazine, 2007: [cowboyprogramming.com/2007/01/05/evolve-your-heirachy](https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/)
2. Weissflog, A. — Handles are the better pointers, 2018 (with the November 2018 per-slot generation-counter update): [floooh.github.io/2018/06/17/handles-vs-pointers.html](https://floooh.github.io/2018/06/17/handles-vs-pointers.html)
