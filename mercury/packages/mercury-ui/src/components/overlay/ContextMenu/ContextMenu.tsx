import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { cx, useAnchoredPosition, useArrowNavigation, useDismiss } from "@mercury/core";
import { Portal } from "../_overlay/Portal";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

/** One row of a {@link ContextMenu}. A plain `item` runs `onSelect` and closes;
 * `label`/`separator` are presentational. `danger` recolours to the negative family. */
export interface ContextMenuItem {
  /** Row kind. Default `"item"`. */
  type?: "item" | "label" | "separator";
  /** The row's visible text. */
  label?: ReactNode;
  /** A leading icon. */
  icon?: IconName;
  /** A trailing key hint. */
  shortcut?: string;
  /** Invoked on activation. */
  onSelect?: () => void;
  /** Non-interactive + excluded from arrow-nav. */
  disabled?: boolean;
  /** Destructive action — recoloured to the negative family. */
  danger?: boolean;
}

export interface ContextMenuProps {
  /** The right-click surface — the wrapped region opens the menu at the pointer. */
  children: ReactNode;
  /** The menu rows, in order. */
  items: ContextMenuItem[];
  /** Panel width (px). Default `220`. */
  width?: number;
}

// Arrow-nav collection: focusable rows only (disabled rows carry aria-disabled).
const CTX_NAV = '[role="menuitem"]:not([aria-disabled="true"])';

/**
 * ContextMenu — a menu opened at the pointer by a right-click on the wrapped
 * region. Composes the overlay-floor: `useAnchoredPosition({ point })` (a
 * pointer-anchored, viewport-clamped portaled panel) + `useDismiss` (outside-press
 * + `Escape`) + `useArrowNavigation`. A local `scroll` listener dismisses while
 * open (the page moving out from under a pinned menu).
 *
 * a11y: the panel is `role="menu"`, rows are `role="menuitem"`. `danger` rows are
 * the sole recolour, token-based (no accent prop).
 */
export function ContextMenu({ children, items, width = 220 }: ContextMenuProps) {
  const [pos, setPos] = useState<{ x: number; y: number } | null>(null);
  const open = pos != null;
  const wrapRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  // Pointer anchor — the floor clamps the panel to the viewport (no manual clamp).
  const { style } = useAnchoredPosition(wrapRef, panelRef, { point: pos, width, open });

  useDismiss(panelRef, {
    onDismiss: () => setPos(null),
    outsideClick: true,
    escapeKey: true,
    enabled: open,
  });

  // Local scroll-dismiss (spec-sanctioned; useDismiss owns outside-press + Escape).
  useEffect(() => {
    if (!open) return;
    const off = () => setPos(null);
    window.addEventListener("scroll", off, true);
    return () => window.removeEventListener("scroll", off, true);
  }, [open]);

  // Move focus into the panel on open so arrow-nav + Escape work from the keyboard.
  useEffect(() => {
    if (!open) return;
    panelRef.current?.focus?.();
  }, [open]);

  function runItem(it: ContextMenuItem) {
    if (it.disabled) return;
    it.onSelect?.();
    setPos(null);
  }

  function renderRow(it: ContextMenuItem, i: number) {
    const key = `${it.type ?? "item"}-${i}`;
    if (it.type === "separator") return <div key={key} className="mx-ctx__sep" role="separator" />;
    if (it.type === "label")
      return (
        <div key={key} className="mx-ctx__label">
          {it.label}
        </div>
      );
    return (
      <button
        key={key}
        type="button"
        role="menuitem"
        aria-disabled={it.disabled || undefined}
        className={cx("mx-ctx__item", it.danger && "mx-ctx__item--danger")}
        onClick={() => runItem(it)}
      >
        {it.icon && <Icon className="mx-ctx__icon" name={it.icon} size={15} />}
        <span className="mx-ctx__text">{it.label}</span>
        {it.shortcut && <span className="mx-ctx__shortcut">{it.shortcut}</span>}
      </button>
    );
  }

  return (
    <>
      <div
        ref={wrapRef}
        className="mx-ctx__area"
        onContextMenu={(e) => {
          e.preventDefault();
          setPos({ x: e.clientX, y: e.clientY });
        }}
      >
        {children}
      </div>
      {open && (
        <Portal>
          <div
            ref={panelRef}
            role="menu"
            tabIndex={-1}
            className="mx-ctx"
            style={style}
            onKeyDown={(e) => {
              // useArrowNavigation is a pure handler, NOT a React hook.
              useArrowNavigation(e.nativeEvent, document.activeElement as HTMLElement, panelRef.current ?? undefined, {
                candidateSelector: CTX_NAV,
                focus: true,
                arrowKeyOptions: "vertical",
              });
            }}
          >
            {items.map((it, i) => renderRow(it, i))}
          </div>
        </Portal>
      )}
    </>
  );
}

export default ContextMenu;
