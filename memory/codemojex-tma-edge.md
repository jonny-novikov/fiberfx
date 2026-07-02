---
name: codemojex-tma-edge
description: "codemojex-tma edge front-end (@codemojex/edge React game island + vendored Phoenix client) — its layout, test infra, and the non-obvious TS/bundle gotchas"
project: codemojex
metadata: 
  node_type: memory
  type: project
  originSessionId: 8f33617c-073d-46e0-b4ac-84ccdc08bf14
---

The **codemojex-tma** track = the TypeScript EDGE front-end of [[codemojex-program]], distinct from the Elixir game engine. It lives in a **self-contained pnpm workspace at `echo/apps/codemojex/assets/`** (the `cm-tma.*` rungs):

- Root pkg **`@codemojex/edge`** (`assets/package.json`) = the React game island. Source in `assets/src/`: `index.tsx` exports `mount(el, props, bridge)` (the ONLY outward contract — `createRoot`, owns its React, no shared-runtime with the LiveView host) + `GameEdge.tsx` (the game component) + `src/components/*` (EmojiKeyboard/EmojiSlots/GuessActions/InfoDashboard/Leaderboard) + `src/types.ts` (the `GameProps`/`Bridge`/`Code`/`GameView` engine↔game contract). `@`→`src` alias.
- Workspace members `packages/*` = the **vendored** `@echo/phoenix` + `@echo/phoenix_live_view` (faithful copies of upstream Phoenix JS; INV-VENDORED-FAITHFUL = type/test edits must be runtime-neutral). One shared `pnpm-lock.yaml` + one `node_modules` for all three.
- Bundler `assets/vite.config.ts` → content-hashed ESM `../priv/static/game/game-[hash].js` + manifest (es2024, React **bundled** not external; NOT git-tracked — the deploy rebuilds it). Uploaded to edge.codemoji.games, dynamic-imported by the GameIsland hook. See [[codemojex-livereact-render]].

**Shipped:** cm-tma.1 (self-contained edge build) · cm-tma.2 (jest→vitest port of both vendored suites, INV-VITEST) · the vendored Phoenix `src/` made strict-typed (Phase A) + `any`-reduced (phoenix 103→58, LV 417→217, runtime-neutral) · **React 18.3.1 → 19.2.7** on the edge (2026-06-29; react-dom + @types to 19.x; zero React-19 component fallout; bundle stayed self-contained) · the **first GameEdge vitest suite** (`assets/vitest.config.ts` jsdom+plugin-react, `test/setup.ts`, `src/GameEdge.test.tsx` — 19 tests through the real component tree against the `Bridge` mock).

**Gotchas (reusable across cm-tma rungs):**
- **jest-dom matcher augmentation must be imported IN the test file.** tsconfig `include:["src","js"]` does NOT cover `test/setup.ts`, so even though setup registers matchers at runtime, tsc won't see the `Assertion` augmentation → `TS2339 toBeInTheDocument does not exist`. Fix: `import "@testing-library/jest-dom/vitest";` at the top of each `*.test.tsx` (idempotent with setup).
- **Evolving-implicit-`any[]` test-scope gap.** The two vendored test tsconfigs set `noImplicitAny:false`, which DISABLES TS's array-evolution analysis → a bare `let x = []` freezes to `never[]` and `.push(string)` fails ONLY under test scope (strict `src` compiles clean). Was the "2 irreducible testScopeErrors" in `phoenix/src/ajax.ts:106` (LV pulls it transitively) — fixed type-only with `let queryStr: string[] = []`.
- **Bundle self-containment check** ("complete package is bundled"): `grep` the output `game-*.js` for external `from"react"`/`require("react")` (expect 0) + grep the inlined version string (`"19.2.7"`) to prove React itself is in the file.
- **pnpm-workspace collision:** `pnpm install` is workspace-GLOBAL (relinks every package's node_modules). NEVER run it while another agent/workflow is running `pnpm build`/`pnpm test` in a sibling package — it throws spurious module-resolution failures → false gate verdicts. File writes to disjoint packages are safe concurrently; installs are not.
- Edge vitest must scope `test.include:["src/**/*.test.{ts,tsx}"]` + `exclude:["packages/**", ...]` so a root run can't pull in the vendored Phoenix suites.

[[codemojex-program]] [[codemojex-livereact-render]] [[jonnify-gitignore-repo-wide-trap]]
