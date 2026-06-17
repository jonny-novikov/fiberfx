# BCS · Appendix C · Composition Approaches

<show-structure depth="2"/>

## Preface to the research appendix

The Branded Component System is a measured manuscript. Its chapters commit to local records: code that runs, tables that exist, contracts that hold. This appendix does something different. It is the literature review the measured chapters stand on. Where the manuscript says *we do it this way*, the appendix says: here is the lineage of ways it has been done, who reported what, and where. Evidence here is reported and attributed to its sources, not measured locally. When a benchmark number appears, it is quoted as the originating author published it, with their hardware and their caveats intact. When a design claim appears, it is traced to the blog post, slide deck, paper, or repository where it was first stated.

This separation is deliberate. A reader who wants to argue with the manuscript's thesis should be able to check the manuscript's evidence against its primary sources without untangling what the BCS authors built from what the field already knew. The three research chapters are organised so that each pillar of the thesis — identity, data, logic, and where the boundaries between them sit — has a documented genealogy.

The thesis the appendix supports is stated once, plainly: encapsulation boundaries are drawn around systems, not objects, and the only thing an object keeps once its state and behavior have moved out is its name. The research that follows shows that nearly every composition approach in fifty years of practice converges on the same three-part split — identity, data, behavior — and that the approaches differ mainly in where they put the boundary and what they allow to cross it. BCS draws the boundary around the system and allows only the identity to cross.

## The three research chapters

**Research Chapter 1 — The history and evolution of composition approaches** ([`bcs.research.1.md`](bcs.research.1.md)). From Simula and Smalltalk objects through the inheritance crisis, the Gang of Four's composition principle, mixins and traits, prototype/delegation models, and into the game-object lineage (Bilas, West, Martin, the Itterheim taxonomy), closing with the actor-model and Helland's entities as a non-game lineage of composition by identity and messaging. Each approach is read for what it composes and where its boundary sits.

**Research Chapter 2 — The modern ECS family in depth** ([`bcs.research.2.md`](bcs.research.2.md)). Archetype storage (Unity DOTS, flecs, Bevy, Unreal Mass), sparse-set storage (EnTT), bitset and reactive variants, the relational/database framing of ECS, generational-index handles as the identity mechanism and their process-local limits, and storage-layout tradeoffs with reported benchmark numbers. The chapter argues which variant sits closest to BCS and why.

**Research Chapter 3 — Composition in distributed systems** ([`bcs.research.3.md`](bcs.research.3.md)). Why handles die at the boundary, Helland's entities and idempotence, the log as a unifying abstraction, event sourcing and the Decider pattern in depth, an advanced Decider sketch for a trading engine keyed by branded identities, the LMAX architecture as a data-driven single-threaded example, and a closing "Putting it all together" synthesis that reads as the thesis statement of the whole appendix.

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

The manuscript builds property stores on Elixir/OTP (2.2), a CHAMP property database (2.3), archetype composition as data folds (2.4), relations as systems (2.5), and a Valkey-native job bus with fencing tokens and fair lanes (3.1, 3.3, 3.4, 3.5). Each of those design choices has a counterpart in the literature. The appendix exists so that the manuscript can point back to its lineage by reference number rather than re-arguing settled history. Chapter 1 supplies the genealogy of the three-part split. Chapter 2 supplies the modern engineering of it and locates BCS within the family. Chapter 3 supplies the distributed-systems turn that motivates the branded snowflake. The reference numbers used across all three chapters are consolidated, with abstracts and a reverse index, in [`bcs.research.references.md`](bcs.research.references.md).

A note on reading the evidence. Several sources cited here speculate about the future or describe work in progress; where that is so, the chapters mark it. Benchmark figures are reported with their authors' own framing — both the flecs and ecs_benchmark maintainers warn against trusting numbers measured on someone else's hardware and workload, and the appendix repeats that warning rather than presenting any figure as a BCS measurement.

### References

This umbrella file cites no external sources of its own; every reference appears in the chapter that uses it and is consolidated in [`bcs.research.references.md`](bcs.research.references.md).
