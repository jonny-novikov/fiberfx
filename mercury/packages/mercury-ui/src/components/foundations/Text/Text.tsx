import type { ElementType, HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type TextVariant =
  | "display"
  | "h1"
  | "h2"
  | "h3"
  | "h4"
  | "lead"
  | "body"
  | "small"
  | "muted"
  | "code"
  | "quote";

export interface TextProps extends HTMLAttributes<HTMLElement> {
  /** Typographic role — selects the element + the `.mx-text--<variant>` recipe. Default `body`. */
  variant?: TextVariant;
  children?: ReactNode;
  /** Ink from an accent ramp (reads `--<ramp>-11`). Overrides the variant ink. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  italic?: boolean;
  align?: "left" | "center" | "right";
}

// The element each variant renders (the variant default ink + face live in CSS).
const TAG_FOR: Record<TextVariant, ElementType> = {
  display: "h1",
  h1: "h1",
  h2: "h2",
  h3: "h3",
  h4: "h4",
  lead: "p",
  body: "p",
  small: "p",
  muted: "p",
  code: "code",
  quote: "blockquote",
};

/**
 * Text — one typography primitive across Mercury's three families. Big headings ride
 * DM Mono (`--font-secondary`); `display` rides DM Serif Display (`--font-display`);
 * body copy rides DM Sans (`--font-primary`). Every variant resolves its ink from the
 * `--fg-*` token families via `.mx-text--<variant>` — no inline color.
 */
export function Text({
  variant = "body",
  children,
  accent,
  italic,
  align,
  className,
  ...rest
}: TextProps) {
  const Tag = TAG_FOR[variant];
  return (
    <Tag
      className={cx(
        "mx-text",
        `mx-text--${variant}`,
        italic && "mx-text--italic",
        align && `mx-text--align-${align}`,
        accent && `mx-text--accent-${accent}`,
        className,
      )}
      {...rest}
    >
      {children}
    </Tag>
  );
}

export default Text;
