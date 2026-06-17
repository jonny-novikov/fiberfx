# BCS · Research 2 · The Modern ECS Family in Depth

<show-structure depth="2"/>

## What the modern family inherited

The modern Entity Component System family takes Adam Martin's cut — entity as identifier, component as data, system as logic [10] — and engineers it for the cache. The defining decisions are about storage layout: how component data for many entities is arranged in memory so that a system iterating one component type touches contiguous bytes. Sander Mertens' ECS FAQ, maintained alongside the flecs engine, gives the standard taxonomy used throughout this chapter: archetype storage, sparse-set storage, bitset storage, and reactive storage, each with different tradeoffs on iteration speed versus the cost of adding and removing components [12]. This chapter takes each family in turn, then argues which one sits closest to BCS.

## Archetype storage

In an archetype ECS, all entities that have exactly the same set of components are stored together in a contiguous table — components are columns, entities are rows. Mertens' storage walk-through describes an archetype as a database table in which each entity occupies a row and each component a column, and an entity lives in exactly one archetype at a time [14]. When a component is added or removed, the entity undergoes a structural change: it is moved out of its current table and into the table for the new component set, and engines cache the edges between archetypes so repeated moves are cheap [13]. Queries iterate the list of archetypes that match the requested component set, and because tables stabilise quickly, the FAQ notes that "query evaluation overhead is reduced to zero on average" [12].

Unity's DOTS Entities is the most documented production example. Unity's own description groups entities with the same component set into an archetype and stores them in chunks of 16 KiB, where the number of entities per chunk depends on the number and size of the archetype's components; each chunk holds tightly packed parallel arrays, one per component type plus one for entity IDs [17] [18]. Unity is explicit about the cost: adding or removing a component switches an entity's archetype, which moves it between chunks and back-swaps the last entity to fill the hole, and the manual warns that frequent moves are resource-intensive and reduce application performance [18]. The same engineering post notes a payoff on the other side — an archetype-laid-out scene loads as close to raw bytes from disk, used in place [17].

flecs, Bevy, and Unreal Mass round out the archetype family. flecs adds entity relationships — pairs of the form (Relationship, Target) added to an entity — and Mertens has documented how relationships are implemented on top of the archetype graph; the FAQ also catalogues the family members, listing Unity DOTS, Unreal Mass, Bevy, Legion, Hecs, and Ark as archetype implementations [12] [15].

| Property | Archetype storage |
|---|---|
| Iteration | very fast, contiguous, vectorizable |
| Add/remove component | slow, moves entity between tables |
| Random access by entity | indirection through entity index |
| Fragmentation | grows with number of distinct component combinations |

flecs documents the fragmentation cost candidly: relationships can multiply the distinct component combinations in a world, spreading entities over more tables, and the engine offers non-fragmenting relationship variants to mitigate it [15].

## Sparse-set storage

EnTT, by Michele Caini (skypjack), is the reference sparse-set implementation. Each component type gets its own sparse set: a packed dense array of component values plus a sparse array indexed by entity ID that points into the dense array. Caini's "ECS back and forth" series explains the appeal — lookup, insertion, and deletion are O(1), and iteration over a single component is O(N) over a tightly packed array [19]. Adding and removing components is far cheaper than an archetype move because only one set changes, which is why the FAQ recommends sparse sets for components that churn, such as those backing a messaging system [12].

The cost is iteration across multiple component types: a query picks the smallest set and tests each entity for membership in the others, with a level of indirection through the sparse array. Caini's answer is groups, described in part 6 of his series — by arranging the packed arrays of several sets so that entities belonging to all of them are ordered identically at the front, EnTT achieves what he calls perfect struct-of-arrays, iterating from zero to N with "no jumps, no branches" [20]. Groups trade some flexibility for speed: a type can belong to only one owning group. Caini also documents pointer stability as a deliberate per-type option (part 12), achieved by leaving tombstone holes instead of swap-and-pop so that references survive removal — a feature archetype engines generally cannot offer because moves invalidate addresses [21].

## Bitset and reactive variants

The FAQ describes two further families. A bitset ECS (EntityX, Specs in Rust) stores each component in an array indexed by entity ID and keeps a bitset marking which entities have it; iteration walks the bitset and fetches components by index [12]. Caini's survey notes the weakness of the naive form — memory is wasted and the holes defeat the point of keeping instances tightly packed [19]. A reactive ECS collects matching entities by listening for the signals (component added, removed, changed) that could change a query's result set, so the matching set is maintained incrementally rather than recomputed; EnTT ships a reactive storage mixin that tracks entities matching given conditions and saves them aside [12].

## ECS as a database

A recurring theme in Mertens' writing is that an ECS is, structurally, a database. His essay "Why it is time to start thinking of games as databases" argues that game state is locked inside data structures meaningful only with the source code, and that a queryable model would let agents and tools read the world directly [16]. The archetype-as-table framing makes the analogy concrete: components are columns, entities are rows, queries are joins over component sets, and relationships are foreign keys [14] [15]. This framing is the strongest bridge to BCS, whose manuscript chapter 2.5 (Relations Are Systems) cites Codd 1970 and treats relations themselves as systems rather than as columns bolted onto an object. The connection runs both ways: the ECS world rediscovered the relational model that the trading domain has used all along.

## Generational-index handles

Inside an ECS world, the entity identifier is rarely a bare integer. It is a generational index: a slot index plus a generation counter, so that when a slot is recycled the old handle's stale generation no longer resolves. flecs documents this directly — its 64-bit entity ID encodes both an ID and a generation counter, and deleting an entity increments the counter so the old ID stops resolving, which prevents use-after-delete [15].

Andre Weissflog's 2018 essay "Handles are the better pointers" is the clearest statement of why this pattern exists outside ECS too. Weissflog's prescription: move memory ownership into centralized systems, group items of one type into arrays the system owns privately, and hand the outside world only an index-handle rather than a pointer, converting a handle to a pointer only at the moment of use and never storing the pointer. The handle spends spare bits on safety checks [22]. This is the manuscript's identity discipline in miniature, and chapter 1.4 cites Weissflog directly.

The limit of the generational handle is the boundary of the process. A handle is an index into a specific array owned by a specific system in a specific address space. It does not survive a socket, a save file, or a foreign store, because the array it indexes does not exist on the other side. This limit is the hinge of the whole appendix. BCS is what happens when the handle must survive those crossings: the branded snowflake is the distributed generational index — typed by a namespace prefix, ordered by mint time, placed by a hash function, and identical across runtimes — so the name resolves anywhere rather than only inside the one array that minted it. [`bcs.research.3.md`](bcs.research.3.md) develops this turn.

## Storage-layout tradeoffs and reported benchmarks

The archetype-versus-sparse-set debate is fundamentally array-of-structs versus struct-of-arrays plus a question of when you pay. Archetypes pay at structural change to make iteration cheap; sparse sets pay at multi-component iteration to make structural change cheap. Caini's own survey of the families concludes that both storage models can carry a full ECS, and that the right choice depends on whether the workload is dominated by iteration or by component churn [19].

Published micro-benchmarks exist and must be read with care. The abeimler/ecs_benchmark repository on GitHub publishes comparative figures across EnTT, flecs, Ginseng, EntityX, gaia-ecs and others. In its "Update 8 entities with 7 Systems" table, EnTT is reported at 355ns, its grouped variant at 199ns, and its stable variant at 253ns, against flecs at 2332ns for the same micro-test; the "Update 64 entities with 7 Systems" row reports EnTT (stable) at 343ns against flecs at 2402ns. These numbers are reported by the repository maintainer on the maintainer's hardware for deliberately minimal tests. The maintainer's own caution is the right frame: real systems have hundreds of components and systems, so one should "always benchmark your specific cases" [24]. flecs' separate benchmark repository (reporting figures for flecs release v4.1.0) repeats the warning that its tests measure as little as possible on purpose and do not reflect real-life scenarios [25]. None of these figures is a BCS measurement; they are cited only to show the shape of the tradeoff as their authors published it.

## Which variant is closest to BCS

BCS is the property-database and relational flavor of the family, not the storage-class flavor. The argument has four parts.

First, lineage. BCS descends from the Thief property database ([`bcs.research.1.md`](bcs.research.1.md)) and cites Codd 1970 (manuscript 2.5), so its native framing is rows keyed by identity, which is the ECS-as-database view, not the archetype-as-memory-layout view.

Second, storage. The manuscript's property stores are GenServer-owned private ETS tables, often ordered_set, keyed by branded IDs. An ordered_set ETS table keyed by entity ID is, functionally, a component table: one column of data indexed by identity, owned privately by one system. This is closer to a per-component sparse set or a relational table than to a packed archetype chunk, because the store is keyed and owned rather than laid out for vectorized iteration.

Third, systems and iteration. In BCS the systems that iterate are the queues and lanes of EchoMQ — work moves through lanes and consumers fold over it. Iteration is over a work stream, not over a contiguous component array, which again places BCS on the relational/messaging side rather than the cache-layout side.

Fourth, and most important, the archetype distinction. In Unity and flecs an archetype is a storage class: a physical table that an entity is physically moved into when its component set changes. In BCS (manuscript 2.4) an archetype is a data fold: composition is computed by folding archetype definitions over a store, not by relocating bytes between tables. The archetype-as-data-fold versus archetype-as-storage-class distinction is the cleanest line between BCS and the mainstream engines, and it follows directly from BCS keeping its identity contracted and external rather than as an in-memory slot index.

| Family | Iteration | Structural change | Identity | Closest to BCS? |
|---|---|---|---|---|
| Archetype (Unity, flecs, Bevy, Unreal Mass) | fastest | expensive (table move) | generational index, process-local | no — storage-class archetypes |
| Sparse-set (EnTT) | fast with groups | cheap | generational index, process-local | partially — keyed per-component stores |
| Bitset / reactive | moderate | cheap | index + bitset / signals | no |
| Relational / database framing (ECS-as-DB) | query-driven | schema-driven | key | yes — rows keyed by identity |
| BCS | over work streams | data fold | branded snowflake, cross-runtime | — |

Bevy deserves a note as the hybrid that proves the rule: its components are stored either in archetype tables or in sparse sets, chosen per component type, with table storage the default for iteration speed and sparse-set storage for components that are added and removed frequently. Bevy's documentation describes exactly this dual strategy, and its archetypes carry generational indices like the rest of the family [23]. Bevy shows that the two storage strategies are points on a spectrum, not rival religions — and BCS picks the keyed, owned end of that spectrum and then lifts the key out of the process entirely.

### References

10. Itterheim — Overview of ECS variations with pseudo-code (taxonomy referenced for the Martin model): [gist.github.com](https://gist.github.com/LearnCocos2D/77f0ced228292676689f)
12. Mertens — Entity Component System FAQ (taxonomy of archetype, sparse-set, bitset, reactive storage): [flecs.dev](http://www.flecs.dev/ecs-faq/)
13. Mertens — Building an ECS #2: Archetypes and Vectorization (archetype tables, vectorized iteration): [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9)
14. Mertens — Building an ECS #3: Storage in Pictures (archetype as a database table): [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-storage-in-pictures-642b8bfd6e04)
15. Mertens — flecs Relationships documentation (relationship pairs, generation counters, fragmentation): [github.com](https://github.com/SanderMertens/flecs/blob/master/docs/Relationships.md)
16. Mertens — Why it is time to start thinking of games as databases (ECS-as-database framing): [ajmmertens.medium.com](https://ajmmertens.medium.com/why-it-is-time-to-start-thinking-of-games-as-databases-e7971da33ac3)
17. Unity — On DOTS: Entity Component System (archetypes, 16 KiB chunks, structural change): [blog.unity.com](https://blog.unity.com/technology/on-dots-entity-component-system)
18. Unity — Archetypes concepts, Entities manual (chunk layout, entity moves between archetypes): [docs.unity3d.com](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/concepts-archetypes.html)
19. Caini — ECS back and forth, Part 9: Sparse sets and EnTT (sparse-set design, O(1) operations): [skypjack.github.io](https://skypjack.github.io/2020-08-02-ecs-baf-part-9/)
20. Caini — ECS back and forth, Part 6 (groups and perfect SoA): [skypjack.github.io](https://skypjack.github.io/2019-11-19-ecs-baf-part-6/)
21. Caini — ECS back and forth, Part 12 (pointer stability via tombstones): [skypjack.github.io](https://skypjack.github.io/2021-08-29-ecs-baf-part-12/)
22. Weissflog — Handles are the better pointers (index-handles, system-owned arrays): [floooh.github.io](https://floooh.github.io/2018/06/17/handles-vs-pointers.html)
23. Bevy — Components and Storage (table vs sparse-set hybrid storage): [deepwiki.com](https://deepwiki.com/bevyengine/bevy/2.2-components-and-storage)
24. abeimler — ecs_benchmark (reported comparative ECS micro-benchmarks): [github.com](https://github.com/abeimler/ecs_benchmark)
25. Mertens — flecs benchmarks repository (caveats on micro-benchmark interpretation): [github.com](https://github.com/SanderMertens/ecs_benchmark)
