import { useEffect, useRef, useState } from "react";
import type { ReactNode, RefObject } from "react";
import { cx, useAnchoredPosition, useArrowNavigation, useDismiss, useId } from "@mercury/core";
import { Portal } from "../../overlay/_overlay/Portal";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

/** One row of a {@link Menubar} submenu. `check`/`radio` carry state; a plain
 * `item` runs `onSelect` and closes; `label`/`separator` are presentational. */
export interface MenubarItem {
  /** Row kind. Default `"item"`. */
  type?: "item" | "check" | "radio" | "label" | "separator";
  /** The row's visible text. */
  label?: ReactNode;
  /** Stable id — required for a `check` row's toggle state. */
  id?: string;
  /** The radio group's name (rows sharing it are mutually exclusive). */
  group?: string;
  /** The radio row's value (the selected value keys the group). */
  value?: string;
  /** Initial checked state for a `check`/`radio` row (thereafter uncontrolled). */
  checked?: boolean;
  /** A trailing key hint. */
  shortcut?: string;
  /** A leading icon (plain item rows). */
  icon?: IconName;
  /** Invoked on activation. */
  onSelect?: () => void;
}

/** One top-level menu of a {@link Menubar}. */
export interface MenubarMenu {
  /** The bar trigger's text. */
  label: string;
  /** A leading icon on the bar trigger. */
  icon?: IconName;
  /** The submenu rows, in order. */
  items: MenubarItem[];
}

export interface MenubarProps {
  /** The top-level menus, left to right. */
  menus: MenubarMenu[];
  /** The check-mark ink + radio-dot fill family. Default `"iris"`. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
}

type Accent = NonNullable<MenubarProps["accent"]>;

// Arrow-nav collection within a submenu (menubar rows are never disabled).
const MENU_NAV =
  '[role="menuitem"]:not([aria-disabled="true"]),[role="menuitemradio"],[role="menuitemcheckbox"]';

/**
 * Menubar — a horizontal bar of menus (a desktop-app menu strip). Each top menu
 * opens a submenu that composes the overlay-floor: `useAnchoredPosition`
 * (portaled, `position: fixed`) + `useDismiss` (outside-press + `Escape`, the
 * whole bar ignored so a sibling trigger switches without a dismiss race) +
 * `useArrowNavigation` (Up/Down within a submenu). `ArrowLeft`/`ArrowRight` on
 * the bar move between the top triggers.
 *
 * a11y: the bar is `role="menubar"`; each trigger is `role="menuitem"` with
 * `aria-haspopup="menu"` + `aria-expanded`; a submenu is `role="menu"` with
 * `menuitem` / `menuitemcheckbox` / `menuitemradio` rows.
 */
export function Menubar({ menus, accent = "iris" }: MenubarProps) {
  const [openIdx, setOpenIdx] = useState<number | null>(null);
  const barRef = useRef<HTMLDivElement>(null);

  // Uncontrolled selection state — checks by id, radios by group → selected value.
  const [checks, setChecks] = useState<Record<string, boolean>>(() => {
    const seed: Record<string, boolean> = {};
    for (const m of menus) for (const it of m.items) if (it.type === "check" && it.id) seed[it.id] = !!it.checked;
    return seed;
  });
  const [radios, setRadios] = useState<Record<string, string>>(() => {
    const seed: Record<string, string> = {};
    for (const m of menus)
      for (const it of m.items) if (it.type === "radio" && it.group && it.value != null && it.checked) seed[it.group] = it.value;
    return seed;
  });

  return (
    <div
      ref={barRef}
      role="menubar"
      className={cx("mx-menubar", `mx-menubar--accent-${accent}`)}
      onKeyDown={(e) => {
        // ArrowLeft/Right move between top triggers (submenus own Up/Down).
        if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
        const bar = barRef.current;
        if (!bar) return;
        const triggers = Array.from(bar.querySelectorAll<HTMLButtonElement>('[role="menuitem"]'));
        const idx = triggers.indexOf(document.activeElement as HTMLButtonElement);
        if (idx === -1) return;
        e.preventDefault();
        const next =
          e.key === "ArrowRight" ? (idx + 1) % triggers.length : (idx - 1 + triggers.length) % triggers.length;
        triggers[next]?.focus();
        setOpenIdx((cur) => (cur != null ? next : cur));
      }}
    >
      {menus.map((m, i) => (
        <MenubarTop
          key={m.label}
          menu={m}
          accent={accent}
          isOpen={openIdx === i}
          anyOpen={openIdx != null}
          barRef={barRef}
          onToggle={() => setOpenIdx((cur) => (cur === i ? null : i))}
          onHover={() => setOpenIdx(i)}
          onClose={() => setOpenIdx(null)}
          checks={checks}
          radios={radios}
          onToggleCheck={(id) => setChecks((c) => ({ ...c, [id]: !c[id] }))}
          onSelectRadio={(group, value) => setRadios((r) => ({ ...r, [group]: value }))}
        />
      ))}
    </div>
  );
}

interface MenubarTopProps {
  menu: MenubarMenu;
  accent: Accent;
  isOpen: boolean;
  anyOpen: boolean;
  barRef: RefObject<HTMLDivElement | null>;
  onToggle: () => void;
  onHover: () => void;
  onClose: () => void;
  checks: Record<string, boolean>;
  radios: Record<string, string>;
  onToggleCheck: (id: string) => void;
  onSelectRadio: (group: string, value: string) => void;
}

/**
 * One top-level menu: a bar trigger + (when open) a portaled submenu. A stable
 * function component so the floor hooks are called once per top menu, never
 * inside the parent's `menus.map()` (rules of hooks).
 */
function MenubarTop({
  menu,
  accent,
  isOpen,
  anyOpen,
  barRef,
  onToggle,
  onHover,
  onClose,
  checks,
  radios,
  onToggleCheck,
  onSelectRadio,
}: MenubarTopProps) {
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const [panelId] = useState(() => useId("mx-menubar"));

  const { style } = useAnchoredPosition(triggerRef, panelRef, { placement: "bottom-start", open: isOpen });

  useDismiss(panelRef, {
    onDismiss: onClose,
    outsideClick: true,
    escapeKey: true,
    ignore: [barRef],
    enabled: isOpen,
  });

  // Move focus into the submenu on open so arrow-nav + Escape work from the keyboard.
  useEffect(() => {
    if (!isOpen) return;
    panelRef.current?.focus?.();
  }, [isOpen]);

  function runItem(it: MenubarItem) {
    if (it.type === "check" && it.id) {
      onToggleCheck(it.id);
      it.onSelect?.();
      return;
    }
    if (it.type === "radio" && it.group && it.value != null) {
      onSelectRadio(it.group, it.value);
      it.onSelect?.();
      return;
    }
    it.onSelect?.();
    onClose();
  }

  function renderItem(it: MenubarItem, i: number) {
    const key = it.id ?? `${it.type ?? "item"}-${i}`;
    if (it.type === "separator") return <div key={key} className="mx-menubar__sep" role="separator" />;
    if (it.type === "label")
      return (
        <div key={key} className="mx-menubar__label">
          {it.label}
        </div>
      );
    const isCheck = it.type === "check";
    const isRadio = it.type === "radio";
    const on =
      isCheck && it.id
        ? !!checks[it.id]
        : isRadio && it.group && it.value != null
          ? radios[it.group] === it.value
          : false;
    return (
      <button
        key={key}
        type="button"
        role={isCheck ? "menuitemcheckbox" : isRadio ? "menuitemradio" : "menuitem"}
        aria-checked={isCheck || isRadio ? on : undefined}
        className="mx-menubar__item"
        onClick={() => runItem(it)}
      >
        {isCheck && (
          <span className="mx-menubar__check" aria-hidden="true">
            {on ? <Icon name="check" size={14} /> : null}
          </span>
        )}
        {isRadio && (
          <span className="mx-menubar__radio" aria-hidden="true">
            {on ? <span className="mx-menubar__radio-dot" /> : null}
          </span>
        )}
        {it.icon && !isCheck && !isRadio && <Icon className="mx-menubar__icon" name={it.icon} size={15} />}
        <span className="mx-menubar__text">{it.label}</span>
        {it.shortcut && <span className="mx-menubar__shortcut">{it.shortcut}</span>}
      </button>
    );
  }

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        role="menuitem"
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-controls={isOpen ? panelId : undefined}
        className={cx("mx-menubar__trigger", isOpen && "mx-menubar__trigger--active")}
        onClick={onToggle}
        onMouseEnter={() => {
          if (anyOpen) onHover();
        }}
      >
        {menu.icon && <Icon name={menu.icon} size={15} />}
        {menu.label}
      </button>
      {isOpen && (
        <Portal>
          <div
            ref={panelRef}
            id={panelId}
            role="menu"
            tabIndex={-1}
            className={cx("mx-menubar__panel", `mx-menubar--accent-${accent}`)}
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
            {menu.items.map((it, i) => renderItem(it, i))}
          </div>
        </Portal>
      )}
    </>
  );
}

export default Menubar;
