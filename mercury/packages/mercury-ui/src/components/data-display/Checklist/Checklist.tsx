import type { ReactNode } from "react";
import { cx } from "../cx";

/**
 * Checklist — a list of requirements with met / unmet markers. Used for
 * password rules, onboarding steps, or any "criteria satisfied" UI.
 */
export interface ChecklistItem {
  label: ReactNode;
  met: boolean;
}

export interface ChecklistProps {
  items: ChecklistItem[];
  className?: string;
}

export function Checklist({ items, className }: ChecklistProps) {
  return (
    <ul className={cx("mx-checklist", className)}>
      {items.map((item, i) => (
        <li key={i} className={cx("mx-checklist__item", item.met && "is-met")}>
          <span className="mx-checklist__mark" aria-hidden="true">
            {item.met ? "✓" : "○"}
          </span>
          <span>{item.label}</span>
        </li>
      ))}
    </ul>
  );
}
