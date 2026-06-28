import { forwardRef, useState, useRef } from "react";
import type { HTMLAttributes, ReactNode, KeyboardEvent } from "react";
import { cx } from "@mercury/core";

export interface AccordionItemData {
  value: string;
  title: ReactNode;
  content: ReactNode;
  disabled?: boolean;
}

export interface AccordionProps extends Omit<HTMLAttributes<HTMLDivElement>, "defaultValue"> {
  items: AccordionItemData[];
  /** "single" (default) keeps one item open at a time; "multiple" allows many. */
  type?: "single" | "multiple";
  /** Initially-open value(s) for the uncontrolled accordion. */
  defaultValue?: string | string[];
  /** In single mode, allow the open item to collapse again. Default true. */
  collapsible?: boolean;
}

function Caret() {
  return (
    <svg
      className="mx-acc__caret"
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M6 9l6 6 6-6" />
    </svg>
  );
}

export const Accordion = forwardRef<HTMLDivElement, AccordionProps>(function Accordion(
  { items, type = "single", defaultValue, collapsible = true, className, ...rest },
  ref,
) {
  const [open, setOpen] = useState<string[]>(() =>
    defaultValue == null ? [] : Array.isArray(defaultValue) ? defaultValue : [defaultValue],
  );
  const triggers = useRef<(HTMLButtonElement | null)[]>([]);

  const toggle = (value: string) => {
    setOpen((cur) => {
      const isOpen = cur.includes(value);
      if (type === "multiple") return isOpen ? cur.filter((v) => v !== value) : [...cur, value];
      if (isOpen) return collapsible ? [] : cur;
      return [value];
    });
  };

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const enabled = items.map((it, idx) => (it.disabled ? -1 : idx)).filter((x) => x >= 0);
    if (enabled.length === 0) return;
    const pos = enabled.indexOf(i);
    let next = -1;
    if (e.key === "ArrowDown") next = enabled[(pos + 1) % enabled.length] ?? -1;
    else if (e.key === "ArrowUp") next = enabled[(pos - 1 + enabled.length) % enabled.length] ?? -1;
    else if (e.key === "Home") next = enabled[0] ?? -1;
    else if (e.key === "End") next = enabled[enabled.length - 1] ?? -1;
    if (next >= 0) {
      e.preventDefault();
      triggers.current?.[next]?.focus();
    }
  };

  return (
    <div ref={ref} className={cx("mx-acc", className)} {...rest}>
      {items.map((it, i) => {
        const isOpen = open.includes(it.value);
        const panelId = `mx-acc-panel-${it.value}`;
        return (
          <div
            key={it.value}
            className={cx("mx-acc__item", isOpen && "is-open", it.disabled && "is-disabled")}
          >
            <h3 className="mx-acc__heading">
              <button
                ref={(el) => {
                  if (triggers.current) triggers.current[i] = el;
                }}
                type="button"
                className="mx-acc__trigger"
                aria-expanded={isOpen}
                aria-controls={panelId}
                disabled={it.disabled}
                onClick={() => toggle(it.value)}
                onKeyDown={(e) => onKey(e, i)}
              >
                <span className="mx-acc__title">{it.title}</span>
                <Caret />
              </button>
            </h3>
            <div id={panelId} className="mx-acc__panel" role="region">
              <div className="mx-acc__content">
                <div className="mx-acc__body">{it.content}</div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
});
