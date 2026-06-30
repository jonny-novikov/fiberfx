import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type KbdSize = "sm" | "md" | "lg";

export interface KbdProps extends HTMLAttributes<HTMLElement> {
  children?: ReactNode;
  /** Cap size. Default `md`. */
  size?: KbdSize;
}

/**
 * Kbd — a keyboard keycap in DM Mono on a raised surface with a subtle bottom
 * edge. Reach for it to mark a key a user presses (`⌘`, `Esc`, `K`); compose
 * several for a shortcut. Styled through `.mx-kbd` token classes — no inline ink.
 */
export function Kbd({ children, size = "md", className, ...rest }: KbdProps) {
  return (
    <kbd className={cx("mx-kbd", `mx-kbd--${size}`, className)} {...rest}>
      {children}
    </kbd>
  );
}

export default Kbd;
