import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { useAnchoredPosition } from "@mercury/core";
import { Portal } from "../_overlay/Portal";

export type HoverCardPlacement = "top" | "bottom" | "left" | "right";

export interface HoverCardProps {
  /**
   * The anchor. Must be **focusable** (a `Link`/`Avatar`/`button`) so keyboard
   * focus — not only hover — opens the card.
   */
  children: ReactNode;
  /** The floating card body. */
  content: ReactNode;
  /** Which side the card anchors to. Default `"bottom"`. */
  placement?: HoverCardPlacement;
  /** Delay before opening on hover/focus (ms). Default `250`. */
  openDelay?: number;
  /** Delay before closing on leave/blur (ms). Default `150`. */
  closeDelay?: number;
  /** Card width (px). Default `280`. */
  width?: number;
}

/**
 * HoverCard — a non-modal preview card revealed on hover OR focus of its
 * anchor. Composes the overlay-floor's `useAnchoredPosition` (portaled
 * `position: fixed`, so it escapes any `overflow`/stacking context) with local
 * open/close timers.
 *
 * Distinct from `Tooltip` (a static, CSS-only label) and `Popover`
 * (click-triggered, dismiss-managed): it holds interactive content and stays
 * open while the pointer is over the card. There is NO dismiss floor
 * (outside-press/`Escape`) and NO focus trap — it is non-modal.
 *
 * a11y: the card is `role="dialog"`; FOCUS (not only hover) opens it, so the
 * wrapped child must be focusable.
 */
export function HoverCard({
  children,
  content,
  placement = "bottom",
  openDelay = 250,
  closeDelay = 150,
  width = 280,
}: HoverCardProps) {
  const [open, setOpen] = useState(false);
  const anchorRef = useRef<HTMLSpanElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  // A single hover/focus timer (React-19 nullable ref — guard before clearing).
  const timer = useRef<number | undefined>(undefined);

  const { style } = useAnchoredPosition(anchorRef, cardRef, { placement, width, open });

  const show = () => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setOpen(true), openDelay);
  };
  const hide = () => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setOpen(false), closeDelay);
  };

  // Clear a pending timer on unmount.
  useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current);
    },
    [],
  );

  return (
    <>
      <span
        ref={anchorRef}
        onMouseEnter={show}
        onMouseLeave={hide}
        onFocus={show}
        onBlur={hide}
      >
        {children}
      </span>
      {open && (
        <Portal>
          <div
            ref={cardRef}
            role="dialog"
            className="mx-hovercard"
            style={style}
            onMouseEnter={show}
            onMouseLeave={hide}
          >
            {content}
          </div>
        </Portal>
      )}
    </>
  );
}

export default HoverCard;
