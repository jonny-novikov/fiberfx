import { useId, useState } from "react";
import type { ReactNode } from "react";
import { cx } from "@mercury/core";
import { Radio } from "../Radio";

type Accent = "iris" | "indigo" | "green" | "orange" | "plum" | "red";

export interface RadioGroupProps {
  items: { value: string; label?: ReactNode; disabled?: boolean }[];
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  name?: string;
  accent?: Accent;
  orientation?: "vertical" | "horizontal";
  disabled?: boolean;
}

export function RadioGroup({
  items,
  value,
  defaultValue,
  onChange,
  name,
  accent,
  orientation = "vertical",
  disabled,
}: RadioGroupProps) {
  const gid = useId();
  const groupName = name ?? gid;
  const [internal, setInternal] = useState(defaultValue ?? "");
  const sel = value ?? internal;

  const onItem = (v: string) => {
    if (value == null) setInternal(v);
    onChange?.(v);
  };

  return (
    <div
      className={cx(
        "mx-radio-group",
        `mx-radio-group--${orientation}`,
        accent && `mx-radio-group--accent-${accent}`,
      )}
      role="radiogroup"
    >
      {items.map((it) => (
        <Radio
          key={it.value}
          value={it.value}
          name={groupName}
          checked={sel === it.value}
          disabled={disabled || it.disabled}
          label={it.label}
          onChange={(v) => onItem(v)}
        />
      ))}
    </div>
  );
}
