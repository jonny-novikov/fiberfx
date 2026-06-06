# Specs → chapter authoring — the redis-patterns spec system

> The contract for the **redis-patterns** course spec system: how a course of static HTML pages is designed as
> specs first and built second. It works in two layers — a **roadmap** that plans how the chapters ship, and a
> **per-chapter spec** that defines each chapter's module ladder and the dives that realize it — over one
> structural map, the **TOC**. A chapter is specified, its modules and dives are named with their pattern and their
> real grounding, and only then are pages authored against it. The aim is a course that is grounded (every pattern
> shown applied in real code, never invented), structured (one consistent chapter→module→dive shape), and correct
> by construction (no page exists that the spec did not first define).

This file is the contract for the spec system itself; every chapter conforms to it. It extends the
[`docs/agile-agent-workflow/`](../../agile-agent-workflow/agile-agent-workflow.toc.md) course patterns and takes
the shape of [`docs/elixir/specs/`](../../elixir/specs/specs.approach.md) — *specs per chapter, a folder of specs
per chapter*. Where the elixir specs define an engine rung by rung (`fN.M` triads), this system defines a course
chapter by chapter (`R[N]` chapter specs), because the artifact is teaching pages, not running code.

## Why this exists

A course of ~46 modules over ~140 pages cannot be authored coherently page by page from memory. The pages would
drift — in structure, in voice, and most dangerously in their worked examples, where an unguided author invents a
Redis API or a Portal surface that does not exist. This spec system fixes the structure and the grounding **before**
any page is written:

- **Design before build.** The chapter→module→dive tree, the pattern each page teaches, and the real artifact each
  page is grounded in are settled in the specs. Page authoring then expands a spec faithfully; it never decides
  structure. (The discipline is the one [`echo/CLAUDE.md`](../../../echo/CLAUDE.md) records for the Portal engine:
  the spec is the source of truth, and authoring ahead of the spec drifts in lockstep.)
- **Grounding, written down.** Each module names the real EchoMQ key, command, Lua script, or Go function it is
  shown in (or the Portal surface, where the pattern is not an EchoMQ one), so the worked example is verifiable, not
  plausible. This is the antidote to the agent failure mode the course exists to correct (see the
  [README](../README.md)).
- **One shape, enforced.** Every chapter index, module hub, and dive has the same anatomy and the same mechanical
  gates, so the course reads as one work.

## What the course is

**redis-patterns** teaches Redis **design patterns** — the judgement layer above the command reference — and
grounds each pattern in how a real system applies it. The running system is **EchoMQ-in-Portal**: EchoMQ is a
polyglot (Elixir/Go/Node.js) job-queue built on the BullMQ protocol, the candidate for **Portal's reserved F7–F9
multi-runtime layer** ([`portal.roadmap.md`](../../elixir/specs/portal.roadmap.md)). Its governing fact — *"the
BullMQ Lua scripts ARE the protocol"* — makes it an almost one-to-one corpus of Redis patterns frozen into an
immutable Redis data layer (L1) and Lua-script layer (L2). So the course doubles as a guided reading of how those
patterns build a real queue, and it **opens the door to a separate, dedicated EchoMQ course** that teaches the
polyglot protocol itself.

The course is served folder-routed at **`/redis-patterns`** by the jonnify Fiber server (`serveDirTree`; the URL
tree mirrors `html/redis-patterns/`, read from disk live — a new `.html` is live on save, no rebuild).

## The three levels — `R[chapter].[module].[dive]`

The course mirrors the elixir/AAW three-level nesting:

- **Chapter** `R[N]` (R0…R8) — a top-level section with a **landing** page `<chapter>/index.html` (route
  `/redis-patterns/caching`). Its spec is `specs/<chapter>/<chapter>.md`.
- **Module** `R[N].[M]` (two-digit M) — a chapter *has* modules; each is a **hub** `<chapter>/<module>/index.html`
  (route `/redis-patterns/caching/cache-aside`) that lists its dives.
- **Dive** `R[N].[M].[S]` — each module has **≥3** deep-dive subpages `<chapter>/<module>/<sub>.html` (the "Dives
  into" list on the hub). A chapter closes with a **workshop** module that advances the running EchoMQ/Portal build.

R0 (Overview) is the course landing — the home `index.html` plus the re-themed catalog `overview/course.html`; it
has no `specs/` folder and is mapped in the [TOC](../redis-patterns.toc.md) and
[roadmap](../redis-patterns.roadmap.md).

## The artifacts

| Artifact | Scope | Role |
|---|---|---|
| [`redis-patterns.toc.md`](../redis-patterns.toc.md) | the course | the **TOC** — the full chapter→module→dive tree + per-module abstracts + build status; the living structural map |
| [`redis-patterns.roadmap.md`](../redis-patterns.roadmap.md) | the course | the **program roadmap** — the chapter sequence as the EchoMQ-build arc, milestones, dependencies, and the →EchoMQ-course door |
| `redis-patterns.md` (this file) | the course | the **contract + index** — the spec-system rules and the chapter map |
| `specs/<chapter>/<chapter>.md` | one chapter | the **chapter spec** — the module ladder (module · pattern · what it adds · grounding · dives), the start/end handoff, the EchoMQ theme + door, conventions |

The TOC is the map; the roadmap is the plan; the chapter spec is the contract a page-authoring batch builds from.

## The "Redis Pattern Applied" grounding rule (the boundary)

Every module declares its **grounding** — the real artifact its worked example is drawn from — and stays inside
this boundary:

- **A redis-patterns module** teaches a transferable Redis technique (a data structure + a command + an atomic Lua
  move) and proves it with **one tight, real excerpt**: a real EchoMQ key (`bull:{queue}:wait`), command
  (`RPOPLPUSH`, `XADD … MAXLEN ~`), Lua script (`moveToActive`, `ExtendLock`), or Go function
  (`apps/echomq-go/pkg/echomq/scripts/scripts.go`), or — where the pattern is not an EchoMQ one (the cache and
  modeling families) — a Portal surface or a clean standalone example. The lesson survives deleting EchoMQ.
- **The dedicated EchoMQ course** owns what only makes sense *with* EchoMQ: the full Lua inventory, the polyglot
  runtimes, the protocol governance. A redis-patterns module that drifts into those is over-scope; it links forward
  to the EchoMQ course instead.

**No invention.** Cite only real surfaces. The Redis grounding map (which pattern → which real key/command/Lua/Go
function) is fixed in the [roadmap](../redis-patterns.roadmap.md) and the per-chapter specs; do not invent an EchoMQ
module, a Lua script, a Redis command, or a Portal API that the sources do not contain. `redlock` is taught as a
**contrast** to EchoMQ's single-Redis lease, not as something EchoMQ implements; exact deduplication (`de:{id}`) is
the **contrast** that motivates probabilistic structures.

## From spec to pages — the authoring pipeline (a later stage)

Page authoring (a separately-approved stage) expands a chapter spec into pages, never the reverse:

1. **Author the module hub** `<chapter>/<module>/index.html` from the module's spec entry.
2. **Author each dive** `<chapter>/<module>/<sub>.html` — a full lesson: the pattern, a worked example on the
   module's real grounding, an interactive, the principle↔practice bridge, a recap, References, a pager.
3. **Relink the chapter landing** and **sync the TOC** so the views agree.
4. **Gate every page** to STATUS: PASS, then adversarially verify the gate-invisible bits.

Pages are drafted md-source-first where the elixir/AAW kits do, and built by the toolkit under
[`toolkit/`](../toolkit/) (a later stage). None of this stage authors pages.

## Quality gates — the mechanical checks

Every page passes the **ten jonnify-cms gates** before it ships (`apps/jonnify-cms/bin/cms check`): `containers` ·
`svg` · `no-future` · `voice` · `storage` · `motion` · `degrade` · `links` · `pager` · **`refs`** (opt-in via
`--require-refs`). The command form for this course:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /redis-patterns=html/redis-patterns \
  --chapter-alias r1=caching,r2=coordination,r3=queues,r4=time-delay-priority,r5=streams-events,r6=flow-control,r7=data-modeling,r8=production-operations \
  --require-refs html/redis-patterns/<path>.html
```

Two checks the gates cannot see, verified by reading: **clamp spacing** (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` —
spaces around `+`/`-`, or the declaration drops to a UA default), and **right-route-vs-resolvable** (the `links`
gate proves an href resolves, not that it is the intended parent — read crumbs and pager). The spec docs themselves
pass the same **voice** gate: no first person, no exclamation, no emoji, and none of `revolutionary`, `blazing`,
`magical`, `simply`, `just`, `obviously`, `effortless`; no perceptual or interior-state verb applied to a tool or
an agent.

## The two mandatory layout rules (page-level; enforced when pages are built)

1. **Clickable segmented route-tag.** The header `.route-tag` renders each path part as its own element —
   intermediate parts are `<a href>` to that route level, the current part is `<span class="rcur">`, separated by
   `<span class="rsep">/</span>`; `/redis-patterns` is one segment.
2. **Canonical 3-column footer.** `<footer class="site-foot">` → `.foot-cols` + `.foot-bottom` carrying the
   `.stamp` + decoder (verbatim; a valid `TSK…` Snowflake id). Copy the head/header/footer/scripts verbatim from a
   built model page; change only `<title>`/`<meta>`, the route-tag, and `<main>`.

## The `<chapter>.md` template

```text
# R[N] · <Chapter title> — <the pattern family>
> <one- or two-sentence value statement: what this chapter teaches and what it builds on the EchoMQ/Portal run>.

## Where this chapter starts and ends
- Start — <the prior chapter's handoff; the patterns assumed>.
- End — <the capability the reader has; the running build advanced>.

## The grounding (Redis Pattern Applied)
<the chapter's EchoMQ/Portal theme: the real keys/commands/Lua/Go functions its modules draw on, and the boundary
to the EchoMQ course (the →door)>.

## The module ladder
| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R[N].01 <slug> | `<pattern-slug>` | <one line> | <real key/command/Lua/Go or Portal surface> | <dive · dive · dive> |
| … | | | | |
| R[N].<workshop> Workshop | — | advances the EchoMQ/Portal build | <the slice built> | — |

## The door to the EchoMQ course
<what this chapter's deeper implementation belongs to the dedicated EchoMQ course, and where it links forward>.

## Conventions
<the two layout rules; the ten gates incl. refs; voice; the no-invent grounding rule; the branded Snowflake stamp>.

Index: ../redis-patterns.md · TOC: ../../redis-patterns.toc.md · Roadmap: ../../redis-patterns.roadmap.md
```

(Relative paths from `specs/<chapter>/<chapter>.md`: the contract index is one level up `../redis-patterns.md`; the
TOC and roadmap are two levels up at the course root, `../../`.)

## The chapter map

The arc is pattern-family chapters sequenced along the **EchoMQ build arc** (coordination → queues → time → streams
→ flow → operations), so the course doubles as a guided build of Portal's reserved Redis tier. All 30 catalog
patterns (the [README](../README.md)'s Fundamental ×20, Community ×6, Production ×4) are placed exactly once.

| Chapter | Slug | The pattern family | Grounding |
|---|---|---|---|
| **R0** | *(landing)* | Overview — the catalog, Redis under Portal, patterns become protocol | — |
| **R1** | [`caching`](caching/caching.md) | Caching | Portal cache machine |
| **R2** | [`coordination`](coordination/coordination.md) | Coordination & consistency | EchoMQ locks / Lua / colocation →door |
| **R3** | [`queues`](queues/queues.md) | Reliable queues | EchoMQ wait/active/RPOPLPUSH →door |
| **R4** | [`time-delay-priority`](time-delay-priority/time-delay-priority.md) | Time, delay & priority | EchoMQ delayed/priority ZSETs →door |
| **R5** | [`streams-events`](streams-events/streams-events.md) | Streams & events | EchoMQ `:events` stream →door |
| **R6** | [`flow-control`](flow-control/flow-control.md) | Flow control & scale | EchoMQ limiter / groups / batches →door |
| **R7** | [`data-modeling`](data-modeling/data-modeling.md) | Data modeling & memory | Portal read-models; EchoMQ memory |
| **R8** | [`production-operations`](production-operations/production-operations.md) | Production & operations | EchoMQ production guide →door (capstone) |

## Conventions

- **Subject.** Redis patterns, taught applied. Commands appear as inline code, never as links; each pattern carries
  its trade-offs (Advantage / Disadvantage / when-to-use), the judgement layer raw command docs omit.
- **Grounding.** Real EchoMQ artifacts (`docs/echomq/`, `apps/echomq-go/`), real Redis commands, the Portal facade
  contract; never a fabricated module. The 5-agent EchoMQ grounding map is fixed in the
  [roadmap](../redis-patterns.roadmap.md).
- **Identifiers.** Every built page carries a branded **Snowflake** build stamp — a three-letter namespace + an
  11-char Base62 snowflake (e.g. `TSK0KHTOWnGLuC`, epoch `1704067200000`) — in the canonical footer.
- **Accent.** The course renders in the shared jonnify dark-editorial design system with a scoped Redis accent token
  added to `:root`; every other token is shared with `/elixir` and `/course/agile-agent-workflow`.

## References

- The project rationale (why Redis patterns for LLMs, the 5W1H): [`../README.md`](../README.md).
- The spec-system lineage this extends: [`../../elixir/specs/specs.approach.md`](../../elixir/specs/specs.approach.md)
  and the AAW course [`../../agile-agent-workflow/agile-agent-workflow.toc.md`](../../agile-agent-workflow/agile-agent-workflow.toc.md).
- The grounding corpus: [`../../echomq/echomq_index.md`](../../echomq/echomq_index.md) and the real Go implementation
  `apps/echomq-go/`. The reserved Portal layer: [`../../elixir/specs/portal.roadmap.md`](../../elixir/specs/portal.roadmap.md).
- The `llms.txt` convention the course's machine map follows: <https://llmstxt.org/>.

---

> Part of the jonnify toolkit. The TOC maps, the roadmap plans, the chapter specs define — and all three are settled
> before any page is built. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
