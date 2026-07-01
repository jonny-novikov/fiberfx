import type { ReactNode } from "react";
import { cx } from "@mercury/core";

export type TabNavSize = "sm" | "md";

export interface TabNavItem {
  /** The item's stable value, matched against `value` to mark the active tab. */
  value: string;
  /** The visible label. */
  label: ReactNode;
  /** The navigation target. Omit for a non-navigating tab (driven by `onChange`). */
  href?: string;
  /** Renders the tab dimmed + non-interactive. */
  disabled?: boolean;
}

export interface TabNavProps {
  /** The tabs, in order. */
  items: TabNavItem[];
  /** The active tab's `value` (controlled). */
  value: string;
  /** Notified with the clicked tab's `value` (unless disabled). */
  onChange?: (value: string) => void;
  /** Density. Default `"md"`. */
  size?: TabNavSize;
}

/**
 * TabNav — link-styled navigation tabs: a `<nav>` of `<a aria-current="page">`
 * anchors sharing an underline rail. Distinct from `Tabs`, which switches
 * in-page panels — TabNav navigates (each tab is a real link with an `href`),
 * so the active tab is the current *page*, not a selected panel.
 *
 * Controlled: `value` marks the active tab; `onChange` fires with the clicked
 * tab's value (a disabled tab is inert — `preventDefault` + no `onChange`).
 * Presentational — no floor, no portal, no internal state.
 *
 * a11y: the active anchor carries `aria-current="page"`; the `:focus-visible`
 * ring is restored (the source prototype's `outline: none` was an a11y
 * regression and is NOT carried over).
 */
export function TabNav({ items, value, onChange, size = "md" }: TabNavProps) {
  return (
    <nav className={cx("mx-tabnav", `mx-tabnav--${size}`)}>
      {items.map((item) => {
        const active = value === item.value;
        return (
          <a
            key={item.value}
            href={item.disabled ? undefined : (item.href ?? "#")}
            aria-current={active ? "page" : undefined}
            aria-disabled={item.disabled || undefined}
            className={cx("mx-tabnav__link", active && "mx-tabnav__link--active")}
            onClick={(e) => {
              if (item.disabled) {
                e.preventDefault();
                return;
              }
              onChange?.(item.value);
            }}
          >
            {item.label}
          </a>
        );
      })}
    </nav>
  );
}

export default TabNav;
