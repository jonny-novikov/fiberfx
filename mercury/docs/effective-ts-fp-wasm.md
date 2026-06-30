# Mercury · Effective TypeScript, functional patterns, and the wasm seam
<show-structure depth="2"/>

This piece is the research behind one decision in Mercury: keep the product
surface in TypeScript, written in a disciplined functional style, but push the
hot identity and compute kernel into Rust compiled to wasm (`@echo/fx`). It
surveys the functional-programming libraries worth reaching for in TypeScript,
weighs the three most relevant side by side, sets out the open problems of the
effect-system approach and of the Node and V8 runtime underneath it, and ends
with the `@echo/fx` roadmap the surface is built toward.

The throughline: TypeScript's type system is strong enough to carry most of the
value of functional programming — typed errors, exhaustiveness, composition —
but the runtime it sits on has hard limits that make a recursion-heavy,
allocation-heavy style expensive. Where those limits bite, the work moves across
a wasm boundary into a kernel that the BEAM side already proves correct.

## Functional patterns that pay rent

A handful of patterns carry most of the practical value in a TypeScript codebase,
independent of any single library:

- **Errors as values.** A function returns `Result<T, E>` instead of throwing,
  and the caller is forced by the type to handle both arms. The discriminated
  union narrows after an `isErr` check, so the success value is reachable only
  once the error case is dealt with. One practitioner write-up measured
  errors-as-values at roughly two orders of magnitude faster than throwing on a
  hot path, though that figure is a single benchmark and worth re-measuring in
  context.
- **Exhaustiveness.** Pattern matching over a tagged union with a compile-time
  check that every case is handled, so adding a variant turns every unhandled
  site into a type error rather than a silent fallthrough.
- **Immutability with structural sharing.** Values are not mutated in place;
  updates produce new values that share unchanged structure. This is the pattern
  most in tension with the runtime, as the GC section below explains.
- **Composition over a pipeline.** Small total functions composed with `pipe`,
  so a transformation reads top to bottom and each step has one job.

The wasm seam fits underneath all four. A codec, a hash, or a fused numeric
pipeline is a pure function with a fixed shape; running it in a Rust kernel keeps
it deterministic, off the GC, and at parity with the native implementation the
BEAM side already runs, while the TypeScript above stays in the functional style
that the type system rewards.

## Three libraries, side by side

The TypeScript ecosystem has converged on a spectrum rather than a single
answer. The three below are the most relevant to Mercury: a full effect system,
a lightweight typed-error library, and an exhaustiveness library. They compose —
many codebases run a Result library and a pattern-matching library together.

### Effect

Effect is the heavyweight. It can be regarded as the successor to fp-ts v2 and
effectively fp-ts v3, and the fp-ts project is officially merging into the
Effect ecosystem, with fp-ts's author joining the Effect organization. It
encodes side effects in the type — an `Effect<A, E, R>` carries the success
type, the error type, and the required services — and ships a fiber-based
runtime for structured concurrency, dependency injection through `Tag` /
`Context` / `Layer`, typed errors that merge at the type level, retries and
scheduling, and built-in services like a clock and a tracer. The fp-ts companion
libraries are being folded in: io-ts users are pointed at `@effect/schema`, and
optics and contrib utilities are superseded by built-ins.

- Plus: one coherent system for errors, concurrency, dependencies, and
  observability; typed errors and dependencies that combine at the type level; a
  Drizzle integration exists under `@effect/sql`, so the Mercury read model could
  sit inside it later; the clear successor with the most active development.
- Minus: the largest of the three by a wide margin because the fiber runtime is
  in the bundle; the steepest learning curve; the generator-based `Effect.gen`
  do-notation and the `Effect<A, E, R>` signature are a real departure from
  idiomatic TypeScript. A `Micro` subset exists for bundle-sensitive use, but
  pulling in any major module brings the full runtime back.

### neverthrow

neverthrow is the lightweight Result library. It is a zero-dependency
`Result<T, E>` (and an async `ResultAsync` that is thenable), with `isOk` /
`isErr` narrowing, `map` / `andThen` composition, and a `safeTry` helper for
chaining. An accompanying eslint plugin forces every result to be consumed, so a
forgotten error becomes a lint failure. It is the pragmatic entry point to
errors-as-values: a team can adopt it gradually, and migrate to Effect later
with modest API changes if the full system is wanted.

- Plus: tiny and dependency-free; the Result type and narrowing are quick to
  read; gradual adoption is supported; the lint plugin closes the
  forgotten-error gap; a clean stepping stone toward Effect.
- Minus: the friction lives at the boundary with throw-based code. A library
  whose API expects a thrown error — a database transaction that rolls back on
  throw is the canonical case — forces a conversion back to throwing, and the
  `safeTry` sugar uses the same generator syntax as `Effect.gen`. The lack of a
  language-level `?` operator means the bridge code is verbose at every seam.

### ts-pattern

ts-pattern is the exhaustiveness library. It brings pattern matching with smart
type inference: `.with(...)` clauses, wildcards like `P._` and `P.string`,
predicates, selection with `P.select`, and `.exhaustive()`, which makes the
compiler reject a match that misses a case. Its footprint is small, on the order
of a couple of kilobytes. It complements either library above — a Result is
matched, a tagged event is dispatched — and it stands in for a language feature
that is not coming soon, since the TC39 pattern-matching proposal is still at an
early stage.

- Plus: exhaustiveness is enforced at compile time, so a new variant turns into
  a type error at every unhandled site; small footprint; reads well on nested
  data; composes with Result libraries.
- Minus: it is a runtime construct, so a match carries a small cost over a hand-
  written switch; the inference, while strong, can produce dense type errors on
  deeply nested patterns; it is matching only, not a full FP toolkit.

### The matrix

| Dimension | Effect | neverthrow | ts-pattern |
|---|---|---|---|
| Scope | full effect system | Result type only | pattern matching only |
| Runtime | fiber runtime in bundle | thin, zero-dep | thin |
| Bundle | largest (Micro subset exists) | tiny | ~2 kB |
| Typed errors | yes, merge at type level | yes, manual union | matches them |
| Concurrency | built in (fibers) | via ResultAsync | n/a |
| Dependency injection | yes (Tag/Context/Layer) | no | no |
| Learning curve | steep | gentle | gentle |
| Boundary friction | own runtime everywhere | at throw-based seams | low |
| Fit for Mercury now | later, full surface | now, errors-as-values | now, dispatch |

Honorable mentions: fp-ts itself remains widely used (on the order of three
million weekly downloads and eleven thousand stars in early 2026) but its future
narrows as it merges into Effect; ts-results offers a Rust-style Result and
Option with built-in matching; ts-toolbelt is compile-time type machinery, not a
runtime library; and for plain data transformation Remeda and Ramda cover
map/filter/group utilities, with Remeda the better-typed of the two for
TypeScript-first code.

For Mercury the working choice is neverthrow plus ts-pattern at the surface now —
errors-as-values and exhaustive dispatch with a tiny footprint and a short
ramp — with Effect held as the option for a later, larger product surface where
its concurrency and dependency model would earn the weight.

## The open problems of Effect

Effect is the clear direction of travel, and its open problems are the cost of
its ambition rather than defects:

- **Bundle weight.** The fiber runtime is in the bundle, so even small programs
  start larger than an fp-ts or neverthrow equivalent. The library's own framing
  is that the overhead amortizes as more of the system uses it, and `Micro`
  exists for the bundle-sensitive case, but a client that wants one small piece
  pays for the runtime the moment it touches a major module.
- **Learning curve and idiom.** The `Effect<A, E, R>` signature and the
  generator-based `Effect.gen` syntax are a significant departure from the way
  TypeScript is usually written. Reading point-free pipelines fluently takes
  weeks for most developers, and the generator do-notation requires
  understanding how `yield*` drives the runtime.
- **Hiring and onboarding.** Because the model differs from mainstream
  TypeScript, the pool of immediately productive engineers is smaller, and a
  team either hires for existing FP experience or invests in training. At least
  one engineering group chose neverthrow over Effect specifically to keep the
  hiring pool wide and the onboarding short.
- **Boundary friction.** An effect system wants to own the program. At every
  seam with throw-based or Promise-based code — a transaction that rolls back on
  a thrown error, a third-party client — there is conversion to write, and the
  same friction shows up in the lightweight Result libraries that are meant to
  be the gentle on-ramp.

## The open problems of Node and V8

These are runtime limits, not library choices, and they are the reason Mercury
pushes hot work into wasm rather than chasing it in TypeScript.

- **One thread by default.** Node runs JavaScript on a single thread; a
  CPU-bound computation blocks the event loop and stalls every concurrent
  request. The two escapes are the cluster module (separate processes) and
  worker threads (threads inside one process), each with its own tradeoffs, set
  out in the roadmap below.
- **No proper tail calls.** ECMAScript 2015 specified proper tail calls, but V8
  implemented and then removed them; among major engines only JavaScriptCore
  (Safari) ships them, and SpiderMonkey removed them as well. V8 proposed an
  explicit syntactic-tail-call form using a `continue` keyword, and that proposal
  stalled. The practical consequence for functional code is that deep recursion
  blows the stack: a recursion-as-iteration style that is the standard loop on
  some runtimes is a stack-overflow risk here, and the workaround is a trampoline
  or a manual rewrite to a loop. The contrast is sharp with the BEAM, where
  tail-recursive functions are optimized automatically and are the normal way to
  write a loop — one more reason the recursion-heavy core stays on the Elixir
  side or in a wasm kernel rather than in Node.
- **Deoptimization and shape instability.** V8 makes hot code fast by speculating
  on object shape: hidden classes (maps) describe a shape, and inline caches at
  each property-access site remember the shapes seen. A site that has seen one
  shape is monomorphic and fastest; two to four shapes is polymorphic and still
  optimizable; beyond four it goes megamorphic and the optimizer typically gives
  up, falling back to dictionary lookups. When a shape assumption is violated the
  optimized code is discarded and execution deoptimizes to the interpreter. A
  functional style that builds many slightly different object shapes — wide
  unions, ad-hoc result records — and that flows heterogeneous values through one
  generic combinator is exactly the pattern that pushes call sites toward
  polymorphic and megamorphic states.
- **Garbage-collection pressure from immutability.** V8's generational collector
  is tuned for the observation that most objects die young, which suits
  short-lived intermediate values. But an allocation-heavy immutable style — a
  pipeline that materializes a new array at every stage — generates exactly that
  young garbage at volume, and the collection cost shows up as pauses under load.
  Structural sharing reduces it; a fused pipeline that produces no intermediate
  arrays removes it. The wasm kernel's `fused_sum_of_squares` is the second case:
  one pass, no intermediates crossing the boundary.
- **BigInt at the identity boundary.** The branded Snowflake is a 63-bit value
  that exceeds the safe integer range, so the decoder returns it as a string and
  callers that need the numeric form reach for BigInt. BigInt is arbitrary
  precision and heap-backed, and it is slower than a machine integer in a hot
  loop, so identity-heavy hot paths keep the value as the fourteen-character
  string and decode lazily rather than carrying BigInt through the loop.
- **The cost of crossing process and isolate boundaries.** Cluster workers are
  separate processes and do not share a heap; moving data between them goes
  through a structured-clone copy over IPC, which is real overhead for large
  payloads. Worker threads can share memory through a `SharedArrayBuffer` with
  `Atomics`, avoiding the copy, but in return the code takes on memory ordering,
  race conditions, and deadlocks. And the practical Node footgun of mixing
  CommonJS and ESM worker entry points produces loader errors that read like a
  missing module even when the path is correct — relevant because the wasm-pack
  output is CommonJS while the surface is ESM, which the harness handles with an
  explicit require bridge.

## The wasm seam: when Rust beats JS, and its costs

Pushing a function into a Rust wasm kernel is worth it when the function is a
pure, fixed-shape computation that the runtime above makes expensive: a codec, a
hash, a tight numeric loop, or a fused pipeline. In the kernel it runs off the
GC, with stable shapes, deterministic under test, and — for identity — at parity
with the native NIF the BEAM side runs, so one algorithm is shared rather than
re-derived in two languages.

The costs are equally concrete and bound the design:

- **Boundary marshaling.** Each call across the wasm boundary copies its
  arguments and results. The seam must stay coarse-grained — one call per logical
  operation, no chatty per-field crossings — which is why `@echo/fx`'s
  TypeScript facade exposes one function per operation and returns a decoded
  value in a single crossing.
- **One isolate per instance.** A wasm instance is a single isolate with private
  linear memory. Two cores cannot share one instance's memory, so a shared work
  queue cannot live in Rust across cores without `SharedArrayBuffer` and wasm
  threads. This is the reason the scheduler is in TypeScript and the kernel is
  per-isolate.
- **Not every function qualifies.** I/O-bound work gains nothing from wasm, and a
  function that is called rarely or that marshals more data than it computes on
  can be slower across the boundary than in plain TypeScript. The kernel holds
  the codecs and the fused numeric primitive, not the glue.

## The echo/fx roadmap

Five rungs, from what ships today to the parallel-execution target. Each names
what it is, why it sits where it does on the cluster-versus-threads spectrum, and
the gate that keeps it correct.

| Rung | What | Mechanism | State |
|---|---|---|---|
| R0 | BrandedId codec + Snowflake minter | Rust → wasm, per-isolate | shipped |
| R1 | Fusion Tasks | fused map/filter/fold in the kernel | seed shipped |
| R2 | Work-stealing | Chase-Lev deque over SharedArrayBuffer + Atomics | proposed |
| R3 | Parallel execution | Node Cluster, one kernel per core | shipped (demo) |
| R4 | Hot code replacement | rolling worker generations | shipped (demo) |

**R0 — identity (shipped).** The fourteen-byte codec, the per-isolate Snowflake
minter, and the routing hash. The minter is lock-free by isolation: each Cluster
worker carries its own node id, so ids are disjoint across cores without a shared
lock. Gate: `cargo test` covers the codec and the minter; the `hash32` value is
PARITY-pending against `EchoData.BrandedId.hash32/1` and is not authoritative for
cross-wire routing until reconciled.

**R1 — Fusion Tasks (seed shipped).** A fused pipeline runs map, filter, and fold
in one pass over linear memory with no intermediate array crossing the boundary,
which is the direct answer to the GC-pressure problem above. The shipped
`fused_sum_of_squares` is the primitive in miniature; the rung generalizes it to
a small set of fused numeric and scoring pipelines. Gate: each pipeline has a
pure-Rust property test and a parity check against a reference TypeScript
implementation.

**R2 — work-stealing (proposed).** A work-stealing scheduler needs a deque that
several workers can push to and steal from, which in Node is only possible with a
`SharedArrayBuffer` and `Atomics` across worker threads — the one place a truly
shared queue can live. A Chase-Lev style deque over shared memory is
the intended mechanism. This is the rung that takes on memory ordering and race
conditions, so it is gated hardest: a single-threaded model test first, then a
stress test under contention, before it carries real work.

**R3 — parallel execution on Node Cluster (shipped as a demo).** The cluster
module forks one process per core; each loads the same wasm kernel and carries a
disjoint node id, so minting stays collision-free without coordination. Work is
fanned round-robin — fairness by rotation, not by hash. Cluster is the right
primitive here rather than worker threads because the processes are fault-
isolated: one crashing or pausing does not take its siblings down. The runnable
proof is `echo/fx/examples/cluster-hcr.mjs`, which fans branded-id minting and
the fused primitive across the cores and asserts the minted ids are disjoint and
collision-free. The standing caution is to cap the worker count near the physical
core count, since oversubscription trades throughput for context-switching.

**R4 — hot code replacement on more than one core (shipped as a demo).** A
rolling reload brings a fresh generation of workers online before draining the
previous one, so there is never a window with zero workers serving. Each
generation occupies a fresh band of node ids, so a reload never reuses a live id.
The same harness demonstrates it: generation one comes online while generation
zero is still serving, work shifts to the new generation, and only then is the
old generation drained. Gate: the harness asserts zero dropped work and zero id
collisions across the reload.

## A decision guide

- Reach for **neverthrow** when the need is typed errors at a boundary and a
  short ramp — the default for the Mercury surface today.
- Add **ts-pattern** when a tagged union needs exhaustive dispatch and a missed
  case should be a compile error.
- Reach for **Effect** when a larger surface needs structured concurrency,
  dependency injection, and observability as one system, and the team can carry
  the weight and the ramp.
- Reach for the **`@echo/fx` wasm kernel** when the work is a pure, fixed-shape
  computation the runtime makes expensive — a codec, a hash, a fused numeric
  pipeline — and keep the seam coarse-grained.

## References

- Effect versus fp-ts, and the fiber-runtime bundle framing:
  `https://effect.website/docs/additional-resources/effect-vs-fp-ts/`
- Effect monorepo and the `@effect/sql` Drizzle integration:
  `https://github.com/Effect-TS/effect`
- The fp-ts into Effect merger announcement:
  `https://dev.to/effect/a-bright-future-for-effect-455m`
- fp-ts repository and higher-kinded-type note:
  `https://github.com/gcanti/fp-ts`
- Effect versus fp-ts versus neverthrow, downloads, learning curve, schema
  migration: `https://www.pkgpulse.com/guides/effect-ts-vs-fp-ts-2026`
- A team's pragmatic case for neverthrow over Effect, with the boundary-friction
  example: `https://runharbor.com/blog/2025-11-24-why-we-dont-use-effect-ts`
- neverthrow API (Result, ResultAsync, safeTry, eslint plugin):
  `https://github.com/supermacro/neverthrow`
- ts-pattern API and the TC39 pattern-matching proposal status:
  `https://github.com/gvergnaud/ts-pattern`
- Library positioning across fp-ts, neverthrow, ts-results, ts-toolbelt:
  `https://npm-compare.com/fp-ts,neverthrow,ts-results,ts-toolbelt`
- Proper tail calls in JavaScript, V8's removal and the syntactic-tail-call
  proposal: `https://mgmarlow.com/words/2021-03-27-proper-tail-calls-js/`
- The unimplemented proper-tail-call standard and engine differences:
  `https://eriklangille.com/blog/proper_tail_calls.html`
- Tail-call optimization across runtimes, including the BEAM's automatic form:
  `https://www.rabinarayanpatra.com/blogs/tail-call-optimization-explained`
- V8 hidden classes, inline-cache states, and deoptimization (glossary):
  `https://sujeet.pro/articles/v8-engine-architecture`
- Hidden classes and inline caching in practice:
  `https://dev.to/maxprilutskiy/hidden-classes-the-javascript-performance-secret-that-changed-everything-3p6c`
- Node cluster versus worker threads, shared memory, and parallelism caps:
  `https://medium.com/@ThinkingLoop/node-js-workers-vs-cluster-pick-the-faster-one-5c1b067b0432`
- Node worker threads, SharedArrayBuffer, Atomics, and the ESM/CJS worker
  pitfall: `https://teachmeidea.com/nodejs-worker-threads-cpu-intensive-tasks/`
- Node Cluster API reference:
  `https://nodejs.org/api/cluster.html`
