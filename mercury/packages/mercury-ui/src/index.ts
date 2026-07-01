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
export * from "./components/inputs/DateField";
export * from "./components/inputs/Calendar";
// selection
export * from "./components/selection/Checkbox";
export * from "./components/selection/Radio";
export * from "./components/selection/Switch";
export * from "./components/selection/Segmented";
export * from "./components/selection/Slider";
export * from "./components/selection/Toggle";
export * from "./components/selection/CheckboxGroup";
export * from "./components/selection/CheckboxCards";
export * from "./components/selection/RadioGroup";
export * from "./components/selection/RadioCards";
// feedback
export * from "./components/feedback/Alert";
export * from "./components/feedback/Progress";
export * from "./components/feedback/PasswordStrength";
export * from "./components/feedback/Callout";
export * from "./components/feedback/Spinner";
export * from "./components/feedback/Skeleton";
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
export * from "./components/data-display/Blockquote";
export * from "./components/data-display/DataList";
export * from "./components/data-display/Code";
export * from "./components/data-display/Kbd";
// navigation
export * from "./components/navigation/Tabs";
export * from "./components/navigation/Accordion";
export * from "./components/navigation/Pagination";
export * from "./components/navigation/Menubar";
export * from "./components/navigation/TabNav";
// overlay
export * from "./components/overlay/Modal";
export * from "./components/overlay/Tooltip";
export * from "./components/overlay/Dialog";
export * from "./components/overlay/AlertDialog";
export * from "./components/overlay/Popover";
export * from "./components/overlay/Dropdown";
export * from "./components/overlay/ContextMenu";
export * from "./components/overlay/HoverCard";
export * from "./components/overlay/LinkPreview";
// layout
export * from "./components/layout/AuthLayout";
export * from "./components/layout/Collapsible";
export * from "./components/layout/AspectRatio";
export * from "./components/layout/ScrollArea";
