/**
 * `@mercury/ui` date utilities — the locale-aware formatters that back the date
 * field / calendar components, surfaced for app and `@mercury/effector` use.
 * Pure (no React, no Effector); for reactive store wiring see
 * `@mercury/effector`'s `createFormatterModel`.
 */
export {
	createFormatter,
	createTimeFormatter,
	type Formatter,
	type TimeFormatter,
	type FormatterOptions,
	type TimeFormatterOptions,
	type MonthFormat,
	type YearFormat,
	type DayPeriodValue,
	type MaybeReadable,
	type Readable,
} from "./internal/date-time/formatter";
