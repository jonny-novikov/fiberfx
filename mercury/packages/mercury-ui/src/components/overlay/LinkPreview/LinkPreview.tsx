import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { useAnchoredPosition } from "@mercury/core";
import { Portal } from "../_overlay/Portal";

export type LinkPreviewPlacement = "top" | "bottom";

export interface LinkPreviewProps {
  /**
   * The anchor — typically a [Link](../../actions/Link/Link.prompt.md). Must be
   * focusable so keyboard focus, not only hover, opens the preview.
   */
  children: ReactNode;
  /** The floating preview body (a URL card, an embed, a summary). */
  content: ReactNode;
  /** Which side the preview anchors to. Default `"bottom"`. */
  placement?: LinkPreviewPlacement;
  /** Delay before opening on hover/focus (ms). Default `300`. */
  openDelay?: number;
  /** Preview width (px). Default `300`. */
  width?: number;
}

/**
 * LinkPreview — the URL-preview specialization of the hover-card family: a
 * non-modal card revealed on hover OR focus of an inline anchor (a link), used
 * to preview where a link leads. Composes the overlay-floor's
 * `useAnchoredPosition` (portaled `position: fixed`) with local open/close
 * timers.
 *
 * Unlike HoverCard there is NO `closeDelay` prop — the preview hides on a fixed
 * 120ms grace so the pointer can bridge the gap onto the card. Non-modal: no
 * dismiss floor, no focus trap.
 *
 * a11y: the card is `role="dialog"`; FOCUS (not only hover) opens it, so the
 * wrapped child must be focusable.
 */
export function LinkPreview({
  children,
  content,
  placement = "bottom",
  openDelay = 300,
  width = 300,
}: LinkPreviewProps) {
  const [open, setOpen] = useState(false);
  const anchorRef = useRef<HTMLSpanElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  // Separate open/close timers (React-19 nullable refs — guard before clearing).
  const openT = useRef<number | undefined>(undefined);
  const closeT = useRef<number | undefined>(undefined);

  const { style } = useAnchoredPosition(anchorRef, cardRef, { placement, width, open });

  const show = () => {
    if (closeT.current) clearTimeout(closeT.current);
    openT.current = window.setTimeout(() => setOpen(true), openDelay);
  };
  const hide = () => {
    if (openT.current) clearTimeout(openT.current);
    closeT.current = window.setTimeout(() => setOpen(false), 120);
  };

  // Clear pending timers on unmount.
  useEffect(
    () => () => {
      if (openT.current) clearTimeout(openT.current);
      if (closeT.current) clearTimeout(closeT.current);
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
            className="mx-linkpreview"
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

export default LinkPreview;
