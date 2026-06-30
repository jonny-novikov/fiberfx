# Mercury · JavaScript engines and runtimes for the echo surface
<show-structure depth="2"/>

The previous research piece (`docs/effective-ts-fp-wasm.md`) named a hard limit:
the recursion-heavy functional style that the type system rewards is unsafe on
the runtime Mercury defaults to, because V8 removed proper tail calls and a
tail-recursive function still grows the stack until it overflows. That limit is
not a property of JavaScript the language; it is a property of the engine. A
different engine changes the answer.

This piece works through the engine question for echo. It starts with the one
engine that ships proper tail calls — JavaScriptCore, the engine under Bun — and
why that matters for the functional core. It then sets the server runtimes side
by side (Node, Bun, Deno, and the edge option), works through the cold-start tier
that fits ephemeral FLAME-style jobs (LLRT and QuickJS), and ends with a proposed
engine strategy for echo. Throughout, one fact from the prior piece holds the
shape together: the `@echo/fx` compute kernel is WebAssembly, so it loads on every
one of these runtimes, and the engine choice is about the JavaScript surface, not
the kernel.

## The engine landscape

A JavaScript runtime is a JavaScript engine plus a platform layer (I/O, modules,
host APIs). The engine decides the two properties that matter here: whether tail
calls are eliminated, and how it trades startup latency against sustained
throughput. The table separates the engines that show up in server and embedded
use.

| Engine | Execution model | Proper tail calls | Startup | Strong at | Seen in |
|---|---|---|---|---|---|
| V8 | multi-tier JIT | no (removed) | slower | sustained throughput | Node, Deno, workerd |
| JavaScriptCore | interpreter + tiered JIT | yes (strict mode) | fast | startup and throughput | Bun, Safari |
| SpiderMonkey | JIT | no (removed) | medium | browser workloads | Firefox, WinterJS |
| QuickJS / quickjs-ng | bytecode interpreter, no JIT | no | very fast | tiny footprint, embedding | LLRT, txiki.js |
| Hermes | AOT bytecode, no JIT | no | very fast | mobile startup and memory | React Native |
| GraalJS | JIT on the JVM (Graal) | no | slow warmup | Java interop, peak throughput | GraalVM hosts |

Two engines run hot code through a JIT and pay a warmup cost for it (V8,
GraalJS). Two precompile or interpret bytecode and stay small and fast to start
at the cost of peak compute (QuickJS, Hermes). JavaScriptCore sits in the middle:
it interprets bytecode first for a fast start, then tiers up frequently executed
paths through successive JIT stages, so it gets a quick start and competitive
sustained throughput. It is also the only engine in the table that eliminates
tail calls.

## JavaScriptCore and proper tail calls

Proper tail calls were specified in ECMAScript 2015: a call in tail position
reuses the current stack frame instead of pushing a new one, so a tail-recursive
loop runs in constant stack space. The specification placed the behavior in
strict mode only, because the frame elimination removes the call-stack
information that the legacy `arguments` and `caller` introspection relied on.

Of the major engines, JavaScriptCore is the one that shipped it and kept it.
Apple's position to the committee was that tail calls are part of the standard and
a compliant engine should implement them, and that making them opt-in by syntax
would break pages already written against the implicit behavior. V8 implemented
the feature behind a flag and then removed it; SpiderMonkey removed it as well.
The result is that on Safari and on any runtime built on JavaScriptCore, a
correctly tail-recursive function in strict mode runs without growing the stack,
and on V8-based runtimes the same function overflows at depth.

Bun is built on JavaScriptCore, so it inherits this. A continuation-passing
traversal of a tree a million levels deep, run under Bun in strict mode, returns
without a stack overflow; the same code under a V8 runtime raises a range error
at depth. JavaScriptCore even exposes an explicit tail-call bytecode intrinsic
internally, which is the mechanism the elimination rides on.

There is one prerequisite that echo already meets and one caveat that echo must
respect.

The prerequisite is strict mode. Tail-call elimination only happens in strict
mode, and an ES module is strict by default. The echo surface — the admin and the
`@echo/fx` facade — is ESM and TypeScript, so it is already in strict mode and
would get the behavior on a JavaScriptCore runtime without any extra annotation.

The caveat is portability, and it is the reason this stays a deliberate decision
rather than a default. Tail recursion is a property of the shape of a function;
stack reuse is a property of the engine running it. A function that is perfectly
tail-recursive still consumes a frame per call on the engines that never adopted
the feature. If echo writes its functional core to depend on tail-call
elimination and then runs any part of it on a V8 runtime — Node for a
compatibility fallback, Deno at an edge, a Lambda — the same code overflows. So
the discipline is: depth-bounded recursion is fine anywhere; unbounded recursion
that relies on elimination is safe only where the engine is pinned to
JavaScriptCore, and a portable build keeps a trampoline or an explicit loop as
the fallback. This is the same NO-INVENT caution applied to a runtime feature:
the property has to be true on the engine in front of you, not assumed from the
language.

## The server runtimes, side by side

Three runtimes are in scope for the always-on echo surface, plus an edge option.
The differences come down to the engine, the implementation language, the I/O
layer, and the ecosystem around them.

| Dimension | Node.js | Bun | Deno |
|---|---|---|---|
| Engine | V8 | JavaScriptCore | V8 |
| Implementation | C++ | Zig | Rust |
| I/O layer | libuv | io_uring on Linux | Tokio |
| Proper tail calls | no | yes (strict mode) | no |
| Cold start | slowest | fastest | middle |
| Idle memory | highest | lowest | middle |
| npm compatibility | full (2M+ packages) | ~95% | ~95% (Deno 2) |
| Security default | full access | full access | permissioned |
| Native addons | N-API and node-gyp | N-API (V8-direct addons fail) | FFI plus partial N-API |
| Built-in toolchain | partial (v24) | bundler, test, package manager | formatter, linter, test, package manager |
| WebAssembly | yes | yes | yes |

**Node.js** runs on V8 with a C++ core and libuv. It is the compatibility and
maturity baseline: the full npm registry, the deepest set of native addons, the
profilers and operational tooling the ecosystem assumes, and long-term-support
releases. Its costs are the slowest cold start of the three and the largest idle
memory, both inherited from V8's optimize-for-long-running design. The Cluster and
worker-thread model that the existing `@echo/fx` scheduler harness is written
against is Node's, and it is the most battle-tested of the three.

**Bun** runs on JavaScriptCore with a Zig core and `io_uring` on Linux. It is the
performance and startup option: the fastest cold start, the lowest idle memory,
and a single binary that also carries a bundler, a test runner, a package
manager, and native SQLite, PostgreSQL, and Redis-protocol clients. It aims to be
a drop-in Node replacement and reaches roughly ninety-five percent API
compatibility. The remaining few percent is where the risk lives: packages built
as V8-targeted C++ addons do not load, because JavaScriptCore and V8 are
binary-incompatible at the addon ABI, and some worker-thread edge cases differ.
Bun has production adopters and, per 2026 reporting, recent institutional
backing through its acquisition, which lowers the bet on its longevity. For echo
specifically, Bun is the one runtime that resolves the tail-call problem and
starts fast, which makes it the natural candidate for the surface — with the
compatibility gap as the thing to test against the actual dependency set.

**Deno** runs on V8 with a Rust core and Tokio. It is the security and
web-standard option: permissions are denied by default and granted explicitly, so
a compromised dependency cannot reach the network or the file system without a
flag; TypeScript runs natively with an optional type check; the APIs follow web
standards; and a formatter and linter ship in the box. Deno 2 restored full
`package.json` and `node_modules` support, so it can run most Node projects. Being
V8-based, it does not get tail-call elimination. Its first-party edge platform is
a strong fit for latency-sensitive functions.

The candid framing on raw speed: the headline throughput gaps between these
runtimes are measured on hello-world HTTP handlers that exercise the networking
hot path. Once a real workload puts Postgres and ValKey in the request, runtime
overhead falls to a small fraction of total request time, and the three converge.
For echo the runtime choice is therefore driven less by requests-per-second and
more by the tail-call property, cold start for ephemeral jobs, the native-client
and addon story, and operational maturity.

A fourth option, **workerd**, is the V8-isolate server that powers Cloudflare
Workers and can be self-hosted. It uses isolates rather than processes, so it has
very low cold start and is not billed per duration, at the cost of a
worker-shaped programming model and the same V8 tail-call limitation. It is an
edge option, not a general server, but it is the right reference for the
isolate-per-request model.

## The cold-start tier for ephemeral jobs

The echo roadmap includes ephemeral FLAME-style job execution: short-lived
machines spun up to run a unit of work and then torn down. For that shape, cold
start dominates the cost, and a different tier of runtime applies — one that drops
the JIT entirely to start in single-digit milliseconds.

**LLRT** (Low Latency Runtime, from AWS Labs) is the clearest example. It is built
in Rust on the QuickJS engine, deliberately omits a JIT compiler, and bundles its
host APIs and AWS SDK clients into the binary so there are no module lookups at
start. The reported effect on Lambda is up to ten times faster startup and around
half the cost of a Node runtime; one published test moved an init from roughly
seven hundred fifty milliseconds to about fifty-five. The deliberate tradeoff is
compute: without a JIT, QuickJS is far slower than V8 on heavy numeric work — a
jitless V8 is on the order of three times faster than QuickJS, and a JIT-enabled
V8 around thirty times faster — so LLRT's own guidance is to use it for small
glue functions (transformation, validation, service integration, authorization)
and not for large data processing or millions of iterations. It is ESM-only,
implements a subset of the Node APIs, and is explicitly experimental, with
WinterCG compliance as a stated goal.

**QuickJS** itself, and its maintained fork **quickjs-ng**, is the engine
underneath this tier: a capable, embeddable interpreter that compiles to well
under a megabyte against V8's tens of megabytes, with a runtime instance whose
full life cycle completes in microseconds. It is the engine in LLRT, in the
`txiki.js` runtime (QuickJS-ng plus libuv, and notably a bundled `wasm3` for
WebAssembly and `libffi` for native calls), and in numerous embedded hosts.
**Hermes**, Meta's engine for React Native, sits in the same no-JIT,
fast-start, low-memory bracket but is aimed at mobile rather than the server.

The synthesis for echo follows directly from the compute tradeoff. A
QuickJS-class runtime is the right shell for an ephemeral job because it starts in
milliseconds, but it is the wrong place to run the scoring and the fused numeric
pipelines, because it has no JIT. Those are exactly the computations the `@echo/fx`
WebAssembly kernel already holds. So an ephemeral echo job is a thin QuickJS or
isolate shell that does the I/O and the orchestration and delegates the compute to
the wasm kernel — fast to start and fast at the math, with neither property
asked of the part of the system that cannot provide it.

## echo/fx and the kernel across engines

The reason the engine choice does not fork the codebase is that the compute
kernel is WebAssembly. Node, Bun, Deno, and workerd all run wasm; `txiki.js` runs
it through a bundled interpreter. The `@echo/fx` codec, Snowflake minter, routing
hash, and fused primitive load and run on every one of them, so moving the surface
between engines does not require porting the kernel. This is the payoff of the
prior piece's decision to put the hot, fixed-shape computation in Rust behind a
coarse wasm seam rather than in TypeScript.

The native-addon picture is where the engines diverge, and it is worth stating
plainly because it shapes the kernel's packaging. N-API is ABI-stable by design,
so an N-API native module works across Node and Bun; an addon written against V8
directly does not cross to JavaScriptCore. A wasm module sidesteps the question
entirely — it is engine-neutral by construction. For echo this means the kernel
stays portable as wasm; an N-API build would be a Node-and-Bun optimization, not a
portable default, and a V8-direct addon would pin the surface to V8. The
foreign-function paths differ too (`bun:ffi`, Deno's FFI, `libffi` in `txiki.js`),
but they are runtime-specific and are not the portable route the kernel takes.

One portability note on the scheduler rather than the kernel, now validated: the
compute pool forks one process per core with `node:child_process`, which both Node
and Bun implement, so the same pool runs on either runtime with no branch — the
typed pool and its hot-code-replacement reload pass on both. The earlier
`node:cluster` harness was checked too and carries onto Bun unchanged. The caution
the tail-call section raises about the process model is, for this pool, discharged
by running it on both engines rather than assuming the move.

## A proposed engine strategy for echo

This is the intended shape, marked PROPOSED because it is a direction, not shipped
configuration. Each rung names the runtime, the reason, and the gate that would
keep it grounded.

- **The always-on surface: Bun (JavaScriptCore), proposed.** It is the one runtime
  that gives the functional core tail-call elimination in the strict-mode ESM the
  surface already uses, and it starts fast and carries native PostgreSQL and
  ValKey clients. Gate: run the existing admin and its full dependency set under
  Bun and confirm the roughly five-percent compatibility gap does not touch a
  required package — the database drivers and any native addon in particular.
- **The compatibility fallback: Node.js (V8).** Where a dependency needs a
  V8-targeted addon or an unported API, Node remains the baseline, and the surface
  must stay runnable on it. Gate: the functional core keeps a trampoline or an
  explicit-loop fallback so that unbounded recursion does not depend on tail-call
  elimination, since Node will not provide it.
- **Ephemeral FLAME jobs: a QuickJS-class runtime (LLRT) or V8 isolates
  (workerd), proposed.** For short-lived job machines, cold start dominates, and a
  no-JIT runtime starts in milliseconds. Gate: the job shell does I/O and
  orchestration only and delegates all compute to the `@echo/fx` wasm kernel,
  because QuickJS without a JIT is the wrong place for the scoring math.
- **The compute kernel: WebAssembly, everywhere.** `@echo/fx` stays wasm so it
  loads unchanged on whichever runtime the surface or a job runs on. Gate: the
  codec and minter parity checks (`cargo test`, and the `hash32` reconciliation
  against the canonical NIF) hold regardless of the host engine.
- **Security-sensitive or edge surface: Deno or workerd.** Where untrusted code or
  an edge deployment is in play, Deno's permission model or a Cloudflare isolate
  fits. Gate: neither path may carry unbounded tail-recursive code, as both are
  V8-based.

The single thread through all five: pin the engine where a property is required
(JavaScriptCore for tail calls, a no-JIT engine for cold start), keep the kernel
engine-neutral as wasm, and never let correctness depend on an optimizer behavior
that is not guaranteed on the engine running the code.

## A decision guide

- Recursion-heavy functional core that wants tail-call safety in JavaScript →
  **Bun / JavaScriptCore**, with a trampoline fallback for portability.
- Maximum npm and native-addon compatibility, deepest operational tooling →
  **Node.js**.
- Untrusted dependencies, a permission boundary, web-standard APIs →
  **Deno**.
- Ephemeral, short-lived job where cold start is the cost → **LLRT / QuickJS** or
  **workerd** isolates, delegating compute to the kernel.
- Hot, fixed-shape computation regardless of host → the **`@echo/fx` wasm
  kernel**.

## References

- JavaScriptCore's tail-call position and the engine differences (TC39 issue):
  `https://github.com/tc39/ecma262/issues/535`
- Tail-call elimination is strict-mode only, and why (the introspection
  conflict): `https://2ality.com/2015/06/tail-call-optimization.html`
- Proper tail calls supported in Safari/WebKit, not V8 or SpiderMonkey:
  `https://www.stefanjudis.com/today-i-learned/proper-tail-calls-in-javascript/`
- Bun does tail-call elimination in strict mode where V8 runtimes overflow (CPS
  example): `https://jnkr.tech/blog/cps-in-ts`
- A V8 runtime overflows on a tail-recursive function that JavaScriptCore handles:
  `https://www.onsclom.net/posts/javascript-tco`
- JavaScriptCore's explicit tail-call bytecode intrinsic (Bun engineer):
  `https://news.ycombinator.com/item?id=38824492`
- The portability caveat — tail-recursive shape is not stack-safe across runtimes:
  `https://blog.gaborkoos.com/posts/2026-05-09-Your-Recursion-Is-Lying-to-You/`
- Bun runtime: JavaScriptCore engine, Zig, fast start, native clients:
  `https://bun.com/docs/runtime`
- Node vs Bun vs Deno: engines, implementation languages, I/O models, cold start:
  `https://dev.to/jsgurujobs/bun-vs-deno-vs-nodejs-in-2026-benchmarks-code-and-real-numbers-2l9d`
- Runtime comparison: npm compatibility, security model, addon ABI limits:
  `https://byteiota.com/javascript-runtime-performance-2026-bun-vs-node-js-vs-deno/`
- Cold-start and serverless framing across the runtimes:
  `https://daily.dev/blog/javascript-runtimes-bun-vs-node-js-vs-deno-comparison/`
- Runtime overhead is a small fraction once a database is in the request:
  `https://tech-insider.org/bun-vs-node-2026/`
- LLRT: Rust plus QuickJS, no JIT, faster cold start, serverless focus (AWS Labs):
  `https://github.com/awslabs/llrt`
- LLRT's compute tradeoff vs V8 (jitless and JIT multipliers) and its niche:
  `https://www.infoq.com/news/2024/02/aws-llrt-lambda-experimental/`
- QuickJS-ng, the maintained fork of the embeddable engine:
  `https://github.com/quickjs-ng/quickjs`
- GraalJS, the JVM-hosted engine with Java interop:
  `https://www.graalvm.org/latest/reference-manual/js/`
- Hermes's AOT-bytecode, no-JIT, fast-start model vs V8 and JavaScriptCore:
  `https://balevdev.medium.com/understanding-javascript-engines-a-dive-into-hermes-webkit-and-v8-59f9d8529fae`
- An index of engines and runtimes (txiki.js with QuickJS-ng, wasm3, libffi;
  workerd; WinterJS): `https://gist.github.com/guest271314/bd292fc33e1b30dede0643a283fadc6a`
