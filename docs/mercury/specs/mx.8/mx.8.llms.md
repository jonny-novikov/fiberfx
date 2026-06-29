# MX.8 — build context (for the implementor / the enrichment wave)

Working notes for building [`mx.8.md`](./mx.8.md) — the Storybook enrichment (palette · roundings · variant
switching · actions · real-world scenes). Root = `mercury/`. The body is authoritative; this file derives
from it. **SOLID-FORWARD:** mx.8 is **built after mx.7.4** and **re-sharpened at its ship** — re-run the
reconcile against the as-built tree first (the post-mx.7.4 component set, the product-app list, the
installed Storybook actions util are all reconciled then). **NO-INVENT:** every ramp/radius/token name here
is a real live name traced from `packages/mercury-ui/src/styles/tokens.css`; every component prop is
verified in the `.tsx`; every Storybook API is verified against the **installed** Storybook before use.
**The `@mercury/ui` barrel + every component file is FROZEN** — mx.8 edits **host config + story files
only**.

## References (read first, in order)

1. [`mx.8.md`](./mx.8.md) — the authoritative body (the §6 mechanisms + §3 token findings are the build
   target; §A the forks).
2. The format exemplar — a host-home Storybook-stories rung with the barrel frozen:
   [`../mx.5/mx.5.md`](../mx.5/mx.5.md) + [`../mx.5/mx.5.llms.md`](../mx.5/mx.5.llms.md).
3. The live host (this rung EXTENDS it): `apps/storybook/.storybook/preview.tsx` (the `withTheme` decorator
   + the `theme` `globalType` — the pattern to generalize), `apps/storybook/.storybook/main.ts` (the glob —
   already spans `stories/scenes/**`), `apps/storybook/package.json` (`build`/`typecheck`; the absent
   actions util).
4. The token source of truth — the palette/roundings grounding:
   `packages/mercury-ui/src/styles/tokens.css` (the six ramps + their **partial** status coverage; the
   `--radius-*` scale with **no** base) and `packages/mercury-ds/project/components/_lib/accent.ts`
   (`mercAccent` — the `-9`/`-11` + alpha precedent; **do not import it into `@mercury/ui`** — it is
   bundle-local; reproduce its discipline in the decorator).
5. The story exemplar to extend — `packages/mercury-ui/src/components/actions/Button/Button.stories.tsx`
   (the typed-union `argTypes` shape the variant audit follows) + the host-home cross-cutting
   `apps/storybook/stories/Tokens.stories.tsx` (the no-`component` host story shape the scenes follow).
6. The scene grounding — the real screens: `apps/mobile/src/screens/{Login,Send,Profile,Home,Wallet,
   Activity}.tsx` + `packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx` (read-only seeds).
7. The component `.tsx` + `<Name>.prompt.md` for every component whose story is audited/enriched (the prop
   surface is truth).

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22.18, pnpm 10.17.1, TypeScript ^5.6.3. `tsconfig.base.json`:
  `moduleResolution: "Bundler"`, `jsx: "react-jsx"`, `verbatimModuleSyntax: true` (so `import type` for
  types), `strict` + `noUncheckedIndexedAccess`.
- **The host IS edited this rung** (unlike mx.5). A toolbar global needs a `preview.tsx` change — that is in
  scope. What stays frozen is the **`@mercury/ui` surface** (barrel + component files). `main.ts` needs
  **no** glob edit (it already spans `stories/**`).
- **`sb:typecheck` is the authoritative NO-INVENT gate.** The library `tsc` excludes `**/*.stories.tsx`
  (mx.3 `D-9`); the host `tsc` (`pnpm sb:typecheck`) is the only `tsc` that checks the enriched stories +
  scenes. An invented enum option, a wrong prop, or a bad scene import fails here.
- **The barrel is FROZEN this rung.** `packages/mercury-ui/src/index.ts` must be byte-identical to HEAD.
  mx.8 adds no export; it does not edit any component `.tsx`/`index.ts`/`.prompt.md`/style. The only
  `packages/mercury-ui/src/**` edits are `*.stories.tsx`.
- **Palette grounding (load-bearing).** `--bg-brand` family resolves over a ramp: `--bg-brand: var(--iris-9)`,
  `--bg-brand-subtle: var(--iris-3)`, `--fg-brand: var(--iris-11)`, … The six ramps are
  `iris · indigo · green · orange · plum · red`. **`iris`/`indigo` ship full 1–12; `green`/`orange`/`plum`/
  `red` ship ONLY `-3`/`-9`/`-11`.** A remap to `--green-10`/`--plum-4` is undefined → broken color. Use the
  §6.1 table (all-six-safe steps + fallbacks).
- **Roundings grounding (load-bearing).** There is **no** `--radius` base — the scale is
  `--radius-2/4/6/8/12/16/20/24/32/full`, read by step. Override `--radius-2 … --radius-32` on the wrapper;
  **never** override `--radius-full` (avatars/switches/chips read it for the circle).
- **Actions util is NOT installed.** `storybook/test`, `@storybook/test`, `@storybook/addon-actions` are all
  absent (re-probe at build). Fork 5: ground the `fn()` import to whatever the installed Storybook 10 line
  exposes, or surface the dep to the Operator.
- **Custom properties in React inline style:** `style={{ "--bg-brand": "rgb(var(--green-9))" } as
  React.CSSProperties}` — React passes custom properties through; the wrapper's descendants inherit them.
- **Hooks in stories/scenes:** call `use*` inside the render component (Storybook treats `render`/the story
  component as a React component), never at module top level.

## What mx.8 edits (the whole diff)

```
apps/storybook/.storybook/preview.tsx        # EXTEND: add palette + radius globalTypes; extend withTheme
apps/storybook/.storybook/main.ts            # ONLY if Fork-5 needs an addons: [...] entry (else untouched)
apps/storybook/package.json + pnpm-lock.yaml # ONLY if Fork-5 adds an actions devDep (Operator rules)
apps/storybook/stories/scenes/<Name>.stories.tsx   # NEW: ≥4 host-home scenes
packages/mercury-ui/src/components/<group>/<Name>/<Name>.stories.tsx   # ENRICH (variant argTypes + actions)
docs/mercury/specs/mx.8/                      # this triad
```

**Frozen (no edit):** `packages/mercury-ui/src/index.ts` (barrel) · any component `.tsx`/`index.ts`/
`.prompt.md` · `packages/mercury-ui/src/styles/**` · the host `vite.config.ts`/`tsconfig.json`.

## The decorator recipe (extend `withTheme` — one wrapper, three globals)

Generalize the mx.3 `withTheme` into a decorator that reads `context.globals.{theme, palette, radius}` and
applies all three to the **one** wrapper:

- `theme` (existing) → `className={`${theme}-theme`}` (overrides the ramps via `.dark-theme`/`.light-theme`).
- `palette` → a `style` object overriding the `--bg-brand` family per the §6.1 table (the chosen ramp). The
  override sits on the same wrapper; because the theme block defines the ramp steps and inline style wins,
  `--bg-brand → rgb(var(--green-9))` resolves correctly in both light and dark.
- `radius` → a `style` object overriding `--radius-2 … --radius-32` per the §6.2 preset; **omit
  `--radius-full`.**

Merge the palette + radius overrides into the wrapper's `style`. Keep the existing `background`/`color`/
`fontFamily` lines. Add the two `globalTypes` (a `select`/`radio` toolbar `items` list) beside the existing
`theme` global.

### §6.1 palette remap table (real names — copy into the decorator)

For ramp `R`:

| CSS var to override | Value |
|---|---|
| `--bg-brand` | `rgb(var(--R-9))` |
| `--bg-brand-hover` | `rgb(var(--R-10))` if R∈{iris,indigo} else `rgb(var(--R-9))` |
| `--bg-brand-pressed` | `rgb(var(--R-11))` |
| `--bg-brand-subtle` | `rgb(var(--R-3))` |
| `--bg-brand-muted` | `rgb(var(--R-3))` |
| `--fg-brand` | `rgb(var(--R-11))` |
| `--border-brand` | `rgb(var(--R-9))` |
| `--fg-on-brand` | `rgb(var(--slate-12))` if R == orange else `rgb(var(--slate-1))` |

> Default palette (iris) = **no override** (the live values already point at iris). Optionally also re-point
> the `--bg-active` family (Fork-1 sub-note) — Operator rules; Steward = brand-only. **Never** emit a
> `--<green|orange|plum|red>-10` or `-4`.

### §6.2 roundings preset table

| Preset | override |
|---|---|
| Default | none |
| Sharp | `--radius-2..32` → `0px` (or ≤2px); `--radius-full` untouched |
| Round | `--radius-2..32` → enlarged (~1.5–2×); `--radius-full` untouched |

## The variant audit recipe (per component)

Follow `Button.stories.tsx`: a typed const-array per enum (`const TONES: AlertTone[] = [...]`) feeding
`argTypes: { tone: { control: "select", options: TONES } }`. Audit every component's story for **full**
coverage of its exported unions; top up gaps. `ReactNode` slots stay `control: false`, driven by a story
arg rendering a real `<Icon/>`. The exported union types the array → an invented option fails
`sb:typecheck`.

## The actions recipe

Set interaction handlers as spies on `args`: `args: { onClick: fn(), onChange: fn() }`. Ground the `fn`
import to the installed Storybook test util (Fork 5 — verify at build; do not assume `@storybook/test`). A
handler arg is a spy, never a `ReactNode` slot.

## The scenes recipe (host-home, grounded)

CSF3, `title: "Scenes/<Name>"`, **no** `component:` field (like `Tokens`). Compose **only** real
`@mercury/ui` exports into a real screen, grounded in a **cited** source. Roster (§6.5 — reconcile at ship):
`SignIn` (Login.tsx) · `SendMoney` (Send.tsx) · `Profile` (Profile.tsx) · `Dashboard`
(Home/Wallet/Activity.tsx + ui_kits). A scene may hold local `useState` for demo interactivity, but imports
only `@mercury/ui` (+ `react`/`@storybook/react-vite`) — **no** `@mercury/effector`, no app import, no
`window.MercuryUI`/`_ds_bundle`. A NO-INVENT lead comment names the cited screen.

## Per-deliverable directives + acceptance gates

Each is a **Directive** (build) + an **Acceptance gate** (the check that closes it).

- **K-1 Palette (S-1).** *Directive:* add the `palette` `globalType` + the §6.1 overrides to the decorator.
  *Pre:* only all-six-safe steps; no `--<status-ramp>-10`/`-4`. *Gate:* `sb:typecheck` 0; the partial-ramp
  grep empty; INV-6 render-check (green ⇒ green-9).
- **K-2 Roundings (S-2).** *Directive:* add the `radius` `globalType` + the §6.2 overrides; omit
  `--radius-full`. *Gate:* `sb:typecheck` 0; INV-6 render-check (Sharp ⇒ Card 0px, Avatar 9999px).
- **K-3 Variants (S-3).** *Directive:* audit + top up every component story's `argTypes` to full exported-
  union coverage. *Gate:* `sb:typecheck` 0; an invented option is a compile error.
- **K-4 Actions (S-4).** *Directive:* spy the interaction handlers on `args`. *Gate:* a handler call logs an
  Actions-panel entry (verify in the running book); `sb:typecheck` 0.
- **K-5 Scenes (S-5).** *Directive:* ≥4 host-home `stories/scenes/*.stories.tsx`, each a cited real screen
  in real `@mercury/ui`. *Gate:* `sb:build` registers the `Scenes/*` homes; `sb:typecheck` 0; no effector/
  app/bundle import.
- **K-6 Gate + liveness (S-6/7/8).** *Directive:* run the gate; prove the globals drive the tokens. *Gate:*
  the full §gate green; barrel byte-identical; INV-6 positive render-check (a no-op decorator FAILS).

## Build order (one wave or fanned out ≤2 heavy authors)

1. **The decorator + globals** (`preview.tsx`) — palette + radius. Land + `sb:typecheck` + the INV-6
   render-check first (it gates everything visual).
2. **The variant audit + actions** — enrich the co-located stories in waves (by group). The Director gates
   each wave with `sb:typecheck` + the barrel-byte-identical diff.
3. **The scenes** — the ≥4 host-home compositions (cite the screen each).
4. **Gate + smoke** — the full ladder + `sb:build` (prior homes unchanged + `Scenes/*`) + the INV-6
   render-check + the §INV-8 greps.

## The gate (run from `mercury/`, all EXIT 0)

```bash
pnpm sb:typecheck                                               # host tsc — the NO-INVENT gate
pnpm --filter "./packages/*" typecheck                         # packages clean
pnpm --filter "./packages/*" build                             # packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build  # the product apps build (count reconciled at ship)
pnpm sb:build                                                  # static build; prior homes unchanged + Scenes/*

# barrel BYTE-IDENTICAL (master invariant, strongest form) — expect EMPTY:
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts

# surface frozen — only *.stories.tsx under mercury-ui; host config + scenes elsewhere:
git diff --name-only

# NO-INVENT / token / design-sync / partial-ramp greps — expect EMPTY:
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/scenes apps/storybook/.storybook
grep -rn "window.MercuryUI\|_ds_bundle\|design-sync\|DesignSync" apps/storybook/stories apps/storybook/.storybook
grep -rnE "\-\-(green|orange|plum|red)-(10|4)\b" apps/storybook/.storybook

# INV-6 render-check (gate-liveness) — Palette=green ⇒ a --bg-brand surface computes rgb(48,164,108);
# Roundings=Sharp ⇒ a --radius-8 surface computes 0px while an Avatar (--radius-full) stays 9999px.
# Harness chosen at ship (play function / getComputedStyle probe). A no-op decorator FAILS this.
```

## Gotchas

- **Partial status ramps.** `green`/`orange`/`plum`/`red` have only `-3`/`-9`/`-11`. Never emit
  `--<ramp>-10`/`-4` — undefined → broken color. Use the §6.1 fallbacks (mirrors `mercAccent`).
- **`--radius-full` is sacred.** Never override it in the roundings preset — avatars/switches/chips read it
  for the circle. Only `--radius-2 … --radius-32` move.
- **The no-op decorator trap (the load-bearing one).** A decorator that registers the picker but never
  overrides the variable compiles green and ships a false feature. INV-6 demands a POSITIVE render proof
  (computed style changes) — a no-op is a LOUD failure, not a silent pass.
- **The barrel is BYTE-IDENTICAL.** Any `packages/mercury-ui/src/index.ts` change is a fail. The only
  `mercury-ui` edits are `*.stories.tsx` (no `.tsx`/`index.ts`/`.prompt.md`/style).
- **Never import the bundle.** No `mercury-ds/.../*.stories.tsx`, no `_ds_bundle`, no `mercAccent` import
  into `@mercury/ui`/the host — reproduce its discipline, don't import it. Design flows DOWN: no
  `/design-sync`, no `DesignSync`.
- **Actions util is not installed.** Ground the `fn()` import (or the addon) at build; surface a new host
  devDep to the Operator (Fork 5). Do not assume an import path.
- **Reconcile at ship.** The component set (post-mx.7.4), the product-app list (now `echomq · marketing-site
  · mobile · website` — moving), and the home count are reconciled against the as-built tree at ship; this
  body pins mechanism, not counts. Re-run `/mercury-ship reconcile mx.8` first.
- **`TMPDIR=/tmp` does NOT apply** (Elixir-only rule). Use `--filter`, never `pnpm -r` (the `codemojex-node`
  sub-workspace carries its own build state).
- **Commit only when asked, pathspec only.** Everything is under `mercury/apps/storybook/`,
  `mercury/packages/mercury-ui/src/**/*.stories.tsx`, and `docs/mercury/specs/mx.8/`; re-verify
  `git diff --cached --name-only` is purely the mx.8 surface (the bundle `mercury-ds/` stays OUT). Never
  `git add -A`.
- **Framing (propagate):** no gendered pronouns for agents; no perceptual/interior-state verbs; no
  first-person narration. State each surface as a contract.
