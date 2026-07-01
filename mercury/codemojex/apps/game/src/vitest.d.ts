// Registers jest-dom's DOM matcher TYPES (toBeInTheDocument, toBeDisabled, …) on the vitest
// `Assertion` the game's tests use, so `tsc` accepts them.
//
// GameEdge.test.tsx already imports "@testing-library/jest-dom/vitest" for this, but that shim
// augments `declare module "vitest"` from JEST-DOM's own module context — and jest-dom (no
// vitest peer dep) resolves the OTHER vitest major hoisted to the workspace root, not the 4.x
// the game runs, so its augmentation lands on the wrong module. Re-applying the augmentation
// HERE resolves "vitest" from the game's own context (its 4.x), where it merges.
//
// The top-level `import` is load-bearing: it makes this file a MODULE, so `declare module`
// AUGMENTS vitest rather than replacing it (a script-mode `declare module` would shadow
// describe/it/expect/vi). Type-only file — never emitted or executed; the runtime matcher
// registration is in test/setup.ts.
import type * as JestDomMatchers from "@testing-library/jest-dom/matchers";

declare module "vitest" {
  interface Assertion<T = any> extends JestDomMatchers.TestingLibraryMatchers<any, T> {}
  interface AsymmetricMatchersContaining
    extends JestDomMatchers.TestingLibraryMatchers<any, any> {}
}
