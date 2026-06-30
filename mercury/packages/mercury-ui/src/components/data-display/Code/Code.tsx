import type { ElementType, HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type CodeVariant = "soft" | "solid" | "outline" | "ghost";
export type CodeSize = "sm" | "md" | "lg";

export interface CodeProps extends HTMLAttributes<HTMLElement> {
  children?: ReactNode;
  /** Surface treatment. Default `soft`. */
  variant?: CodeVariant;
  /** Type size + inline padding. Default `md`. */
  size?: CodeSize;
  /** Accent ramp — tints soft/outline/ghost and recolours solid (`--<ramp>-9` / `--<ramp>-11`). */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Render as a multi-line block (`<pre>`) instead of inline (`<code>`). Default `false`. */
  block?: boolean;
}

/**
 * Code — inline (or block) monospace code in DM Mono on a tinted surface. Inline
 * renders `<code>`; `block` renders a scrollable `<pre>`. `variant` picks the
 * surface (soft/solid/outline/ghost); `accent` re-skins it from a ramp. Styled
 * through `.mx-code` token classes — no inline ink.
 */
export function Code({
  children,
  variant = "soft",
  size = "md",
  accent,
  block = false,
  className,
  ...rest
}: CodeProps) {
  const Tag: ElementType = block ? "pre" : "code";
  return (
    <Tag
      className={cx(
        "mx-code",
        `mx-code--${variant}`,
        `mx-code--${size}`,
        block && "mx-code--block",
        accent && `mx-code--accent-${accent}`,
        className,
      )}
      {...rest}
    >
      {children}
    </Tag>
  );
}

export default Code;
