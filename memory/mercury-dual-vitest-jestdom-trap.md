---
name: mercury-dual-vitest-jestdom-trap
description: "mercury pnpm-workspace jest-dom matchers fail (\"Invalid Chai property\" + TS2339) when a package runs a different vitest major than the hoisted root; fix extends the package's OWN expect"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 8c85ea96-925f-41ca-80a2-7859620110e6
---

In the `mercury/` pnpm workspace, a package on a different **vitest major** than the root-hoisted one silently breaks `@testing-library/jest-dom`. Root hoists `vitest@3.x` to `node_modules/vitest`; a package (e.g. `mercury/codemojex/apps/game` on `vitest@4.x`) runs its own. jest-dom@6 declares **no vitest peer**, so its `/vitest` shim resolves the *hoisted 3.x* and `expect.extend`s THAT instance — the package's 4.x `expect` never gets the matchers.

**Symptoms (look like a missing import but AREN'T — the import is already present):** runtime `Invalid Chai property: toBeInTheDocument`; typecheck `TS2339 Property 'toBeInTheDocument' does not exist on type 'Assertion<HTMLElement>'` (vitest 4 re-exports `Assertion` from `@vitest/expect`; jest-dom's `declare module "vitest"` runs from jest-dom's mis-resolving context → augments the wrong module).

**Fix — anchor BOTH in the package's own module context:**
1. `test/setup.ts`: `import * as m from "@testing-library/jest-dom/matchers"; import {expect} from "vitest"; expect.extend(m)` (bypasses the shim; extends the package's 4.x expect).
2. `src/vitest.d.ts`: a MODULE-mode `declare module "vitest"` (a top-level `import type` makes it MERGE, not replace) extending jest-dom's `TestingLibraryMatchers`. Must live under a tsconfig-`include`d dir (game's `include:["src","js"]` excludes `test/`).

**Clean long-term fix:** converge the workspace on ONE vitest major. Diagnose with: which `node_modules/vitest` version is hoisted vs the package's. Found shipping cmt.3 (2026-07-01). Sibling workspace trap: [[jonnify-gitignore-repo-wide-trap]]. See [[mercury-design-system]] [[codemojex-tauri-track]].
