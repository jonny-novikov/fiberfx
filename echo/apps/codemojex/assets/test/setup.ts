// Per-test environment for the @codemojex/edge game island.
// - jest-dom/vitest registers the DOM matchers (toBeInTheDocument, toBeDisabled, …).
// - React Testing Library does not auto-clean between tests under vitest, so we unmount
//   every mounted root after each test to keep the jsdom document fresh.
import "@testing-library/jest-dom/vitest";
import { afterEach } from "vitest";
import { cleanup } from "@testing-library/react";

afterEach(() => {
  cleanup();
});
