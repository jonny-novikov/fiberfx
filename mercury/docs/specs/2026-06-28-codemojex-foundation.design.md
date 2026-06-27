# Codemojex Foundation — SP‑0 (React 19) + SP‑1 (flat‑fold · `cm` scripts · vitest)

**Status:** design / spec — authored by Venus, awaiting the Operator approval gate. No production code, no scaffold, no `pnpm install`, no commit.
**Date:** 2026-06-28
**Scope:** SP‑0 then SP‑1 (sequenced). SP‑2 (`codemoji-ai` app) and SP‑3 (branded‑id entity browser + L2 Valkey cache) are OUT OF SCOPE here — named only as the downstream rungs this foundation unblocks.
**LOCKED (RULED by the Operator — author around these, do not re‑litigate):** one flat pnpm workspace folding `codemojex-node`; React 19.x monorepo‑wide; `pnpm cm` / `pnpm cm:node` (+ proposed `cm:ai`); vitest the runner; SP‑0 → SP‑1 order.

> Grounding rule for this doc: every "as‑built" claim is cited at `path:line`. Anything not yet built is written forward‑tense and named as a file to be created. Verified compat facts are cited to the exact installed `package.json` they were read from.

---

## 1. Reconcile findings — the as‑built reality

### 1.1 The two workspaces today

**`mercury/` — a pnpm workspace** (`mercury/package.json:7` → `"packageManager": "pnpm@10.17.1"`; `mercury/pnpm-workspace.yaml:1-3` globs `packages/*` + `apps/*`). One lockfile: `mercury/pnpm-lock.yaml` (git‑tracked — `git ls-files` returns it). Members:

| Member | name | React deps today |
|---|---|---|
| `packages/mercury-ui` | `@mercury/ui` | peer `react`/`react-dom` `>=18` (`packages/mercury-ui/package.json:23-24`); dev `@types/react@^18.3.12`, `@types/react-dom@^18.3.1` (`:27-28`) |
| `packages/mercury-effector` | `@mercury/effector` | peer `react >=18` + `effector*`/`@mercury/ui` (`packages/mercury-effector/package.json:22-23`); dev `@types/react@^18.3.12` (`:27`), `react@^18.3.1` (`:31`), `effector(-react)@^23.3.0` (`:30`) |
| `apps/showcase` | `@mercury/showcase` | `react`/`react-dom@^18.3.1` (`apps/showcase/package.json:17-18`); dev `@types/react@^18.3.12`, `@types/react-dom@^18.3.1` (`:21-22`) |
| `apps/catalogue` | `@mercury/catalogue` | identical 18.x shape (`apps/catalogue/package.json:17-18,21-22`) |
| `apps/echomq` | `@mercury/echomq` | identical 18.x shape (`apps/echomq/package.json:17-18,21-22`) |
| `apps/docs` | `@mercury/docs` | identical 18.x shape (`apps/docs/package.json:17-18,21-22`) |

All four apps already consume `@mercury/ui` + `@mercury/effector` via `workspace:*` (e.g. `apps/showcase/package.json:14-15`) and bootstrap with React 18's `createRoot` (`apps/{showcase,catalogue,echomq,docs}/src/main.tsx:2,8-12` — `import { createRoot } from "react-dom/client"`). **This is already the React‑18 client root, so the entry code needs no change for 19.**

**`codemojex-node/` — its OWN npm workspace** (`codemojex-node/package.json:6` → npm `"workspaces": ["packages/*","apps/*"]`; a 146 KB `codemojex-node/package-lock.json`, **NOT git‑tracked**). Members:

| Member | name | intra‑repo deps (the `*` to flip) |
|---|---|---|
| `apps/api` | `codemojex-api` | `@codemojex/types`, `@codemojex/db`, `@codemojex/dto` all `"*"` (`apps/api/package.json:14-16`) |
| `packages/types` | `@codemojex/types` | none — leaf (`packages/types/package.json`) |
| `packages/db` | `@codemojex/db` | `@codemojex/types: "*"` (`packages/db/package.json:16`) |
| `packages/dto` | `@codemojex/dto` | `@codemojex/types: "*"`, `@codemojex/db: "*"` (`packages/dto/package.json:11-12`) |

The api is a Fastify‑5 server whose **`buildApp(env)` factory** (`codemojex-node/apps/api/src/app.ts:17`) returns a fully‑wired instance *without* calling `.listen()` (that lives in `server.ts:9`). The health route is `GET /api/health` → `{ status: "ok", uptime }`, validated by a zod response schema (`codemojex-node/apps/api/src/routes/health.ts:5-10`); it is mounted under `prefix: "/api"` (`app.ts:34`). This factory is the natural `app.inject()` seam for vitest (§4.4).

### 1.2 dev orchestration — the real mechanism `cm` must extend

`mercury/package.json:13` → `"dev": "bash scripts/dev-all.sh"`. `scripts/dev-all.sh:13-16` launches the four apps with a fixed port each, backgrounded, under a `trap 'kill 0' EXIT INT TERM` (`:11`) that tears the whole process group down on Ctrl‑C, then `wait`s (`:27`). Ports: showcase 5173 · catalogue 5174 · echomq 5175 · docs 5176 (`scripts/dev-all.sh:13-16`, mirrored in the `dev:*` scripts `mercury/package.json:14-17`).

`scripts/kill.sh` stops **only the listeners on those fixed ports** via `lsof -ti "tcp:${port}" -sTCP:LISTEN` (`kill.sh:20`) — deliberately NOT `pkill vite` (`kill.sh:6`), and it accepts extra ports as args (`kill.sh:16` → `PORTS=(5173 5174 5175 5176 "$@")`). **This is the contract `cm` extends: fixed‑port + group‑trap + port‑scoped kill — not a new mechanism.**

### 1.3 tsconfig topology (matters for `pnpm -r typecheck`)

There is **no root `tsconfig.json`** in mercury — only `mercury/tsconfig.base.json` (`jsx: "react-jsx"`, `moduleResolution: "Bundler"`, `strict`, `skipLibCheck: true`). Each React package/app extends it and pins `"types": ["react","react-dom"]` (`packages/mercury-ui/tsconfig.json`, `apps/showcase/tsconfig.json`). `codemojex-node/tsconfig.base.json` pins `"types": ["node"]` instead. So `pnpm -r typecheck` (`mercury/package.json:23` → `pnpm -r --if-present typecheck`) runs each member's own `tsc --noEmit`, and the React vs Node ambient type sets stay **disjoint** — which is correct and must be preserved through the fold. pnpm's non‑hoisted store enforces this (a package sees only its declared deps), a point in favour of the LOCKED pnpm‑over‑npm choice.

### 1.4 The React‑19 risk surface — `none — clean`, with evidence

I scanned every component (`packages/mercury-ui/src/components/*.tsx`), the entry (`packages/mercury-ui/src/index.ts`), the effector source (`packages/mercury-effector/src/*`), and all four apps' `src/`. The React‑19 hard‑break patterns return **zero hits**:

| React‑19 break | grep result | evidence |
|---|---|---|
| `defaultProps` on a function component | **none** | defaults are via destructuring, e.g. `Button.tsx:29` `{ variant = "primary", … }`, `Selection.tsx:17` `{ checked = false, … }` |
| `propTypes` | **none** | TS types only |
| legacy context (`childContextTypes`/`contextTypes`/`getChildContext`) | **none** | — |
| string refs (`ref="…"`) | **none** | only object/callback refs |
| `UNSAFE_*` lifecycles | **none** | no class components at all |
| `ReactDOM.render` / `.hydrate` (removed in 19) | **none in lib**; apps already on `createRoot` | `apps/*/src/main.tsx:2` use `react-dom/client` `createRoot` — the React‑18 API React 19 keeps |
| `React.FC` / implicit‑children | **none** | children are explicit `children?: ReactNode` props, e.g. `Card.tsx:7`, `Overlay.tsx:13` |
| `react-dom/test-utils` (`act` moved) | **none** | — |

**Patterns present that are React‑19‑compatible (no rewrite needed, just a version bump):**

- **`forwardRef`** in `Button.tsx:1,28`, `Input.tsx:1,14,54`, `Select.tsx:1,19`. In React 19 `forwardRef` is *soft‑deprecated* (ref‑as‑prop is the new idiom) but **fully functional** — modernizing it is explicitly NOT in SP‑0's scope.
- **Callback refs** in `AuthCode.tsx:33-35` use a **block body that returns `void`**. This matters: React 19 adds *ref cleanup functions*, so a callback ref that implicitly returned a value would now be misread as a cleanup. These return nothing — **safe**.
- **`useRef<T>(null)`** (`Selection.tsx:18`, `AuthCode.tsx:15`) and **`useId`** (`Input.tsx:18,58`, `Select.tsx`) — unchanged in 19.
- **`createPortal`** (`Overlay.tsx:2,28`) — unchanged in 19.
- **`React.CSSProperties` via the global namespace without importing React** (`toast.tsx:64`). Works under `@types/react@18` and is **retained** under `@types/react@19`'s global namespace — not a break. Flagged only because the `types-react-codemod` may rewrite global‑`React.*` references to named imports; if it does, that's a cosmetic, safe edit.

**Conclusion:** SP‑0 is a **pure dependency bump with zero source rewrites expected.** The only file edits SP‑0 *might* make are codemod‑driven cosmetic ones (§3.3), and the realistic outcome is "the codemod reports no changes."

### 1.5 Verified external compatibility facts

| Fact | Verified value | Read from |
|---|---|---|
| `effector-react@23.3.0` peer `react` range | **`">=16.8.0 <20.0.0"`** → React 19 allowed (19 < 20); **no bump needed** | installed `node_modules/.pnpm/effector-react@23.3.0_…/node_modules/effector-react/package.json` (`peerDependencies.react`) |
| `@vitejs/plugin-react` version + react ceiling | **`4.7.0`**; peers only on `vite` (`^4.2.0 \|\| ^5 \|\| ^6 \|\| ^7`) — **no react peer ceiling** → 19 fine | installed `node_modules/.pnpm/@vitejs+plugin-react@4.7.0_…/…/package.json` + `mercury/pnpm-lock.yaml` |
| `vite` version | **`6.4.3`** (satisfies plugin‑react's `^6.0.0`) | `mercury/pnpm-lock.yaml` (`vite@6.4.3`) |
| currently‑resolved React types | **`@types/react@18.3.31`, `@types/react-dom@18.3.7`** (the SP‑0 bump origin) | `node_modules/.pnpm/@types+react@18.3.31`, `…@types+react-dom@18.3.7_…` dir names |
| vitest present anywhere? | **no** — every `vitest` hit is a transitive dep inside `node_modules`; SP‑1's floor is greenfield | `grep -rn "vitest\|@testing-library\|jsdom" --include=package.json` over `mercury/` |
| `codemojex-node/package-lock.json` tracked? | **no** — only `mercury/pnpm-lock.yaml` is tracked | `git ls-files` |

---

## 2. Decision summary (around the LOCKED rulings)

1. **SP‑0 first, then SP‑1** — bump React to 19 across the existing six members while they are still two separate installs is *avoidable churn*; but the LOCKED order is SP‑0 then SP‑1, so SP‑0 bumps the **four apps + two packages of `mercury/`** (the six React members) under the *current* pnpm install, proves them green, and only then SP‑1 folds `codemojex-node` in. `codemojex-node` has no React, so SP‑0 never touches it.
2. **Flat pnpm fold, folder kept in place** — extend the glob, delete the npm lockfile + the npm `"workspaces"` field, flip `* → workspace:*`. The `codemojex-node/` directory stays where it is.
3. **`cm` extends `dev-all.sh`** — a sibling orchestrator script, same fixed‑port + trap + port‑scoped‑kill contract.
4. **vitest is the runner** — one root config with projects (or per‑package configs), `app.inject()` for the api, `@testing-library/react` + `jsdom` for React.

---

## 3. SP‑0 — React 19 migration

**Done‑criterion:** all four apps + both packages typecheck clean, build clean, and still render — under React 19. `codemojex-node` untouched.

### 3.1 Version bumps (a table — exact, per package)

Bump these four specifiers to React 19 everywhere they appear; **leave `effector`, `effector-react`, `vite`, `@vitejs/plugin-react`, `typescript` exactly as they are** (all already 19‑compatible — §1.5).

| Package/app | manifest line(s) today | bump to |
|---|---|---|
| `@mercury/ui` | peer `react`/`react-dom` `>=18` (`mercury-ui/package.json:31-32`); dev `@types/react@^18.3.12`, `@types/react-dom@^18.3.1` (`:35-36`) | peer `>=19` (or keep `>=18` — see fork F‑5); dev `@types/react@^19`, `@types/react-dom@^19` |
| `@mercury/effector` | peer `react >=18` (`mercury-effector/package.json:26`); dev `@types/react@^18.3.12`, `react@^18.3.1` (`:31,35`) | peer `react >=19` (or keep `>=18`); dev `@types/react@^19`, `react@^19` |
| `@mercury/showcase` | `react`/`react-dom@^18.3.1` (`:13-14`); dev `@types/react@^18.3.12`, `@types/react-dom@^18.3.1` (`:17-18`) | `react`/`react-dom@^19`; dev `@types/react@^19`, `@types/react-dom@^19` |
| `@mercury/catalogue` | same shape (`:13-14,17-18`) | same → `^19` |
| `@mercury/echomq` | same shape (`:13-14,17-18`) | same → `^19` |
| `@mercury/docs` | same shape (`:13-14,17-18`) | same → `^19` |

> Use the precise current React 19 patch the registry resolves (e.g. `^19.x`); the brief pins `^19` and lets the resolver choose, then the lockfile records the exact version. The two *peer* ranges in the packages (`>=18`) **can stay `>=18`** since 19 satisfies `>=18` — see fork **F‑5** for whether to tighten them to `>=19`.

### 3.2 The codemod step (`types-react-codemod`)

After the `@types/react@19` bump, run the official **`types-react-codemod`** preset against the two TS‑heavy packages (it rewrites `@types/react@18`‑only typings to their `@types/react@19` forms — chiefly the `ReactElement`/`JSX.Element`/implicit‑children typing changes):

```
npx types-react-codemod@latest preset-19 packages/mercury-ui/src packages/mercury-effector/src apps/*/src
```

Given §1.4, the **expected output is "no changes"** (no `JSX.Element` namespace usage, no implicit children, no `propTypes`). Run it anyway as the belt‑and‑braces step the LOCKED spec asks for, and record its diff (likely empty) in the rung notes. Do **not** auto‑apply `--force`; review any hunk it proposes against §1.4 before keeping it.

### 3.3 Break‑risks found → fixes

**None — clean** (§1.4). There is no source rewrite to do. The only conceivable edits are codemod cosmetics:

- *If* the codemod rewrites `toast.tsx:64`'s global `React.CSSProperties` to a named `import type { CSSProperties }` — keep it (harmless, and consistent with the rest of the file which already imports types named, e.g. `Selection.tsx:2`). It is not required.
- No other file is a candidate.

### 3.4 The per‑package SP‑0 gate (TDD note — what proves green)

For each of the six members, in dependency order (`@mercury/ui` → `@mercury/effector` → the four apps):

1. **typecheck clean** — `pnpm --filter <name> typecheck` (each maps to `tsc --noEmit`, e.g. `mercury-ui/package.json:20`). This is the *first* green signal: it proves `@types/react@19` typings resolve with no new errors.
2. **build clean** — `pnpm --filter <name> build` for the two packages (`vite build && tsc -p tsconfig.build.json`, `mercury-ui/package.json:18`); `pnpm --filter <app> build` for the apps (`vite build`, `showcase/package.json` `build`).
3. **apps still render (smoke)** — `pnpm dev:showcase` (and the other three) boots Vite on its fixed port and serves the app; eyeball the page. Until vitest lands in SP‑1 there is no automated render test, so the SP‑0 render proof is the dev/preview smoke. (SP‑1 then backfills an automated `@testing-library/react` render test so this becomes a CI signal — noted, not required for SP‑0 done.)

**SP‑0 done = all six green on (1)+(2) and the four apps pass the (3) smoke.** This is the TDD "red→green" for a dep bump: the typecheck is the failing/ passing oracle, the build is the integration oracle, the smoke is the acceptance oracle.

> SP‑0 changes only `package.json` specifiers (+ at most a codemod cosmetic). It does **not** run `pnpm install` as part of *authoring* — installation is the build agent's action under the Operator's gate, producing the updated `pnpm-lock.yaml`. Per the LOCKED constraints this design doc does not mutate the lockfile.

---

## 4. SP‑1 — flat‑fold + `cm` scripts + vitest

**Done‑criterion:** `pnpm cm:node` boots `codemojex-api` from the mercury root; `pnpm test` is green; install is clean on **one** lockfile (`mercury/pnpm-lock.yaml`), with `codemojex-node/package-lock.json` gone.

### 4.1 The `mercury/pnpm-workspace.yaml` edit (exact)

Today (`mercury/pnpm-workspace.yaml:1-3`):

```yaml
packages:
  - "packages/*"
  - "apps/*"
```

After:

```yaml
packages:
  - "packages/*"
  - "apps/*"
  - "codemojex-node/packages/*"
  - "codemojex-node/apps/*"
```

This pulls `@codemojex/{types,db,dto}` + `codemojex-api` into the **one** pnpm workspace, keeping the `codemojex-node/` folder intact (LOCKED ruling 1).

### 4.2 npm‑workspace teardown (exact files/fields)

1. **Delete** `codemojex-node/package-lock.json` (untracked — §1.5 — so a plain `rm`, no git step).
2. **Remove the `"workspaces"` field** from `codemojex-node/package.json:6` (`"workspaces": ["packages/*","apps/*"]`). Its npm‑workspace scripts that use `-w` flags (`codemojex-node/package.json:10-14` — `dev`/`build`/`start`/`db:*` all `npm run … -w <member>`) **stop working under pnpm** and should be left as‑is only if harmless, but cleaner to either drop them or rewrite them to `pnpm --filter` (see §4.4 note). The root `cm:*` scripts in `mercury/package.json` supersede them.
3. **Add `codemojex-node/package-lock.json` to a gitignore** is unnecessary (untracked already), but optionally add it to `mercury/.gitignore` defensively so a stray `npm install` inside the folder can't reintroduce it. *Surface, don't decide* — fork F‑6.

### 4.3 The full `* → workspace:*` rewrite list (exact, complete)

Every intra‑repo `@codemojex/*` specifier (all currently `"*"` — §1.1) flips to `"workspace:*"`. This is the **complete** set (verified by scanning all four manifests):

| manifest | dependency | `"*"` → |
|---|---|---|
| `codemojex-node/apps/api/package.json:14` | `@codemojex/types` | `"workspace:*"` |
| `codemojex-node/apps/api/package.json:15` | `@codemojex/db` | `"workspace:*"` |
| `codemojex-node/apps/api/package.json:16` | `@codemojex/dto` | `"workspace:*"` |
| `codemojex-node/packages/db/package.json:21` | `@codemojex/types` | `"workspace:*"` |
| `codemojex-node/packages/dto/package.json:22` | `@codemojex/types` | `"workspace:*"` |
| `codemojex-node/packages/dto/package.json:23` | `@codemojex/db` | `"workspace:*"` |

`packages/types/package.json` has **no** intra‑repo deps (leaf) — nothing to flip there. Six rewrites total, across three manifests. The external deps (`fastify`, `drizzle-orm`, `zod`, `pg`, …) are untouched.

### 4.4 vitest floor — authored TDD‑first

**Add** vitest as the monorepo runner. Author the *first test before* wiring beyond what makes it pass (red→green).

- **The first test (api, `app.inject()`):** a new `codemojex-node/apps/api/test/health.test.ts` that imports `buildApp` from `../src/app.ts` (`app.ts:17`), builds the app with a test env (a dummy `DATABASE_URL` is fine — `health.ts` never touches the pool; the pg pool in `plugins/db.ts` connects lazily on first query, not at registration), and asserts:

  ```ts
  import { test, expect } from "vitest";
  import { buildApp } from "../src/app.js";

  test("GET /api/health → 200 ok", async () => {
    const app = await buildApp({
      DATABASE_URL: "postgres://test", PORT: 0, HOST: "127.0.0.1", LOG_LEVEL: "silent",
    });
    const res = await app.inject({ method: "GET", url: "/api/health" });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ status: "ok" });
    await app.close();
  });
  ```

  This is the canonical Fastify test idiom — `inject()` exercises the full plugin/route stack in‑process, no port. It proves the fold worked end‑to‑end: vitest resolves the workspace‑linked `@codemojex/*` sources through the api.

- **The React render floor (one representative test):** a `packages/mercury-ui/test/Button.test.tsx` using `@testing-library/react` + `jsdom` that renders `<Button>Go</Button>` and asserts the label text + `mx-btn` class are present (grounding: `Button.tsx:38,46`). This both seeds the React test harness and becomes the **automated** SP‑0 render proof (§3.4 step 3) going forward.

- **Config shape — recommend a single root `vitest.workspace.ts`** (or `test.projects` in a root `vitest.config.ts`) at `mercury/` with two projects:
  - a **node** project (environment `node`) globbing `codemojex-node/apps/*/test/**` + `codemojex-node/packages/*/test/**`;
  - a **jsdom** project (environment `jsdom`, `@testing-library/jest-dom` setup) globbing `packages/*/test/**` + `apps/*/test/**`.

  One root config keeps a single `pnpm test` entry and avoids six per‑package configs; the per‑project `environment` split is what lets Fastify tests run under `node` and React tests under `jsdom` in one run.

- **New dev‑deps to add (at the mercury root):** `vitest`, `@vitest/ui` (optional), `@testing-library/react`, `@testing-library/jest-dom`, `jsdom`. (`@vitejs/plugin-react@4.7.0` is already present and feeds the React project's transform.) Versions: pin `vitest@^3` (the line `@vitejs/plugin-react` itself dev‑deps — `node_modules/.pnpm/@vitejs+plugin-react@4.7.0…` lists `vitest: "^3.2.4"`), `jsdom` current, `@testing-library/react@^16` (the React‑19‑compatible major). Confirm the exact `@testing-library/react` major resolves against React 19 at install (it is the v16 line that adds React‑19 support).

- **Root `test` script:** add to `mercury/package.json:scripts` → `"test": "vitest run"` and `"test:watch": "vitest"`.

### 4.5 `cm` / `cm:node` (+ proposed `cm:ai`) — grounded in `dev-all.sh`

The LOCKED behaviour: `pnpm cm` runs **all `codemojex-*` apps**; `pnpm cm:node` runs the Fastify backend (`codemojex-api`) only. Mirror the real `dev-all.sh` structure (§1.2) — fixed ports, group‑trap, port‑scoped kill — in a sibling script `scripts/cm-all.sh`:

- **`cm:node`** is a thin, single‑process script (no orchestrator needed): `pnpm --filter codemojex-api dev` (which runs `tsx watch src/server.ts` — `apps/api/package.json` `dev`), with the api's port driven by its own `env.ts` (`PORT` default 3000 — `env.ts:5`). Add to `mercury/package.json`: `"cm:node": "pnpm --filter codemojex-api exec tsx watch src/server.ts"` (or `pnpm --filter codemojex-api dev`).
- **`cm`** runs every `codemojex-*` app concurrently via `scripts/cm-all.sh`, structured exactly like `dev-all.sh:11-27`: `trap 'kill 0' EXIT INT TERM`, each member backgrounded on a fixed port, a banner, then `wait`. At SP‑1 the only `codemojex-*` member is `codemojex-api`, so `cm` = `cm:node`‑plus‑banner today; the script is written so that when `codemoji-ai` (SP‑2) lands it is **one added line** (fork F‑3 covers static‑list vs dynamic discovery). Add `"cm": "bash scripts/cm-all.sh"`.
- **Port assignment for the `cm` family (fork F‑4):** the Vite apps own 5173–5176; the api owns 3000 (`env.ts:5`). Propose the `codemojex-*` family take a non‑overlapping block — e.g. api stays 3000, and reserve **5180+** for a future `codemoji-ai` Vite UI — and **extend `scripts/kill.sh`** to know the `cm` ports (it already accepts extra ports as args — `kill.sh:16` — so `pnpm stop 3000 5180` works today; cleaner to add a `cm`‑aware kill). Surface, don't decide.
- **`cm:ai` (proposed, SP‑2):** by symmetry add (flagged proposed, not built this rung) `"cm:ai": "pnpm --filter <codemoji-ai-name> dev"` once the app exists. The app's package name is the open naming question — fork **F‑1**.

### 4.6 The SP‑1 gate

After the fold + scripts + vitest are in place, the build agent (under the Operator's gate) runs:

1. **one clean install** — `pnpm install` at `mercury/` resolves the now‑seven‑plus‑members workspace into the single `mercury/pnpm-lock.yaml`; `codemojex-node/package-lock.json` is gone. Verify no `@codemojex/*` resolves from the registry (all `workspace:*` → linked).
2. **`pnpm -r typecheck`** — every member's `tsc --noEmit` (`mercury/package.json:23`), including the api's (`apps/api/package.json:11` `typecheck`) and the three `@codemojex/*` packages'. Proves the React/Node disjoint type sets survived the fold (§1.3).
3. **build** — `pnpm build` (packages) + `pnpm build:apps` (`mercury/package.json:21-22`); the api builds via its own `tsup` (`apps/api/package.json:9` `build`). Add the api to `build:apps` reach or invoke `pnpm --filter codemojex-api build` explicitly (fork F‑7: the existing `build:apps` globs `./apps/*` which is **mercury's** apps, not `codemojex-node/apps/*` — decide whether to widen the glob or call the api build separately).
4. **`pnpm test`** — vitest runs both projects green (the health `inject()` test + the Button render test).
5. **`pnpm cm:node`** — boots `codemojex-api` from the mercury root and serves `GET /api/health` 200 (the headline done‑criterion).

---

## 5. Risks & open forks (SURFACE — for the Operator to decide, not Venus)

- **F‑1 — `codemoji-ai` vs `codemojex-ai` naming (SP‑2).** The backend folder/name family is **`codemojex-*`** (`codemojex-node`, `@codemojex/*`, `codemojex-api`). The Operator's brief says the new app is `codemoji-ai` (no `x`) and the script is `cm:ai`. There is **no existing `codemoji-ai`/`codemojex-ai`/`cm:ai` reference anywhere** in `mercury/` (grep clean). Recommend deciding the canonical spelling now so `cm` (which discovers `codemojex-*`) and `cm:ai` agree; if the AI app is `codemoji-ai` (no `x`), then a `cm` that greps for `codemojex-*` would **miss it** — F‑3 below.
- **F‑2 — does `cm` discover `codemojex-*` members dynamically or list them?** Dynamic (`pnpm -r --filter "codemoji*" ...`) auto‑includes a future AI app but is sensitive to the F‑1 spelling and could sweep in non‑app packages (`@codemojex/types` etc.). A static list (like `dev-all.sh:13-16`) is explicit and port‑pinnable but needs a one‑line edit per new app. Recommend **static list now** (matches `dev-all.sh`, gives fixed ports), revisit at SP‑2.
- **F‑3 — `cm` filter glob vs the F‑1 spelling.** If `cm` uses a name glob, it must match both `codemojex-api` and the eventual AI app; `codemoji*` matches both `codemoji-ai` and `codemojex-api`, `codemojex*` matches only the latter. Tie this to F‑1.
- **F‑4 — port assignment for the `cm` family.** api = 3000 (`env.ts:5`); the Vite apps hold 5173–5176. Proposal: reserve 5180+ for `codemoji-ai`'s UI and extend `kill.sh` to know the `cm` ports. Needs a ruling on the exact ports.
- **F‑5 — tighten the two package peer ranges to `>=19`?** `@mercury/ui` + `@mercury/effector` peer `react >=18`. React 19 already satisfies `>=18`, so leaving them is correct and maximally compatible. Tightening to `>=19` documents intent but drops 18 consumers (there are none in‑repo). Recommend **leave `>=18`** unless the Operator wants to forbid 18.
- **F‑6 — defensively gitignore `codemojex-node/package-lock.json`?** Untracked already; adding it to `mercury/.gitignore` prevents a stray `npm install` in the folder from reintroducing it. Low‑stakes; recommend yes.
- **F‑7 — `build:apps` glob reach.** `mercury/package.json:21` globs `./apps/*` (mercury's apps only). After the fold, `codemojex-api`'s `tsup` build isn't covered. Decide: widen the glob to also match `codemojex-node/apps/*`, or invoke `pnpm --filter codemojex-api build` separately. Recommend a separate filtered build (the api uses `tsup`, the React apps use `vite build` — different toolchains, cleaner kept distinct).
- **F‑8 — `codemojex-node` root‑script residue.** `codemojex-node/package.json:10-14` has npm‑`-w` scripts that break under pnpm. Decide: delete them, or rewrite to `pnpm --filter`. Recommend delete (the mercury‑root `cm:*` + `db:*` supersede them) — but **surface**, since `db:generate`/`db:migrate` (`codemojex-node/package.json:13-14` → `@codemojex/db`'s `drizzle-kit`) are real workflows that need a root home (`pnpm --filter @codemojex/db db:migrate`).
- **F‑9 — `@testing-library/react` major vs React 19.** The v16 line is the React‑19‑compatible one; confirm at install that the resolved major declares a React‑19 peer. Low risk, flagged for the build gate.

---

## 6. TDD‑shaped task list

> Each task ends in an **independently verifiable green**. No commit steps — "commit only when asked" (the Operator commits the rung; this list does not include git). SP‑0 fully green before any SP‑1 task starts (LOCKED sequence).

### SP‑0 — React 19 migration

1. **Bump `@mercury/ui`** — edit `mercury-ui/package.json` dev `@types/react`/`@types/react-dom` → `^19` (peer stays `>=18` pending F‑5). ✅ *green:* `pnpm --filter @mercury/ui typecheck` clean, then `pnpm --filter @mercury/ui build` clean.
2. **Bump `@mercury/effector`** — edit dev `@types/react`/`react` → `^19`. ✅ *green:* `pnpm --filter @mercury/effector typecheck` + `build` clean.
3. **Bump the four apps** — each `react`/`react-dom` → `^19`, dev `@types/react`/`@types/react-dom` → `^19` (`showcase`, `catalogue`, `echomq`, `docs`). ✅ *green:* `pnpm -r --filter "./apps/*" typecheck` clean.
4. **Run `types-react-codemod preset-19`** over `packages/*/src` + `apps/*/src`; review any hunk against §1.4; keep only safe cosmetics. ✅ *green:* codemod reports no changes (expected) **or** the reviewed diff still typechecks — `pnpm -r typecheck` clean.
5. **Install + build‑all** (build agent, under the gate) — `pnpm install` (updates `pnpm-lock.yaml`), then `pnpm build:all`. ✅ *green:* both build steps succeed.
6. **App smoke** — boot each app (`pnpm dev:showcase` … `dev:docs`) and confirm it renders on its port. ✅ *green:* four apps render under React 19. **← SP‑0 done.**

### SP‑1 — flat‑fold + scripts + vitest

7. **Extend the workspace glob** — add `codemojex-node/packages/*` + `codemojex-node/apps/*` to `mercury/pnpm-workspace.yaml` (§4.1). ✅ *green:* after step 9's install, `pnpm ls -r` lists `codemojex-api` + the three `@codemojex/*`.
8. **Flip `* → workspace:*`** — the six rewrites in §4.3 (api ×3, db ×1, dto ×2). ✅ *green:* `grep -rn '"@codemojex/[^"]*": "\*"'` over `codemojex-node` returns nothing.
9. **Tear down the npm workspace** — delete `codemojex-node/package-lock.json`; remove the `"workspaces"` field (`codemojex-node/package.json:6`); resolve F‑8 residue. Then **one clean install** `pnpm install` at `mercury/`. ✅ *green:* a single `mercury/pnpm-lock.yaml`; no `@codemojex/*` resolved from the registry; `pnpm -r typecheck` clean (proves the disjoint type sets survived — §1.3).
10. **Author the api health test (red→green)** — write `codemojex-node/apps/api/test/health.test.ts` (§4.4) **and** the root vitest config + `test` script + the new dev‑deps. ✅ *green:* `pnpm test` runs the node project and the health `inject()` test passes.
11. **Author the React render floor** — `packages/mercury-ui/test/Button.test.tsx` (§4.4) under the jsdom project. ✅ *green:* `pnpm test` runs both projects green (this also automates the SP‑0 render proof).
12. **Add `cm` + `cm:node` (+ proposed `cm:ai`)** — `scripts/cm-all.sh` modelled on `dev-all.sh` (§4.5); the three root scripts in `mercury/package.json`; resolve F‑3/F‑4 ports. ✅ *green:* `pnpm cm:node` boots `codemojex-api` from the mercury root and `GET /api/health` returns 200; `pnpm cm` brings the family up under one trap. **← SP‑1 done.**

---

## 7. What this foundation unblocks (out of scope here)

- **SP‑2 — the `codemoji-ai` app** (naming per F‑1): a new monorepo member that joins the flat workspace and the `cm`/`cm:ai` family with zero workspace surgery — the point of doing SP‑1 first.
- **SP‑3 — the branded‑id entity browser + L2 Valkey cache**: builds on the `@codemojex/*` types + the Fastify `/api` surface (the BCS `{ns}{base62}` ids the api already validates — `README.md` "Branded ids") and the EchoStore L1/L2 cache‑aside pattern from the Elixir stack.
