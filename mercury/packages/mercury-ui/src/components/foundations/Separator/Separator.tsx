import type { CSSProperties, HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type SeparatorOrientation = "horizontal" | "vertical";

export interface SeparatorProps extends HTMLAttributes<HTMLDivElement> {
  orientation?: SeparatorOrientation;
  /** Optional centered label (horizontal only) — e.g. "or". */
  label?: ReactNode;
  /** Length: width for horizontal, height for vertical. Defaults to filling the container. */
  size?: number | string;
  /** Purely visual (default). Set `false` when it genuinely separates groups for AT. */
  decorative?: boolean;
}

/**
 * Separator — a thin rule that divides content, horizontal or vertical, with an
 * optional inline label. The Claude-Design sibling of `Divider`, with a richer
 * `orientation` / `label` / `size` / `decorative` surface. The rule reads
 * `--border-secondary` via `.mx-separator`; a custom `size` rides the
 * `--mx-sep-size` custom property (no inline color).
 */
export function Separator({
  orientation = "horizontal",
  label,
  size,
  decorative = true,
  className,
  style,
  ...rest
}: SeparatorProps) {
  const dim = size != null ? (typeof size === "number" ? `${size}px` : size) : undefined;
  const sizeVar = dim ? ({ "--mx-sep-size": dim } as CSSProperties) : undefined;
  const mergedStyle = sizeVar || style ? { ...sizeVar, ...style } : undefined;
  const aria = decorative
    ? ({ role: "none" } as const)
    : ({ role: "separator", "aria-orientation": orientation } as const);

  if (orientation === "vertical") {
    return (
      <div
        className={cx("mx-separator", "mx-separator--v", className)}
        style={mergedStyle}
        {...rest}
        {...aria}
      />
    );
  }

  if (label != null) {
    return (
      <div
        className={cx("mx-separator", "mx-separator--label", className)}
        style={mergedStyle}
        {...rest}
        {...aria}
      >
        <span className="mx-separator__line" />
        <span className="mx-separator__lbl">{label}</span>
        <span className="mx-separator__line" />
      </div>
    );
  }

  return (
    <div className={cx("mx-separator", className)} style={mergedStyle} {...rest} {...aria} />
  );
}

export default Separator;
