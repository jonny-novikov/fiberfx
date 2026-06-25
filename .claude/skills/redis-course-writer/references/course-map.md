# Redis Patterns Applied — course map

The course "Redis Patterns Applied" is served at **`/redis-patterns`** (folder-routed via `serveDirTree`; the URL
tree mirrors `html/redis-patterns/`). "Applied" means **applied to the BCS architecture** — the real as-built echo
data layer: **EchoMQ** backed by **Valkey** (`echo/apps/echo_mq/` + the owned client `echo/apps/echo_wire/`),
**EchoStore** in front (`echo/apps/echo_store/`), worked through the **codemojex** consumer
(`echo/apps/codemojex/` — `Codemojex.Guesses` / `Codemojex.Board` / `Codemojex.ScoreWorker`). The **home**
(`html/redis-patterns/index.html`) and **every chapter landing** are **route manifests that reach a FULL
links-PASS** (the BCS philosophy — no fail-by-design): a built chapter/module is an anchor card `<a class="mod">`,
an unbuilt one a **non-anchor** card `<div class="mod">` with the `soon` pill; every lesson/hub page keeps all
internal links resolving.

**Design system:** the BCS contract-sheet identity with the redis-red `#d6584f` accent — the light-paper `--b-*`
tokens + `--r-red`, mono-forward SYSTEM fonts (nothing fetched), `figure.frozen` evidence blocks, the 14-cell
`.idrule`, `.sech` section headers. The identity authority is
`docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md`; the model to copy is
`html/redis-patterns/index.html`. The reframe is in progress: R0–R2 are reframed + reconciled (the contract-sheet
identity); R3–R4 await their reframe rungs (`re4`–`re5`) — never copy identity from an unreframed page.

**The authoritative structural map is the TOC** (`docs/redis-patterns/redis-patterns.toc.md`); this file is the
skill-side digest. The grounding map (which pattern lands where) is authoritative in
`docs/redis-patterns/redis-patterns.roadmap.md`; what may be **quoted** is the **real as-built echo data layer**
(`echo/apps/echo_mq/`, `echo/apps/echo_store/`, `echo/apps/echo_wire/`, `echo/apps/codemojex/`), supplemented by the
committed BCS manuscript figures the reframe contract's figure inventory licenses (`docs/echo/bcs/content/bcs3.*` /
`bcs4.*` / `bcsA.md` + `docs/echo_mq/emq.design.md`) — cite them, never invent, **never a `.out` rung transcript
or a gate dump**.

## Numbering — three levels, `R<chapter>.<module>.<dive>`

- **Chapter** `R[N]` → a landing page. Routes are the semantic `specs/` folder slugs, not positional
  (`/redis-patterns/caching`, not `/r1`).
- **Module** `R[N].[M]` (two-digit M) → a hub, nested under the chapter dir (`/redis-patterns/caching/<module>`).
- **Dive** `R[N].[M].[S]` (single-digit S) → a deep-dive inside the module
  (`/redis-patterns/caching/<module>/<sub>`).

R0 (`overview/`) is the orientation chapter: the **home** is `/redis-patterns` (`index.html`, the full
chapter→module map); the **overview landing** is `/redis-patterns/overview` (`overview/index.html`, R0's module
cards + an "Up next" grid). R0 is taken **deep** in the spec system — a chapter index + `r0.md` roadmap + per-module
**quads** (`r0.M.md` / `.stories.md` / `.llms.md` / `.prompt.md`) — the exemplar later chapters follow.

## The chapter-landing anatomy (R1–R8)

Each pattern chapter's landing is the teaching arc: **overview → why & when (use cases) → what (the patterns, as
module cards) → how to apply → the EchoMQ exemplar workshop module**, closing with an **"Up next" grid** of the
chapters that follow. The chapter's modules are its pattern family; the workshop is the capstone that applies the
chapter's pattern family to the BCS build.

## The chapters

| Chapter | Title | Landing route | Dir | Grounding | Status |
|---|---|---|---|---|---|
| R0 | Overview — the catalog, the BCS thesis | `/redis-patterns` (home) + `/redis-patterns/overview` | `overview/` | the BCS thesis (EchoMQ backed by Valkey, EchoStore in front; the codemojex consumer) | **built; reframed by `re0` (home + overview landing + R0.3) except R0.2 — rung `re1`** |
| R1 | Caching | `/redis-patterns/caching` | `caching/` | EchoStore (`echo/apps/echo_store/`; `bcs4.*` figures) | **built + reconciled — contract-sheet, gated PASS (29 pp)** |
| R2 | Coordination & Consistency | `/redis-patterns/coordination` | `coordination/` | the claim script, the `attempts` fencing token, the co-location law → EchoMQ (`echo/apps/echo_mq/`) | **built + reconciled — contract-sheet, doors → `/echomq/protocol`, gated PASS (22 pp)** |
| R3 | Reliable Queues | `/redis-patterns/queues` | `queues/` | the EchoMQ state machine (the lanes, the verbs, reap) → EchoMQ (`echo/apps/echo_mq/`) | **built — dark-editorial until `re4`** |
| R4 | Time, Delay & Priority | `/redis-patterns/time-delay-priority` | `time-delay-priority/` | the schedule set (run-at scores, promote) → EchoMQ (`echo/apps/echo_mq/`) | **built — dark-editorial until `re5`** |
| R5 | Streams & Events | `/redis-patterns/streams-events` | `streams-events/` | per the roadmap's grounding map, settled against the as-built echo data layer at authoring | **chapter spec authored; pages planned — born reframed** |
| R6 | Flow Control & Scale | `/redis-patterns/flow-control` | `flow-control/` | per the roadmap's grounding map, settled against the as-built echo data layer at authoring | **chapter spec authored; pages planned — born reframed** |
| R7 | Data Modeling & Memory | `/redis-patterns/data-modeling` | `data-modeling/` | per the roadmap's grounding map, settled against the as-built echo data layer at authoring | **chapter spec authored; pages planned — born reframed** |
| R8 | Production & Operations | `/redis-patterns/production-operations` | `production-operations/` | per the roadmap's grounding map, settled against the as-built echo data layer at authoring (capstone) | **chapter spec authored; pages planned — born reframed** |

All 30 catalog patterns are placed once across R1–R8 (Fundamental ×20, Community ×6, Production ×4); the per-module
abstracts, dives, and grounding are in the TOC and the chapter specs.

## The grounding boundary (the no-invent rule)

A redis-patterns module teaches a transferable Redis technique proven by **one real excerpt**, verbatim from a
real as-built surface — `echo/apps/echo_mq/`, `echo/apps/echo_store/`, `echo/apps/echo_wire/`,
`echo/apps/codemojex/` (or a committed BCS figure `docs/echo/bcs/content/bcs3.*` / `bcs4.*` / `bcsA.md`,
`docs/echo_mq/emq.design.md`): a real EchoMQ key (`emq:{q}:` form), a script verb, the `attempts` fencing token,
an EchoStore figure, an `Codemojex.*` consumer call, or a Valkey-documented command. **Never a `.out` rung
transcript or a "PASS N/N" gate dump — those are not course material; teach the PATTERN from the real code.** EchoMQ
implementation *depth* (the full Lua bundle, the version-fence internals, the protocol governance) belongs to the
dedicated **EchoMQ course** (`/echomq`); chapters R2–R6 and R8 link forward to it. Never fabricate a Redis/Valkey
command, Lua script, EchoMQ module, or echo-data-layer / `Codemojex.*` surface — **verify on disk in
`echo/apps/`**. **NO mention of BullMQ at all:** the course contains zero BullMQ references — no lineage note, never
"BullMQ-compatible", never the `bull:` keyspace, never bullmq.io in Sources, never "EchoMQ 2.0" as a recurring
label, **never Dragonfly** (the engine is **Valkey only**). `redlock` and `probabilistic-data-structures` are
taught as **contrasts**, not as EchoMQ features.

## Resume point

**R0–R4 are BUILT** (111 pages; the spec system, the server wiring, and the Stage-3 authoring through R4 are
done). The course is now in the **reframe** (`docs/redis-patterns/specs/reframe-echomq/` — the contract +
roadmap): **`re0` SHIPPED** — the home + the overview landing + the R0.3 `patterns-become-protocol` module (hub +
3 dives) reframed to the contract-sheet identity; those six pages are the models every later reframed page copies.

**Resume = `re1`**: reframe **R0.2** `redis-under-game` (hub + 3 dives, + the R0 `llms.txt` sync) — R0 complete.
Then **`re2`–`re5`** reframe R1–R4 chapter by chapter (caching → coordination → queues → time-delay-priority);
**`re2`/`re3` (R1/R2) are reconciled — contract-sheet, gated PASS, R2 doors retargeted to `/echomq/protocol`; the
frontier is `re4` (R3 queues)**.
**R5–R8** are authored **born reframed** from their chapter specs once the reframe absorbs (RM4). Author every
page **specs-first**; never ahead of the spec.
