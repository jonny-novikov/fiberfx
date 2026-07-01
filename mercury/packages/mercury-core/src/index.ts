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

// Date-field composable + value kit (consumed by @mercury/ui DateField; ui keeps no @internationalized/date dep — INV-6).
export { useDateField } from "./internal/date-time/field/use-date-field";
export type { UseDateFieldOptions, UseDateFieldReturn } from "./internal/date-time/field/use-date-field";
export type { DateValue } from "@internationalized/date";
export { CalendarDate, parseDate } from "@internationalized/date";

// Month-grid calendar composable (consumed by @mercury/ui Calendar; reuses the date value kit above — INV-6).
export { useCalendar } from "./internal/date-time/calendar/use-calendar";
export type { UseCalendarOptions, UseCalendarReturn, CalendarCell, CalendarCellProps, CalendarNavProps } from "./internal/date-time/calendar/use-calendar";

// Overlay-floor headless hooks (consumed by @mercury/ui overlays; published for mx.7.5 — mx.7.4 §A, D-5).
export { useFocusTrap } from "./internal/use-focus-trap";
export type { UseFocusTrapOptions } from "./internal/use-focus-trap";
export { useDismiss } from "./internal/use-dismiss";
export type { UseDismissOptions } from "./internal/use-dismiss";
export { useAnchoredPosition } from "./internal/use-anchored-position";
export type {
	UseAnchoredPositionOptions,
	UseAnchoredPositionReturn,
	AnchoredPlacement,
	AnchoredAlign,
	AnchoredPoint,
} from "./internal/use-anchored-position";
// Stable-id + arrow-nav helpers for aria wiring (useId now; useArrowNavigation published for mx.7.5's menus).
export { useId } from "./internal/use-id";
export { useArrowNavigation } from "./internal/use-arrow-navigation";
