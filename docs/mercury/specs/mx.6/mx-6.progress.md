# mx-6 — AAW scope ledger

## {mx-6-analysis} Analysis

### A-1 — mx.6 reconcile: the gate-liveness hole (load-bearing)

Director framed mx.6 as "page-level *.stories.tsx co-located in apps/*/src/, host needs nothing (like mx.5)". The GLOB half is TRUE (main.ts `../../*/src/**/*.stories.tsx` reaches apps for sb:build); the TYPE-CHECK half is FALSE. With stories in apps/*/src/, NO gate leg type-checks them:
- sb:typecheck (host tsc) — host tsconfig include = {.storybook, stories, packages/mercury-ui/src/**/*.stories.tsx}; does NOT reach apps/*/src.
- packages typecheck/build — packages only.
- apps build = bare `vite build` — a .stories.tsx not imported by main.tsx is never in the graph; vite build doesn't typecheck anyway.
- sb:build — Storybook/esbuild strips types; a type error does NOT fail it.
So D-10's `sb:typecheck` NO-INVENT gate is a NO-OP for mx.6 unless closed. AND: the app's own tsc (include:["src"]) WOULD compile the story but FAIL — apps carry no @storybook/react-vite dep/types — so co-locating regresses `pnpm -r typecheck`.

=> Fork D (the load-bearing one): WHERE stories live + HOW the type gate is made live.
- D1 (RECOMMENDED): co-locate in apps/*/src (honor Operator model) + (a) host tsconfig include += "../*/src/**/*.stories.tsx" (base = apps/storybook/, NOT ../../ like main.ts), (b) each app tsconfig exclude += "**/*.stories.tsx" (exact analog of D-9 library exclude). Config-only, no source.
- D2: host-home apps/storybook/stories/apps/<App>.stories.tsx (mirror mx.5) — zero app edit, host already typechecks+globs stories/**; deep relative imports into ../../../<app>/src.
- D3: add @storybook to all 5 apps + gate via per-app typecheck — heaviest, wasteful (apps retire).

Other forks: A granularity (App-level vs per-screen), B isolation (render <App/> + app CSS; effector is module-global → NO Provider needed), C barrel (freeze — apps already render on current surface). CSS-collision checked: app css html/body{margin:0;height:100%}, no-op #root (Storybook uses #storybook-root), cosmetic webkit scrollbars; classes app-prefixed/compound-scoped — leak is BENIGN, recorded as a handled hazard not a fork.

Screen inventory: showcase 19 pages (Overview + 12 component pages + 3 foundations + 3 patterns), echomq 5 views, mobile 6 screens, catalogue+docs monolithic single-<App/>.

## {mx-6-progress} Progress

### P-1 — mx.6 triad authored (BUILD-GRADE pending Fork-D ruling)

Wrote docs/mercury/specs/mx.6/mx.6.{md,stories.md,llms.md}. Reconcile verdict: BUILD-GRADE on grounding (every screen/store/CSS/surface claim verified in source; no invention), with ONE load-bearing fork OPEN (Fork D — the NO-INVENT type gate is a no-op for an apps/*/src story until host tsc include + app tsc exclude land; Operator rules since it relaxes mx.5's zero-host-edit).

Recommended forks: A=App-level (5 files, 42→47 homes), B=render <App/>+import app CSS (effector module-global → no Provider), C=freeze barrel byte-identical (no gap found), D=D1 co-located + 2 config edits (host include "../*/src/**/*.stories.tsx" + app exclude "**/*.stories.tsx" mirroring D-9).

Grounding: 5 apps already compose Mercury DS today. showcase 19 pages, echomq 5 views, mobile 6 screens, catalogue+docs monolithic. CSS leak benign; store leak avoided by App-level. catalogue has no CSS file.

Canon delta for Director (do-no-harm, not fixed): roadmap "How the program runs" step 3 says pnpm -r typecheck/build where island gate is pnpm --filter "./packages/*".
