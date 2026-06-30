import { cx, useDateField } from "@mercury/core";
import type { DateValue } from "@mercury/core";
import type { ReactNode } from "react";

export interface DateFieldProps {
  /** Controlled date value (a `DateValue` from `@mercury/core`). Pass `undefined` for uncontrolled. */
  value?: DateValue;
  /** Initial value when uncontrolled. */
  defaultValue?: DateValue;
  /** Fires on each committed segment edit; `undefined` when the field is cleared. */
  onChange?: (value: DateValue | undefined) => void;
  /** Label above the segmented field. */
  label?: ReactNode;
  /** BCP-47 locale for segment ordering + literals (default `"en"`, via the hook). */
  locale?: string;
  /** Fades the field and blocks entry. */
  disabled?: boolean;
  className?: string;
}

/**
 * DateField — a segmented mm/dd/yyyy date entry. The value model, segment list,
 * and keyboard arithmetic come from `@mercury/core`'s `useDateField` (over the
 * owned `internal/date-time` machinery); this component is the presentational
 * `@mercury/ui` home that renders the segments. INV-6: date types cross through
 * `@mercury/core`, never `@internationalized/date` directly.
 */
export function DateField({
  value,
  defaultValue,
  onChange,
  label,
  locale,
  disabled,
  className,
}: DateFieldProps) {
  const { segments, fieldProps, segmentProps } = useDateField({ value, defaultValue, onChange, locale });
  return (
    <label className={cx("mx-datefield", disabled && "mx-datefield--disabled", className)}>
      {label != null && <span className="mx-datefield__lbl">{label}</span>}
      <span {...fieldProps} className="mx-datefield__field">
        {segments.map((seg, i) =>
          seg.part === "literal" ? (
            <span key={i} className="mx-datefield__sep" aria-hidden="true">
              {seg.value}
            </span>
          ) : (
            // `readOnly`: the hook drives the value via its key handler (it
            // `preventDefault`s digits), so the native input never owns it —
            // this suppresses React's controlled-without-onChange warning.
            // The per-segment `width` is a non-color dynamic inline (INV-2).
            <input
              key={seg.part}
              {...segmentProps(seg.part)}
              className="mx-datefield__seg"
              style={{ width: seg.part === "year" ? 44 : 24 }}
              value={seg.value}
              readOnly
              disabled={disabled}
            />
          ),
        )}
      </span>
    </label>
  );
}
