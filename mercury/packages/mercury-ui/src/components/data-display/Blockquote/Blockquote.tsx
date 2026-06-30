import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type BlockquoteSize = "sm" | "md" | "lg";

export interface BlockquoteProps extends Omit<HTMLAttributes<HTMLQuoteElement>, "cite"> {
  children?: ReactNode;
  size?: BlockquoteSize;
  /** Colour of the leading rule + attribution ink, from an accent ramp (rule `--<ramp>-9`, ink `--<ramp>-11`). */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Attribution line, rendered below in DM Mono. */
  cite?: ReactNode;
}

/**
 * Blockquote — a quotation set off by a leading rule, in secondary ink with an
 * optional attribution line (DM Mono). The rule is `--border-strong` by default;
 * an `accent` recolours the rule (`--<ramp>-9`) and the attribution (`--<ramp>-11`).
 * Styled through `.mx-blockquote` token classes — no inline ink.
 */
export function Blockquote({ children, size = "md", accent, cite, className, ...rest }: BlockquoteProps) {
  return (
    <blockquote
      className={cx("mx-blockquote", `mx-blockquote--${size}`, accent && `mx-blockquote--accent-${accent}`, className)}
      {...rest}
    >
      <p className="mx-blockquote__text">{children}</p>
      {cite && <footer className="mx-blockquote__cite">{cite}</footer>}
    </blockquote>
  );
}

export default Blockquote;
