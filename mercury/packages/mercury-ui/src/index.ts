/**
 * @mercury/ui — Mercury Design System React component library.
 * Token-driven, className-based components. Import the stylesheet once
 * (this entry pulls it in) and consume components anywhere.
 *
 * Components live one-folder-per-component under `components/<group>/<Name>/`
 * (the Claude-Design layout). The UI-free foundation (`cx`, the `date`
 * formatters, headless hooks, shared types) lives in `@mercury/core`; the
 * cross-boundary symbols are re-exported below so this public surface is
 * unchanged for consumers.
 */
import "./styles/index.css";

export { cx } from "@mercury/core";
export type { ClassValue } from "@mercury/core";

// Date formatting utilities (locale-aware Intl wrappers). Framework-agnostic;
// `@mercury/effector` adapts these to stores via `createFormatterModel`.
export { createFormatter, createTimeFormatter } from "@mercury/core";
export type {
  Formatter,
  TimeFormatter,
  FormatterOptions,
  TimeFormatterOptions,
  MonthFormat,
  YearFormat,
  DayPeriodValue,
  MaybeReadable,
  Readable,
} from "@mercury/core";

// actions
export * from "./components/actions/Button";
export * from "./components/actions/Link";
export * from "./components/actions/IconButton";
// foundations
export * from "./components/foundations/Icon";
export * from "./components/foundations/Divider";
export * from "./components/foundations/Heading";
export * from "./components/foundations/Text";
export * from "./components/foundations/Separator";
// inputs
export * from "./components/inputs/Input";
export * from "./components/inputs/Textarea";
export * from "./components/inputs/Search";
export * from "./components/inputs/Select";
export * from "./components/inputs/AuthCode";
export * from "./components/inputs/MoneyInput";
export * from "./components/inputs/Label";
// selection
export * from "./components/selection/Checkbox";
export * from "./components/selection/Radio";
export * from "./components/selection/Switch";
export * from "./components/selection/Segmented";
export * from "./components/selection/Slider";
export * from "./components/selection/Toggle";
// feedback
export * from "./components/feedback/Alert";
export * from "./components/feedback/Progress";
export * from "./components/feedback/PasswordStrength";
// data-display
export * from "./components/data-display/Chip";
export * from "./components/data-display/Tag";
export * from "./components/data-display/Badge";
export * from "./components/data-display/Avatar";
export * from "./components/data-display/Card";
export * from "./components/data-display/Table";
export * from "./components/data-display/Stat";
export * from "./components/data-display/Chart";
export * from "./components/data-display/Checklist";
export * from "./components/data-display/ListRow";
// navigation
export * from "./components/navigation/Tabs";
export * from "./components/navigation/Accordion";
export * from "./components/navigation/Pagination";
// overlay
export * from "./components/overlay/Modal";
export * from "./components/overlay/Tooltip";
// layout
export * from "./components/layout/AuthLayout";
