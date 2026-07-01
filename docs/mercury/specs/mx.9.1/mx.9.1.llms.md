# MX.9.1 · build context (the agent brief)

Build context for [`mx.9.1.md`](./mx.9.1.md) (authoritative body) + [`mx.9.1.stories.md`](./mx.9.1.stories.md)
(acceptance). The body wins on any disagreement. **BUILD-READY + WRITE-READY**: every target file's exact
content is carried below — the first actions are writes. Grounding was verified 2026-07-02 against the
as-built tree (source lines cited per block); re-probe only on a mismatch error, not by default.

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## References — read first (≤2 files; the bytes below are pre-transcribed)

1. **This brief + the body** — [`mx.9.1.md`](./mx.9.1.md) (§3 invariants, §4 deliverables).
2. *(Only on a mismatch)* the mirror sources: `mercury/apps/echomq/package.json` ·
   `mercury/apps/echomq/vite.config.ts` · `mercury/apps/echomq/tsconfig.json`; the barrel
   `mercury/packages/mercury-ui/src/index.ts` (`Button` line 33 · `Badge` 73 · `Card` 75; the stylesheet
   side-effect import line 12); tokens `mercury/packages/mercury-ui/src/styles/tokens.css` (`--indigo-3` 116
   · `--bg-brand` 171 · `--bg-brand-subtle` 174 · `--fg-on-brand` 200). The parent epic
   [`../mx.9/mx.9.md`](../mx.9/mx.9.md) is context, not required reading.

**Inherited rulings (2026-07-02, closed):** Fork B `apps/showcase`/`@mercury/showcase` · Fork C conventional
vite/React on the source alias (`loader.js`/`@babel/standalone` REJECTED) · Fork D prototypes untracked
read-only · Fork E zero new dependency.

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | `package.json` mirrors the exact `apps/echomq` dep/devDep set (`@mercury/showcase`, private, type module, 4 scripts) | S-1 | INV-3, INV-7 |
| R-2 | `vite.config.ts` = the echomq alias block byte-mirrored + ONE `storybook/test` shim entry | S-2 | INV-2, INV-4 |
| R-3 | `src/shims/storybook-test.ts` exports exactly `fn` + the five play-only stubs | S-2 | INV-4 |
| R-4 | `tsconfig.json` mirrors echomq (extends base, same `paths`; NO `storybook/test` paths entry) | S-2 | INV-2, INV-5 |
| R-5 | The sanity page renders `Button`/`Card`/`Badge` + the four token swatches with no package `dist/` | S-1, S-2 | INV-2 |
| R-6 | Root `dev:showcase` ADDED (port 5176, strictPort); `pnpm install` writes the importer block | S-4 | INV-7 |
| R-7 | The gate ladder is green: packages unchanged · showcase typecheck+build · 3-app gate · greps empty | S-3, S-4 | INV-1, INV-3, INV-6 |

## Execution topology — the exact files (write these)

**Runtime shape:** trivial — `index.html` → `src/main.tsx` → `<App/>` (the static sanity page). No routing,
no state, no registry (mx.9.2). The build-order DAG: write the 7 app files → edit the root script → `pnpm
install` → dev-smoke → gate.

### `mercury/apps/showcase/package.json`
*(dep/devDep set byte-mirrors `apps/echomq/package.json` as of 2026-07-02 — including its deliberate absence
of a `@mercury/core` dependency entry; the alias covers core. Do not "fix" the mirror.)*

```json
{
  "name": "@mercury/showcase",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@mercury/effector": "workspace:*",
    "@mercury/ui": "workspace:*",
    "effector": "^23.3.0",
    "effector-react": "^23.3.0",
    "react": "^19",
    "react-dom": "^19"
  },
  "devDependencies": {
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "@vitejs/plugin-react": "^4.3.3",
    "typescript": "^5.6.3",
    "vite": "^6.0.0"
  }
}
```

### `mercury/apps/showcase/vite.config.ts`
*(the three `@mercury/*` lines are byte-identical to `apps/echomq/vite.config.ts`; the fourth entry is the
showcase-specific shim — `storybook/test` is a bare specifier, NOT `@storybook/*` scope)*

```ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@mercury/ui": resolve(__dirname, "../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../packages/mercury-effector/src/index.ts"),
      "@mercury/core": resolve(__dirname, "../../packages/mercury-core/src/index.ts"),
      // 11 story files VALUE-import "storybook/test" (mx.8.2 fn() + play helpers);
      // resolve the bare specifier to app-local code — the showcase never runs play.
      "storybook/test": resolve(__dirname, "src/shims/storybook-test.ts"),
    },
  },
});
```

### `mercury/apps/showcase/src/shims/storybook-test.ts`

```ts
// Local no-op shim for the bare "storybook/test" specifier. Only fn() executes
// at story-module top level (in `args`), so it returns a callable no-op; the
// five play-only helpers throw loudly if ever reached — the showcase renders
// stories but never runs `play` (interaction tests are the Storybook host's job).
// A new story importing a 7th name fails LOUD at vite import-analysis; the fix
// is one added export here.

type AnyFn = (...args: unknown[]) => unknown;

export function fn(impl?: AnyFn): AnyFn {
  return (...args: unknown[]) => impl?.(...args);
}

function playOnly(name: string): AnyFn {
  return () => {
    throw new Error(`storybook/test shim: ${name} is play-only; the showcase does not run play functions`);
  };
}

export const expect = playOnly("expect");
export const userEvent = playOnly("userEvent");
export const fireEvent = playOnly("fireEvent");
export const waitFor = playOnly("waitFor");
export const within = playOnly("within");
```

### `mercury/apps/showcase/tsconfig.json`
*(mirrors `apps/echomq/tsconfig.json`; NO `storybook/test` paths entry — `tsc` does not traverse
`import.meta.glob` targets and no mx.9.1 source imports the specifier. Fallback if a later rung proves
otherwise: a `paths` entry pointing at the shim itself — `"storybook/test": ["./src/shims/storybook-test.ts"]`
— keeping types and runtime aligned.)*

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "noEmit": true,
    "declaration": false,
    "baseUrl": ".",
    "types": ["react", "react-dom"],
    "paths": {
      "@mercury/ui": ["../../packages/mercury-ui/src/index.ts"],
      "@mercury/effector": ["../../packages/mercury-effector/src/index.ts"],
      "@mercury/core": ["../../packages/mercury-core/src/index.ts"]
    }
  },
  "include": ["src"]
}
```

### `mercury/apps/showcase/index.html`
*(`class="light-theme"` per the canon §0 theme mechanism — Mercury is light-primary)*

```html
<!doctype html>
<html lang="en" class="light-theme">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Mercury Showcase</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### `mercury/apps/showcase/src/main.tsx`

```tsx
import { createRoot } from "react-dom/client";
import { App } from "./App";

createRoot(document.getElementById("root")!).render(<App />);
```

### `mercury/apps/showcase/src/App.tsx`
*(a usage SKETCH — `Button`/`Card`/`Badge` are barrel-verified exports (index.ts:33/73/75); adjust each
usage to its co-located `<Name>.prompt.md` contract if a prop below disagrees. The four token names are
styles-verified (tokens.css:171/174/200/116); tokens are space-separated RGB triples consumed as
`rgb(var(--token))`. The barrel import loads the full stylesheet — index.ts:12 side-effect-imports
`./styles/index.css` — so NO css import appears here.)*

```tsx
import { Badge, Button, Card } from "@mercury/ui";

const SWATCHES = ["--bg-brand", "--bg-brand-subtle", "--fg-on-brand", "--indigo-3"] as const;

export function App() {
  return (
    <main style={{ padding: 24, maxWidth: 720, margin: "0 auto" }}>
      <h1>@mercury/showcase — the spine</h1>
      <p>
        Source-resolved via the workspace alias; the stylesheet arrives through the barrel. The registry,
        shell, stories, and docs surfaces land at mx.9.2–9.5.
      </p>
      <Card>
        <Button>Primary action</Button> <Badge>alias-live</Badge>
      </Card>
      <section aria-label="token swatches">
        {SWATCHES.map((token) => (
          <div
            key={token}
            style={{ background: `rgb(var(${token}))`, padding: 8, marginTop: 8 }}
          >
            <code>{token}</code>
          </div>
        ))}
      </section>
    </main>
  );
}
```

### `mercury/package.json` — ONE line added
After the `"dev:mobile"` script line (5174/5175/5177/5180 are taken; 5176 verified free 2026-07-02):

```json
    "dev:showcase": "pnpm --filter @mercury/showcase exec vite --port 5176 --strictPort",
```

No other root edit — the app auto-joins `build:apps` (the `./apps/*` glob minus `!@mercury/storybook`).

### `mercury/pnpm-lock.yaml`
Written by `pnpm install` (run from `mercury/`): gains the `@mercury/showcase` importer block (cf. the
`apps/echomq:` importer, ~line 33) — **no new external dependency versions**. Do not hand-edit. The worktree
lockfile is already dirty from a sibling program; the Director partitions at commit.

## Agent stories — Directive + Acceptance gate

- **AS-1 · Write the scaffold.** *Directive:* write the seven `apps/showcase` files exactly as above.
  *Acceptance:* `pnpm install` (from `mercury/`) exits 0; `pnpm --filter @mercury/showcase typecheck` and
  `pnpm --filter @mercury/showcase build` exit 0 → `apps/showcase/dist/`.
- **AS-2 · Wire the root.** *Directive:* add the one `dev:showcase` script line. *Acceptance:*
  `grep -n "dev:showcase" package.json` → the exact line; `pnpm run dev:showcase` serves on `:5176`
  (strictPort — a collision fails loud), `curl -s localhost:5176 | grep -c 'id="root"'` → 1.
- **AS-3 · Prove the spine.** *Directive:* with no package `dist/` present, load the dev-served sanity page.
  *Acceptance:* the three components render and the four swatches paint (a non-transparent computed
  `background-color`); report the observation — the Director re-verifies at review.
- **AS-4 · Close the gate.** *Directive:* run the gate ladder below; report each command's exit.
  *Acceptance:* every step green; the greps empty. The barrel-diff and the lockfile partition are
  Director-run (agents run no git).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`; Node ≥22, pnpm ≥10.17; no TMPDIR var)

```bash
pnpm --filter "./packages/*" typecheck            # unchanged by mx.9.1
pnpm --filter "./packages/*" build                # unchanged
pnpm --filter @mercury/showcase typecheck
pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build    # exactly 3 product apps
grep -RnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
grep -n "storybook/test" apps/showcase/vite.config.ts            # → exactly 1 alias entry
# Director-run: barrel-diff byte-identical; lockfile delta = the importer block only.
```

## The prompt (leaves no decision open)

Write the seven `apps/showcase` files byte-for-byte as this brief's Topology section carries them: the
`@mercury/showcase` package.json (the exact echomq dep set — including no `@mercury/core` entry),
the vite config (three byte-mirrored `@mercury/*` aliases + the one `storybook/test` shim entry), the
six-export shim module, the mirrored tsconfig (no `storybook/test` paths entry), the `light-theme` index.html,
main.tsx, and the sanity App.tsx (adjusting `Button`/`Card`/`Badge` usage only if a co-located `.prompt.md`
contract contradicts the sketch). Add the one `dev:showcase` line to `mercury/package.json` after
`dev:mobile`, run `pnpm install` from `mercury/`, smoke the dev server on `:5176` with no package `dist/`,
then run the gate ladder verbatim and report each exit. Touch nothing else: no `packages/**` edit, no other
app, no git, no `pnpm -r`, no new dependency (Fork E RULED), design seeds unread. Escalate any
mismatch between this brief and the as-built tree — do not improvise past it.
