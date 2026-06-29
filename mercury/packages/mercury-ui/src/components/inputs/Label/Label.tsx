import type { LabelHTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type LabelSize = "sm" | "md" | "lg";

export interface LabelProps extends LabelHTMLAttributes<HTMLLabelElement> {
  children?: ReactNode;
  required?: boolean;
  optional?: boolean;
  disabled?: boolean;
  size?: LabelSize;
  /** Accent ramp for the required asterisk (reads `--<ramp>-11`). Default `red`. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  hint?: ReactNode;
}

/**
 * Label — the form-caption primitive: semibold, tight tracking, with an accent-tinted
 * required marker, a muted `(optional)` tag, and an optional hint line. Styled through
 * `.mx-label` token classes; the required `*` reads `--<ramp>-11` (default `--red-11`)
 * via the accent class — no inline color.
 */
export function Label({
  children,
  required,
  optional,
  disabled,
  size = "md",
  accent = "red",
  hint,
  className,
  ...rest
}: LabelProps) {
  return (
    <label
      className={cx(
        "mx-label",
        `mx-label--${size}`,
        `mx-label--accent-${accent}`,
        disabled && "is-disabled",
        className,
      )}
      {...rest}
    >
      <span className="mx-label__text">
        {children}
        {required && (
          <span className="mx-label__req" aria-hidden="true">
            *
          </span>
        )}
        {optional && <span className="mx-label__opt">(optional)</span>}
      </span>
      {hint != null && <span className="mx-label__hint">{hint}</span>}
    </label>
  );
}

export default Label;
