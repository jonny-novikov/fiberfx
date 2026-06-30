import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type ScrollAreaScrollbars = "vertical" | "horizontal" | "both";
export type ScrollAreaSize = "sm" | "md" | "lg";

export interface ScrollAreaProps extends HTMLAttributes<HTMLDivElement> {
  children?: ReactNode;
  /** Which axes scroll. Default `vertical`. */
  scrollbars?: ScrollAreaScrollbars;
  /** Scrollbar thickness. Default `md`. */
  size?: ScrollAreaSize;
  /** Cap height — needed for `vertical`/`both` to scroll. Number → px. */
  maxHeight?: number | string;
  /** Container width. Number → px. */
  width?: number | string;
}

/**
 * ScrollArea — a scroll container with Mercury's thin, rounded custom scrollbars.
 * `scrollbars` picks the axes; `size` picks the bar thickness. The scrollbar
 * styling lives in `.mx-scrollarea` (webkit pseudo-elements reading neutral border
 * tokens); only the `maxHeight`/`width` caps are non-color dynamic inline styles.
 */
export function ScrollArea({
  children,
  scrollbars = "vertical",
  size = "md",
  maxHeight,
  width,
  className,
  style,
  ...rest
}: ScrollAreaProps) {
  return (
    <div
      className={cx("mx-scrollarea", `mx-scrollarea--${scrollbars}`, `mx-scrollarea--${size}`, className)}
      // maxHeight/width are non-color dynamic inline styles (allowed by INV-2).
      style={{ maxHeight, width, ...style }}
      {...rest}
    >
      {children}
    </div>
  );
}

export default ScrollArea;
