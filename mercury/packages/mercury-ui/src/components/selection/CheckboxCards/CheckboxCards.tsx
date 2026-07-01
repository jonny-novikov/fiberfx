import { useState } from "react";
import type { ReactNode } from "react";
import { cx } from "@mercury/core";
import { Checkbox } from "../Checkbox";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

type Accent = "iris" | "indigo" | "green" | "orange" | "plum" | "red";

export interface CheckboxCardsProps {
  items: {
    value: string;
    label?: ReactNode;
    description?: ReactNode;
    icon?: IconName;
    disabled?: boolean;
  }[];
  value?: string[];
  defaultValue?: string[];
  onChange?: (value: string[]) => void;
  accent?: Accent;
  columns?: number;
  size?: "sm" | "md" | "lg";
}

export function CheckboxCards({
  items,
  value,
  defaultValue,
  onChange,
  accent,
  columns = 1,
  size = "md",
}: CheckboxCardsProps) {
  const [internal, setInternal] = useState<string[]>(defaultValue ?? []);
  const sel = value ?? internal;

  const onItem = (v: string) => {
    const next = sel.includes(v) ? sel.filter((x) => x !== v) : [...sel, v];
    if (value == null) setInternal(next);
    onChange?.(next);
  };

  return (
    <div
      className={cx(
        "mx-checkbox-cards",
        `mx-checkbox-cards--${size}`,
        accent && `mx-checkbox-cards--accent-${accent}`,
      )}
      style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}
    >
      {items.map((it) => (
        <div
          key={it.value}
          className={cx(
            "mx-checkbox-cards__card",
            sel.includes(it.value) && "is-selected",
            it.disabled && "is-disabled",
          )}
        >
          <Checkbox
            checked={sel.includes(it.value)}
            disabled={it.disabled}
            onChange={() => onItem(it.value)}
            label={
              <span className="mx-checkbox-cards__body">
                {it.icon && <Icon name={it.icon} className="mx-checkbox-cards__icon" />}
                <span className="mx-checkbox-cards__text">
                  {it.label != null && <span className="mx-checkbox-cards__label">{it.label}</span>}
                  {it.description != null && (
                    <span className="mx-checkbox-cards__desc">{it.description}</span>
                  )}
                </span>
              </span>
            }
          />
        </div>
      ))}
    </div>
  );
}
