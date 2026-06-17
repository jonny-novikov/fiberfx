# BCS · Part II — The Elixir BCS Core

<show-structure depth="2"/>

Part I argued; this part builds. Part II is the reference implementation of a *system* — the word the law's first clause is about — on the platform where that clause is not a discipline imposed on the language but the language's native shape. The seed already exists and is transcript-proven: the substrate of Chapter 1.1 (`runtimes/elixir/lib/echo_data/bcs.ex`, `bcs/property_store.ex`, `bcs/supervisor.ex`) grows here into the full treatment, with the trading domain as the working vocabulary throughout. The part's claim fits in one sentence: **on the BEAM, a system is an OTP application — the supervision tree is the boundary, the owning process is the encapsulation, and restart semantics are part of the design rather than an accident of it.**

## The law, landed on OTP

**Ownership is a process, and existence is a supervisor's.** Clause one lands as a private ETS table held by one owning process — total ownership, enforced by the runtime rather than by review. The correction Part I recorded travels with it: the BEAM guards data, not existence — any process can send exit signals, so the boundary that matters for *liveness* is the supervision tree, and a system's restart strategy is a statement about what dies together and what survives alone.

**Message passing is the only verb, and copying is its price.** Clause two is free on this platform — processes share nothing, so identities-and-messages is the grain of the runtime, not a rule against it. The trap that remains is the BEAM's own traveling object: terms are deep-copied between processes, so a message that carries a system's state in a map has forked truth at the mailbox even though no pointer crossed. The discipline survives translation intact: send the name, let the owner resolve it.

**The contract gates at the pattern match.** Clause three lands where Chapter 1.2 placed it — function heads over `<<ns::binary-size(3), _::binary-size(11)>>`, the `~b` sigil for compile-time literals, and the native codec proven byte-equal to the pure path before any store accepts a write. A system's ingress declares its admitted namespaces in code the compiler reads.

## Design guidelines

The Part I guidelines stand; these are the seven this part adds, applied before the first GenServer is written. The trading vocabulary supplies the examples: `AST` instruments, `PRT` portfolios, `ORD` orders, `RSK` envelopes.

**One application per system; the tree is the boundary.** A system exports functions over identities and exports nothing else — no table names, no pids, no records with internals. If the application's public module list does not say it, other systems cannot want it.

**The store process owns the table; sharing is a recorded exception.** Default access is a message to the owner. Read-path acceleration — a protected table, `read_concurrency`, a replica — is a deliberate, per-store decision with its reason written down, never a starting point. The part's closing chapter prices when the exception pays.

**Pure core, process shell.** A GenServer holds a mailbox, ownership, and nothing clever; the work lives in pure functions the shell calls — decidable, testable without a process tree, and ready for the decider treatment the strategies part will give them.

**Crash on contract violation, refuse on domain grounds.** A malformed identity at the boundary earns the caller a typed error; an impossible state *inside* the boundary earns a crash and a supervised restart. What state survives the restart is the store's business, not the process heap's — checkpoints are rows, not memories.

**A snapshot is a structure, not a copy.** Where history is first-class, structural sharing does the work and the contract hash places entries inside the trie — clause three's placement property landing in-process. Where history is not first-class, the flat table wins; the CHAMP chapter states the crossover instead of evangelizing.

**Relations are systems, not fields.** *Portfolio holds asset* is a row in the edges store keyed by a tuple of names, owned like any other property table — never an id list embedded in either endpoint, which is the reach-through wearing a convenience's clothes.

**Archetypes are data.** An equity, a future, an option — bundles of property values with per-instrument overrides, composed at read time. No behaviour-module hierarchy for domain kinds; the Looking Glass move, made on the BEAM.

## The chapters of this part

Chapter 2.1 gives the OTP application the full treatment the substrate previewed — boundary, tree, ownership, and restart semantics as architecture. Chapter 2.2 builds the property stores on ETS: positions, balances, and instrument state with the branded id as the only key and chronology as a property of the keyspace. Chapter 2.3 introduces the CHAMP property database — structural sharing as the snapshot mechanism, the contract hash as the trie's placement function, and the line where a persistent forest beats a flat table. Chapter 2.4 makes archetypes and composition concrete in the instrument domain. Chapter 2.5 promotes relations to systems of their own, with paged traversal over tuple-keyed edges. Chapter 2.6 closes at the boundary: namespace gates on every ingress, the deferred Ecto adapter, and the measured line where the native codec pays on the BEAM.
