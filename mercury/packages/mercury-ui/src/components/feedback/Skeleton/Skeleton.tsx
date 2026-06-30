import type { CSSProperties, HTMLAttributes } from "react";
import { cx } from "@mercury/core";

export interface SkeletonProps extends Omit<HTMLAttributes<HTMLSpanElement>, "children"> {
  /** CSS width — number (px) or any length string. Default `100%`. */
  width?: number | string;
  /** CSS height — number (px) or string. Ignored when `circle`. Default `16`. */
  height?: number | string;
  /** Corner radius in px (ignored when `circle`). Default `6`. */
  radius?: number;
  /** Render a circle of diameter `width` (for avatars). */
  circle?: boolean;
}

const dim = (v: number | string) => (typeof v === "number" ? `${v}px` : v);

/**
 * Skeleton — a pulsing placeholder that holds layout while content loads. The
 * dimensions (`width`/`height`/`radius`/`circle`) are non-color inline styles; the
 * surface (`--bg-tertiary`) and the 1.5s pulse live in `.mx-skeleton`. Decorative
 * (`aria-hidden`) — announce the load with a sibling `Spinner`/live region.
 */
export function Skeleton({ width = "100%", height = 16, radius = 6, circle, className, style, ...rest }: SkeletonProps) {
  // Dimensions are non-color inline styles (allowed by INV-2).
  const dynamic: CSSProperties = {
    width: dim(width),
    height: circle ? dim(width) : dim(height),
    borderRadius: circle ? "9999px" : `${radius}px`,
  };
  return <span aria-hidden="true" className={cx("mx-skeleton", className)} style={{ ...dynamic, ...style }} {...rest} />;
}

export default Skeleton;
