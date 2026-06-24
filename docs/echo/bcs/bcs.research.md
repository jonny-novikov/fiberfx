# BCS · Research · Composition Approaches

## Preface to the research appendix

The Branded Component System is a measured manuscript. Its chapters commit to local records: code that runs, tables that exist, contracts that hold. This appendix does something different. It is the literature review the measured chapters stand on. Where the manuscript says "we do it this way," the appendix says "here is the lineage of ways it has been done, who reported what, and where." Evidence here is reported and attributed to its sources, not measured locally. When a benchmark number appears, it is quoted as the originating author published it, with their hardware and their caveats intact. When a design claim appears, it is traced to the blog post, slide deck, paper, or repository where it was first stated.

This separation is deliberate. A reader who wants to argue with the manuscript's thesis should be able to check the manuscript's evidence against its primary sources without untangling what the BCS authors built from what the field already knew. The three research chapters are organised so that each pillar of the thesis — identity, data, logic, and where the boundaries between them sit — has a documented genealogy.

The thesis the appendix supports is stated once, plainly: encapsulation boundaries are drawn around systems, not objects, and the only thing an object keeps once its state and behavior have moved out is its name. The research that follows shows that nearly every composition approach in fifty years of practice converges on the same three-part split — identity, data, behavior — and that the approaches differ mainly in where they put the boundary and what they allow to cross it. BCS draws the boundary around the system and allows only the identity to cross.

## The three research chapters

**Research Chapter 1 — The history and evolution of composition approaches.** From Simula and Smalltalk objects through the inheritance crisis, the Gang of Four's composition principle, mixins and traits, prototype/delegation models, and into the game-object lineage (Bilas, West, Martin, the Itterheim taxonomy), closing with the actor-model and Helland's entities as a non-game lineage of composition by identity and messaging. Each approach is read for what it composes and where its boundary sits.

**Research Chapter 2 — The modern ECS family in depth.** Archetype storage (Unity DOTS, flecs, Bevy, Unreal Mass), sparse-set storage (EnTT), bitset and reactive variants, the relational/database framing of ECS, generational-index handles as the identity mechanism and their process-local limits, and storage-layout tradeoffs with reported benchmark numbers. The chapter argues which variant sits closest to BCS and why.

**Research Chapter 3 — Composition in distributed systems.** Why handles die at the boundary, Helland's entities and idempotence, the log as a unifying abstraction, event sourcing and the Decider pattern in depth, an advanced Decider sketch for a trading engine keyed by branded identities, the LMAX architecture as a data-driven single-threaded example, and a closing "Putting it all together" synthesis that reads as the thesis statement of the whole appendix.

## Index of composition approaches

- Class inheritance and the inheritance crisis — Chapter 1
- Object composition (Gang of Four) — Chapter 1
- Mixins and traits — Chapter 1
- Prototypes and delegation (Self) — Chapter 1
- Game-object components (Bilas / West) — Chapter 1
- Entity systems as data (Martin) — Chapter 1, Chapter 2
- Actor model and OTP supervision — Chapter 1, Chapter 3
- Helland entities (composition by identity) — Chapter 1, Chapter 3
- Archetype ECS (Unity DOTS, flecs, Bevy, Unreal Mass) — Chapter 2
- Sparse-set ECS (EnTT) — Chapter 2
- Bitset and reactive ECS — Chapter 2
- ECS as a database / relational framing — Chapter 2
- Generational-index handles — Chapter 2, Chapter 3
- The log and event streaming — Chapter 3
- Event sourcing, CQRS, the Decider pattern — Chapter 3
- LMAX / data-driven business-logic processor — Chapter 3

## Rationale and connection to the BCS thesis

The manuscript builds property stores on Elixir/OTP (2.2), a CHAMP property database (2.3), archetype composition as data folds (2.4), relations as systems (2.5), and a Valkey-native job bus with fencing tokens and fair lanes (3.1, 3.3, 3.4, 3.5). Each of those design choices has a counterpart in the literature. The appendix exists so that the manuscript can point back to its lineage by reference number rather than re-arguing settled history. Chapter 1 supplies the genealogy of the three-part split. Chapter 2 supplies the modern engineering of it and locates BCS within the family. Chapter 3 supplies the distributed-systems turn that motivates the branded snowflake. The reference numbers used across all three chapters are consolidated, with abstracts and a reverse index, in bcs.research.references.md.

A note on reading the evidence. Several sources cited here speculate about the future or describe work in progress; where that is so, the chapters mark it. Benchmark figures are reported with their authors' own framing — both the flecs and ecs_benchmark maintainers warn against trusting numbers measured on someone else's hardware and workload, and the appendix repeats that warning rather than presenting any figure as a BCS measurement.

### References

This umbrella file cites no external sources of its own; every reference appears in the chapter that uses it and is consolidated in bcs.research.references.md.

---

# BCS · Research 1 · The History and Evolution of Composition Approaches — bcs.research.1.md
<show-structure depth="2"/>

## Why a history of composition

Composition is the question of how a larger thing is assembled from smaller things, and where the seams between those things fall. Every era of programming has answered it, and the answers rhyme. This chapter reads the major answers in roughly chronological order, asking of each: what does it compose — logic, data, or both — and where does it draw the encapsulation boundary. The manuscript's Preface already fixes the deep historical anchors (Ross 1961 plexes, Sutherland 1963 Sketchpad master/instance, Hoare 1965 typed references, Leonard 1999 Thief). This chapter widens that frame into the composition debate proper and connects it to manuscript chapter 1.4 (From ECS to BCS) and 2.4 (Archetypes and Composition).

## Objects and the inheritance crisis

The object, as it matured in Simula and Smalltalk, bundled three things together: an identity, a parcel of state, and a parcel of behavior. Reuse was achieved largely through class inheritance — a subclass borrowed and extended the structure and behavior of a superclass. For a decade this looked like the natural unit of composition. Then the costs became visible.

Two failure modes are named repeatedly in the literature. The first is the "deadly diamond of death," where multiple inheritance produces a class that inherits the same ancestor along two paths and the language must arbitrate which copy wins. The second is the "fragile base class problem," where a change to a superclass silently breaks subclasses that depended on its internal behavior. The deeper issue is coupling: a subclass is welded to the implementation of its parent, not to a contract.

The standard remedy was stated as a design principle by the Gang of Four. In the artima.com interview "Design Principles from Design Patterns," Erich Gamma restates the book's rule — "Favor object composition over class inheritance" — and explains why it survived: inheritance, he says, "is a cool way to change behavior. But it's brittle," because the base and subclass are tightly bound. Composition reduces that coupling by plugging small objects into a larger one, what the interview calls black-box reuse, with the Strategy pattern as the canonical example. Gamma adds that the principle held up: "I still think it's true even after ten years." For BCS this is the root of the family tree: the move from inheriting structure to assembling it.

| Approach | Composes | Boundary | Pros | Cons |
|---|---|---|---|---|
| Class inheritance | structure + behavior | around the class hierarchy | concise reuse for true is-a relations | fragile base class, diamond, deep coupling |
| Object composition | behavior via held references | around each collaborating object | flexible, swappable, testable | more wiring, indirection |

## Mixins and traits

If composition is the goal, the next question is the unit. Mixins, originating in the Flavors dialect of Lisp and later CLOS, let a class mix in fragments of behavior from several sources, resolved by a linearization of the inheritance order. Mixins compose behavior, but their conflict resolution is positional and therefore order-sensitive, which reintroduces some of inheritance's fragility.

Traits, defined by Schärli, Ducasse, Nierstrasz, and Black in the ECOOP 2003 paper "Traits: Composable Units of Behaviour," sharpen the unit. A trait is, in their words, "a group of pure methods that serves as a building block for classes." Traits carry behavior but not state, and composition conflicts are made explicit rather than resolved by order — the composing class must resolve a clash deliberately. The paper opens by arguing that single, multiple, and mixin inheritance all "suffer from conceptual and practical problems," and offers traits as a flatter alternative. The relevance to BCS is the separation move: a trait is behavior detached from a specific object's state, which is one step toward the ECS idea that behavior lives in systems and not in the data.

## Prototypes and delegation

A parallel tradition removed classes altogether. In "Self: The Power of Simplicity" (Ungar and Smith, OOPSLA 1987), objects are built by cloning prototypes and sharing behavior by delegation among objects rather than through a class layer. The authors note that "unlike Smalltalk, Self includes neither classes nor variables." Composition here is assembly by copying and pointing: an object's capabilities come from the objects it delegates to. This matters to the BCS lineage because it shows that identity plus delegation can stand in for the entire class machinery — the object is a name with links, and behavior is found by following the links. BCS pushes this further by making the links contracted identities rather than in-memory pointers.

## The game-object lineage

Games arrived at composition from a practical direction: deep class hierarchies of game entities became unmanageable as designers demanded new combinations. The Thief Dark Engine, documented in Tom Leonard's "Postmortem: Thief: The Dark Project" (Game Developer, 1999), is an early and explicit example. Leonard describes the Dark Object System as "a general database for managing the individual objects in a simulation," providing "a generic notion of properties that an object might possess," and states the consequence directly: "In Thief there was no code-based game object hierarchy of any kind." Designers specified object composition through tools, independent of the programming staff. This is the property-database ancestor the BCS manuscript claims descent from — objects as rows of properties in a database, not as instances of a class.

Scott Bilas generalised the pattern in his GDC 2002 talk "A Data-Driven Game Object System," built for Dungeon Siege. The slides describe a game object as a piece of logical interactive content assembled from components, with a stated goal of removing engineer involvement from content — the line between engine and content, Bilas notes, is always moving. The scale is concrete in his slides: the system supported "\>7300 unique object types (i.e. can be placed in the editor)" with "\>100,000 objects placed in our two maps." In the Bilas model the entity is a class that owns its components, and each component is itself a class carrying both logic and data; the update loop walks entities and then their components.

Mick West's 2007 essay "Evolve Your Hierarchy" on cowboyprogramming.com argued the case to a wider audience: the tide, he wrote, was shifting from deep hierarchies "to a variety of methods that compose a game entity object as an aggregation of components." West is candid about the practical compromises — components should not know about each other, but in practice they need fast access. In his words: "Initially we had all component references going through the component manager, however when this started using up over 5% of our CPU time, we allowed the components to store pointers to one another, and call member functions in other components directly." This is an early, documented instance of the tension BCS resolves at the system boundary: who is allowed to hold a reference to whom.

Adam Martin's 2007 series "Entity Systems are the future of MMOG development" on t-machine.org made the decisive conceptual cut. In Martin's model the entity is a pure identifier with no data and no methods, the component is pure data, and the system is logic that runs over arrays of one component type. Martin frames the whole thing as a data problem rather than an object problem, and explicitly connects entity systems to relational databases. His articulation — entities have, in his words, "no data and no methods" — is the line the modern ECS family descends from.

## The Itterheim taxonomy

Steffen Itterheim's gist "Overview of Entity Component System (ECS) variations with pseudo-code" is a compact map of the variants and the source the manuscript treats as given. It distinguishes: the Scott Bilas model (entity is a class with components, component is a class with logic and data, the loop runs entity then components); a Bilas variant that iterates component-types-then-components to enforce a component-type update order regardless of per-entity ordering; Apple's GameplayKit GKComponentSystem variant; and the Adam Martin model (entity is a pure ID/index, component is a pure data struct, a component system runs logic over arrays of one component type). The gist motivates the Martin model by contiguous memory, cache locality, parallelization, the PS3 Cell SPE architecture, and serialization, framing it as a necessity that arose with console hardware and multi-core CPUs from roughly 2005 onward. Itterheim's practical verdict is stated bluntly: if you have those performance needs, "use Martin's ECS. Otherwise you can safely default to Bilas' ECS." BCS sits closer to the Martin and Thief side — data in stores keyed by identity, behavior in systems — and the manuscript's chapter 1.4 makes that allegiance explicit, citing West 2007 and Weissflog 2018.

## A non-game lineage: actors and entities

Composition by identity and messaging has a second, parallel ancestry that owes nothing to games. The actor model, realised in Erlang and the OTP framework, composes a system from independent processes that share nothing and communicate only by messages. Supervision trees compose reliability: a supervisor owns its children, and the unit of composition is the process, addressed by a name. The BCS manuscript's chapter 2.1 (A System Is an OTP Application) and the consumers-as-supervised-owners design of EchoMQ inherit this directly — a store is a process that owns its data and is reachable only by message.

Pat Helland's 2007 paper "Life beyond Distributed Transactions: an Apostate's Opinion" gives the database-world version of the same idea. Helland's entities are collections of keyed data that can be atomically updated within one entity but never across entities; each is identified by a unique key and lives in a single scope of serializability. Composition across entities happens by messaging, and correctness depends on idempotence — the receiving entity is, in the paper's words, "designed to remember" the messages it has processed so retries are harmless. This is the exact shape of EchoMQ's exactly-once effect via provenance guards (manuscript 3.5), where every row remembers the job names it has absorbed. Chapter 3 develops this lineage in full.

The chapter's through-line: across objects, traits, prototypes, game components, actors, and Helland entities, the same three roles recur — something names the thing, something holds its data, something runs its behavior. The disagreements are about where the boundary falls and what crosses it. BCS's answer is previewed here and argued in Chapter 3.

### References

1. Gamma, Helm, Johnson, Vlissides (with Venners) — Design Principles from Design Patterns (composition-over-inheritance principle and Gamma's defence of it): [artima.com](https://www.artima.com/articles/design-principles-from-design-patterns)
2. Schärli, Ducasse, Nierstrasz, Black — Traits: Composable Units of Behaviour, ECOOP 2003 (traits as stateless composable behavior units): [rmod-files.lille.inria.fr](https://rmod-files.lille.inria.fr/Team/Texts/Papers/Scha03a-ECOOP-Traits.pdf)
3. Ungar, Smith — Self: The Power of Simplicity (prototypes and delegation without classes): [doi.org](https://doi.org/10.1007/BF01806105)
4. Leonard — Postmortem: Thief: The Dark Project (the Dark Object System as a property database): [gamedeveloper.com](https://www.gamedeveloper.com/design/postmortem-i-thief-the-dark-project-i-)
5. Bilas — A Data-Driven Game Object System, GDC 2002 (entity assembled from components): [gamedevs.org](https://www.gamedevs.org/uploads/data-driven-game-object-system.pdf)
6. West — Evolve Your Hierarchy (aggregation of components over deep hierarchies): [cowboyprogramming.com](https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/)
7. Martin — Entity Systems are the future of MMOG development, Part 1 (entity as pure ID, component as data, system as logic): [t-machine.org](https://t-machine.org/index.php/2007/09/03/entity-systems-are-the-future-of-mmog-development-part-1/)
8. Martin — Entity Systems, Part 2 (definition of component-oriented entity systems): [t-machine.org](https://t-machine.org/index.php/2007/11/11/entity-systems-are-the-future-of-mmog-development-part-2/)
9. Martin — Entity Systems, Part 3 (link between entity systems and relational databases): [t-machine.org](https://t-machine.org/index.php/2007/12/22/entity-systems-are-the-future-of-mmog-development-part-3/)
10. Itterheim — Overview of ECS variations with pseudo-code (taxonomy of Bilas, GameplayKit, Martin variants): [gist.github.com](https://gist.github.com/LearnCocos2D/77f0ced228292676689f)
11. Helland — Life beyond Distributed Transactions (entities, keys, idempotence by remembering): [ics.uci.edu](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf)

---

## BCS · Research 2 · The Modern ECS Family in Depth

## What the modern family inherited

The modern Entity Component System family takes Adam Martin's cut — entity as identifier, component as data, system as logic — and engineers it for the cache. The defining decisions are about storage layout: how component data for many entities is arranged in memory so that a system iterating one component type touches contiguous bytes. Sander Mertens' ECS FAQ, maintained alongside the flecs engine, gives the standard taxonomy used throughout this chapter: archetype storage, sparse-set storage, bitset storage, and reactive storage, each with different tradeoffs on iteration speed versus the cost of adding and removing components. This chapter takes each family in turn, then argues which one sits closest to BCS.

## Archetype storage

In an archetype ECS, all entities that have exactly the same set of components are stored together in a contiguous table — components are columns, entities are rows. Mertens describes the structure plainly: an archetype is "much like a database table, where each row is an entity, and each column is a component," and an entity lives in exactly one archetype at a time. When a component is added or removed, the entity undergoes a structural change: it is moved out of its current table and into the table for the new component set, and engines cache the edges between archetypes so repeated moves are cheap. Queries iterate the list of archetypes that match the requested component set, and because tables stabilise quickly, the FAQ notes that "query evaluation overhead is reduced to zero on average."

Unity's DOTS Entities is the most documented production example. Unity's own description groups entities with the same component set into an archetype and stores them in chunks; the Entities manual states that "each chunk consists of 16KiB and the number of entities that they can store depends on the number and size of the components in the chunk's archetype." Each chunk holds tightly packed parallel arrays, one per component type plus one for entity IDs. Unity is explicit about the cost: adding or removing a component switches an entity's archetype, which moves it between chunks and back-swaps the last entity to fill the hole, and the docs warn that moving entities frequently "is resource-intensive and reduces the performance of your application." The same blog notes a payoff — loading an archetype-laid-out scene "isn't much more than just loading raw bytes from disk and using them as is."

flecs, Bevy, and Unreal Mass round out the archetype family. flecs adds entity relationships — pairs of the form (Relationship, Target) added to an entity — and Mertens has documented how relationships are implemented on top of the archetype graph; the FAQ also catalogues the family members, listing Unity DOTS, Unreal Mass, Bevy, Legion, Hecs, and Ark as archetype implementations.

| Property | Archetype storage |
|---|---|
| Iteration | very fast, contiguous, vectorizable |
| Add/remove component | slow, moves entity between tables |
| Random access by entity | indirection through entity index |
| Fragmentation | grows with number of distinct component combinations |

flecs documents the fragmentation cost candidly: relationships can produce "many different combinations of components," spreading entities over more tables, and the engine offers non-fragmenting relationship variants to mitigate it.

## Sparse-set storage

EnTT, by Michele Caini (skypjack), is the reference sparse-set implementation. Each component type gets its own sparse set: a packed dense array of component values plus a sparse array indexed by entity ID that points into the dense array. Caini's "ECS back and forth" series explains the appeal — lookup, insertion, and deletion are O(1), and iteration over a single component is O(N) over a tightly packed array. Adding and removing components is far cheaper than an archetype move because only one set changes, which is why the FAQ recommends sparse sets for components that churn, such as those backing a messaging system.

The cost is iteration across multiple component types: a query picks the smallest set and tests each entity for membership in the others, with a level of indirection through the sparse array. Caini's answer is groups, described in part 6 of his series — by arranging the packed arrays of several sets so that entities belonging to all of them are ordered identically at the front, EnTT achieves what he calls perfect struct-of-arrays, iterating "from 0 to N" with "no jumps, no branches." Groups trade some flexibility for speed: a type can belong to only one owning group. Caini also documents pointer stability as a deliberate per-type option (part 12), achieved by leaving tombstone holes instead of swap-and-pop so that references survive removal — a feature archetype engines generally cannot offer because moves invalidate addresses.

## Bitset and reactive variants

The FAQ describes two further families. A bitset ECS (EntityX, Specs in Rust) stores each component in an array indexed by entity ID and keeps a bitset marking which entities have it; iteration walks the bitset and fetches components by index. Caini's survey notes the weakness of the naive form — too much memory is wasted and the holes "defeat the purpose of keeping instances tightly packed." A reactive ECS collects matching entities by listening for the signals (component added, removed, changed) that could change a query's result set, so the matching set is maintained incrementally rather than recomputed. EnTT ships a reactive storage mixin that tracks entities matching given conditions and saves them aside.

## ECS as a database

A recurring theme in Mertens' writing is that an ECS is, structurally, a database. His essay "Why it is time to start thinking of games as databases" argues that game state is locked inside data structures meaningful only with the source code, and that a queryable model would let agents and tools read the world directly. The archetype-as-table framing makes the analogy concrete: components are columns, entities are rows, queries are joins over component sets, and relationships are foreign keys. This framing is the strongest bridge to BCS, whose manuscript chapter 2.5 (Relations Are Systems) cites Codd 1970 and treats relations themselves as systems rather than as columns bolted onto an object. The connection runs both ways: the ECS world rediscovered the relational model that the trading domain has used all along.

## Generational-index handles

Inside an ECS world, the entity identifier is rarely a bare integer. It is a generational index: a slot index plus a generation counter, so that when a slot is recycled the old handle's stale generation no longer resolves. flecs documents this directly — its 64-bit entity ID encodes both an ID and a generation counter, and when an entity is deleted "its generation counter increases, causing the old entity ID to become invalid," which prevents use-after-delete.

Andre Weissflog's 2018 essay "Handles are the better pointers" is the clearest statement of why this pattern exists outside ECS too. Weissflog's prescription: move memory ownership into centralized systems, group items of one type into arrays the system owns privately, and hand the outside world only an index-handle rather than a pointer, converting a handle to a pointer only at the moment of use and never storing the pointer. The handle spends spare bits on safety checks. This is the manuscript's identity discipline in miniature, and chapter 1.4 cites Weissflog directly.

The limit of the generational handle is the boundary of the process. A handle is an index into a specific array owned by a specific system in a specific address space. It does not survive a socket, a save file, or a foreign store, because the array it indexes does not exist on the other side. This limit is the hinge of the whole appendix. BCS is what happens when the handle must survive those crossings: the branded snowflake is the distributed generational index — typed by a namespace prefix, ordered by mint time, placed by a hash function, and identical across runtimes — so the name resolves anywhere rather than only inside the one array that minted it. Chapter 3 develops this turn.

## Storage-layout tradeoffs and reported benchmarks

The archetype-versus-sparse-set debate is fundamentally array-of-structs versus struct-of-arrays plus a question of when you pay. Archetypes pay at structural change to make iteration cheap; sparse sets pay at multi-component iteration to make structural change cheap. Caini's slides summarise the family honestly: both are fine for going full-ECS, and the right choice depends on whether your workload is dominated by iteration or by component churn.

Published micro-benchmarks exist and must be read with care. The abeimler/ecs_benchmark repository on GitHub publishes comparative figures across EnTT, flecs, Ginseng, EntityX, gaia-ecs and others. In its "Update 8 entities with 7 Systems" table, EnTT is reported at 355ns, its grouped variant at 199ns, and its stable variant at 253ns, against flecs at 2332ns for the same micro-test; the "Update 64 entities with 7 Systems" row reports EnTT (stable) at 343ns against flecs at 2402ns. These numbers are reported by the repository maintainer on the maintainer's hardware for deliberately minimal tests. The maintainer's own caution is the right frame: real systems have hundreds of components and systems, so one should "always benchmark your specific cases." flecs' separate benchmark repository (reporting figures for flecs release v4.1.0) repeats the warning that its tests "intentionally measure as little as possible, and do not reflect real-life scenarios." None of these figures is a BCS measurement; they are cited only to show the shape of the tradeoff as their authors published it.

## Which variant is closest to BCS

BCS is the property-database and relational flavor of the family, not the storage-class flavor. The argument has four parts.

First, lineage. BCS descends from the Thief property database (Chapter 1) and cites Codd 1970 (manuscript 2.5), so its native framing is rows keyed by identity, which is the ECS-as-database view, not the archetype-as-memory-layout view.

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

Bevy deserves a note as the hybrid that proves the rule: its components are stored either in archetype tables or in sparse sets, chosen per component type, with table storage the default for iteration speed and sparse-set storage for components that are added and removed frequently. Bevy's documentation describes exactly this dual strategy, and its archetypes carry generational indices like the rest of the family. Bevy shows that the two storage strategies are points on a spectrum, not rival religions — and BCS picks the keyed, owned end of that spectrum and then lifts the key out of the process entirely.

### References

10. Itterheim — Overview of ECS variations with pseudo-code (taxonomy referenced for the Martin model): [gist.github.com](https://gist.github.com/LearnCocos2D/77f0ced228292676689f)
12. Mertens — Entity Component System FAQ (taxonomy of archetype, sparse-set, bitset, reactive storage): [flecs.dev](http://www.flecs.dev/ecs-faq/)
13. Mertens — Building an ECS #2: Archetypes and Vectorization (archetype tables, vectorized iteration): [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9)
14. Mertens — Building an ECS #3: Storage in Pictures (archetype as a database table): [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-storage-in-pictures-642b8bfd6e04)
15. Mertens — flecs Relationships documentation (relationship pairs and fragmentation): [github.com](https://github.com/SanderMertens/flecs/blob/master/docs/Relationships.md)
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

---

## BCS · Research 3 · Composition in Distributed Systems, the Decider Pattern

## When the handle crosses the wire

Chapter 2 ended at a wall: the generational-index handle is an index into an array owned by one system in one address space, and it means nothing on the other side of a socket, a save file, or a foreign store. 
Distributed composition begins exactly where the pointer dies. This chapter traces how the field composes systems when references cannot be shared, develops the Decider pattern as the unit of distributed business logic, sketches an advanced Decider design for a trading engine keyed by branded identities, and closes with the synthesis that states the appendix's thesis.

## Helland's entities and idempotence

Pat Helland's "Life beyond Distributed Transactions: an Apostate's Opinion" (2007, reprinted in ACM Queue 2016) is the foundational text. Helland argues that at scale you cannot have transactions that span entities, so the unit of atomicity shrinks to a single entity — a collection of keyed data with a unique key, living in one scope of serializability. Anything that must affect another entity does so by sending a message, and because messages can be retried, the receiving entity must be idempotent. Helland's mechanism is memory: the entity is "designed to remember" which messages it has already absorbed, so a duplicate is harmless. The manuscript's chapter 3.5 cites this paper, and EchoMQ's provenance guards — every row remembering the job names it has absorbed — are a direct implementation of Helland's remembering.

Helland's later "Immutability Changes Everything" (ACM Queue 2015/2016) supplies the other half: as storage gets cheaper we increasingly store and send immutable data, because, in his framing, immutability is what lets systems "coordinate at a distance" without locks. An immutable event, once written, can be replicated, cached, and replayed without coordination. This is the conceptual ground under event sourcing and under EchoCache's snowflake-versioned newer-wins coherence (manuscript Part IV), where a version is a mint-ordered identity and the newer one always wins without a lock.

## The log as a unifying abstraction

Jay Kreps' "The Log: What every software engineer should know about real-time data's unifying abstraction" (LinkedIn Engineering, 2013) reframes composition itself. A log is, in Kreps' definition, "an append-only, totally-ordered sequence of records ordered by time." If every system publishes its changes to a shared log and every consumer reads from it, then systems are composed by the log rather than by direct calls: producers and consumers are decoupled, can be added independently, and can replay history to rebuild state. Kreps notes that the one domain where real-time stream processing already had traction was finance, where real-time data streams were the norm and processing had become the bottleneck. EchoMQ is a log-flavored bus: the manuscript's fair lanes, fencing tokens, and park-don't-poll consumers compose systems by messages on a shared substrate, which is the log idea applied to a job bus.

## Event sourcing, CQRS, and the Decider

Event sourcing stores the sequence of events that happened rather than the current state, and rebuilds state by folding the events. CQRS separates the write path that decides what happens from the read path that serves queries. The Decider pattern is the functional distillation of the write path, and it is the centerpiece of this chapter.

Jérémie Chassaing introduced the Decider in "Functional Event Sourcing Decider" (thinkbeforecoding.com, 2021). A Decider is three types and four elements:

```
type Command
type Event
type State
initialState : State
decide : Command -> State -> Event list
evolve : State -> Event -> State
isTerminal : State -> bool
```

`decide` takes a command and the current state and returns the events that should happen; `evolve` takes a state and an event and returns the next state; `initialState` is the state before anything has happened; `isTerminal` marks a state past which no command is accepted. Chassaing's framing starts from a system as a function of inputs over time, and the Decider is the shape that falls out. Oskar Dudycz, in "How to effectively compose your business logic" (event-driven.io), describes why this shape matters for composition: the Decider "groups business logic, state evolution and rebuild together with the initial state," and because it is built on functional composition it lets the developer focus on the business process rather than on wiring. Both authors note the property that makes the Decider distributable: it is a pure function. Given the same command and state it yields the same events, so it can run anywhere the state can be reconstructed, and the events it emits are immutable facts in Helland's sense.

A Decider is also composable in the large. Chassaing's post shows many small Deciders combined into one, and the same machinery expresses a process manager — a Decider whose commands and events are the events and commands of other Deciders. This is the bridge from a single aggregate to a composed system.