// Per-test environment for the @codemojex/edge game island.
// - jest-dom's DOM matchers (toBeInTheDocument, toBeDisabled, …) are registered on THIS
//   package's own vitest `expect`. The workspace hoists a second vitest major to the root,
//   and jest-dom's `/vitest` shim resolves THAT copy (it declares no vitest peer to pin it),
//   so its own `expect.extend` lands on the wrong instance and the matchers never reach the
//   4.x `expect` the tests use. Importing the framework-agnostic matchers and extending the
//   `expect` imported here (the running instance) is the fix. The vitest `Assertion` type
//   augmentation is a type-only concern and lives in src/vitest.d.ts (tsconfig `include`
//   covers `src`, not `test/`).
// - React Testing Library does not auto-clean between tests under vitest, so we unmount
//   every mounted root after each test to keep the jsdom document fresh.
import * as matchers from "@testing-library/jest-dom/matchers";
import { afterEach, expect } from "vitest";
import { cleanup } from "@testing-library/react";

expect.extend(matchers);

afterEach(() => {
  cleanup();
});
