import { DateFormatter, type DateValue } from "@internationalized/date";
import { hasTime, isZonedDateTime, toDate } from "./utils";
import type { HourCycle, TimeValue } from "../../shared/date/types";
import { convertTimeValueToDateValue } from "./time-value";

/**
 * A read-only, *live* value source — anything that exposes its current value
 * behind a `current` getter. A Svelte `box`, a signal wrapper, or the Effector
 * adapter from `@mercury/effector` (`createFormatterModel`) all satisfy it. The
 * formatter reads `.current` on every call, so changes to the source are picked
 * up immediately with no rebuild and no framework coupling in this package.
 */
export interface Readable<T> {
	readonly current: T;
}

/** A formatter input that may be a plain value or a live {@link Readable}. */
export type MaybeReadable<T> = T | Readable<T>;

/**
 * How the month renders in {@link Formatter.fullMonthAndYear}: an `Intl` month
 * style (`"long"`, `"short"`, `"narrow"`, `"numeric"`, `"2-digit"`) or a custom
 * mapper from the 1-based month number to a string.
 */
export type MonthFormat =
	| NonNullable<Intl.DateTimeFormatOptions["month"]>
	| ((month: number) => string);

/**
 * How the year renders in {@link Formatter.fullMonthAndYear}: an `Intl` year
 * style (`"numeric"`, `"2-digit"`) or a custom mapper from the full year.
 */
export type YearFormat =
	| NonNullable<Intl.DateTimeFormatOptions["year"]>
	| ((year: number) => string);

/** The resolved day period. */
export type DayPeriodValue = "AM" | "PM";

/** Options for {@link createFormatter}. Only `locale` is required. */
export interface FormatterOptions {
	/** BCP-47 locale tag. Static, or a live source to follow a locale store. */
	locale: MaybeReadable<string>;
	/** Month rendering for `fullMonthAndYear`. Defaults to `"long"`. */
	monthFormat?: MaybeReadable<MonthFormat>;
	/** Year rendering for `fullMonthAndYear`. Defaults to `"numeric"`. */
	yearFormat?: MaybeReadable<YearFormat>;
}

/**
 * The locale-aware date-formatting surface used across the date builders. Every
 * method goes through `Intl`'s {@link DateFormatter} at the *current* locale, so
 * output stays consistent and updates when a live `locale` source changes.
 */
export interface Formatter {
	/** Imperatively override the active locale (wins over a live `locale` source). */
	setLocale(newLocale: string): void;
	/** The active locale — the override if one was set, else the (possibly live) source. */
	getLocale(): string;
	/** Format a native `Date` with arbitrary `Intl` options. */
	custom(date: Date, options: Intl.DateTimeFormatOptions): string;
	/** A human "selected date" string, with time included when the value carries one. */
	selectedDate(date: DateValue, includeTime?: boolean): string;
	/** The full month + year, honoring `monthFormat` / `yearFormat`. */
	fullMonthAndYear(date: Date): string;
	/** The full ("long") month name. */
	fullMonth(date: Date): string;
	/** The numeric year. */
	fullYear(date: Date): string;
	/** The `Intl` parts of a date value, timezone-aware for zoned values. */
	toParts(date: DateValue, options?: Intl.DateTimeFormatOptions): Intl.DateTimeFormatPart[];
	/** A single weekday label at the given width (default `"narrow"`). */
	dayOfWeek(date: Date, length?: Intl.DateTimeFormatOptions["weekday"]): string;
	/** "AM" / "PM" for the given instant under the (optional) hour cycle. */
	dayPeriod(date: Date, hourCycle?: HourCycle): DayPeriodValue;
	/** The string value of one `Intl` part of a date value (`""` if absent). */
	part(
		dateObj: DateValue,
		type: Intl.DateTimeFormatPartTypes,
		options?: Intl.DateTimeFormatOptions
	): string;
}

/** Options for {@link createTimeFormatter}. */
export interface TimeFormatterOptions {
	/** BCP-47 locale tag. Static, or a live source to follow a locale store. */
	locale: MaybeReadable<string>;
}

/** The locale-aware time-formatting surface (the time-only counterpart to {@link Formatter}). */
export interface TimeFormatter {
	/** Imperatively override the active locale (wins over a live `locale` source). */
	setLocale(newLocale: string): void;
	/** The active locale — the override if one was set, else the (possibly live) source. */
	getLocale(): string;
	/** Format a native `Date` with arbitrary `Intl` options. */
	custom(date: Date, options: Intl.DateTimeFormatOptions): string;
	/** A human "selected time" string (long time style). */
	selectedTime(date: TimeValue): string;
	/** The `Intl` parts of a time value, timezone-aware for zoned values. */
	toParts(timeValue: TimeValue, options?: Intl.DateTimeFormatOptions): Intl.DateTimeFormatPart[];
	/** "AM" / "PM" for the given instant under the (optional) hour cycle. */
	dayPeriod(date: Date, hourCycle?: HourCycle): DayPeriodValue;
	/** The string value of one `Intl` part of a time value (`""` if absent). */
	part(
		dateObj: TimeValue,
		type: Intl.DateTimeFormatPartTypes,
		options?: Intl.DateTimeFormatOptions
	): string;
}

const defaultPartOptions: Intl.DateTimeFormatOptions = {
	year: "numeric",
	month: "numeric",
	day: "numeric",
	hour: "numeric",
	minute: "numeric",
	second: "numeric",
};

function isReadable<T>(value: MaybeReadable<T>): value is Readable<T> {
	return typeof value === "object" && value !== null && "current" in value;
}

/** Collapse a plain value or a live {@link Readable} into a getter read on every call. */
function reader<T>(value: MaybeReadable<T>): () => T {
	return isReadable(value) ? () => value.current : () => value;
}

/**
 * Creates a typed wrapper around `@internationalized/date`'s {@link DateFormatter}
 * — itself an improved {@link Intl.DateTimeFormat} — used by the date builders to
 * format dates consistently.
 *
 * The wrapper is framework-agnostic: pass plain values for a static formatter, or
 * {@link Readable} sources (Svelte boxes, signals, the `@mercury/effector` store
 * adapter) for one that tracks live locale / format changes.
 *
 * @example Static
 * ```ts
 * const fmt = createFormatter({ locale: "en-GB" });
 * fmt.fullMonthAndYear(new Date()); // "December 2025"
 * ```
 * @example Live (Effector — see `@mercury/effector` `createFormatterModel`)
 * ```ts
 * const fmt = createFormatter({ locale: { get current() { return $locale.getState(); } } });
 * ```
 *
 * @see [DateFormatter](https://react-spectrum.adobe.com/internationalized/date/DateFormatter.html)
 */
export function createFormatter(opts: FormatterOptions): Formatter {
	const readLocale = reader(opts.locale);
	const readMonthFormat = reader<MonthFormat>(opts.monthFormat ?? "long");
	const readYearFormat = reader<YearFormat>(opts.yearFormat ?? "numeric");

	let override: string | undefined;
	const locale = (): string => override ?? readLocale();

	function setLocale(newLocale: string): void {
		override = newLocale;
	}

	function getLocale(): string {
		return locale();
	}

	function custom(date: Date, options: Intl.DateTimeFormatOptions): string {
		return new DateFormatter(locale(), options).format(date);
	}

	function selectedDate(date: DateValue, includeTime = true): string {
		if (hasTime(date) && includeTime) {
			return custom(toDate(date), { dateStyle: "long", timeStyle: "long" });
		}
		return custom(toDate(date), { dateStyle: "long" });
	}

	function fullMonthAndYear(date: Date): string {
		const month = readMonthFormat();
		const year = readYearFormat();

		// Fast path: when both are `Intl` styles, a single formatter yields the
		// locale-correct order and spacing (e.g. "décembre 2025" / "2025年12月").
		if (typeof month !== "function" && typeof year !== "function") {
			return new DateFormatter(locale(), { month, year }).format(date);
		}

		const formattedMonth =
			typeof month === "function"
				? month(date.getMonth() + 1)
				: new DateFormatter(locale(), { month }).format(date);
		const formattedYear =
			typeof year === "function"
				? year(date.getFullYear())
				: new DateFormatter(locale(), { year }).format(date);

		return `${formattedMonth} ${formattedYear}`;
	}

	function fullMonth(date: Date): string {
		return new DateFormatter(locale(), { month: "long" }).format(date);
	}

	function fullYear(date: Date): string {
		return new DateFormatter(locale(), { year: "numeric" }).format(date);
	}

	function toParts(
		date: DateValue,
		options?: Intl.DateTimeFormatOptions
	): Intl.DateTimeFormatPart[] {
		if (isZonedDateTime(date)) {
			return new DateFormatter(locale(), { ...options, timeZone: date.timeZone }).formatToParts(
				toDate(date)
			);
		}
		return new DateFormatter(locale(), options).formatToParts(toDate(date));
	}

	function dayOfWeek(
		date: Date,
		length: Intl.DateTimeFormatOptions["weekday"] = "narrow"
	): string {
		return new DateFormatter(locale(), { weekday: length }).format(date);
	}

	function dayPeriod(date: Date, hourCycle: HourCycle | undefined = undefined): DayPeriodValue {
		const parts = new DateFormatter(locale(), {
			hour: "numeric",
			minute: "numeric",
			hourCycle: hourCycle === 24 ? "h23" : undefined,
		}).formatToParts(date);
		const value = parts.find((p) => p.type === "dayPeriod")?.value;
		return value === "PM" ? "PM" : "AM";
	}

	function part(
		dateObj: DateValue,
		type: Intl.DateTimeFormatPartTypes,
		options: Intl.DateTimeFormatOptions = {}
	): string {
		const parts = toParts(dateObj, { ...defaultPartOptions, ...options });
		return parts.find((p) => p.type === type)?.value ?? "";
	}

	return {
		setLocale,
		getLocale,
		custom,
		selectedDate,
		fullMonthAndYear,
		fullMonth,
		fullYear,
		toParts,
		dayOfWeek,
		dayPeriod,
		part,
	};
}

/**
 * The time-only counterpart to {@link createFormatter}. Accepts a plain locale
 * string or a live {@link Readable} source, the same way.
 */
export function createTimeFormatter(locale: MaybeReadable<string>): TimeFormatter {
	const readLocale = reader(locale);
	let override: string | undefined;
	const activeLocale = (): string => override ?? readLocale();

	function setLocale(newLocale: string): void {
		override = newLocale;
	}

	function getLocale(): string {
		return activeLocale();
	}

	function custom(date: Date, options: Intl.DateTimeFormatOptions): string {
		return new DateFormatter(activeLocale(), options).format(date);
	}

	function selectedTime(date: TimeValue): string {
		return custom(toDate(convertTimeValueToDateValue(date)), { timeStyle: "long" });
	}

	function toParts(
		timeValue: TimeValue,
		options?: Intl.DateTimeFormatOptions
	): Intl.DateTimeFormatPart[] {
		const dateValue = convertTimeValueToDateValue(timeValue);
		if (isZonedDateTime(dateValue)) {
			return new DateFormatter(activeLocale(), {
				...options,
				timeZone: dateValue.timeZone,
			}).formatToParts(toDate(dateValue));
		}
		return new DateFormatter(activeLocale(), options).formatToParts(toDate(dateValue));
	}

	function dayPeriod(date: Date, hourCycle: HourCycle | undefined = undefined): DayPeriodValue {
		const parts = new DateFormatter(activeLocale(), {
			hour: "numeric",
			minute: "numeric",
			hourCycle: hourCycle === 24 ? "h23" : undefined,
		}).formatToParts(date);
		const value = parts.find((p) => p.type === "dayPeriod")?.value;
		return value === "PM" ? "PM" : "AM";
	}

	function part(
		dateObj: TimeValue,
		type: Intl.DateTimeFormatPartTypes,
		options: Intl.DateTimeFormatOptions = {}
	): string {
		const parts = toParts(dateObj, { ...defaultPartOptions, ...options });
		return parts.find((p) => p.type === type)?.value ?? "";
	}

	return {
		setLocale,
		getLocale,
		custom,
		selectedTime,
		toParts,
		dayPeriod,
		part,
	};
}
