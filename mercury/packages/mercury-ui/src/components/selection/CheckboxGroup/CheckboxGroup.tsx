import { useState } from "react";
import type { ReactNode } from "react";
import { cx } from "@mercury/core";
import { Checkbox } from "../Checkbox";

type Accent = "iris" | "indigo" | "green" | "orange" | "plum" | "red";

export interface CheckboxGroupProps {
  items: { value: string; label?: ReactNode; disabled?: boolean }[];
  value?: string[];
  defaultValue?: string[];
  onChange?: (value: string[]) => void;
  accent?: Accent;
  orientation?: "vertical" | "horizontal";
  disabled?: boolean;
}

export function CheckboxGroup({
  items,
  value,
  defaultValue,
  onChange,
  accent,
  orientation = "vertical",
  disabled,
}: CheckboxGroupProps) {
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
        "mx-checkbox-group",
        `mx-checkbox-group--${orientation}`,
        accent && `mx-checkbox-group--accent-${accent}`,
      )}
      role="group"
    >
      {items.map((it) => (
        <Checkbox
          key={it.value}
          checked={sel.includes(it.value)}
          disabled={disabled || it.disabled}
          label={it.label}
          onChange={() => onItem(it.value)}
        />
      ))}
    </div>
  );
}
