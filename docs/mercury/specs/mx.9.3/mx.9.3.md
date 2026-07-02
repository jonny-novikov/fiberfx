# MX.9.3 · The live-stories surface — the CSF interpreter + the shim liveness gate

> **Status: ✅ BUILT (gate-green 2026-07-02 via `/mercury-ship mx.9.3`; Trio — Venus re-sharpen →
> Mars pass-1 clean → Director deepened verify, the harden pass collapsed; as-built record §7. The CSF
> census over all 65 story files + the `StoryBlock` seed read were DONE at the re-sharpen; the field set
> below is censused, not deferred).** The third sub-rung of the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC —
> **hard-gates on [mx.9.2](../mx.9.2/mx.9.2.md)** (the registry + the Stories stub it fills). mx.9.3 lands
> the epic's K-3: a small **CSF interpreter** (the bundle `StoryBlock` pattern, reimplemented typed AND
> corrected — the seed's exact algorithm mis-renders the real files, see §5) rendering each component's
> live `*.stories.tsx` in the Stories panel — **and it is the rung where the mx.9.1 `storybook/test` shim
> must prove its liveness**: this is the first rung that executes story modules. Pattern source:
> `packages/mercury-ds/project/showcase/library.jsx` `StoryBlock` (read-only untracked seed, read
> 2026-07-02). **FORK-1 (decorators) RULED: Arm A — support the censused shape (§4).**
>
> **Risk: ELEVATED · formation Trio + deepened verify** (the shim-liveness sweep, the no-Storybook-runtime
> re-proof, and the adversarial probes below are the deepening — a story-module regression here is
> silent-at-build and loud-at-runtime, the worst kind). The Operator may override at ship. **Inherited
> rulings (2026-07-02, epic §7 — closed):** B · C · D · E.

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rung: [`../mx.9.2/mx.9.2.md`](../mx.9.2/mx.9.2.md)
· the shim contract: [`../mx.9.1/mx.9.1.md`](../mx.9.1/mx.9.1.md) (INV-4/INV-5) · canon:
[`../../mercury.design.md`](../../mercury.design.md) · acceptance:
[`mx.9.3.stories.md`](./mx.9.3.stories.md) · build context: [`mx.9.3.llms.md`](./mx.9.3.llms.md).

## 0 · The slice

The epic's K-3 (the story renderer) realizing epic S-5. The mx.9.2 Stories stub becomes live: selecting a
component and opening its Stories tab lazy-loads that component's `*.stories.tsx` module (the registry's
`loadStories` loader — first invoked HERE) and renders its named-export stories through a small
interpreter — **no Storybook runtime**. Two loads bear the risk: (a) the **module graph** — 11 of the 65
story files VALUE-import `storybook/test`, resolved by the mx.9.1 shim; this rung's gate proves the shim
LIVE across all 65 modules, not just present; (b) the **execution discipline** — the interpreter reads
the censused meta + story fields (`render`/`args` at BOTH levels, merged — see §1) and never touches
`play` (interaction tests stay the Storybook host's job).

## 1 · Goal

Every component's Stories tab renders its live stories from source. The interpreter reads the CSF module
per the **censused field set** (all 65 files, 2026-07-02): `mod.default` = the meta — `component` (65/65),
`args` (64/65), `render` (3/65: Tabs · Pagination · TabNav), `decorators` (5/65 — per the FORK-1 ruling,
§4); `title` and `argTypes` are present but IGNORED (nav is filesystem-derived; controls are the Storybook
host's job). The named exports = the stories — the census finds **zero non-story exports** across all 65
files (every file is exactly `export default meta` + typed `export const <Name>: Story`), so the story
filter is: every named export except `default`. Per story the interpreter resolves
`render = story.render ?? meta.render` and `args = { ...meta.args, ...story.args }` (the CSF merge law —
`Playground: Story = {}` in 65/65 files renders ONLY via merged meta args); where a render exists it is
mounted **as its own component receiving the merged args as props** (17 of the 115 render sites read
their first parameter; zero read a second), else `createElement(meta.component, args)`; the card title is
`story.name ?? the export name` (8 a11y stories carry `name`; an `args.name` — Avatar, Radio — is a
component prop, never a title). Each story mounts in its own error boundary. All **65** story modules load
cleanly through the shim; `fn()`-produced `args` handlers (the 3 actions files: `onClick: fn()`) are
callable no-ops; no play-only stub ever fires during render; grep finds no value import from
`@storybook/*` anywhere in `apps/showcase/src/**`.

> **[RE-SHARPENED 2026-07-02]** Two authoring-time claims fell to the census: **(a)** `parameters.summary`
> has **0 occurrences** in the tree — a bundle-inherited claim (the seed's own CLAUDE.md §4 + `library.jsx`
> line 138), never imported into the real files; DROPPED from the interpreter's read set. **(b)** `render`
> was framed "where present" (the exception); it is the DOMINANT path — `render:` appears in 65/65 files
> (115 sites: 98 `() =>` · 11 `(args) =>` · 6 `(r) =>`), and 3 files carry it at META level, so the seed's
> story-only, zero-prop mount (`createElement(story.render)`) mis-renders the real tree.

## 2 · Rationale (5W)

- **Why.** The Stories surface is the showcase's live half of the one-source law (epic §0): the same
  co-located `*.stories.tsx` the Storybook host renders with its runtime, rendered here by a ~100-line
  interpreter — one source, two renderers. It is also the only place the shim's design can be PROVEN: a
  gate that never executes a story module would satisfy the shim's letter while proving nothing.
- **What.** The interpreter module + the wired Stories panel + the liveness sweep + the two adversarial
  probes (the deepened verify).
- **Who.** *Built by* the implementor to [`mx.9.3.llms.md`](./mx.9.3.llms.md); *verified by* the Director
  with the deepened-verify checklist; *consumed by* every browser of the library and by mx.9.5 (the
  dual-theme acceptance renders THROUGH this surface).
- **When.** After mx.9.2 (the registry + stub). Parallel-safe with mx.9.4 (different stub, different
  loader). Before mx.9.5 (the closer re-runs this surface whole).
- **Where.** `mercury/apps/showcase/src/**` only.

## 3 · Invariants (runnable checks)

- **INV-1 · The render path is live source, no Storybook runtime** (epic INV-5 render half + K-3). The
  interpreter consumes the CSF module shape directly; the story files' `import type { Meta, StoryObj }
  from "@storybook/react-vite"` stays type-only (erased at build). Checks:
  `grep -rnE "from \"@storybook/" apps/showcase/src` → empty (no value OR type import in app code);
  `grep -rn "import type" packages/mercury-ui/src/components/**/[A-Z]*.stories.tsx | grep "@storybook"`
  confirms the type-only shape unchanged (re-proof, not assumption); the built app resolves no
  `@storybook/*` package (bundle-analysis or resolve-trace at ship).
- **INV-2 · THE SHIM LIVENESS GATE — all 65 story modules load through the mx.9.1 shim.** A present
  precondition MUST exercise its gate with a positive proof: the verify step iterates the **whole
  registry** and awaits every `loadStories()` — every one of the 65 modules (DERIVED count) resolves and
  its stories mount; the **11 `storybook/test` value-importers are the proof surface** (each must appear
  in the sweep's pass list by name). The censused split of the 11 `[RE-SHARPENED 2026-07-02]`: **3
  `fn`-importers** — `actions/{Button,IconButton,Link}` (`onClick: fn()` in meta args — the click-probe
  surface: clicking a rendered story's control fires the no-op silently, no throw, no console error) — and
  **8 play-only-name importers** — `navigation/{Menubar,TabNav}` + `overlay/{AlertDialog,ContextMenu,
  Dialog,Dropdown,HoverCard,Popover}` (import `expect`/`userEvent`/`within` ± `waitFor` ± `fireEvent`; the
  same 8 files carry all the tree's real `play:` fields and all 8 story-level `name:` fields). **If a
  play-only stub throws during render, that IS the gate catching a broken assumption ("the showcase never
  runs play") — ESCALATE to the Director; never patch the shim or the interpreter to swallow it.** (The
  shim's two loud modes, both play-confined: a direct call — `within(el)`, `waitFor(fn)` — throws the shim
  `Error`; a property-access-then-call — `userEvent.click(x)`, `expect(x).toBe(y)` — throws a `TypeError`.
  Either during RENDER is the same escalation.)
- **INV-3 · `play` is never executed.** The interpreter reads the meta + each story's censused fields and
  **never invokes `story.play`**. Check: `grep -rn "\.play" apps/showcase/src` → the only permitted hits
  are a comment or a deliberate exclusion line, never a call. (Census craft: a field-census grep must
  anchor `^\s*play:` — a bare `play:` matches every `display:` style line.)
- **INV-4 · Per-story error boundaries.** One broken story renders an inline error card (the story name +
  the message); its siblings and the shell render on. Check: the broken-story adversarial probe (§4 K-4).
- **INV-5 · Lazy per selection.** Only the selected component's story module loads (the mx.9.2 lazy
  discipline carried forward — navigation to component A must not load component B's module). Observable:
  the dev network panel on a two-component navigation.
- **INV-6 · Scope + barrel.** The diff is `apps/showcase/src/**` only; `packages/**` untouched; the
  barrel byte-identical (Director-run diff); the consume-down greps stay empty.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **interpreter** (`src/lib/storyRender.tsx`) — parse the CSF module per the §1 censused field set (meta `component`/`args`/`render` + FORK-1 `decorators`; stories = every named export except `default`), resolve `story.render ?? meta.render` over merged `{ ...meta.args, ...story.args }`, mount render-as-component WITH the merged args as props else `createElement(meta.component, args)`, each in an error boundary, titled `story.name ?? export name` | S-1; INV-1, INV-3, INV-4 |
| K-2 | The **Stories panel wired** — the mx.9.2 stub (`ComponentPage.tsx` line 41–42) replaced: `loadStories()` awaited with a loading state, the interpreter renders the story cards | S-1; INV-2, INV-5 |
| K-3 | The **liveness sweep** — a verify-stage pass over the whole registry (all 65 loaders awaited + mounted; the 11 shim-dependent files named in the pass evidence) | S-2; INV-2 |
| K-4 | The **adversarial probes** (deepened verify): (a) a throwaway story importing a **7th** `storybook/test` name fails **LOUD at vite import-analysis** — the shim's designed failure mode (mx.9.1 shim header; the fix is one shim export, an escalation not a patch); (b) a throwaway story whose `render()` throws renders an inline error card while siblings render (revert both probes) | S-3; INV-2, INV-4 |

**FORK-1 (decorators) — OPEN at the re-sharpen; the Operator rules before the build.** The census finds
`decorators` in exactly **5 files** — `foundations/{Separator,Divider}` · `feedback/{Progress,
PasswordStrength}` · `layout/AuthLayout` — ALL meta-level, ALL single-element arrays, ONE signature:
`(Story) => JSX` (four inline 320px-width demo frames + AuthLayout's named `Frame: Decorator`, a 760px
height/border/overflow box around a `height:100%` layout component). **Arm A** — support the censused
shape (~6 lines: wrap the resolved story element in each meta decorator, innermost-first); the 5
components' stories render as designed. **Arm B** — ignore decorators (the pre-census letter); the 4
width-framed components render unframed (cosmetic width bleed) and AuthLayout's stories render without
their height box (a `height:100%` layout in an unconstrained card — visibly broken framing). The full
Rationale / 5W / Steelman / Steward frame is in [`mx.9.3.llms.md`](./mx.9.3.llms.md) §FORK-1. The ruling
lands here as a one-line `RULED` note; INV numbering is stable under either arm.

**RULED (Operator, 2026-07-02, via AskUserQuestion): Arm A** — support exactly the censused shape
(meta-level, single `(Story) => JSX` signature, length-1 arrays); anything beyond renders unwrapped and is
a future rung's fork.

## 5 · The method (build order)

1. **Write the interpreter** to the K-1 contract. `[RE-SHARPENED 2026-07-02]` The CSF census is DONE
   (recorded in [`mx.9.3.llms.md`](./mx.9.3.llms.md) §Ground census — all 65 files, the seed `StoryBlock`
   read included); the build starts at the brief's §Interpreter contract, no re-census required. Three
   seed corrections are binding: merge meta args, resolve meta-level render, pass the merged args to the
   mounted render function.
2. **Wire the Stories panel** (replace the stub; loading state; story cards).
3. **Run the liveness sweep** (K-3) and record the 65-module pass with the 11 shim files named.
4. **Run the adversarial probes** (K-4), revert the throwaway files.
5. **Run the gate ladder** (brief §Gate) + the deepened-verify checklist; the Director re-runs
   independently.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.2](../mx.9.2/mx.9.2.md) (the registry + the stub). The mx.9.1 shim is the
  load-bearing precondition this rung proves.
- **Unblocks:** mx.9.5 (the dual-theme acceptance renders through this surface). Independent of mx.9.4.
- **Touches:** `mercury/apps/showcase/src/**` only (probe files transiently excepted, reverted).

## 7 · As-built record (2026-07-02)

Trio: Venus (`venus-mercury`) ship-time re-sharpen → Mars (`mars-mercury`) pass-1 clean → Director
deepened verify, zero findings, the harden pass collapsed. As-built files: `src/lib/storyRender.tsx`
(~160 lines — `parseCsfModule` / `StoryCard` / `StoriesPanel`, the 7-step resolution law with the three
seed corrections binding; FORK-1 Arm A as `applyDecorators`, censused-shape-only; resolution inside a
`ResolvedStory` component so decorator calls + render mount + the missing-component throw all land inside
the boundary; cards keyed `entryKey/storyKey` so no boundary carries stale error state across entries) ·
`src/shell/ComponentPage.tsx` (stories stub → `<StoriesPanel entry={entry} />`; Docs branch byte-intact) ·
`src/showcase.css` (additive `showcase-story*`, tokens only).

**The shim liveness gate (INV-2) — PROVEN twice.** Mars: the transient vitest sweep (root-run, the brief's
caveat-4 root-relative-include fallback) — 65/65 modules loaded + every story mounted with an explicit
zero-boundary-catch assertion; the 11 `storybook/test` importers asserted by name; the `fn()` click no-op
green; zero play-only stub fired. Director (independent, stronger witnesses): 65/65 boundary-catch-free +
the merged-args content witness (Button `Playground` renders its meta-args children) + the meta-render
witness (Tabs) + both FORK-1 witnesses found in the DOM (Separator's 320px wrapper · AuthLayout's 760px
`Frame`) + inline containment (one error card, sibling renders). Probes: (a) run twice with different
missing names (`spyOn` — Mars · `screen` — Director), both failing LOUD at vite import-analysis with the
designed message, both folders deleted, `packages/**` clean; (b) contained render throw proven at jsdom
level through `StoryCard` (both passes). **Mutation spot-check (behavioral, LAW-1a):** dropping
`...meta.args` from the merge failed 4 of 5 Director tests INCLUDING the liveness sweep itself
(`inputs/Select` throws `undefined.map` without meta args) — the merge law is load-bearing; reverted
net-zero. Gate: `typecheck:mercury` / `build:mercury` / showcase / `build:apps` all 0; the `.play` grep
hits only the deliberate-exclusion comment (`storyRender.tsx:69`); barrel byte-identical. **Manual
residuals (stated honestly, no browser in the loop):** the `:5176` visual pass (probe-b card, Tabs
interactivity, a11y `name:` titles) and the dev-network-panel two-component lazy observation — INV-5 held
by code shape (the panel awaits only `entry.loadStories()` in an entry-keyed effect; no `REGISTRY`
iteration) and by the code-split build output.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
