import { useCallback, useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { useAnchoredPosition, useDismiss, useId } from "@mercury/core";
import { Portal } from "../_overlay/Portal";

export type PopoverPlacement = "bottom-start" | "bottom-end" | "top-start" | "top-end";

export interface PopoverProps {
  /**
   * The trigger's content — pass a label or icon, NOT an interactive element:
   * Popover renders its own `<button>`, and nesting a button inside is invalid.
   */
  trigger: ReactNode;
  /** The panel content. */
  children?: ReactNode;
  /** Controlled open state. Omit for uncontrolled (see `defaultOpen`). */
  open?: boolean;
  /** Initial open state when uncontrolled. Default `false`. */
  defaultOpen?: boolean;
  /** Notified on every open/close (both controlled and uncontrolled). */
  onOpenChange?: (open: boolean) => void;
  /** Where the panel anchors relative to the trigger. Default `"bottom-start"`. */
  placement?: PopoverPlacement;
  /** Panel width (px). Default `280`. */
  width?: number;
}

/**
 * Popover — a floating panel anchored to a trigger, holding arbitrary
 * interactive content. Controlled or uncontrolled. Composes the overlay-floor:
 * `useAnchoredPosition` (portaled `position: fixed`, so it escapes any
 * overflow/stacking context) + `useDismiss` (outside-press + `Escape`, the
 * trigger ignored so re-pressing toggles).
 *
 * a11y: a real `<button>` trigger carries `aria-haspopup="dialog"` +
 * `aria-expanded`; the panel is `role="dialog"`. Non-modal — focus moves into
 * the panel on open and returns to the trigger on close, but `Tab` is NOT
 * trapped (focus may leave freely).
 */
export function Popover({
  trigger,
  children,
  open: openProp,
  defaultOpen = false,
  onOpenChange,
  placement = "bottom-start",
  width = 280,
}: PopoverProps) {
  const isControlled = openProp != null;
  const [internal, setInternal] = useState(defaultOpen);
  const open = isControlled ? openProp : internal;
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const [panelId] = useState(() => useId("mx-popover"));

  const set = useCallback(
    (v: boolean) => {
      if (!isControlled) setInternal(v);
      onOpenChange?.(v);
    },
    [isControlled, onOpenChange],
  );

  const { style } = useAnchoredPosition(triggerRef, panelRef, { placement, width, open });

  useDismiss(panelRef, {
    onDismiss: () => set(false),
    outsideClick: true,
    escapeKey: true,
    ignore: [triggerRef],
    enabled: open,
  });

  // Non-modal focus: move into the panel on open, return to the trigger on
  // close — but do NOT trap (Tab may leave).
  useEffect(() => {
    if (!open) return;
    const triggerEl = triggerRef.current;
    panelRef.current?.focus?.();
    return () => triggerEl?.focus?.();
  }, [open]);

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        className="mx-popover__trigger"
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls={open ? panelId : undefined}
        onClick={() => set(!open)}
      >
        {trigger}
      </button>
      {open && (
        <Portal>
          <div
            ref={panelRef}
            id={panelId}
            role="dialog"
            tabIndex={-1}
            className="mx-popover"
            style={style}
          >
            {children}
          </div>
        </Portal>
      )}
    </>
  );
}

export default Popover;
