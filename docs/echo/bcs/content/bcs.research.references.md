# BCS · Appendix C · Consolidated References

<show-structure depth="2"/>

Every research reference used across the three chapters, with full citation, URL, a short abstract, and the chapter(s) that cite it. A reverse index by chapter follows the list.

### 1. Gamma, E. (with Venners, B.) — Design Principles from Design Patterns.

Artima Developer, 2005. [artima.com](https://www.artima.com/articles/design-principles-from-design-patterns). Abstract: Interview in which Gang of Four co-author Erich Gamma restates and defends the principle "favor object composition over class inheritance," arguing inheritance is brittle through base/subclass coupling while composition gives black-box reuse. Cited by: Chapter 1.
### 2. Schärli, N., Ducasse, S., Nierstrasz, O., Black, A.P. — Traits: Composable Units of Behaviour.

ECOOP 2003, LNCS 2743, pp. 248–274. [rmod-files.lille.inria.fr](https://rmod-files.lille.inria.fr/Team/Texts/Papers/Scha03a-ECOOP-Traits.pdf). Abstract: Identifies conceptual and practical problems in single, multiple, and mixin inheritance and proposes traits — stateless groups of pure methods that compose into classes with explicit conflict resolution. Cited by: Chapter 1.
### 3. Ungar, D., Smith, R.B. — Self: The Power of Simplicity.

OOPSLA 1987; revised in Lisp and Symbolic Computation 4 (1991). [doi.org](https://doi.org/10.1007/BF01806105). Abstract: Introduces Self, a class-free language built on prototypes, slots, and delegation, where objects are cloned from prototypes and share behavior by delegation rather than through classes. Cited by: Chapter 1.
### 4. Leonard, T. — Postmortem: Thief: The Dark Project.

Game Developer Magazine, 1999. [gamedeveloper.com](https://www.gamedeveloper.com/design/postmortem-i-thief-the-dark-project-i-). Abstract: Looking Glass lead programmer's postmortem describing the Dark Object System as a general property database for simulation objects, with no code-based object hierarchy and designer-driven composition through tools. Cited by: Chapter 1.
### 5. Bilas, S. — A Data-Driven Game Object System.

GDC 2002 (Dungeon Siege). [gamedevs.org](https://www.gamedevs.org/uploads/data-driven-game-object-system.pdf). Abstract: Slides presenting a component-assembled game object system aimed at removing engineer involvement from content; reports more than 7,300 unique placeable object types and over 100,000 objects placed across the game's two maps. Cited by: Chapter 1.
### 6. West, M. — Evolve Your Hierarchy.

Cowboy Programming, 2007. [cowboyprogramming.com](https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/). Abstract: Argues for composing game entities as aggregations of components instead of deep class hierarchies; documents allowing components to hold direct pointers to one another after manager-routed references cost over 5% of CPU time. Cited by: Chapter 1.
### 7. Martin, A. — Entity Systems are the future of MMOG development, Part 1.

T-machine.org, 2007. [t-machine.org](https://t-machine.org/index.php/2007/09/03/entity-systems-are-the-future-of-mmog-development-part-1/). Abstract: Opens the influential series framing entity systems as a data problem, with entities as pure identifiers, components as data, and systems as logic over component arrays. Cited by: Chapter 1.
### 8. Martin, A. — Entity Systems, Part 2.

T-machine.org, 2007. [t-machine.org](https://t-machine.org/index.php/2007/11/11/entity-systems-are-the-future-of-mmog-development-part-2/). Abstract: Defines component-oriented entity systems as a subset of component-oriented programming and states that entities have no data and no methods. Cited by: Chapter 1.
### 9. Martin, A. — Entity Systems, Part 3.

T-machine.org, 2007. [t-machine.org](https://t-machine.org/index.php/2007/12/22/entity-systems-are-the-future-of-mmog-development-part-3/). Abstract: Connects entity systems to SQL and relational databases, treating the entity store as a queryable data model. Cited by: Chapter 1.
### 10. Itterheim, S. — Overview of Entity Component System (ECS) variations with pseudo-code.

GitHub gist. [gist.github.com](https://gist.github.com/LearnCocos2D/77f0ced228292676689f). Abstract: Compares ECS variants in pseudo-code — Bilas (entity owns components), a Bilas component-type-ordered variant, GameplayKit, and Martin (entity as ID, component as data, system as logic) — recommending Martin's model when console/multi-core performance demands it and defaulting to Bilas' otherwise. Cited by: Chapter 1, Chapter 2.
### 11. Helland, P. — Life beyond Distributed Transactions: an Apostate's Opinion.

CIDR 2007 / ACM Queue 2016. [ics.uci.edu](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf). Abstract: Argues atomicity at scale shrinks to a single keyed entity, with cross-entity coordination by retriable messages and correctness via idempotence — the entity remembers messages it has processed. Cited by: Chapter 1, Chapter 3.
### 12. Mertens, S. — Entity Component System FAQ.

flecs.dev / GitHub. [flecs.dev](http://www.flecs.dev/ecs-faq/). Abstract: Reference taxonomy of ECS storage strategies — archetype, sparse-set, bitset, reactive — with their iteration and structural-change tradeoffs and lists of implementing engines; notes archetype query overhead reduces to zero on average. Cited by: Chapter 2.
### 13. Mertens, S. — Building an ECS #2: Archetypes and Vectorization.

Medium. [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9). Abstract: Explains archetype tables, contiguous component arrays, archetype-edge caching for structural changes, and why array layout enables cache-friendly vectorized iteration. Cited by: Chapter 2.
### 14. Mertens, S. — Building an ECS #3: Storage in Pictures.

Medium. [ajmmertens.medium.com](https://ajmmertens.medium.com/building-an-ecs-storage-in-pictures-642b8bfd6e04). Abstract: Visual walk-through of flecs storage describing an archetype as a database table with entities as rows and components as columns, plus tag and relationship handling. Cited by: Chapter 2.
### 15. Mertens, S. — flecs Relationships documentation.

GitHub. [github.com](https://github.com/SanderMertens/flecs/blob/master/docs/Relationships.md). Abstract: Documents entity relationship pairs (Relationship, Target), their implementation on the archetype graph, generation counters on entity ids, and the fragmentation cost of many component combinations. Cited by: Chapter 2.
### 16. Mertens, S. — Why it is time to start thinking of games as databases.

Medium. [ajmmertens.medium.com](https://ajmmertens.medium.com/why-it-is-time-to-start-thinking-of-games-as-databases-e7971da33ac3). Abstract: Argues game state should be a queryable database so tools and agents can read the world, making explicit the ECS-as-database framing. Cited by: Chapter 2.
### 17. Unity Technologies — On DOTS: Entity Component System.

Unity Blog. [blog.unity.com](https://blog.unity.com/technology/on-dots-entity-component-system). Abstract: Describes DOTS grouping entities with identical component sets into archetypes stored in 16 KiB chunks, the cost of archetype switching, and fast load times from raw byte layout. Cited by: Chapter 2.
### 18. Unity Technologies — Archetypes concepts,

Entities manual (com.unity.entities@1.0). [docs.unity3d.com](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/concepts-archetypes.html). Abstract: Documentation detailing 16 KiB chunk arrays per component type, entity movement between archetypes on structural change, and the warning that frequent moves reduce performance. Cited by: Chapter 2.
### 19. Caini, M. (skypjack) — ECS back and forth, Part 9: Sparse sets and EnTT.

[skypjack.github.io](https://skypjack.github.io/2020-08-02-ecs-baf-part-9/). Abstract: Explains the sparse-set model behind EnTT — dense packed arrays plus sparse index arrays — with O(1) operations and O(N) tightly packed iteration. Cited by: Chapter 2.
### 20. Caini, M. — ECS back and forth, Part 6.

[skypjack.github.io](https://skypjack.github.io/2019-11-19-ecs-baf-part-6/). Abstract: Describes EnTT groups, which arrange multiple sparse sets so shared entities are ordered identically at the front, enabling branchless perfect struct-of-arrays iteration. Cited by: Chapter 2.
### 21. Caini, M. — ECS back and forth, Part 12.

[skypjack.github.io](https://skypjack.github.io/2021-08-29-ecs-baf-part-12/). Abstract: Shows how EnTT achieves optional per-type pointer stability by leaving tombstone holes instead of swap-and-pop, preserving references across removals. Cited by: Chapter 2.
### 22. Weissflog, A. — Handles are the better pointers.

Published 2018. [floooh.github.io](https://floooh.github.io/2018/06/17/handles-vs-pointers.html). Abstract: Advocates centralized system-owned arrays exposing index-handles with safety-check bits instead of raw pointers, converting to a pointer only at use and never storing it. Cited by: Chapter 2.
### 23. Bevy contributors — Components and Storage.

DeepWiki (bevyengine/bevy). [deepwiki.com](https://deepwiki.com/bevyengine/bevy/2.2-components-and-storage). Abstract: Documents Bevy's hybrid per-component storage — table storage for fast iteration (default) and sparse-set storage for frequently added/removed components — over generational-index archetypes. Cited by: Chapter 2.
### 24. abeimler — ecs_benchmark.

GitHub. [github.com](https://github.com/abeimler/ecs_benchmark). Abstract: Comparative ECS micro-benchmark suite reporting per-operation timings (for example, "Update 8 entities with 7 Systems": EnTT 355ns, EnTT group 199ns, flecs 2332ns) across EnTT, flecs, EntityX, Ginseng, gaia-ecs and others, with the maintainer's caution to benchmark one's own workload. Cited by: Chapter 2.
### 25. Mertens, S. — ecs_benchmark (flecs).

GitHub. [github.com](https://github.com/SanderMertens/ecs_benchmark). Abstract: flecs' own benchmark repository (figures for release v4.1.0), stating the tests intentionally measure as little as possible and do not reflect real-life scenarios. Cited by: Chapter 2.
### 26. Helland, P. — Immutability Changes Everything.

ACM Queue 13(9), 2015/2016. [queue.acm.org](https://queue.acm.org/detail.cfm?id=2884038). Abstract: Argues that cheap storage drives a trend toward immutable data, which is what lets distributed systems coordinate at a distance without locks, underpinning event sourcing and versioned coherence. Cited by: Chapter 3.
### 27. Kreps, J. — The Log: What every software engineer should know about real-time data's unifying abstraction.

LinkedIn Engineering, 2013. [engineering.linkedin.com](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying). Abstract: Defines the log as an append-only totally-ordered record sequence and shows how publishing to and reading from a shared log decouples and composes systems, with finance as the early stream-processing adopter. Cited by: Chapter 3.
### 28. Chassaing, J. — Functional Event Sourcing Decider.

thinkbeforecoding.com, 2021. [thinkbeforecoding.com](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider). Abstract: Introduces the Decider — decide (Command, State → Event list), evolve (State, Event → State), initialState, isTerminal — and shows many Deciders composing into one and into process managers. Cited by: Chapter 3.
### 29. Dudycz, O. — How to effectively compose your business logic.

event-driven.io, 2022. [event-driven.io](https://event-driven.io/en/how_to_effectively_compose_your_business_logic/). Abstract: Applies the Decider pattern to a shopping-cart state machine, describing it as grouping business logic, state evolution, and initial state via functional composition, crediting Chassaing. Cited by: Chapter 3.
### 30. Fowler, M. — The LMAX Architecture.

martinfowler.com, 2011. [martinfowler.com](https://martinfowler.com/articles/lmax.html). Abstract: Describes the LMAX exchange's single-threaded in-memory event-sourced Business Logic Processor, reported at 6 million orders per second on a 3 GHz dual-socket quad-core Nehalem Dell server with 32 GB RAM, surrounded by lock-free Disruptor ring buffers. Cited by: Chapter 3.

## Reverse index (chapter → reference numbers)

- Chapter 1 ([`bcs.research.1.md`](bcs.research.1.md)): 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
- Chapter 2 ([`bcs.research.2.md`](bcs.research.2.md)): 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
- Chapter 3 ([`bcs.research.3.md`](bcs.research.3.md)): 11, 26, 27, 28, 29, 30
