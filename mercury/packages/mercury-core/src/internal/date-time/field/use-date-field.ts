import { useCallback, useMemo, useRef, useState } from "react";
import type { KeyboardEvent, RefObject } from "react";
import { CalendarDate, type DateValue } from "@internationalized/date";
import { createFormatter } from "#internal/date-time/formatter.js";
import { getDaysInMonth } from "#internal/date-time/utils.js";
import {
  areAllSegmentsFilled,
  createContent,
  getValueFromSegments,
  initializeSegmentValues,
  isDateSegmentPart,
} from "./helpers.js";
import { getNextSegment, getPrevSegment, getSegments } from "./segments.js";
import type { DateSegmentPart, SegmentValueObj } from "./types.js";

/** Options for {@link useDateField}. */
export type UseDateFieldOptions = {
  /** Controlled value. When set, the hook reflects this value and reports edits via `onChange`. */
  value?: DateValue;
  /** Uncontrolled initial value — seeds the segments on first render. */
  defaultValue?: DateValue;
  /** Called with the reconstructed value when every editable segment is filled, or `undefined` otherwise. */
  onChange?: (v: DateValue | undefined) => void;
  /** BCP-47 locale that orders the segments and renders the literals. Defaults to `"en"`. */
  locale?: string;
  /** Granularity of the field. Date-only for this wave. */
  granularity?: "day";
};

/** One rendered slot of the date field — an editable part or a literal separator. */
export interface DateSegment {
  part: string;
  value: string;
}

/** Props for the field container element. */
export interface FieldProps {
  ref: RefObject<HTMLElement | null>;
  role: "group";
}

/** Props for an editable segment (spinbutton) — spread onto the part element. */
export interface EditableSegmentProps {
  "data-segment": string;
  role: "spinbutton";
  inputMode: "numeric";
  tabIndex: number;
  "aria-label": string;
  "aria-valuenow"?: number;
  "aria-valuemin": number;
  "aria-valuemax": number;
  onKeyDown: (e: KeyboardEvent<HTMLElement>) => void;
}

/** Props for a literal (separator) segment. */
export interface LiteralSegmentProps {
  "data-segment": string;
}

/** The two segment shapes spread by {@link UseDateFieldReturn.segmentProps}. */
export type SegmentProps = EditableSegmentProps | LiteralSegmentProps;

/** Return shape of {@link useDateField}. */
export interface UseDateFieldReturn {
  /** Ordered render list — editable parts and literal separators, in locale order. */
  segments: DateSegment[];
  /** Props for the field container (carries the ref the machinery queries). */
  fieldProps: FieldProps;
  /** Props builder for a single segment, keyed by its part name. */
  segmentProps: (part: string) => SegmentProps;
  /** The current value — controlled value when set, else the reconstruction when all parts are filled. */
  value: DateValue | undefined;
}

const NEUTRAL_YEAR = 2024;

/** Build a `SegmentValueObj` from a `DateValue`, seeding the date parts from its fields. */
function segmentsFromValue(date: DateValue): SegmentValueObj {
  return {
    ...initializeSegmentValues("day"),
    day: String(date.day),
    month: String(date.month),
    year: String(date.year),
  } as SegmentValueObj;
}

/** Days in the month implied by the current segment values (falls back to a neutral month). */
function daysInCurrentMonth(segValues: SegmentValueObj): number {
  return getDaysInMonth(
    new CalendarDate(Number(segValues.year) || NEUTRAL_YEAR, Number(segValues.month) || 1, 1)
  );
}

/** The inclusive maximum for an editable date part. */
function maxFor(part: DateSegmentPart, segValues: SegmentValueObj): number {
  if (part === "month") return 12;
  if (part === "year") return 9999;
  return daysInCurrentMonth(segValues);
}

/**
 * Headless date-field composable. Composes the owned `internal/date-time` machinery
 * (segment seeding, locale formatter, content layout, value reconstruction, caret
 * navigation) into a presentational-ready prop kit. The keyboard reducer is the only
 * new logic; no native date math is hand-rolled.
 */
export function useDateField(options: UseDateFieldOptions = {}): UseDateFieldReturn {
  const { value, defaultValue, onChange, locale = "en" } = options;
  const isControlled = value !== undefined;

  const fieldRef = useRef<HTMLElement | null>(null);

  const [internal, setInternal] = useState<SegmentValueObj>(() =>
    defaultValue !== undefined ? segmentsFromValue(defaultValue) : initializeSegmentValues("day")
  );

  const segValues = useMemo<SegmentValueObj>(
    () => (value !== undefined ? segmentsFromValue(value) : internal),
    [value, internal]
  );

  const formatter = useMemo(() => createFormatter({ locale }), [locale]);
  const dateRef = useMemo(() => new CalendarDate(NEUTRAL_YEAR, 1, 1), []);

  const content = useMemo(
    () =>
      createContent({
        segmentValues: segValues,
        formatter,
        locale,
        dateRef,
        granularity: "day",
        hideTimeZone: false,
        hourCycle: undefined,
      }),
    [segValues, formatter, locale, dateRef]
  );

  const onSegKeyDown = useCallback(
    (part: DateSegmentPart) =>
      (e: KeyboardEvent<HTMLElement>): void => {
        const node = fieldRef.current;
        const segs = getSegments(node);
        const cur = segValues[part];
        const width = part === "year" ? 4 : 2;
        const max = maxFor(part, segValues);

        // Apply a new value for this part, mirror it to uncontrolled state, and
        // report through onChange when every used segment is filled.
        const commit = (nextVal: string | null): void => {
          const next = { ...segValues, [part]: nextVal } as SegmentValueObj;
          if (!isControlled) setInternal(next);
          if (node && areAllSegmentsFilled(next, node)) {
            onChange?.(getValueFromSegments({ segmentObj: next, fieldNode: node, dateRef }));
          } else {
            onChange?.(undefined);
          }
        };

        if (/^[0-9]$/.test(e.key)) {
          e.preventDefault();
          const prev = cur && cur.length < width ? cur : "";
          let candidate = prev + e.key;
          if (Number(candidate) > max) candidate = e.key;
          const complete = candidate.length >= width || Number(candidate) * 10 > max;
          const stored =
            complete && candidate.length < width ? candidate.padStart(width, "0") : candidate;
          commit(stored);
          if (complete) getNextSegment(e.currentTarget, segs)?.focus();
          return;
        }

        if (e.key === "ArrowUp" || e.key === "ArrowDown") {
          e.preventDefault();
          const delta = e.key === "ArrowUp" ? 1 : -1;
          let n = Number(cur);
          if (!cur || Number.isNaN(n)) {
            n = delta > 0 ? 1 : max;
          } else {
            n += delta;
            if (n > max) n = 1;
            if (n < 1) n = max;
          }
          commit(part === "year" ? String(n) : String(n).padStart(2, "0"));
          return;
        }

        if (e.key === "ArrowLeft") {
          e.preventDefault();
          getPrevSegment(e.currentTarget, segs)?.focus();
          return;
        }
        if (e.key === "ArrowRight") {
          e.preventDefault();
          getNextSegment(e.currentTarget, segs)?.focus();
          return;
        }

        if (e.key === "Backspace") {
          e.preventDefault();
          if (!cur) {
            commit(null);
          } else {
            const trimmed = cur.slice(0, -1);
            commit(trimmed.length ? trimmed : null);
          }
        }
      },
    [segValues, isControlled, onChange, dateRef]
  );

  const segmentProps = useCallback(
    (part: string): SegmentProps => {
      if (!isDateSegmentPart(part)) {
        return { "data-segment": part };
      }
      return {
        "data-segment": part,
        role: "spinbutton",
        inputMode: "numeric",
        tabIndex: 0,
        "aria-label": part,
        "aria-valuenow": Number(segValues[part]) || undefined,
        "aria-valuemin": 1,
        "aria-valuemax": maxFor(part, segValues),
        onKeyDown: onSegKeyDown(part),
      };
    },
    [segValues, onSegKeyDown]
  );

  const segments = useMemo<DateSegment[]>(
    () => content.arr.map((seg) => ({ part: seg.part, value: seg.value })),
    [content]
  );

  const resolvedValue = useMemo<DateValue | undefined>(() => {
    if (value !== undefined) return value;
    const node = fieldRef.current;
    if (node && areAllSegmentsFilled(segValues, node)) {
      return getValueFromSegments({ segmentObj: segValues, fieldNode: node, dateRef });
    }
    return undefined;
  }, [value, segValues, dateRef]);

  return {
    segments,
    fieldProps: { ref: fieldRef, role: "group" },
    segmentProps,
    value: resolvedValue,
  };
}
