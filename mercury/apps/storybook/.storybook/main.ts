import type { StorybookConfig } from "@storybook/react-vite";

// CSF3 host. The `stories` glob is forward-compatible (mx.3.md INV-6): it spans
//   1. the host's own stories/ home (the Tokens story — this rung),
//   2. the library co-located stories (Icon/Button — this rung),
//   3. the apps' src trees (EMPTY until mx.4 — recorded forward).
// Globs resolve from `.storybook/`, so `../../*/src/**` = `apps/*/src/**`.
// The host resolves @mercury/* from source via the auto-merged `vite.config.ts`
// alias block (mx.3.md INV-4); no package `dist/` is required to render a story.
const config: StorybookConfig = {
  framework: "@storybook/react-vite",
  stories: [
    "../stories/**/*.stories.@(tsx|ts)",
    "../../../packages/mercury-ui/src/**/*.stories.@(tsx|ts)",
    "../../*/src/**/*.stories.@(tsx|ts)",
  ],
  addons: [],
};

export default config;
