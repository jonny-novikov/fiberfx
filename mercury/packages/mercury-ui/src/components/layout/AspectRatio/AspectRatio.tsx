import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface AspectRatioProps extends HTMLAttributes<HTMLDivElement> {
  /** width / height — e.g. `16/9`, `1`, `4/3`. Default `16/9`. */
  ratio?: number;
  children?: ReactNode;
}

/**
 * AspectRatio — constrains its content to a fixed width-to-height ratio (media
 * embeds, image frames, video). The box fills its container's width and derives
 * its height from `ratio`; the child fills it absolutely. Structure lives in
 * `.mx-aspect`; the ratio itself is a non-color dynamic inline style.
 */
export function AspectRatio({ ratio = 16 / 9, children, className, style, ...rest }: AspectRatioProps) {
  return (
    <div
      className={cx("mx-aspect", className)}
      // aspect-ratio is a non-color dynamic inline style (allowed by INV-2).
      style={{ aspectRatio: String(ratio), ...style }}
      {...rest}
    >
      <div className="mx-aspect__inner">{children}</div>
    </div>
  );
}

export default AspectRatio;
