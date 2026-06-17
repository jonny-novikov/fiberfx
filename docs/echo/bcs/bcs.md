# Specs → chapter authoring — the BCS course spec system

> The contract for the **Branded Component System** course spec system: how the BCS manuscript becomes a course of
> static HTML pages served at **`/bcs`**, designed as specs first and built second. It works in two layers — a
> **roadmap** that plans how the chapters ship, and a **per-chapter spec triad** that defines each chapter's module
> ladder — over one structural map, the **TOC**. A chapter is specified, its modules are paired with their
> manuscript chapters and their frozen evidence, and only then are pages authored against it. The aim is a course
> that is grounded (every claim drawn from the manuscript or its committed outputs, never invented), structured
> (one consistent chapter→module→dive shape), and correct by construction (no page exists that the spec did not
> first define).

This file is the contract for the spec system itself; every chapter conforms to it. It takes the shape of
[`docs/redis-patterns/specs/redis-patterns.md`](../../redis-patterns/specs/redis-patterns.md) — the established
course-spec lineage, shared with the `/echomq` course — with one structural difference: the **source-of-record
is a book**. The BCS manuscript lives at [`content/`](content/bcs.toc.md)
(Parts I–VIII, the D-4 file layout, decisions D-1…D-10 in [`content/bcs.progress.md`](content/bcs.progress.md)),
and the course mirrors it chapter for chapter. The manuscript and its evidence package are the Author/Operator's;
course authoring reads them and never edits them.

## Why this exists

A course built over an eight-part manuscript cannot be authored page by page from memory. The pages would drift —
in structure, in voice, and most dangerously in their figures, where an unguided author paraphrases a benchmark
into a number the committed outputs do not contain. This spec system fixes the structure and the grounding
**before** any page is written:

- **Design before build.** The chapter→module→dive tree and the manuscript chapter each module teaches are settled
  in the specs. Page authoring expands a spec faithfully; it never decides structure.
- **Grounding, written down.** Each module names the manuscript chapter it is drawn from and the evidence files
  behind it (`content/echo_data/**`, the contract, the vectors, the frozen rung transcripts), so every figure on a
  page is verifiable against a committed output.
- **One shape, enforced.** Every landing, hub, and dive has the same anatomy and the same mechanical gates, so the
  course reads as one work.

## What the course is

**BCS** teaches the Branded Component System — the architecture law the manuscript states in three clauses:
*systems own their state and behavior; only identities, and messages about identities, cross boundaries; identity
is a typed, ordered, placed contract.* The contract is the **branded snowflake**: a 14-byte id (3-character
uppercase namespace + 11 Base62 characters carrying a 63-bit snowflake — `ts(41) | node(10) | seq(12)`, epoch
`1704067200000`), conformant across Elixir, Go, Node/TypeScript+wasm, PostgreSQL, and Rust/C against one canon.
The worked project threaded through the applied parts is a **trading system**; the bus between systems is
**EchoMQ 2.0, backed by Valkey**. Every manuscript chapter that narrates built work quotes only committed outputs
— the frozen-transcript ethic the course inherits page by page.

The course is served folder-routed at **`/bcs`** by the jonnify Fiber server (`serveDirTree`; the URL tree mirrors
`html/bcs/`, read from disk live — a new `.html` is live on save, no rebuild).

## The three levels — `B[chapter].[module].[dive]`

- **Chapter** `B[N]` (B0…B8) — a top-level section with a **landing** page `<chapter>/index.html` (route
  `/bcs/ideas`). Its spec is the triad `specs/bcs.N.{md,specs.md,llms.md}`.
- **Module** `B[N].[M]` — a chapter *has* modules; module numbers map one-to-one to manuscript chapters
  (`B1.3` teaches [`content/bcs1.3.md`](content/bcs1.3.md)). Each is a **hub** `<chapter>/<module>/index.html`.
- **Dive** `B[N].[M].[S]` — each module has **≥3** deep-dive subpages `<chapter>/<module>/<sub>.html`, fixed in
  the chapter spec when the chapter is deepened for build.

**B0** is the orientation chapter, realized as the course landing itself (`/bcs` → `html/bcs/index.html`): the
law, the id anatomy, the evidence ethic, and the course map. Its triad ([`specs/bcs.0.md`](specs/bcs.0.md)) is the
exemplar the later chapter triads follow.

## The artifacts

| Artifact | Scope | Role |
|---|---|---|
| [`bcs.toc.md`](bcs.toc.md) | the course | the **TOC** — the chapter→module tree + abstracts + build status; the living structural map |
| [`bcs.roadmap.md`](bcs.roadmap.md) | the course | the **roadmap** — the chapter sequence, milestones, the canonical grounding map, the seams ledger |
| `bcs.md` (this file) | the course | the **contract + index** — the spec-system rules and the chapter map |
| `specs/bcs.N.md` + `specs/bcs.N.specs.md` + `specs/bcs.N.llms.md` | one chapter | the **chapter triad** — the chapter doc in 5W form, the spec of record with acceptance stories folded in, and the agent brief |

The triad naming follows the manuscript's own **decision D-4** (`content/bcs.progress.md`): the chapter doc, a
`.specs.md` with the stories folded in, and a `.llms.md` agent guide — not the `.stories.md` convention of the
elixir rung triads. The TOC is the map; the roadmap is the plan; the chapter triad is the contract a page-authoring
batch builds from.

**Name collision, resolved by path:** [`bcs.toc.md`](bcs.toc.md) at the course root is the *course* TOC;
[`content/bcs.toc.md`](content/bcs.toc.md) is the *manuscript's* reading order — a different artifact, never edited
by course authoring.

## The grounding rule (the boundary)

Every module declares its **grounding** — the manuscript chapter it teaches and the evidence behind it — and stays
inside this boundary:

- **A BCS course page** teaches what the manuscript wrote, with **every figure quoted verbatim from a committed
  output**: the contract ([`content/contract.md`](content/contract.md), canonical vector `hash32 = 234878118`,
  `MAX_PAYLOAD = "AzL8n0Y58m7"`), the vectors file, the rung check transcripts under `content/echo_data/`, the
  bench outputs, and the five historical articles under [`content/docs/`](content/docs/). A number that is not in
  a committed output does not appear on a page.
- **The living-status discipline.** Parts IV–VIII exist as TOC abstracts; their manuscript chapters are not yet
  written. A course page that references them writes *"the manuscript plans…"* — never asserted-as-written. When a
  manuscript chapter ships, the corresponding course chapter is re-grounded from it.
- **The sibling courses own their depth.** EchoMQ protocol internals belong to `/echomq` (spec authority: the
  EMQ ladder, [`echo_mq.md`](../../echo_mq/echo_mq.md)); transferable Redis patterns belong to
  [`/redis-patterns`](../../redis-patterns/redis-patterns.toc.md); the Portal engine belongs to `/elixir`. A BCS
  page that drifts into those links forward instead.

**No invention.** Cite only the manuscript and its committed outputs. Do not invent a namespace, a benchmark
figure, a gate count, a Lua script, or an API the sources do not contain. The grounding map is fixed in the
[roadmap](bcs.roadmap.md).

## The page surfaces

- **The course landing / home** (`/bcs` → `index.html`) — B0 itself: the law in three clauses, the id anatomy, the
  evidence ethic, and the chapter map (B1–B8 as cards; unbuilt chapters are **non-anchor `soon` cards**, so the
  landing holds a full `links` PASS — the deliberate inversion of the sibling courses' fail-by-design manifests).
- **A chapter landing** (`/bcs/<chapter>` → `<chapter>/index.html`) — the chapter's teaching arc over its module
  cards, closing with an "Up next" grid.
- **A module hub** (`<chapter>/<module>/index.html`) — a module's framing plus its ≥3 dive cards.
- **A dive** (`<chapter>/<module>/<sub>.html`) — a full lesson: the concept, the manuscript's worked material, an
  interactive, a recap, References, a pager.

Every page is authored **md-first**: the route-mirror markdown at `docs/echo/bcs/markdown/<route>.md` is written
before the HTML it mirrors.

## The BCS visual identity — its own design system

The course renders in **its own visual identity**, not the shared jonnify dark-editorial system. The identity is
defined by the B0 landing (the design exemplar every later page copies from) and is derived from the manuscript's
character:

- **The id anatomy as the anchor motif.** The 14-byte form — a 3-character namespace segment + an 11-character
  Base62 payload — drives the typography (monospace-forward) and the segmentation rhythm (3/11) of the layout.
- **The three-clause law as the layout grammar.** Triptych compositions: three-column statements, three-part
  section headers.
- **The frozen-transcript ethic as the evidence styling.** Measured figures render in transcript blocks styled as
  committed terminal output — bordered, labelled with their source file, quoted verbatim.

**MUST NOT use** (the dark-editorial tokens of `/elixir`, `/redis-patterns`, `/echomq`,
`/course/agile-agent-workflow`): the dark navy `--ink` / cream / gold palette, the Cormorant Garamond / PT Serif /
Manrope font stacks, and the `.chap`/`.mods`/`.mod` card-grid classes copied from those courses. A BCS page copies
its design from a **built BCS page**, never from another course.

**Kept invariants** (course-system-wide, identity-independent): the two mandatory layout rules below, the literal
`class="pager"` block, `prefers-reduced-motion` handling, no-JS readability, no storage APIs, and the branded
build stamp.

## Quality gates — the mechanical checks

Every page passes the **ten jonnify-cms gates** before it ships (`apps/jonnify-cms/bin/cms check`): `containers` ·
`svg` · `no-future` · `voice` · `storage` · `motion` · `degrade` · `links` · `pager` · **`refs`** (opt-in via
`--require-refs`). The command form for this course:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /bcs=html/bcs \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir \
  --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading \
  --require-refs html/bcs/<path>.html
```

The extra mounts let the door links to the sibling courses resolve in-gate. Two checks the gates cannot see,
verified by reading: **clamp spacing** (spaces around `+`/`-` inside `clamp()`, or the declaration drops to a UA
default) and **right-route-vs-resolvable** (read crumbs and pager intent). The spec docs themselves pass the same
**voice** gate: no first person, no exclamation, no emoji, and none of `revolutionary`, `blazing`, `magical`,
`simply`, `just`, `obviously`, `effortless`; no perceptual or interior-state verb applied to a tool or an agent.

## The two mandatory layout rules (page-level)

1. **Clickable segmented route-tag.** The header `.route-tag` renders each path part as its own element —
   intermediate parts are `<a href>` to that route level, the current part is `<span class="rcur">`, separated by
   `<span class="rsep">/</span>`; `/bcs` is one segment. The site root `/` is **not** a linkable segment.
2. **Canonical 3-column footer.** A `footer` with three link columns + a bottom bar carrying the `.stamp` +
   decoder — a valid **`BCS…`** branded Snowflake id, minted by `apps/jonnify-cms/bin/cms stamp mint --ns BCS`.
   The course stamps in its **own namespace** — the D-8 rule applied to the course itself: a kind earns a
   namespace when it needs identity and lifecycle of its own.

Both rules are restyled into the BCS identity; their structure is invariant.

## The chapter triad template

```text
specs/bcs.N.md        — the chapter doc, 5W form: Why · What · Who · When · Where · How,
                        plus Decisions, Boundaries, and References (the manuscript's chapter form).
specs/bcs.N.specs.md  — the spec of record: Deliverables (BCS.N-D#), Invariants (BCS.N-INV#),
                        the module ladder (module · manuscript chapter · what it adds · grounding · dives),
                        acceptance stories folded in (BCS.N-US#), Definition of Done.
specs/bcs.N.llms.md   — the agent brief: References · Requirements (BCS.N-R# [US: …]) · Do-NOTs ·
                        Agent stories (BCS.N-AS#) · the exact gate/mint/verify commands · a comprehensive prompt.
```

Footer line on each: `Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript:
../content/bcs.toc.md`.

## The chapter map

| Chapter | Route | Theme (manuscript Part) | Modules |
|---|---|---|---|
| **B0** | `/bcs` | Orientation — the law, the id anatomy, the course map | the landing ([`specs/bcs.0.md`](specs/bcs.0.md)) |
| **B1** | `/bcs/ideas` | Ideas Behind (Part I) | B1.1–B1.6 ([`specs/bcs.1.md`](specs/bcs.1.md)) |
| **B2** | `/bcs/elixir-core` | The Elixir BCS Core (Part II) | B2.1–B2.6 |
| **B3** | `/bcs/bus` | EchoMQ, Valkey-native (Part III) | B3.1–B3.6 + Appendix A (the connector) |
| **B4** | `/bcs/cache` | EchoCache (Part IV) | B4.1–B4.2 |
| **B5** | `/bcs/go` | Go (Part V) | B5.1–B5.2 |
| **B6** | `/bcs/node` | Node 22+ (Part VI) | B6.1–B6.3 |
| **B7** | `/bcs/fly` | Production on Fly (Part VII) | B7.1–B7.4 |
| **B8** | `/bcs/trading` | The Trading System (Part VIII) | B8.1–B8.4 |

## Conventions

- **Subject.** The architecture law and its contract, taught from the manuscript; figures verbatim from committed
  outputs; ids as inline code.
- **Grounding.** The manuscript under `content/`, the canon (`content/contract.md` + `content/vectors.json`), the
  evidence package (`content/echo_data/`), the historical articles (`content/docs/`); never a fabricated figure or
  surface. The grounding map is fixed in the [roadmap](bcs.roadmap.md).
- **Identifiers.** Every built page carries a branded **`BCS…`** Snowflake build stamp in the canonical footer
  (3-letter namespace + 11-char Base62, epoch `1704067200000`).
- **Identity.** The course's own design system, defined by the B0 exemplar; the MUST-NOT list above is binding.

## References

- The manuscript: [`content/bcs.toc.md`](content/bcs.toc.md) (reading order),
  [`content/bcs.preface.md`](content/bcs.preface.md) (the historical case),
  [`content/bcs.progress.md`](content/bcs.progress.md) (status + decisions of record).
- The identity canon: [`content/contract.md`](content/contract.md) + [`content/vectors.json`](content/vectors.json).
- The spec-system lineage: [`../../redis-patterns/specs/redis-patterns.md`](../../redis-patterns/specs/redis-patterns.md),
  [`../../elixir/specs/specs.approach.md`](../../elixir/specs/specs.approach.md).
- The sibling courses the doors open onto: `/echomq` (program authority
  [`echo_mq.md`](../../echo_mq/echo_mq.md)) · [`/redis-patterns`](../../redis-patterns/redis-patterns.toc.md).

---

> Part of the jonnify toolkit. The TOC maps, the roadmap plans, the chapter triads define — and all three are
> settled before any page is built. Branded id format: `BCS` + Base62(snowflake), e.g. `BCS0NtBpC9oGGW`.
