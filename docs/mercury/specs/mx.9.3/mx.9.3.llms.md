# MX.9.3 · build context (the agent brief)

Build context for [`mx.9.3.md`](./mx.9.3.md) (authoritative body) + [`mx.9.3.stories.md`](./mx.9.3.stories.md).
The body wins on any disagreement. **WRITE-READY (RE-SHARPENED 2026-07-02 at the rung's own ship):** the
CSF census over all 65 story files, the `StoryBlock` seed read, and the sweep-form feasibility probe are
DONE and recorded below — the implementor's first actions are writes. Required reading beyond this brief:
**≤2 files** (§References).

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

**Precondition:** mx.9.2 SHIPPED (`38a55e46`) — the registry + shell exist; NOTHING calls the loaders yet;
the 9.2 build already code-split all 65 story chunks green, so the module GRAPH resolves — what this rung
proves is top-level EXECUTION + MOUNT. **Inherited rulings:** B · C · D · E (epic §7 — notably E: **zero
new dependency**, anywhere, including devDependencies). **Formation: Trio + deepened verify (ELEVATED)** —
the Director's verify includes the liveness sweep and both adversarial probes, independently re-run.
**FORK-1 (decorators) is OPEN** — the Operator rules before the build; both arms are specified in §FORK-1
so the ruling changes ~6 lines, not the plan.

## References (read at build start — everything else is carried in this brief)

1. `mercury/apps/showcase/src/registry.ts` — the input surface (`ShowcaseEntry`, `REGISTRY`, `TOTAL`); 94
   lines, read whole.
2. `mercury/apps/showcase/src/shell/ComponentPage.tsx` — the stub to replace (48 lines, read whole).

Cited, NOT required reading: the seed `packages/mercury-ds/project/showcase/library.jsx` lines 72–117
(`StoryErrorBoundary` + `StoryBlock` — its corrections are §Interpreter contract); the shim
`apps/showcase/src/shims/storybook-test.ts` (six exports — `fn` + five play-only throwers); the census
exemplars `Button/Tabs/Dialog/Separator/AuthLayout .stories.tsx`; the shim contract mx.9.1 INV-4/INV-5.

## Ground census (2026-07-02 — all 65 `packages/mercury-ui/src/components/**/*.stories.tsx`)

- **Export discipline (uniform, zero exceptions):** every file is exactly `export default meta;` (65) +
  typed `export const <Name>: Story = …` story exports. Zero `export function`, zero `satisfies`, zero
  re-exported helpers, zero `__namedExportsOrder`. Every file has `export const Playground: Story = {}`.
  **The non-story filter is therefore: every named export except `default`** (a defensive skip of a
  non-object export is permitted; none exists today).
- **Meta fields (inside `const meta: Meta<…> = {…}`):** `title` 65/65 (IGNORED — nav is
  filesystem-derived) · `component` 65/65 · `argTypes` ~65 (IGNORED — controls are the Storybook host's
  job) · `args` **64/65** · `render` **3/65** (`navigation/{Tabs,Pagination,TabNav}` — controlled
  components wrapped in a stateful demo wrapper, e.g. Tabs line 59: `render: (args) =>
  <ControlledTabs {...args} />`) · `decorators` **5/65** (§FORK-1). **`parameters`: 0/65 — the
  `parameters.summary` claim was bundle-inherited and is DROPPED.**
- **Story fields:** `render` (the dominant path — `render:` appears in 65/65 files; 115 sites total: 98
  `() =>` · 11 `(args) =>` · 6 `(r) =>`; **zero take a second/context parameter**) · `args` · `name`
  **8 stories** (all the a11y stories, e.g. Dialog line 72 `name: "a11y — focus trap"`) · `play` **8
  files** (`navigation/{Menubar,TabNav}` + `overlay/{AlertDialog,ContextMenu,Dialog,Dropdown,HoverCard,
  Popover}` — NEVER invoked, INV-3). An `args`-level `name` exists (Avatar, Radio) — it is a component
  prop, never a title.
- **The 11 `storybook/test` value-importers (the INV-2 proof surface):** 3 `fn`-only —
  `actions/{Button,IconButton,Link}` (`onClick: fn()` in meta args) — plus the 8 play-files above
  (`expect`/`userEvent`/`within` ± `waitFor`; `ContextMenu` also `fireEvent`). All other `@storybook/*`
  imports tree-wide are `import type` (value-import grep = 0).
- **The shim (`src/shims/storybook-test.ts`, six exports):** `fn(impl?)` → a callable no-op delegating to
  `impl`. The five play-only names are functions that throw the shim `Error` **when called directly**
  (`within(el)`, `waitFor(fn)`); a property-access-then-call (`userEvent.click(x)`, `expect(x).toBe(y)`)
  throws a `TypeError` instead — both loud, both play-confined. A 7th imported name fails at vite
  import-analysis (probe (a)).
- **jsdom hazard sweep:** zero hits for `ResizeObserver|IntersectionObserver|matchMedia|getContext|
  createObjectURL` across `packages/mercury-ui/src/components/**` — no known environment blocker for the
  sweep default.

## The interpreter contract (K-1 — `src/lib/storyRender.tsx`, NEW)

Exact shapes; names are binding for the sweep + ComponentPage imports:

```tsx
import { Component, createElement, type ComponentType, type ReactNode } from "react";
import type { ShowcaseEntry } from "../registry";

type StoryArgs = Record<string, unknown>;
type RenderFn = (args: StoryArgs) => ReactNode;
type Decorator = (Story: ComponentType) => ReactNode;        // the censused signature (FORK-1 Arm A)

export type CsfMeta = {
  component?: ComponentType<StoryArgs>;
  args?: StoryArgs;
  render?: RenderFn;                                          // 3 files: Tabs · Pagination · TabNav
  decorators?: readonly Decorator[];                          // 5 files, all meta-level, all length 1
  // present but IGNORED: title, argTypes
};

export type CsfStory = {
  name?: string;
  args?: StoryArgs;
  render?: RenderFn;
  play?: unknown;                                             // NEVER invoked (INV-3)
};

export type ParsedStory = { key: string; title: string; meta: CsfMeta; story: CsfStory };

export function parseCsfModule(mod: Record<string, unknown>): { meta: CsfMeta; stories: ParsedStory[] };
export function StoryCard(props: { parsed: ParsedStory }): ReactNode;   // boundary + title + stage
export function StoriesPanel(props: { entry: ShowcaseEntry }): ReactNode;
```

**The resolution law (per story — the three seed corrections are load-bearing):**

1. `meta = mod.default as CsfMeta`; `stories` = every other named export, in `Object.keys(mod)` order
   (census: zero non-story exports; the seed's `__esModule` skip is harmless to keep).
2. **Merge args:** `args = { ...meta.args, ...story.args }` — the seed read `story.args` only, which
   renders every `Playground: Story = {}` (65/65 files) empty (e.g. Button loses `children`/`onClick`).
3. **Resolve render:** `const render = story.render ?? meta.render` — the seed ignored meta-level render,
   which breaks Tabs/Pagination/TabNav args-only stories (controlled components with no state wrapper).
4. **Mount:** if `render` exists → `createElement(render, args)` — mounted **as its own component with the
   merged args as its props** (hooks stay legal — Dialog `Sizes` calls `useState` in render; 17 of 115
   render sites read their first parameter, and React passes props as exactly that parameter; zero sites
   read a second). Else → `createElement(meta.component, args)`. (`meta.component` is non-null in 65/65
   files; a missing component renders an inline error card, never a crash.)
5. **Title:** `story.name ?? <export key>` (8 a11y stories carry `name`; never read `args.name`). A
   camel-case-to-spaced prettify of the export key is permitted micro-craft.
6. **Decorators (per the FORK-1 ruling):** Arm A — wrap the resolved element in each `meta.decorators`
   entry, first entry innermost: the decorator is called with a component whose render returns the
   resolved element (`dec(() => element)`-shaped), and its returned JSX mounts inside the error boundary.
   The censused decorators are pure JSX wrappers (no hooks); all arrays are length 1. Arm B — skip this
   step entirely.
7. **`play` is dead data** — carried on `CsfStory` only so the exclusion is visible; no code path touches
   it (INV-3).

`StoryCard` reimplements the seed's `StoryErrorBoundary` (a class component with
`static getDerivedStateFromError`) typed: on error → an inline card with the story title + the error
message; siblings and the shell render on (INV-4). Card chrome (title row + stage) styles via NEW
`showcase-story*` classes in `src/showcase.css` using `rgb(var(--token))` families only (the mx.9.1/9.2
app-CSS discipline — e.g. `--fg-negative` for the error text, per the seed).

## Topology (files — exact)

- **NEW** `apps/showcase/src/lib/storyRender.tsx` — the contract above (~100–130 lines).
- **EDIT** `apps/showcase/src/shell/ComponentPage.tsx` — line 41–42: the ternary's stories branch
  `<p className="showcase-stub">The live stories surface lands at mx.9.3.</p>` →
  `<StoriesPanel entry={entry} />` (import from `"../lib/storyRender"`). The docs branch stays byte-intact
  (mx.9.4's stub).
- **EDIT** `apps/showcase/src/showcase.css` — the `showcase-story*` card classes (additive).
- **`StoriesPanel` behavior:** an effect keyed by `entry.group + "/" + entry.name` awaits
  `entry.loadStories()` with an alive-guard (the seed's `let alive = true` pattern); states: loading →
  cards | inline load-error (a rejected loader is a module-graph failure — at verify that is an INV-2
  escalation, never swallowed). No bespoke module cache: dynamic `import()` caches natively (the seed's
  `MOD_CACHE` is dead weight — do not port it). Lazy law (INV-5): only the selected entry's loader is
  invoked; `App.tsx` already mounts `ComponentPage` per selection, so the panel must simply never iterate
  `REGISTRY`.

## The sweep default (K-3 — pre-verified feasible; the FORM stays the implementor's call)

**The contract:** all 65 loaders awaited + every story mounted with **no error-boundary catch** (a sweep
that mounts through the boundary lets a broken story pass silently — mount the RESOLVED element directly,
or assert zero caught errors); the 11 shim importers named in the pass evidence; no sweep artifact ships
(INV-6 letter: the committed diff is `apps/showcase/src/**` only — both sweep files are TRANSIENT,
deleted before the gate; the evidence is the run transcript in the rung report).

**The pre-verified default form** — two transient files + one root-run command:

```ts
// apps/showcase/vitest.sweep.config.ts (TRANSIENT)
import { defineConfig, mergeConfig } from "vitest/config";
import viteConfig from "./vite.config";
export default mergeConfig(
  viteConfig,                       // ← carries @mercury/* source aliases AND "storybook/test" → the shim
  defineConfig({ test: { environment: "jsdom", include: ["test/stories-liveness.sweep.test.tsx"] } }),
);
```

```tsx
// apps/showcase/test/stories-liveness.sweep.test.tsx (TRANSIENT) — sketch
import { expect, it } from "vitest";
import { render } from "@testing-library/react";               // ROOT devDep ^16
import { REGISTRY, TOTAL } from "../src/registry";
import { parseCsfModule } from "../src/lib/storyRender";
const SHIM_IMPORTERS = [
  "actions/Button", "actions/IconButton", "actions/Link",
  "navigation/Menubar", "navigation/TabNav",
  "overlay/AlertDialog", "overlay/ContextMenu", "overlay/Dialog",
  "overlay/Dropdown", "overlay/HoverCard", "overlay/Popover",
];
it("all 65 story modules load and mount through the shim", async () => {
  expect(TOTAL).toBe(65);
  const passed: string[] = [];
  for (const group of REGISTRY)
    for (const entry of group.entries) {
      const mod = await entry.loadStories();                   // the shim-liveness moment
      const { stories } = parseCsfModule(mod);
      expect(stories.length).toBeGreaterThan(0);
      for (const parsed of stories) {
        const { unmount } = render(<>{/* the RESOLVED element — no boundary */}</>);
        unmount();
      }
      passed.push(`${group.key}/${entry.name}`);
    }
  expect(passed).toHaveLength(65);
  for (const key of SHIM_IMPORTERS) expect(passed).toContain(key);
}, 60_000);
```

```bash
# From mercury/ (the workspace ROOT — resolution caveat 1):
pnpm exec vitest run --config apps/showcase/vitest.sweep.config.ts
```

**Resolution caveats (pre-verified 2026-07-02):**

1. **Run from the workspace root.** `vitest ^3`, `jsdom ^25`, `@testing-library/react ^16`, `react ^19`
   are ROOT devDependencies; the showcase has NO test infra (pnpm strict —
   `pnpm --filter @mercury/showcase exec vitest` does not resolve). **Do NOT add vitest/jsdom to
   `apps/showcase/package.json`** — barred by ruling E, and a second vitest MAJOR is the known
   jest-dom-breaking trap. One vitest (the root ^3) runs everything.
2. **The merged app `vite.config.ts` is what routes `storybook/test` → the shim** — the sweep proves the
   SHIM path. The root `vitest.config.ts` jsdom project (which already globs `apps/*/test/**`) carries
   NEITHER the `@mercury/*` aliases NOR the shim alias — a sweep under it fails resolution; do not use it
   and do not edit it (out of scope).
3. `import.meta.glob` in `registry.ts` is vitest-native (vite-node) — the registry derives identically.
4. If the jsdom environment fails to resolve from the app-rooted config, the recorded fallback is an
   explicit `--root .` invocation with a root-relative include — an evidence note, never a devDep add. A
   jsdom-missing-API throw would be an ENVIRONMENT artifact (census: zero known — see §Ground census); the
   remedy is a stub inside the transient test file, stated in evidence, never an app/package change.
5. The `fn()` no-op click proof: the sweep MAY dispatch a click on a rendered `actions/Button` story and
   assert no throw; the browser click on `:5176` stays in the Director's deepened verify either way.

## The adversarial probes (K-4 — exact procedure, both TRANSIENT)

- **(a) The 7th name → LOUD.** Create
  `packages/mercury-ui/src/components/actions/__ProbeSeventh__/__ProbeSeventh__.stories.tsx`: a minimal
  CSF file adding `import { spyOn } from "storybook/test";` (`spyOn` is a real storybook/test export the
  shim deliberately lacks). Run `pnpm --filter @mercury/showcase build` (or load it on `:5176`) → vite
  import-analysis fails LOUD (no matching export in `storybook-test.ts`). Record the failing output; the
  recorded remedy is ONE added shim export via escalation, never an inline workaround. DELETE the folder.
- **(b) The render throw → CONTAINED.** Create
  `packages/mercury-ui/src/components/actions/__ProbeThrow__/__ProbeThrow__.stories.tsx`: a local trivial
  component as `meta.component`, one story whose `render` throws `new Error("probe: render throw")`, one
  sibling args-only story. On `:5176` the throwing card shows the inline error (title + message), the
  sibling renders, the shell stays live. DELETE the folder.
- **After both:** `git status --porcelain packages/` → empty (the Director re-verifies).

## FORK-1 — meta-level decorators (OPEN; the Operator rules; framed, never decided)

- **Arm A — support the censused decorator shape.**
  *Rationale:* 5 components author their demo framing as a meta decorator; the interpreter's one-source
  law (epic §0) says the showcase renders the same story the Storybook host renders.
  *5W:* the 5 files (`Separator`, `Divider`, `Progress`, `PasswordStrength`, `AuthLayout`) render framed
  everywhere their stories are consumed; the cost is ~6 lines in `parseCsfModule`/`StoryCard`, censused to
  ONE signature (`(Story) => JSX`), meta-level only, arrays of length 1.
  *Steelman for B:* it is new interpreted surface beyond the pre-census letter ("render/args only"), and a
  future story-level or hook-bearing decorator would silently exceed what this rung proved.
  *Steward note:* the supported shape is pinned to the census (meta-level, the one signature); anything
  beyond renders unwrapped and is a future rung's fork.
- **Arm B — ignore decorators (the pre-census letter).**
  *Rationale:* the smallest interpreter; decorators stay the Storybook host's concern.
  *5W:* 4 components render their width-frame demos unframed (cosmetic bleed at panel width);
  `AuthLayout` — a `height:100%` layout — renders without its 760px frame box, i.e. visibly broken
  framing on a flagship layout component, on the surface mx.9.5's dual-theme acceptance renders through.
  *Steelman for A:* the divergence is not cosmetic for AuthLayout; and "one source, two renderers"
  is the epic's stated law — a renderer that drops a censused field is a second source.
  *Steward note:* under B, INV-2's sweep still passes (mount ≠ framing) — the loss is visual fidelity,
  not liveness.
- **Steward: Arm A** — ~6 censused lines buy as-designed rendering on 5 components including the one
  layout flagship; the supported shape is closed by census, so the surface growth is bounded.

The ruling lands as one `RULED` line in the body §4 FORK-1 block; both arms keep INV numbering intact.

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The interpreter parses the CSF module per §Interpreter contract — merged args, `story.render ?? meta.render` mounted WITH args, `createElement(meta.component, args)` fallback, `story.name ?? export key` titles, error-boundaried cards, FORK-1 decorators per ruling | S-1 | INV-1, INV-3, INV-4 |
| R-2 | The Stories stub (ComponentPage.tsx:41–42) is replaced by `<StoriesPanel entry={entry} />` (await → loading → cards; docs stub untouched) | S-1 | INV-2, INV-5 |
| R-3 | `play` is never invoked; play-only shim stubs never fire during render; a stub throw ESCALATES (both loud modes — the shim `Error` and the property-access `TypeError`) | S-2 | INV-3, INV-2 |
| R-4 | The liveness sweep: all 65 loaders awaited + every story mounted boundary-free; the 11 shim importers named in evidence; both sweep files transient | S-2 | INV-2, INV-6 |
| R-5 | The two adversarial probes run and revert (`__ProbeSeventh__` → loud vite failure; `__ProbeThrow__` → contained card); `packages/` clean after | S-3 | INV-2, INV-4 |
| R-6 | Lazy per selection (only the selected entry's loader fires); committed scope `apps/showcase/src/**`; barrel byte-identical; consume-down greps empty | S-4 | INV-5, INV-6 |

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`; the mx.9.2 lessons carried)

```bash
pnpm run typecheck:mercury            # @mercury/*-scoped — NOT ./packages/*: a raw ./packages/* sweep
pnpm run build:mercury                # walks @echo/fx, which fails from HEAD (the mx.9.2 lesson)
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm run build:apps                   # ./apps/* minus @mercury/storybook → echomq + mobile + showcase
grep -rnE "from \"@storybook/" apps/showcase/src --exclude-dir=node_modules            # → empty
grep -rnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" \
  apps/showcase --exclude-dir=node_modules                                             # → empty
grep -rn "\.play" apps/showcase/src   # → only a comment / deliberate exclusion line, never a call
# Deepened verify (Director, independent): the 65-module liveness sweep (11 shim importers named) ·
# probe (a) 7th-name loud failure · probe (b) contained render throw · the fn() click no-op on an
# actions/Button story at :5176 · lazy two-component navigation (dev network panel) ·
# barrel-diff byte-identical · `git status --porcelain packages/` empty.
```

## Agent stories (Directive → Acceptance gate)

- **AS-1 (interpreter).** *Directive:* write `src/lib/storyRender.tsx` to §Interpreter contract — the
  three seed corrections (args merge · meta-render resolution · args-as-props mount) are binding; apply
  the FORK-1 ruling. *Gate:* Button `Playground` renders a labeled primary button (merged meta args);
  Tabs `Playground` renders an INTERACTIVE tab strip (meta render + state wrapper); Dialog `Sizes` opens
  (hooks in a mounted render); the 8 a11y stories show their `name:` titles.
- **AS-2 (wiring).** *Directive:* replace the stub per §Topology; loading state; inline load-error state.
  *Gate:* selecting a component + Stories tab shows its cards; the Docs stub is byte-unchanged; no
  `REGISTRY` iteration inside the panel (INV-5).
- **AS-3 (sweep).** *Directive:* run the K-3 sweep (the §Sweep default or an equivalent meeting the
  contract). *Gate:* 65/65 pass boundary-free, the 11 named, transcript recorded, both transient files
  deleted.
- **AS-4 (probes).** *Directive:* run K-4 (a) then (b) exactly per §Probes. *Gate:* the loud failure and
  the contained card are both evidenced; `git status --porcelain packages/` → empty.
- **AS-5 (gate).** *Directive:* run §Gate ladder top to bottom. *Gate:* every step green; the report
  carries the sweep + probe evidence verbatim.

## The prompt (the decisions this spec fixes — none are left open except FORK-1)

Replace the mx.9.2 Stories stub with a live panel built to §Interpreter contract: parse `mod.default` as
the meta and every other named export as a story (census: zero non-story exports); per story merge
`{ ...meta.args, ...story.args }`, resolve `story.render ?? meta.render`, mount the render function as its
own component receiving the merged args as props, else `createElement(meta.component, args)`; title by
`story.name ?? export key`; wrap each card in an error boundary; apply meta decorators per the FORK-1
ruling; **never touch `play`**; `parameters` does not exist in the tree — do not read it. Prove the mx.9.1
shim LIVE: sweep all 65 modules boundary-free (the pre-verified vitest form in §Sweep, run from the
workspace ROOT, both files transient), name the 11 `storybook/test` value-importers in evidence, verify
the `fn()` handlers no-op silently, and treat any play-only stub throw (shim `Error` or property-access
`TypeError`) as an escalation, never a patch. Run both adversarial probes and revert them. Commit scope
`apps/showcase/src/**` only; zero new dependency anywhere (ruling E); no git; the ladder + deepened verify
green before reporting.
