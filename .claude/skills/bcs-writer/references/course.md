# BCS course spec — the served `/bcs` pages

The course teaches the manuscript as self-contained HTML pages on the BCS contract
sheet. This file is the spec the toolkit (`scripts/build_course.py`) and the gate
(`scripts/course_lint.py`) implement.

## The shape (hard law)

```
Chapter   B[N]        /bcs/<chapter-slug>                       a landing, maps 6 modules
  Module  B[N].[M]    /bcs/<chapter-slug>/<module-slug>         a hub, maps 3 dives
    Dive  B[N].[M].[D] /bcs/<chapter-slug>/<module-slug>/<dive-slug>   a leaf, the teaching
```

Six modules per chapter, three dives per module — fixed. A chapter landing never
lists dives; it lists its six modules, each a card linking to the module hub. A
module hub lists its three dives. The reading order is the arc figure on the
landing.

## Slug routes (hard law)

Links are semantic slugs, never the on-disk file name. `bc.route("ideas",
"identity-contract")` → `/bcs/ideas/identity-contract`. Forbidden in any `href`:
`/bcs.1.2`, `bcs.1.2.html`, `/bcs/ideas/2`. The file may be `bcs.1.2.html` on
disk; what the page emits is the slug. The dev server resolves slug routes
(`http://localhost:1330/bcs/ideas/identity-contract`).

Chapter slugs: `ideas` (B1), then B2…B9 as the book ships. The B1 module slugs are
fixed below.

## Page anatomy

Every page, built by `bc.page(...)`:

- **header** — brand `jonnify·bcs`, the slug breadcrumb (`bc.route_tag`), section topnav.
- **hero** — kicker (`B[N] · …` or `B[N].[M] · dive D of 3`), an h1 with one `.hns` accent, a lede, an optional `.heronote`.
- **the interactive figure** (mandatory, exactly one) — `bc.figure(caption, svg, buttons, default)`. An `.anat` SVG of `g[data-seg]` groups, a `.segbar` of buttons, a `.readout`. Selecting or hovering a segment dims the rest and writes its line into the readout. Pure lookup, no storage; with script off the segments are all visible. A landing's figure is the chapter arc (chapter → 6 nodes; module → 3 nodes); a leaf's figure illustrates its mechanism.
- **`.idrule`** — the 14-cell 3/11 device.
- **body** — `§1…` sections (`bc.sech`), prose-led; module/dive maps via `bc.grid` of `bc.card`.
- **doors** — `bc.DOORS`: `/echomq`, `/redis-patterns`, `/echo-persistence`.
- **references** — `bc.refs(no, sources)`; every URL search-verified this session.
- **pager** — `bc.pager(prev, nxt)` with slug routes.
- **footer** — chapter map (B0–B9, Persistence Floor at B5), the courses list, and a real `BCS…` build stamp the footer script decodes.

## Grounding (hard law) — what the last build got wrong

A number appears only if the committed repo proves it. Two legitimate sources:

1. **A committed `.out` file** — shown in a `.frozen` block whose caption names the
   path, which must resolve under the repo. The current snapshot has **none**.
2. **Source that asserts the value** — chiefly `branded_id.ex`'s `self_check!`,
   which the runtime asserts at boot: `placement(USR0KHTOWnGLuC)` is `234878118`;
   `parse("USR0NgWEfAEJfs")` is `{:ok,"USR",320636799581945856}`; an overflow
   `decode` is `:error`. The layout constants (3+11 bytes; 41/10/12 snowflake bits;
   the 2024-01-01 epoch `1704067200000`; the September-2093 horizon) are contract,
   not measurement, and are citable.

**Banned:** any `bench/branding-vs-decimal` or `bench/valkey-id` figure (the encode
ratios, the byte-per-key rows, the stream-entry rows) — there is no committed
`.out` for them, so they are thin and do not go on a page. The conceptual content
those chapters carry (the derivation that a fixed-width 11-divmod render is cheaper
than a variable-width 19-divmod one; that the contract form is printable, typed,
and ordered) stands without numbers. **Also banned:** gate-dump blocks (`PASS n/n`,
`G1 … ok` ladders) — describe the idea instead. `bc.cite_guard` raises on a thin
figure; `course_lint.py` re-checks the rendered page.

## The B1 chapter — `Ideas Behind`, 6 modules

`/bcs/ideas`. Part I, the conceptual floor. Each module is a hub of 3 dives.

| module | slug | thesis (no thin numbers) |
|---|---|---|
| B1.1 The System Substrate | `system-substrate` | the law executable: a process owning a private table behind a namespace gate; chronology from the key, no clock |
| B1.2 The Identity Contract | `identity-contract` | the 14-byte id read field by field — namespace as discriminant, order theorem, `hash32` placement (the `234878118` vector), the canon |
| B1.3 Choosing the ID System | `id-system` | the chooser as a derivation — why a printable, typed, ordered key is the right default; the measured rows live in a chapter whose `.out` must be committed first |
| B1.4 From ECS to BCS | `ecs-to-bcs` | the index-handle's three deaths (save, socket, store), each a missing contract property; the translation table |
| B1.5 The Time Inside the Name | `time-inside-the-name` | the 41-bit horizon (September 2093), the law of two clocks, the monotonic mint floor |
| B1.6 Branding Beats Its Own Integer | `branding-beats-integer` | the derivation that the brand's render is the cheap one in compiled code, and where the canon sends the runtime that pays; numbers pending a committed `.out` |

## The B0 chapter — `Orientation`

`/bcs`. The course home and design exemplar: the law as a triptych, the id anatomy
as the anchor interactive figure, the contract self-check as the grounded evidence,
the B1–B9 chapter map, the doors. It sets the visual identity every other page
inherits.
