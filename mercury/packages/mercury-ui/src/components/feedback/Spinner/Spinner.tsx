import type { CSSProperties, HTMLAttributes } from "react";
import { cx } from "@mercury/core";

export type SpinnerSize = "sm" | "md" | "lg";

export interface SpinnerProps extends Omit<HTMLAttributes<HTMLSpanElement>, "children"> {
  /** Named size or an explicit pixel diameter. Default `md`. */
  size?: SpinnerSize | number;
  /** Accent ramp for the moving arc (reads `--<ramp>-9`). Omit to inherit `currentColor` (e.g. inside a button). */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Accessible label announced to screen readers. Default `Loading`. */
  label?: string;
}

/**
 * Spinner — an indeterminate loading indicator: a token-coloured ring on a 360°/1s
 * spin. With no `accent` the arc inherits `currentColor` (so it reads correctly inside
 * a button); an `accent` paints the arc from a ramp. Carries `role="status"` + the
 * `label` as its accessible name. Honours `prefers-reduced-motion`.
 */
export function Spinner({ size = "md", accent, label = "Loading", className, style, ...rest }: SpinnerProps) {
  const numeric = typeof size === "number";
  // Dynamic dims for a numeric diameter are non-color inline styles (allowed by INV-2).
  const dynamic: CSSProperties | undefined = numeric
    ? { width: size, height: size, borderWidth: Math.max(2, Math.round(size / 10)) }
    : undefined;
  return (
    <span
      role="status"
      aria-label={label}
      className={cx("mx-spinner", !numeric && `mx-spinner--${size}`, accent && `mx-spinner--accent-${accent}`, className)}
      style={{ ...dynamic, ...style }}
      {...rest}
    />
  );
}

export default Spinner;
