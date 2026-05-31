# F0 · History — the lineup

Two orientation modules sit in chapter **F0**, before the algebra of F1 begins. They
answer a question most courses skip: *where did this come from?* F0.1 traces the
languages and runtimes; F0.2 traces the BEAM. Each carries three optional **dives**
for readers who want the formal roots. Everything here is **status: soon** — planned
and specified, not yet shipped — so the contents page links nothing that does not exist.

Both modules live under the chapter route `/elixir/course`. They are context, not
prerequisites: F1 stands on its own, but a reader who works through F0 will recognise
Elixir's design as inheritance rather than novelty.

| ID    | Module                                                      | Route                          | Status |
|-------|-------------------------------------------------------------|--------------------------------|--------|
| F0.1  | The evolution of functional programming languages & runtimes | `/elixir/course/fp-evolution`   | soon   |
| F0.2  | The evolution of Erlang, the BEAM & OTP                     | `/elixir/course/beam-evolution` | soon   |

---

## F0.1 · The evolution of functional programming languages & runtimes

Functional programming is the oldest continuous idea in computing, not a recent
fashion. This module follows one line — from the λ-calculus through LISP, the ML and
Haskell branch, and the immutable-data generation — so that Elixir's three
inheritances are visible before you write any Elixir: homoiconicity and macros from
LISP, pattern matching and algebraic data types from ML, and persistent data
structures from the immutable turn.

The throughline is the *runtime*: each era changed not only how programs were written
but how they were executed and how memory was managed. That is the part that matters
for a language whose runtime — the BEAM — is its defining feature.

### Dives

| ID      | Dive                                                       | Route                            | Status |
|---------|------------------------------------------------------------|----------------------------------|--------|
| F0.1.1  | From λ-calculus to LISP — the first functional runtime     | `/elixir/course/lisp-origins`    | soon   |
| F0.1.2  | Types & laziness — the ML and Haskell branch               | `/elixir/course/ml-haskell`      | soon   |
| F0.1.3  | The immutable turn — persistent data on the JVM & CLR      | `/elixir/course/immutable-turn`  | soon   |

#### F0.1.1 · From λ-calculus to LISP — the first functional runtime

Alonzo Church's λ-calculus (1930s) reduced all of computation to three things:
variables, function abstraction, and application. Computation *is* β-reduction —
substituting an argument into a function body. It is Turing-complete with no machine,
no memory cells, no mutation.

LISP (McCarthy, 1958) made that idea run. Programs are S-expressions, so code is data
the program can inspect and build — *homoiconicity*. A short `eval`/`apply` pair
defines the language in itself, and garbage collection was introduced here, because a
language that allocates list structure freely cannot ask the programmer to free it.
The runtime is a tree-walking evaluator over a managed heap.

**Trade-off.** Expressive power and metaprogramming came at an early performance cost,
and dynamic typing traded compile-time guarantees for flexibility.

**Bridge to Elixir.** `quote`/`unquote` and macros are the LISP line; the BEAM's
per-process garbage collector is the descendant of the idea McCarthy needed to make
LISP usable.

You will be able to read a β-reduction, explain why "code as data" is what makes macros
possible, and name what Elixir kept from LISP.

#### F0.1.2 · Types & laziness — the ML and Haskell branch

ML (Milner, 1970s) introduced Hindley–Milner type inference: sound static typing that
usually needs no annotations, paired with pattern matching, algebraic data types, and
parametric polymorphism. SML, OCaml, and F# descend from it.

Haskell (1990) pushed two ideas to their conclusion: purity by default and lazy
(call-by-need) evaluation. Effects are not forbidden; they are made explicit in the
type system, which is all a monad is in this context — a discipline for sequencing
effects, not a mystery. The runtime evaluates a graph of deferred computations
(thunks), and strictness analysis is the optimisation that keeps it affordable.

**Trade-off.** Laziness buys composability and infinite structures but costs
predictable space and time — space leaks are the failure mode. Static purity buys
strong reasoning but adds ceremony around ordinary effects.

**Bridge to Elixir.** Elixir is eager and dynamically typed, yet it took ML's pattern
matching and data shaping wholesale; `Stream` provides laziness exactly where you ask
for it. Reading Elixir against Haskell clarifies what "functional" does and does not
require.

You will be able to distinguish eager from lazy evaluation, describe HM inference at a
high level, and place Elixir's choices against the ML and Haskell branch.

#### F0.1.3 · The immutable turn — persistent data on the JVM & CLR

In the 2000s, immutability moved from academic to default. Clojure (2007) put a
functional language on the JVM; Scala and F# brought functional style to industrial
runtimes. The enabling idea is **persistent data structures**: Bagwell's Hash Array
Mapped Trie and Okasaki's work make a functional update cheap by sharing structure —
an update returns a new value that reuses most of the old one, in roughly O(log₃₂ n).

The runtime lesson is the important one: immutable values plus structural sharing plus
a fast garbage collector make functional updates practical at scale. This is precisely
what the BEAM depends on.

**Trade-off.** Immutability buys safe sharing across concurrent processes with no locks,
at the cost of allocation pressure the garbage collector must absorb.

**Bridge to Elixir.** This is the direct on-ramp to **F4** (HAMT → CHAMP → branded
CHAMP). Elixir's maps are HAMT-backed, and per-process heaps make immutable updates
both cheap and concurrency-safe.

You will be able to explain structural sharing, justify why immutability and
concurrency reinforce each other, and connect this directly to F4's CHAMP modules.

---

## F0.2 · The evolution of Erlang, the BEAM & OTP

Erlang was engineered for one job — telephone switches that do not stop — and every
trait people associate with it is an answer to that requirement. Processes, message
passing, "let it crash", and supervision are not style choices; they are what
continuous availability demands. This module is the systems-history companion to
F0.1's language history.

It earns its place because the later chapters rest on the BEAM: **F5** (concurrency),
**F6** (distribution and real-time), and **F8** (LiveView) all assume its model.
Knowing why the runtime exists makes those chapters read as consequences rather than
arbitrary facts.

### Dives

| ID      | Dive                                                        | Route                              | Status |
|---------|-------------------------------------------------------------|------------------------------------|--------|
| F0.2.1  | Telecom roots & "let it crash"                              | `/elixir/course/telecom-roots`     | soon   |
| F0.2.2  | Inside the BEAM — scheduling, heaps & soft-real-time GC     | `/elixir/course/inside-beam`       | soon   |
| F0.2.3  | OTP & the supervision tree — and the polyglot BEAM          | `/elixir/course/otp-supervision`   | soon   |

#### F0.2.1 · Telecom roots & "let it crash"

At Ericsson in the mid-1980s, Joe Armstrong, Robert Virding, and Mike Williams built a
language for fault-tolerant, concurrent, distributed telecom software, with a surface
syntax influenced by Prolog. The requirement was near-continuous availability — the
"nine nines", about 99.9999999% uptime — together with upgrades applied to a running
system. The AXD301 switch was the proof it worked.

"Let it crash" follows from that requirement. Rather than defend every line against
every error, you isolate failure to a process and restart it from a known-good state.
Errors are data; recovery is structural. Erlang was open-sourced in 1998.

**Trade-off.** Process isolation and restart simplify error handling and raise
availability, at the cost of copying messages between isolated heaps — there is no
shared memory to mutate.

**Bridge to later chapters.** This stance is F7's "let it crash" lesson and the reason
F5's supervisors exist at all.

You will be able to state the problem Erlang was built to solve and explain "let it
crash" as an engineering position, not a slogan.

#### F0.2.2 · Inside the BEAM — scheduling, heaps & soft-real-time GC

The BEAM — Bogdan/Björn's Erlang Abstract Machine — is the register-based virtual
machine that Erlang and Elixir compile to. Three design choices set it apart from the
JVM and the CLR.

Processes are a VM-level construct, not operating-system threads: a few kilobytes each,
millions per node. Scheduling is preemptive by *reduction counting* — each process runs
for a fixed budget of work and is then suspended, so no single process can starve the
others. That is the source of the BEAM's soft-real-time latency. And each process owns
its heap, so garbage collection is per-process and concurrent: many short, local pauses
instead of one global stop-the-world.

**Trade-off.** Shared-heap runtimes get fast in-process data sharing but pay with
global GC pauses and lock-based concurrency. The BEAM trades the cost of copying
messages for isolation, predictable latency, and lock-free concurrency.

**Bridge to Elixir.** This is the substrate beneath F5's scheduler and reductions
lesson, and the reason LiveView (F8) can afford one process per connection.

You will be able to explain reduction-based preemption, per-process garbage collection,
and why the BEAM optimises for latency and isolation rather than raw throughput.

#### F0.2.3 · OTP & the supervision tree — and the polyglot BEAM

OTP, the Open Telecom Platform, is the standard library of concurrency patterns:
behaviours such as `GenServer`, `Supervisor`, and `Application`, plus releases and hot
code upgrades. A behaviour separates the generic part — the server loop, the restart
logic — from the specific part you supply as callbacks, so a supervision tree is
assembled from tested parts rather than written by hand.

The supervision tree is the central structure. Processes are arranged so a supervisor
restarts failed children under a declared strategy — one-for-one, rest-for-one, or
one-for-all. Fault tolerance becomes a tree you design, not error handling you scatter.

The runtime is also polyglot. Elixir (José Valim, 2012) added a modern surface,
macros, and tooling; Gleam adds static types; LFE is a LISP on the BEAM. All of them
share OTP and the scheduler.

**Trade-off.** Behaviours impose structure and a learning curve, but buy reusable,
battle-tested fault tolerance in place of bespoke error handling.

**Bridge to Elixir.** This is the backbone of F3.08, of F5.03–F5.05, and of F7's
supervision lab.

You will be able to explain what a behaviour is, read a supervision tree and its
restart strategy, and place Elixir, Gleam, and LFE as guests on a single runtime.

---

## Publishing notes

Canonical identifiers are the F-number and the route slug; statuses drive whether the
contents page renders a link or a non-linking card. The full F0 lineup, in reading
order:

| ID      | Title                                                       | Route                              | Status |
|---------|-------------------------------------------------------------|------------------------------------|--------|
| F0.0    | Course contents & how to read it                            | `/elixir/course`                   | live   |
| F0.1    | The evolution of functional programming languages & runtimes | `/elixir/course/fp-evolution`     | soon   |
| F0.1.1  | From λ-calculus to LISP — the first functional runtime      | `/elixir/course/lisp-origins`      | soon   |
| F0.1.2  | Types & laziness — the ML and Haskell branch                | `/elixir/course/ml-haskell`        | soon   |
| F0.1.3  | The immutable turn — persistent data on the JVM & CLR       | `/elixir/course/immutable-turn`    | soon   |
| F0.2    | The evolution of Erlang, the BEAM & OTP                     | `/elixir/course/beam-evolution`    | soon   |
| F0.2.1  | Telecom roots & "let it crash"                              | `/elixir/course/telecom-roots`     | soon   |
| F0.2.2  | Inside the BEAM — scheduling, heaps & soft-real-time GC      | `/elixir/course/inside-beam`       | soon   |
| F0.2.3  | OTP & the supervision tree — and the polyglot BEAM          | `/elixir/course/otp-supervision`   | soon   |

These rows match the manifest in `build_page.py` exactly. To publish a module, change
its status from `soon` to `built` or `live` in the manifest and rebuild; the contents
page turns the card into a link automatically. The two `soon` history modules and their
six dives are F0's contribution to the course total of 84 modules.
