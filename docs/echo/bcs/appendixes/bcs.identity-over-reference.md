# BCS · Identity over Reference — Why Systems, Not Objects

<show-structure depth="2"/>

The difference between an object-oriented design and a Branded Component System is what crosses a boundary. In the object design it is an object — data, behaviour, and identity fused, shared by reference. In BCS it is an identity, a value, and a message about it; the data stays as components owned by the system that holds them, and behaviour is the set of messages a system accepts. This article sets the two side by side on one feature — a player, their referrer, their friends, their games — using the running referral and game systems as the concrete case, and shows why the BCS shape is the one that survives a process boundary.

## Scope and method

This is a design comparison, not a benchmark. It is grounded in the application built across this series: the registration and referral systems (`BcsApp.Registration`, `BcsApp.Referrals`), the game system and its emulator (`BcsGame.Games`, `BcsGame.Engine`), the Valkey-backed sessions and leaderboard (`BcsGame.Sessions`, `BcsGame.Leaderboard`), and the near-cache (`EchoStore`) over the component stores. The identity is the branded snowflake [1]; the systems-own-their-slice and pull-not-push posture follows the social-graph store TAO [2]. The claims here are about shape, and the shapes are the ones the running code uses.

## The boundary question

Every multi-part system has boundaries — between modules, between processes, between services and their stores. The design decision that matters most is what is allowed to cross one. The two paradigms answer differently, and almost everything else follows from the answer.

The object-oriented answer is: the object crosses. A `Player` is an object that holds its data and its methods, and references to the other objects it relates to — its referrer, its friends, its games. To work with a player you hold the object and call its methods, and the objects it points to come along by reference.

The BCS answer is: the identity crosses, and nothing else. A player is a branded `USR` id — a value. The data about that player is components, each owned by the system that cares about it, each keyed by the id. To work with a player you hold the id and send a message to the system that owns the slice you need. No object travels; no reference is shared.

## OOP: the object crosses, and leaks

The object-oriented shape draws encapsulation around the object. That is its strength in the small and its trouble at the edges, for three reasons.

Identity is a reference. Two parts of the program that both hold the `Player` object hold the same mutable thing; a change in one is a change in the other, at a distance, and the coupling is invisible because it is a pointer, not a declaration. Data and behaviour are fused: the methods that act on a player live on the player, so a `Player` that must support referrals and friendships and games accretes knowledge of all three and becomes the object every part of the system reaches into — the god object the smell is named for. And the object graph does not cross a boundary intact. A reference is meaningful only inside one address space; at a process or storage boundary the graph has to be flattened — serialized whole, or lazily loaded edge by edge, which is the read amplification and the object-relational impedance mismatch that object persistence layers spend their complexity fighting. The encapsulation that held inside the program leaks the moment the object has to leave it.

Concretely, a player's social-and-game view in the object shape is a traversal: from the `Player` to its `friends`, from each friend to their `games`, from each game to its `score`. The `Player` object transitively knows about friendships, games, and scores; the traversal pulls an object graph that, across a database, is a chain of lazy loads. One object owns the world, and the world has to be reassembled every time it moves.

## BCS: the identity crosses

The BCS shape draws encapsulation around the system, not the object, and the only things that cross a system boundary are an identity and a message about an identity.

A player is the `USR` id. The data is components, owned per system and keyed by that id: the registration system owns the user record, the referral system owns the referral edges, the game system owns the games and the per-player scores, the session system owns the live sessions. No system owns the player; each owns its slice, and the id is the thread that runs through all of them. Identity is a value, not a reference — copyable, comparable, serializable, the same fourteen bytes in an ETS key, a Valkey key, a database key, and a log line — so passing it across a boundary couples nothing: the receiver cannot reach into the owner's data, it can only hold the id or send a message. Behaviour lives with the components, in the system that owns them, and is reached by messages the system declares it accepts.

The same social-and-game view, in the BCS shape, is two messages, not a traversal. Ask the referral and social systems for the friend ids of a `USR`; ask the game system for the scores of those ids. Two systems answer about a set of ids; neither holds an object that knows about both friends and scores. The view is assembled by pulling from each system, the way TAO resolves a page from the graph at read time rather than precomputing it [2]. No object graph is serialized, because there is no object graph — only ids crossing and components staying home.

## Declaring behaviour across systems

In the object shape, behaviour is a method you call on an object you hold. In BCS, behaviour is a message a system accepts about an identity, declared as the system's boundary contract. The referral system accepts `refer`, `inviter_of`, and `referrals_of` about `USR` ids; the game system accepts `new_game` and `move` about a player and a game id; the session system accepts `whoami` about a `SES` token. These are the messages, and they are the whole of what a caller can do — there is no field to reach past them, because the caller never holds the data, only the id.

The contract is enforced at the boundary by the gate: a message about an id is admitted only if the id's namespace is the kind the system expects, so a `USR` presented where a `SES` is required is refused before any work begins, and a player may move only in a game the game system confirms is theirs. The boundary is a value being checked, not an object being trusted. Behaviour is declared across systems as the messages they exchange about identities, and a new behaviour is a new message on the owning system — local, not a new method bolted onto a shared object that everyone already depends on.

## Why it survives a boundary

The BCS shape is indifferent to where a system runs, and the running application is the demonstration. Sessions live in Valkey, a `SES` token resolved to a player by one `GET`; the leaderboard is a Valkey sorted set, a win one `ZINCRBY` and the ranking one `ZREVRANGE`; players are read through an L1-over-L2 cache; games and scores live in their own stores. These are four different substrates, in different processes, and the application crosses between them without flattening anything, because the only thing that crosses is an id. Coherence across the cache is by id and version, not by a shared reference — a write invalidates by naming the id, and a stale message is a comparison that answers stale, never a dangling pointer. Each system could become its own service tomorrow and the code between them would not change shape, because that code already passes ids and messages, which is exactly what a wire carries. The object shape reaches this point only by first solving serialization and identity-mapping; the BCS shape was never anywhere else.

## The decision

Object orientation couples by sharing references to mutable state; BCS couples by sharing immutable identities and explicit messages. Inside one module, in one process, the object shape is fine and often clearer — a self-contained widget with no boundary to cross has nothing to gain from the discipline. BCS earns its keep the moment state spans systems, processes, or stores: where the object shape would share an object and then spend effort keeping the sharing safe and serializable, BCS shares an id and a message and is done. The rule is one sentence: pass the id, not the object, and let the system that owns the data answer for it.

## Boundaries

This is a comparison of shapes, not a verdict that object orientation is wrong; the two coexist, and the components a BCS system owns are perfectly ordinary data structures inside their system. The argument is about what crosses a boundary, and it bites in proportion to how many boundaries a design has. The application grounding it is real and runs, but the claims here are structural rather than measured; the per-substrate costs that make the shape practical are measured elsewhere in the series.

## References

1. Snowflake ID. https://en.wikipedia.org/wiki/Snowflake_ID
2. N. Bronson et al., TAO: Facebook's Distributed Data Store for the Social Graph, USENIX ATC 2013. https://www.usenix.org/system/files/conference/atc13/atc13-bronson.pdf
