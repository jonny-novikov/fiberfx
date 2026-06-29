import type { ElementType, HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type HeadingSize = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
export type HeadingWeight = "regular" | "medium" | "semibold" | "bold";
export type HeadingAlign = "left" | "center" | "right";
export type HeadingTag = "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "div";

export interface HeadingProps extends HTMLAttributes<HTMLElement> {
  children?: ReactNode;
  /** 1 (smallest) → 9 (display). Default 6. Maps onto the canon 18..72 type scale. */
  size?: HeadingSize;
  /** Type weight. Default `bold` (the canon heading weight). */
  weight?: HeadingWeight;
  align?: HeadingAlign;
  /** Render tag. Defaults to a sensible h-level derived from `size`. */
  as?: HeadingTag;
  /** Ink from an accent ramp (reads `--<ramp>-11`). Overrides the default ink. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  truncate?: boolean;
}

// Default semantic h-level per size rank (overridable via `as`).
const TAG_FOR: Record<HeadingSize, HeadingTag> = {
  1: "h6",
  2: "h6",
  3: "h6",
  4: "h5",
  5: "h4",
  6: "h3",
  7: "h2",
  8: "h1",
  9: "h1",
};

/**
 * Heading — section titles across the Mercury type scale. The display sizes (5–9)
 * ride DM Mono (`--font-secondary`), Mercury's technical display face; the small
 * sizes (1–4) use DM Sans (`--font-primary`). Styled entirely through `.mx-heading`
 * token classes — no inline ink.
 */
export function Heading({
  size = 6,
  weight = "bold",
  align,
  as,
  accent,
  truncate,
  className,
  children,
  ...rest
}: HeadingProps) {
  const Tag = (as ?? TAG_FOR[size]) as ElementType;
  return (
    <Tag
      className={cx(
        "mx-heading",
        `mx-heading--${size}`,
        `mx-heading--w-${weight}`,
        align && `mx-heading--align-${align}`,
        accent && `mx-heading--accent-${accent}`,
        truncate && "mx-heading--truncate",
        className,
      )}
      {...rest}
    >
      {children}
    </Tag>
  );
}

export default Heading;
