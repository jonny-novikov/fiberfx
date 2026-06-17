# BCS · Research 1 · The History and Evolution of Composition Approaches

<show-structure depth="2"/>

## Why a history of composition

Composition is the question of how a larger thing is assembled from smaller things, and where the seams between those things fall. Every era of programming has answered it, and the answers rhyme. This chapter reads the major answers in roughly chronological order, asking of each: what does it compose — logic, data, or both — and where does it draw the encapsulation boundary. The manuscript's Preface already fixes the deep historical anchors (Ross 1961 plexes, Sutherland 1963 Sketchpad master/instance, Hoare 1965 typed references, Leonard 1999 Thief). This chapter widens that frame into the composition debate proper and connects it to manuscript chapter 1.4 (From ECS to BCS) and 2.4 (Archetypes and Composition).

## Objects and the inheritance crisis

The object, as it matured in Simula and Smalltalk, bundled three things together: an identity, a parcel of state, and a parcel of behavior. Reuse was achieved largely through class inheritance — a subclass borrowed and extended the structure and behavior of a superclass. For a decade this looked like the natural unit of composition. Then the costs became visible.

Two failure modes are named repeatedly in the literature. The first is the "deadly diamond of death," where multiple inheritance produces a class that inherits the same ancestor along two paths and the language must arbitrate which copy wins. The second is the "fragile base class problem," where a change to a superclass silently breaks subclasses that depended on its internal behavior. The deeper issue is coupling: a subclass is welded to the implementation of its parent, not to a contract.

The standard remedy was stated as a design principle by the Gang of Four. In the artima.com interview "Design Principles from Design Patterns," Erich Gamma restates the book's rule — "Favor object composition over class inheritance" — and explains why it survived: inheritance changes behavior concisely but couples the subclass to the base class's implementation, so a base-class change can break subclasses that did nothing wrong, while composition plugs small objects into a larger one through interfaces — what the interview calls black-box reuse, with the Strategy pattern as the canonical example. A decade after publication, Gamma's verdict in the interview is that the principle held up [1]. For BCS this is the root of the family tree: the move from inheriting structure to assembling it.

| Approach | Composes | Boundary | Pros | Cons |
|---|---|---|---|---|
| Class inheritance | structure + behavior | around the class hierarchy | concise reuse for true is-a relations | fragile base class, diamond, deep coupling |
| Object composition | behavior via held references | around each collaborating object | flexible, swappable, testable | more wiring, indirection |

## Mixins and traits

If composition is the goal, the next question is the unit. Mixins, originating in the Flavors dialect of Lisp and later CLOS, let a class mix in fragments of behavior from several sources, resolved by a linearization of the inheritance order. Mixins compose behavior, but their conflict resolution is positional and therefore order-sensitive, which reintroduces some of inheritance's fragility.

Traits, defined by Schärli, Ducasse, Nierstrasz, and Black in the ECOOP 2003 paper "Traits: Composable Units of Behaviour," sharpen the unit. A trait is, in their words, "a group of pure methods that serves as a building block for classes." Traits carry behavior but not state, and composition conflicts are made explicit rather than resolved by order — the composing class must resolve a clash deliberately. The paper opens by cataloguing the conceptual and practical problems of single, multiple, and mixin inheritance, and offers traits as a flatter alternative [2]. The relevance to BCS is the separation move: a trait is behavior detached from a specific object's state, which is one step toward the ECS idea that behavior lives in systems and not in the data.

## Prototypes and delegation

A parallel tradition removed classes altogether. In "Self: The Power of Simplicity" (Ungar and Smith, OOPSLA 1987), objects are built by cloning prototypes and sharing behavior by delegation among objects rather than through a class layer. The authors note that "unlike Smalltalk, Self includes neither classes nor variables" [3]. Composition here is assembly by copying and pointing: an object's capabilities come from the objects it delegates to. This matters to the BCS lineage because it shows that identity plus delegation can stand in for the entire class machinery — the object is a name with links, and behavior is found by following the links. BCS pushes this further by making the links contracted identities rather than in-memory pointers.

## The game-object lineage

Games arrived at composition from a practical direction: deep class hierarchies of game entities became unmanageable as designers demanded new combinations. The Thief Dark Engine, documented in Tom Leonard's "Postmortem: Thief: The Dark Project" (Game Developer, 1999), is an early and explicit example. Leonard describes the Dark Object System as "a general database for managing the individual objects in a simulation," providing a generic notion of properties an object might possess; the postmortem states that Thief shipped with no code-based game object hierarchy of any kind, and that designers specified object composition through tools, independent of the programming staff [4]. This is the property-database ancestor the BCS manuscript claims descent from — objects as rows of properties in a database, not as instances of a class.

Scott Bilas generalised the pattern in his GDC 2002 talk "A Data-Driven Game Object System," built for Dungeon Siege. The slides describe a game object as a piece of logical interactive content assembled from components, with a stated goal of removing engineer involvement from content — the line between engine and content, Bilas notes, is always moving. The scale is concrete in his slides: the system supported more than 7,300 unique placeable object types, with "\>100,000 objects placed in our two maps" [5]. In the Bilas model the entity is a class that owns its components, and each component is itself a class carrying both logic and data; the update loop walks entities and then their components.

Mick West's 2007 essay "Evolve Your Hierarchy" on cowboyprogramming.com argued the case to a wider audience: the tide, he wrote, was shifting toward composing "a game entity object as an aggregation of components." West is candid about the practical compromises — components should not know about each other, but in practice they need fast access. He reports that routing all inter-component references through the component manager began consuming over 5% of CPU time, after which his team allowed components to hold direct pointers to one another and call member functions across them [6]. This is an early, documented instance of the tension BCS resolves at the system boundary: who is allowed to hold a reference to whom.

Adam Martin's 2007 series "Entity Systems are the future of MMOG development" on t-machine.org made the decisive conceptual cut. In Martin's model the entity is a pure identifier with no data and no methods, the component is pure data, and the system is logic that runs over arrays of one component type [7] [8]. Martin frames the whole thing as a data problem rather than an object problem, and explicitly connects entity systems to relational databases [9]. His articulation — entities have, in his words, "no data and no methods" — is the line the modern ECS family descends from.

## The Itterheim taxonomy

Steffen Itterheim's gist "Overview of Entity Component System (ECS) variations with pseudo-code" is a compact map of the variants and the source the manuscript treats as given. It distinguishes: the Scott Bilas model (entity is a class with components, component is a class with logic and data, the loop runs entity then components); a Bilas variant that iterates component-types-then-components to enforce a component-type update order regardless of per-entity ordering; Apple's GameplayKit GKComponentSystem variant; and the Adam Martin model (entity is a pure ID/index, component is a pure data struct, a component system runs logic over arrays of one component type). The gist motivates the Martin model by contiguous memory, cache locality, parallelization, the PS3 Cell SPE architecture, and serialization, framing it as a necessity that arose with console hardware and multi-core CPUs from roughly 2005 onward. Itterheim's practical verdict is stated bluntly: if you have those performance needs, "use Martin's ECS. Otherwise you can safely default to Bilas' ECS" [10]. BCS sits closer to the Martin and Thief side — data in stores keyed by identity, behavior in systems — and the manuscript's chapter 1.4 makes that allegiance explicit, citing West 2007 and Weissflog 2018.

## A non-game lineage: actors and entities

Composition by identity and messaging has a second, parallel ancestry that owes nothing to games. The actor model, realised in Erlang and the OTP framework, composes a system from independent processes that share nothing and communicate only by messages. Supervision trees compose reliability: a supervisor owns its children, and the unit of composition is the process, addressed by a name. The BCS manuscript's chapter 2.1 (A System Is an OTP Application) and the consumers-as-supervised-owners design of EchoMQ inherit this directly — a store is a process that owns its data and is reachable only by message.

Pat Helland's 2007 paper "Life beyond Distributed Transactions: an Apostate's Opinion" gives the database-world version of the same idea. Helland's entities are collections of keyed data that can be atomically updated within one entity but never across entities; each is identified by a unique key and lives in a single scope of serializability. Composition across entities happens by messaging, and correctness depends on idempotence — the receiving entity is, in the paper's words, "designed to remember" the messages it has processed so retries are harmless [11]. This is the exact shape of EchoMQ's exactly-once effect via provenance guards (manuscript 3.5), where every row remembers the job names it has absorbed. Chapter 3 develops this lineage in full.

The chapter's through-line: across objects, traits, prototypes, game components, actors, and Helland entities, the same three roles recur — something names the thing, something holds its data, something runs its behavior. The disagreements are about where the boundary falls and what crosses it. BCS's answer is previewed here and argued in [`bcs.research.3.md`](bcs.research.3.md).

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
