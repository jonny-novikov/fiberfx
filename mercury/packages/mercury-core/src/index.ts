/**
 * @mercury/core — Mercury's UI-free foundation.
 *
 * The layer that sits below `@mercury/ui` and `@mercury/effector`: the class
 * utility, the locale-aware date formatters, and (in `internal/`, `shared/`,
 * `utils/`, `types`) the headless hooks and shared types the components build
 * on. No React components, no styles. Consumed from source via a vite/tsconfig
 * alias — there is no build step.
 *
 * This barrel surfaces what crosses the package boundary today: `cx` (consumed
 * by every component) and the `date` formatters (re-exported by `@mercury/ui`
 * for app and `@mercury/effector` use). The deeper foundation lives here as
 * files and is surfaced as consumers need it.
 */
export { cx } from "./cx";
export type { ClassValue } from "./cx";

// Locale-aware Intl formatters (pure — no React, no Effector).
export * from "./date";
