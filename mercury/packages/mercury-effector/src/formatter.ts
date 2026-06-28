import { createEvent, createStore, type EventCallable, type Store } from "effector";
import { useUnit } from "effector-react";
import {
  createFormatter,
  type Formatter,
  type MonthFormat,
  type YearFormat,
  type Readable,
} from "@mercury/ui";

/**
 * createFormatterModel — an Effector-backed wrapper around `@mercury/ui`'s
 * `createFormatter`. The locale and month/year styles live in stores; the
 * formatter reads them live, so changing any of them re-renders every component
 * that called `useFormatter()`. Components stay presentational; this wires state.
 */
export interface FormatterModelOptions {
  /** Initial BCP-47 locale. Defaults to the browser locale, else `"en-US"`. */
  locale?: string;
  /** Initial month rendering for `fullMonthAndYear`. Defaults to `"long"`. */
  monthFormat?: MonthFormat;
  /** Initial year rendering for `fullMonthAndYear`. Defaults to `"numeric"`. */
  yearFormat?: YearFormat;
}

export interface FormatterModel {
  /** Active locale store. */
  $locale: Store<string>;
  /** Active month-format store. */
  $monthFormat: Store<MonthFormat>;
  /** Active year-format store. */
  $yearFormat: Store<YearFormat>;
  /** Set the active locale. */
  setLocale: EventCallable<string>;
  /** Set how months render in `fullMonthAndYear`. */
  setMonthFormat: EventCallable<MonthFormat>;
  /** Set how years render in `fullMonthAndYear`. */
  setYearFormat: EventCallable<YearFormat>;
  /**
   * The formatter instance. Stable across renders — its methods read the stores
   * live. Use directly outside React; inside React prefer {@link FormatterModel.useFormatter}
   * so the component re-renders when inputs change.
   */
  formatter: Formatter;
  /** React hook: subscribes to the stores and returns the (stable) formatter. */
  useFormatter: () => Formatter;
}

function defaultLocale(): string {
  if (typeof navigator !== "undefined" && navigator.language) return navigator.language;
  return "en-US";
}

/** Adapt an Effector store to the framework-agnostic `Readable` the formatter consumes. */
function storeToReadable<T>(store: Store<T>): Readable<T> {
  return {
    get current() {
      return store.getState();
    },
  };
}

export function createFormatterModel(opts: FormatterModelOptions = {}): FormatterModel {
  const setLocale = createEvent<string>();
  const setMonthFormat = createEvent<MonthFormat>();
  const setYearFormat = createEvent<YearFormat>();

  const $locale = createStore<string>(opts.locale ?? defaultLocale()).on(setLocale, (_, l) => l);
  const $monthFormat = createStore<MonthFormat>(opts.monthFormat ?? "long").on(
    setMonthFormat,
    (_, v) => v
  );
  const $yearFormat = createStore<YearFormat>(opts.yearFormat ?? "numeric").on(
    setYearFormat,
    (_, v) => v
  );

  const formatter = createFormatter({
    locale: storeToReadable($locale),
    monthFormat: storeToReadable($monthFormat),
    yearFormat: storeToReadable($yearFormat),
  });

  function useFormatter(): Formatter {
    // Subscribe so the component re-renders when any input changes; the
    // formatter object is stable and reads the current store values on call.
    useUnit([$locale, $monthFormat, $yearFormat]);
    return formatter;
  }

  return {
    $locale,
    $monthFormat,
    $yearFormat,
    setLocale,
    setMonthFormat,
    setYearFormat,
    formatter,
    useFormatter,
  };
}
