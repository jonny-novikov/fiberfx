import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { cx, useAnchoredPosition, useArrowNavigation, useDismiss, useId } from "@mercury/core";
import { Portal } from "../_overlay/Portal";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

/** One row of a {@link Dropdown} menu. A `check` row toggles in place; a plain
 * `item` runs `onSelect` and closes; `label`/`separator` are presentational. */
export interface DropdownItem {
  /** Row kind. Default `"item"`. */
  type?: "item" | "label" | "separator" | "check";
  /** The row's visible text (item/label/check). */
  label?: ReactNode;
  /** A leading icon (item rows). */
  icon?: IconName;
  /** A trailing key hint, e.g. `"⌘K"`. */
  shortcut?: string;
  /** Initial checked state for a `check` row (thereafter uncontrolled). */
  checked?: boolean;
  /** Stable id — required for a `check` row's toggle state. */
  id?: string;
  /** Invoked on activation (both `item` and `check`). */
  onSelect?: () => void;
  /** Non-interactive + excluded from arrow-nav. */
  disabled?: boolean;
}

export interface DropdownProps {
  /** The trigger's content — a label/icon, NOT an interactive element (Dropdown
   * renders its own `<button>`). */
  trigger: ReactNode;
  /** The menu rows, in order. */
  items: DropdownItem[];
  /** The check-mark ink family. Default `"iris"`. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Which trigger edge the panel aligns to. Default `"start"`. */
  align?: "start" | "end";
  /** Panel width (px). Default `220`. */
  width?: number;
}

// Arrow-nav collection: focusable rows only (disabled rows carry aria-disabled).
const MENU_NAV =
  '[role="menuitem"]:not([aria-disabled="true"]),[role="menuitemcheckbox"]:not([aria-disabled="true"])';

/**
 * Dropdown — a menu of actions anchored to a trigger. Composes the overlay-floor:
 * `useAnchoredPosition` (portaled `position: fixed`, so it escapes overflow/
 * stacking) + `useDismiss` (outside-press + `Escape`, the trigger ignored so
 * re-pressing toggles) + `useArrowNavigation` (Up/Down over the rows).
 *
 * a11y: a real `<button>` trigger carries `aria-haspopup="menu"` +
 * `aria-expanded`; the panel is `role="menu"`, rows are `role="menuitem"` /
 * `role="menuitemcheckbox"`. Non-modal — focus moves into the panel on open and
 * returns to the trigger on close, but `Tab` is NOT trapped.
 */
export function Dropdown({ trigger, items, accent = "iris", align = "start", width = 220 }: DropdownProps) {
  const [open, setOpen] = useState(false);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const [menuId] = useState(() => useId("mx-dropdown"));

  // Uncontrolled check state — a `check` row toggles in place (seeded from `checked`).
  const [checks, setChecks] = useState<Record<string, boolean>>(() => {
    const seed: Record<string, boolean> = {};
    for (const it of items) if (it.type === "check" && it.id) seed[it.id] = !!it.checked;
    return seed;
  });

  const { style } = useAnchoredPosition(triggerRef, panelRef, {
    placement: align === "end" ? "bottom-end" : "bottom-start",
    width,
    open,
  });

  useDismiss(panelRef, {
    onDismiss: () => setOpen(false),
    outsideClick: true,
    escapeKey: true,
    ignore: [triggerRef],
    enabled: open,
  });

  // Non-modal focus: move into the panel on open (arrow-nav then reaches the
  // rows), return to the trigger on close — but do NOT trap.
  useEffect(() => {
    if (!open) return;
    const triggerEl = triggerRef.current;
    panelRef.current?.focus?.();
    return () => triggerEl?.focus?.();
  }, [open]);

  function runItem(it: DropdownItem) {
    if (it.disabled) return;
    if (it.type === "check" && it.id) {
      const id = it.id;
      setChecks((c) => ({ ...c, [id]: !c[id] }));
      it.onSelect?.();
      return;
    }
    it.onSelect?.();
    setOpen(false);
  }

  function renderRow(it: DropdownItem, i: number) {
    const key = it.id ?? `${it.type ?? "item"}-${i}`;
    if (it.type === "separator") return <div key={key} className="mx-dropdown__sep" role="separator" />;
    if (it.type === "label")
      return (
        <div key={key} className="mx-dropdown__label">
          {it.label}
        </div>
      );
    const isCheck = it.type === "check";
    const on = isCheck && it.id ? checks[it.id] : false;
    return (
      <button
        key={key}
        type="button"
        role={isCheck ? "menuitemcheckbox" : "menuitem"}
        aria-checked={isCheck ? !!on : undefined}
        aria-disabled={it.disabled || undefined}
        className="mx-dropdown__item"
        onClick={() => runItem(it)}
      >
        {isCheck && (
          <span className="mx-dropdown__check" aria-hidden="true">
            {on ? <Icon name="check" size={14} /> : null}
          </span>
        )}
        {it.icon && !isCheck && <Icon className="mx-dropdown__icon" name={it.icon} size={15} />}
        <span className="mx-dropdown__text">{it.label}</span>
        {it.shortcut && <span className="mx-dropdown__shortcut">{it.shortcut}</span>}
      </button>
    );
  }

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        className="mx-dropdown__trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={open ? menuId : undefined}
        onClick={() => setOpen((o) => !o)}
      >
        {trigger}
      </button>
      {open && (
        <Portal>
          <div
            ref={panelRef}
            id={menuId}
            role="menu"
            tabIndex={-1}
            className={cx("mx-dropdown", `mx-dropdown--accent-${accent}`)}
            style={style}
            onKeyDown={(e) => {
              // useArrowNavigation is a pure handler, NOT a React hook.
              useArrowNavigation(e.nativeEvent, document.activeElement as HTMLElement, panelRef.current ?? undefined, {
                candidateSelector: MENU_NAV,
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

export default Dropdown;
