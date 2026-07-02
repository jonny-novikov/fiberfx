# MX.9.2 · The derived registry + the shell — glob-built nav, tab stubs, the theme mechanism

> **Status: ✅ BUILT (gate-green 2026-07-02 via `/mercury-ship mx.9.2`; Duo+ — Director + Mars pass-1
> clean, the harden pass collapsed; as-built record §7).** The second sub-rung of
> the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC — **hard-gates on [mx.9.1](../mx.9.1/mx.9.1.md)** (the
> scaffold it builds inside). mx.9.2 lands the **engine's frame**: the DERIVED registry (two lazy
> `import.meta.glob` calls over the real `@mercury/ui` tree — epic INV-6), the grouped sidebar + topbar, the
> persisted route, the component page with **Stories | Docs tab STUBS** (the live panels land at mx.9.3 /
> mx.9.4), and the **theme-toggle mechanism** (the class flip; dual-theme *acceptance* deepens at mx.9.5).
> No story module executes on this rung — the globs stay lazy and uninvoked.
>
> **Risk: NORMAL · formation Trio.** The Operator may override at ship. **Inherited rulings (2026-07-02,
> epic §7 — closed):** B (`@mercury/showcase`) · C (conventional vite/React; chrome skin at mx.9.5) · D
> (prototypes untracked) · E (zero new dependency).

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rung: [`../mx.9.1/mx.9.1.md`](../mx.9.1/mx.9.1.md) ·
canon: [`../../mercury.design.md`](../../mercury.design.md) · acceptance:
[`mx.9.2.stories.md`](./mx.9.2.stories.md) · build context: [`mx.9.2.llms.md`](./mx.9.2.llms.md).

## 0 · The slice

The epic's K-2 (the derived registry + shell) plus the **mechanism half** of K-5 (the theme toggle; the
chrome skin and dual-theme acceptance stay at mx.9.5). The bundle `library.jsx` shapes are REIMPLEMENTED
typed, never ported verbatim: `CAT_ORDER`/`CAT_LABEL` becomes a fixed order/label map keyed by the **real 9
group segments** (app chrome, not a component list — epic INV-6 holds), and the localStorage-persisted
route/theme shape becomes two typed keys. The mx.9.1 sanity page is superseded: its content relocates to the
shell's no-selection Home panel (keeping the token proof + the barrel import that delivers the stylesheet).

## 1 · Goal

The showcase shell exists: a grouped sidebar derived at build time from the real
`packages/mercury-ui/src/components/<group>/<Name>/` tree (65 story-backed components at the 2026-07-02
count — DERIVED, never hardcoded), a topbar with a working light/`dark-theme` toggle, a persisted
`{ group, name, tab }` route, and a component page whose Stories/Docs panels are explicit stubs pointing at
mx.9.3/mx.9.4. Adding a component folder to `@mercury/ui` makes it appear in the nav with **zero**
`apps/showcase/src/**` edit; nav count equals the story-file count; no story module loads.

## 2 · Rationale (5W)

- **Why.** The registry is the epic's anti-drift core (INV-6): derived once, every later surface (stories,
  docs, chrome) keys off it and can never fork from the real tree. Landing it with STUB panels isolates the
  derivation + navigation risk from the interpreter/renderer risk (mx.9.3/9.4).
- **What.** One derivation module (`src/registry.ts`), four chrome pieces (`src/shell/{Sidebar,Topbar,
  ComponentPage,Home}.tsx`), the App rewrite that composes them, a theme-boot line in `main.tsx`, and
  structural CSS (`src/showcase.css`) styled through tokens only.
- **Who.** *Built by* the implementor to [`mx.9.2.llms.md`](./mx.9.2.llms.md). *Consumed by* mx.9.3/9.4
  (each fills one stub panel) and every browser of the library.
- **When.** Second rung; hard-gates on mx.9.1 (the scaffold + shim + gate join). Unblocks mx.9.3 and mx.9.4
  (which may then proceed independently).
- **Where.** `mercury/apps/showcase/src/**` only — no root edit, no lockfile delta, no `packages/**` touch.

## 3 · Invariants (runnable checks)

- **INV-1 · The registry is DERIVED, never hardcoded** (epic INV-6). `src/registry.ts` builds the nav from
  exactly **two** `import.meta.glob` patterns over `../../../packages/mercury-ui/src/components/**` (the
  `*.stories.tsx` modules, lazy; the `*.prompt.md` files, lazy `{ query: "?raw", import: "default" }`),
  deriving `{ group, name }` from path segments. Checks:
  `grep -c "import.meta.glob" apps/showcase/src/registry.ts` → 2;
  `grep -nE '"(Button|Badge|Card|Icon|Tabs|Modal|Table)"' apps/showcase/src/registry.ts` → empty (spot-check:
  no component-name literal); the **liveness probe** (S-1): a throwaway
  `packages/mercury-ui/src/components/foundations/__Probe__/__Probe__.stories.tsx` appears in the nav with
  zero `apps/showcase/src/**` edit — then is deleted (the probe never touches the barrel: `index.ts` lists
  folders explicitly, so an unlisted probe folder is glob-visible but barrel-invisible).
- **INV-2 · Count parity** (epic S-4). The sidebar footer renders the derived total; it equals
  `find packages/mercury-ui/src/components -name "*.stories.tsx" | wc -l` (65 at 2026-07-02 — the number
  appears in the CHECK, never in the code).
- **INV-3 · The shell is app chrome — composes, never houses** (epic INV-4). `apps/showcase/src/shell/**`
  exports nothing beyond the app (no package edit, no barrel entry); the chrome MAY compose `@mercury/ui`
  primitives (it is a consumer app), but defines no reusable library component. Check: `packages/**`
  untouched (Director barrel-diff), and no `apps/showcase` path is imported by anything outside the app.
- **INV-4 · The theme mechanism works** (epic INV-8, mechanism half). The topbar toggle flips
  `light-theme`/`dark-theme` on `document.documentElement` (canon §0), persists to
  `mx-showcase.theme.v1`, and re-applies on boot before first paint. Observable: the Home panel's swatches
  and components repaint on toggle and the class survives a reload. Dual-theme *acceptance across the
  rendered library* is mx.9.5's gate.
- **INV-5 · Lazy discipline — no story module executes at mx.9.2.** The registry stores the glob loader
  functions; nothing calls them this rung (the stubs are static). Enforcement is **MANUAL at review** (a
  loader call is a one-token change no grep can robustly forbid) plus one honest signal: the dev-server
  network panel loads no `*.stories.tsx` on boot or navigation. This keeps the `storybook/test` shim
  unexercised until mx.9.3 — the rung specified to prove its liveness.
- **INV-6 · Scope discipline** (epic INV-9). The diff is `apps/showcase/src/**` only (+ nothing else): no
  root `package.json`, no lockfile, no `packages/**`, no other app. Consume-down greps stay empty
  (`design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle` over `apps/showcase`).

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | `src/registry.ts` — the two lazy globs · path-segment derivation · the fixed 9-group order/label map in the epic-S-4 order (Foundations · Actions · Inputs · Selection · Data display · Feedback · Overlay · Navigation · Layout), unknown segments appended derived (never dropped) · names sorted within a group | S-1, S-2; INV-1 |
| K-2 | `src/shell/Sidebar.tsx` (grouped nav + the derived total in the footer) + `src/shell/Topbar.tsx` (title + theme toggle composing `Button` from `@mercury/ui`) | S-2, S-3; INV-2, INV-3 |
| K-3 | `src/shell/ComponentPage.tsx` — header (group · name) + **Stories | Docs** tab bar; each panel a static stub naming the rung that fills it (mx.9.3 / mx.9.4); no loader call | S-3; INV-5 |
| K-4 | `src/shell/Home.tsx` — the relocated mx.9.1 sanity content (the no-selection panel; keeps the token proof + the stylesheet-carrying barrel import) + `src/App.tsx` rewritten as the shell composition with the persisted route (`mx-showcase.route.v1`, `{ group, name, tab }`) | S-3; INV-3 |
| K-5 | The theme mechanism — `main.tsx` boot-applies the persisted class; the toggle flips + persists (`mx-showcase.theme.v1`); `src/showcase.css` structural layout styled via `rgb(var(--token))` families only (no raw hex — token discipline) | S-4; INV-4 |

## 5 · The method (build order)

1. **Write `src/registry.ts`** to the shape carried in [`mx.9.2.llms.md`](./mx.9.2.llms.md) §Topology (the
   glob patterns, the parse function, the order/label map, the types).
2. **Write the shell** — Sidebar, Topbar, ComponentPage (stubs), Home (relocate the sanity content); rewrite
   `App.tsx` composing them over the persisted route; add the `main.tsx` theme-boot line; add
   `showcase.css` (token-only).
3. **Run the probe + parity checks** (S-1, S-2) — create the throwaway story folder, observe the nav entry,
   delete it; compare the footer total against the `find | wc -l` count.
4. **Run the gate ladder** (brief §Gate) — packages unchanged · showcase typecheck/build · the 3-app gate ·
   the greps; Director re-runs + barrel-diff.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.1](../mx.9.1/mx.9.1.md) (the scaffold, the shim alias, the gate join).
- **Unblocks:** mx.9.3 (fills the Stories stub — and first invokes the story loaders through the shim) and
  mx.9.4 (fills the Docs stub from the prompt loaders); mx.9.5 (chrome + acceptance over this shell).
- **Touches:** `mercury/apps/showcase/src/**` only.

## 7 · As-built record (2026-07-02)

Built by the Duo+ formation (the architect leg collapsed — the triad was WRITE-READY, authored same-day
lag-1; the Director's pre-spawn ground-truth reconcile returned all-MATCH). Pass-1 clean; the harden pass
collapsed. As-built files: `src/registry.ts` (the brief §Topology shape transcribed) ·
`src/shell/{Sidebar,Topbar,ComponentPage,Home}.tsx` · `src/showcase.css` · `src/App.tsx` (rewrite) ·
`src/main.tsx` (boot line) · `src/vite-env.d.ts` (see below). Three flagged realizations, Director-accepted:

1. **`src/vite-env.d.ts` NEW** — the scaffold's tsconfig pins `"types": ["react", "react-dom"]`, so
   `import.meta.glob` is TS2339 without the canonical in-src `/// <reference types="vite/client" />`;
   the app tsconfig is outside the `src/**` boundary, the in-src reference is not. Zero runtime surface.
2. **`parse()` strict-safe realization** — the brief's literal fails strict indexed access
   (`string | undefined`); realized behavior-identically (bind segments to locals, guard `undefined`).
3. **`Home.tsx` wrapper `<main>` → `<section>`** — the shell's `App.tsx` owns the single `<main>`
   landmark; the relocated sanity content is otherwise verbatim.

Gate evidence: packages typecheck + the `@mercury/*`-scoped builds green (the raw `./packages/*` build
still trips the PRE-EXISTING `@echo/fx` wasm-pack failure from HEAD — untouched, out of scope); showcase
typecheck/build green; the 3-app gate green (`showcase · echomq · mobile`); every ladder grep clean with
`--exclude-dir=node_modules`; 65-count parity derived (the number in the check, never the code). The S-1
liveness probe ran **twice** — Mars (`foundations/__Probe__`) and the Director adversarially under an
**unknown group segment** (`zz-probe/__DirProbe__`, exercising the appended-derived path): both
present→deleted→absent with `packages/**` clean after. INV-5 held: zero `loadStories(`/`loadPrompt(` call
sites; every story/prompt chunk code-split lazy, none statically imported by the entry (the dev-server
network-panel observation remains the stated manual step). LAW-1a mutation spot-check: `REGISTRY` export
renamed → TS2724 at the import site → reverted net-zero.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
