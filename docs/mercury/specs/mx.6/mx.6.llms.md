# MX.6 — build context (for the implementor / the story-author wave)

Working notes for building [`mx.6.md`](./mx.6.md) — five App-level page stories that render the product apps'
real screens inside the Storybook host. Root = `mercury/`. The body is authoritative; this file derives from
it. **NO-INVENT:** every `@mercury/ui`/`@mercury/effector` name a story touches is reached through the app's
own `<App/>` (the story imports the app, not the library directly — so there is nothing to invent); every path
is real; no story authors a component or a prop. **Edit ONLY** the five new `apps/<app>/src/App.stories.tsx`
files **+ (Fork D-D1)** the host `tsconfig` `include` (one line) and each app `tsconfig` `exclude` (one line) —
**no app source `.tsx`/`.css` edit, no `@mercury/ui` edit.**

> **STOP-AND-SURFACE.** This brief assumes the recommended forks (A = App-level, B = render `<App/>` + app CSS,
> C = freeze, **D = D1 co-located + the two config edits**). **Fork D is the Operator's call** (it relaxes
> mx.5's "zero host-config edit"). Do **not** build until the Director relays the Fork-D ruling. If Fork D = D2
> (host-home), the five files move to `apps/storybook/stories/apps/<App>.stories.tsx`, import the app via deep
> relative paths, and the two config edits are dropped — re-read the body's §A-D before building.

## References (read first, in order)

1. [`mx.6.md`](./mx.6.md) — the authoritative body (the §6 render map + §A forks are the build target).
2. The exemplar story shapes — imitate the CSF3 + NO-INVENT-comment shape exactly:
   `apps/storybook/stories/effector/Theme.stories.tsx` (a cross-component host-home story — the closest sibling
   in spirit) and `apps/storybook/stories/Tokens.stories.tsx` (a render-based, no-`component:`-field story).
3. The app entry each story renders (read each `App.tsx` + `store.ts` to confirm the render is self-contained):
   `apps/{showcase,echomq,mobile,catalogue,docs}/src/App.tsx` + their `store.ts` (the three multi-screen apps).
4. The host (the gate owner): `apps/storybook/.storybook/main.ts` (the glob — already reaches `apps/*/src/**`,
   do NOT edit), `apps/storybook/tsconfig.json` (the `include` — **Fork D-D1 edits this**),
   `apps/storybook/.storybook/preview.tsx` (the mx.3 theme decorator — leave it).
5. The `D-9` precedent for the app `exclude`: `packages/mercury-ui/tsconfig.json`
   (`"exclude": ["**/*.stories.tsx", "**/*.stories.ts"]`).

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6.0.0, React 19, Node 22.18, pnpm 10.17.1, TypeScript ^5.6.3. `tsconfig.base.json`:
  `target/lib ES2024`, `moduleResolution: "Bundler"`, `jsx: "react-jsx"`, `verbatimModuleSyntax: true` (so
  `import type` for types), `isolatedModules`, `strict` + `noUncheckedIndexedAccess`.
- **The apps already compose Mercury DS.** Every app imports `@mercury/ui` + `@mercury/effector` and renders
  real screens today (body §3). A page story **renders the app**, it does not rebuild it — so there is no
  component/prop surface to get wrong inside the story (the surface lives in the app, which already compiles).
- **Effector state is module-global — no Provider.** Every app store is `createStore`/`createEvent`/`createForm`
  at module scope read via `useUnit`; rendering `<App/>` (or any screen) needs **no** context wrapper.
- **CSS is the binding need.** Each app's layout/chrome CSS is imported only in `main.tsx` (Storybook never runs
  `main.tsx`), so the story brings it: `import "./<app>.css"` for `showcase`/`echomq`/`mobile`/`docs`;
  `catalogue` has **no** CSS file (inline styles + tokens) → import none.
- **The sb:build glob already reaches `apps/*/src/**`** (`main.ts` `"../../*/src/**/*.stories.@(tsx|ts)"`,
  resolved from `.storybook/`). A story in `apps/<app>/src/` is registered with **no** `main.ts` edit. Economy
  (`codemojex-node/apps/economy`) is NOT under `apps/` → out of scope.
- **`sb:typecheck` is the authoritative NO-INVENT gate — but it does NOT see `apps/*/src/` until Fork D-D1.**
  Host `tsconfig.json` `include` lacks `apps/*/src`; each app lacks `@storybook/react-vite`. Fork D-D1 fixes
  both (below). The library `tsc` excludes `**/*.stories.tsx` (`D-9`); the host `tsc` is the only story `tsc`.
- **CSF3 import:** `import type { Meta, StoryObj } from "@storybook/react-vite";` (see the exemplars).

## The file tree (Fork D-D1 — create/edit exactly these; nothing else)

```
# NEW story files (the whole substance):
apps/showcase/src/App.stories.tsx
apps/echomq/src/App.stories.tsx
apps/mobile/src/App.stories.tsx
apps/catalogue/src/App.stories.tsx
apps/docs/src/App.stories.tsx

# Fork D-D1 config edits (config, NOT source):
apps/storybook/tsconfig.json        # include += "../*/src/**/*.stories.tsx"   (ONE line)
apps/showcase/tsconfig.json         # exclude (new array) = ["**/*.stories.tsx"]
apps/echomq/tsconfig.json           # exclude (new array) = ["**/*.stories.tsx"]
apps/mobile/tsconfig.json           # exclude (new array) = ["**/*.stories.tsx"]
apps/catalogue/tsconfig.json        # exclude (new array) = ["**/*.stories.tsx"]
apps/docs/tsconfig.json             # exclude (new array) = ["**/*.stories.tsx"]
```

No `main.ts` edit · no `@mercury/ui` edit · no app source `.tsx`/`.css` edit · no per-screen story.

## The Fork D-D1 config edits (exact)

1. **Host `apps/storybook/tsconfig.json` — add ONE `include` entry** so `sb:typecheck` compiles the apps-side
   stories. The `include` resolves from `apps/storybook/`, so `apps/*` = `../*` (NOT `../../*` — that base is
   `main.ts`'s, which resolves from `.storybook/`):
   ```jsonc
   "include": [
     ".storybook/**/*.ts",
     ".storybook/**/*.tsx",
     "stories/**/*.ts",
     "stories/**/*.tsx",
     "../../packages/mercury-ui/src/**/*.stories.tsx",
     "../*/src/**/*.stories.tsx"          // ← NEW: the five apps-side page stories
   ]
   ```
   *Verify after:* `pnpm sb:typecheck` now type-checks the five new files (the liveness proof in §gate).

2. **Each app `tsconfig.json` — add an `exclude`** (the `D-9` analog) so the app's own `tsc` ignores the
   co-located story (the app carries no `@storybook/react-vite` types). The five app tsconfigs currently have
   **no** `exclude` key — add one:
   ```jsonc
   "include": ["src"],
   "exclude": ["**/*.stories.tsx"]       // ← NEW (mirrors packages/mercury-ui/tsconfig.json, D-9)
   ```
   *Verify after:* `pnpm --filter "./apps/*" --filter "!@mercury/storybook" typecheck` stays 0.

## The story-shape recipe (every file)

CSF3, mirroring the Tokens/effector exemplars — minimal, because the app does the work:

```tsx
// NO-INVENT: renders the real <App/> from this app — composed entirely from
// @mercury/ui + @mercury/effector (see App.tsx). The story authors no component
// and no prop; the app's module-global effector store drives navigation.
import type { Meta, StoryObj } from "@storybook/react-vite";
import { App } from "./App";
import "./<app>.css";                    // OMIT for catalogue (no stylesheet)

const meta: Meta = { title: "Apps/<App>" };   // cross-app page — no `component:` field
export default meta;
type Story = StoryObj;

export const Default: Story = { render: () => <App /> };
```

- `title` scheme: **`Apps/<App>`** — `Apps/Showcase`, `Apps/EchoMQ`, `Apps/Mobile`, `Apps/Catalogue`,
  `Apps/Docs`. One `title` = one sidebar home → **+5 homes** regardless of stories-per-file.
- No `component:` field (these are cross-component pages, like `Tokens.stories.tsx`).
- A leading NO-INVENT comment naming what the story renders (the exemplar pattern).
- Optional polish (not required): a story may set `parameters: { layout: "fullscreen" }`; note the mx.3
  decorator still wraps every story in its own `padding:24px` + theme div, so the app renders inset by 24px —
  cosmetic, acceptable. Do **not** edit the shared decorator to remove the padding (it serves all 47 homes).

## The grounding table (app → what the story renders → isolation needs)

> The story renders the app; verify each `App.tsx` renders self-contained (no Provider, store at defaults)
> before trusting. Source is truth.

| Story file | Renders | Real screens surfaced | CSS import | State (module-global, no Provider) |
|---|---|---|---|---|
| `apps/showcase/src/App.stories.tsx` | `<App/>` → `<Shell>` + `PAGES[useRoute()]` | Overview + 12 component pages + 3 foundations + 3 patterns (19) | `./showcase.css` | `$route`/`$progress`/`$inviteOpen`/`$dangerOpen` |
| `apps/echomq/src/App.stories.tsx` | `<App/>` → `.eqd` frame + `Tabs<View>` | Overview·Jobs·Groups·Batches·Processors (5) | `./echomq.css` | `$view`/`$range`/`$selected`/`$run`/`$procRunning` |
| `apps/mobile/src/App.stories.tsx` | `<App/>` → `.em-phone` + auth/tab router | Home·Activity·Wallet·Profile·Send·Login (6) | `./mobile.css` | `$authed`(=true)/`$tab`/`$sending`/`$filter`/`sendForm` |
| `apps/catalogue/src/App.stories.tsx` | `<App/>` (monolithic 130 lines) | colors/type/components (internal `useState`) | **none** | local `useState` + effector theme |
| `apps/docs/src/App.stories.tsx` | `<App/>` (monolithic 309 lines) | doc sections + `createForm` demo + scroll-spy | `./docs.css` | local `useState` + module-scope `createForm` + effector theme |

### Per-story directives + acceptance gates

Each story is a **Directive** (build) + an **Acceptance gate** (the check that closes it). Surfaces stated as
contracts (precondition / postcondition).

- **Showcase (S-1).** *Directive:* `import { App } from "./App"`; `import "./showcase.css"`; `Default: { render:
  () => <App/> }`. *Post:* renders Shell + the routed page; sidebar nav works in-story. *Gate:* `sb:typecheck` 0
  (story in program); `sb:build` registers `Apps/Showcase`.
- **EchoMQ (S-2).** *Directive:* same shape; `import "./echomq.css"`. *Post:* renders the dashboard + `Tabs`;
  views switch in-story. *Pre:* the theme is governed by the Storybook toolbar (the story does not run the app's
  dark-default `main.tsx`) — acceptable. *Gate:* `sb:typecheck` 0; home `Apps/EchoMQ`.
- **Mobile (S-3).** *Directive:* same shape; `import "./mobile.css"`. *Post:* renders the phone frame; `$authed`
  default `true` → Home; tabs/Send/Login reachable interactively. *Pre:* **mutate no store at module/render
  scope** — render `<App/>` at defaults (leak-free; the screens set state only in `onClick`). *Gate:*
  `sb:typecheck` 0; home `Apps/Mobile`.
- **Catalogue (S-4).** *Directive:* `import { App } from "./App"`; **no** CSS import; `Default: { render: () =>
  <App/> }`. *Post:* renders on tokens alone (the preview loads the `@mercury/ui` stylesheet). *Gate:*
  `sb:typecheck` 0; home `Apps/Catalogue`; the raw-hex grep over the story file empty.
- **Docs (S-5).** *Directive:* same shape; `import "./docs.css"`. *Post:* renders the docs site; the scroll-spy
  `useEffect` mounts and cleans up without error. *Gate:* `sb:typecheck` 0; home `Apps/Docs`.

## Build order (one wave is fine; the files are independent)

The five story files share no file and touch no barrel — buildable in one pass. The Fork D-D1 config edits are
a prerequisite for the gate (do them first, then the five stories). If fanned out: one author can do all five
stories (they are near-identical); the config edits are a single small change. A single-author single-wave
build is the expected formation (the rung is small).

## The gate (run from `mercury/`)

```bash
pnpm sb:typecheck                                                   # host tsc — NO-INVENT gate, exit 0, NOW covers apps/*/src stories
pnpm --filter "./packages/*" typecheck                             # 3 packages clean
pnpm --filter "./packages/*" build                                 # 3 packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build      # the FIVE product apps build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" typecheck  # the FIVE apps typecheck (Fork-D exclude keeps them green)
pnpm sb:build                                                       # static build, exit 0 → 47 story homes

# barrel BYTE-IDENTICAL (master invariant, strongest form) — expect EMPTY:
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts

# no app source rewritten — git diff lists ONLY the 5 stories + 6 tsconfigs (+ the triad):
git diff --name-only ; git status --porcelain apps

# NO-INVENT + token discipline greps over the STORY files only — expect EMPTY:
grep -rln "window.MercuryUI\|_ds_bundle" apps/*/src/*.stories.tsx
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/*/src/*.stories.tsx
```

`sb:build` home count: confirm **47** homes — the 42 prior (36 component/foundation + 6 `Effector/*`) unchanged
+ the 5 new `Apps/{Catalogue,Docs,EchoMQ,Mobile,Showcase}`.

**Liveness proof (do once, then revert):** to prove `sb:typecheck` actually compiles the new stories, edit one
apps-side story to render `<App/>` with a deliberately invalid extra prop (`<App bogusProp={1} />`); re-run
`pnpm sb:typecheck` — it MUST turn RED on that file (the gate runs on it, not skips it); then revert. A gate
whose letter a no-op satisfies proves nothing — this confirms it is live.

## Gotchas

- **The type gate is the rung's load-bearing risk.** With stories in `apps/*/src/`, **no** gate type-checks them
  until Fork D-D1's two config edits land. Build the config edits FIRST; verify the liveness proof above. If the
  Operator ruled Fork D = D2 (host-home), the location and config differ — re-read the body §A-D.
- **The barrel is BYTE-IDENTICAL this rung** (Fork C). Any change to `packages/mercury-ui/src/index.ts` is a
  fail. No app reaches for a missing component (body §3) — if a render genuinely needs a new surface, STOP and
  surface it (the mx.4 additive-growth fork), never grow the barrel silently.
- **Render the app — do NOT rebuild a screen.** The story is `render: () => <App/>`. Authoring chrome or a screen
  inside a story re-implements the app (brittle, and risks inventing surface). Import and render the shipped app.
- **Effector is module-global — no Provider.** Do not wrap `<App/>` in any context provider; the stores resolve
  themselves. Do **not** call a store setter at module/render scope (leak across stories) — the App's defaults
  render fine.
- **CSS import is global in the shared Storybook** — that is expected and benign (body §6.6: only `html,body`
  margin/height, a no-op `#root`, cosmetic webkit scrollbars leak; chrome classes are app-prefixed). Do NOT try
  to scope it by editing the app CSS (out of scope — no app-source edit). `catalogue` imports no CSS.
- **Token-discipline grep roots at the STORY files, not the app source.** Existing app screens may carry a raw
  hex (e.g. `apps/mobile/src/screens/Login.tsx` `color:"#fff"`) — mx.6 neither adds nor edits it, so the grep
  must target `apps/*/src/*.stories.tsx` only. Grepping app source would false-fail on pre-existing hex.
- **The host `include` base differs from the glob base.** `tsconfig.json` `include` resolves from
  `apps/storybook/` → apps are `../*`; `main.ts`'s glob resolves from `apps/storybook/.storybook/` → apps are
  `../../*`. Use `../*/src/**/*.stories.tsx` in the tsconfig (NOT `../../*`).
- **The app `exclude` is the `D-9` analog.** Adding `"**/*.stories.tsx"` to each app `tsconfig` mirrors what
  `packages/mercury-ui/tsconfig.json` already does — keeps the app `tsc` green now that a story lives in `src`.
- **Commit only when asked, pathspec only.** Everything is under `mercury/apps/*/src/*.stories.tsx` + the six
  `mercury/apps/*/tsconfig.json` (+ `docs/mercury/specs/mx.6/`). Re-verify `git diff --cached --name-only` is
  purely the mx.6 surface before any commit. **Exclude `mercury/vitest.config.ts`** — it is the Operator's
  out-of-band edit, not mx.6 (carried from mx.5; leave it to the Operator's staging). Never `git add -A`;
  never `pnpm -r` (use `--filter`).
- **Framing (propagate):** no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person
  narration. State each surface as a contract.
