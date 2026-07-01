import { useId, useState } from "react";
import type { ReactNode } from "react";
import { cx } from "@mercury/core";
import { Radio } from "../Radio";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

type Accent = "iris" | "indigo" | "green" | "orange" | "plum" | "red";

export interface RadioCardsProps {
  items: {
    value: string;
    label?: ReactNode;
    description?: ReactNode;
    icon?: IconName;
    disabled?: boolean;
  }[];
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  accent?: Accent;
  columns?: number;
  size?: "sm" | "md" | "lg";
}

export function RadioCards({
  items,
  value,
  defaultValue,
  onChange,
  accent,
  columns = 1,
  size = "md",
}: RadioCardsProps) {
  const gid = useId();
  const groupName = gid;
  const [internal, setInternal] = useState(defaultValue ?? "");
  const sel = value ?? internal;

  const onItem = (v: string) => {
    if (value == null) setInternal(v);
    onChange?.(v);
  };

  return (
    <div
      className={cx(
        "mx-radio-cards",
        `mx-radio-cards--${size}`,
        accent && `mx-radio-cards--accent-${accent}`,
      )}
      style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}
    >
      {items.map((it) => (
        <div
          key={it.value}
          className={cx(
            "mx-radio-cards__card",
            sel === it.value && "is-selected",
            it.disabled && "is-disabled",
          )}
        >
          <Radio
            value={it.value}
            name={groupName}
            checked={sel === it.value}
            disabled={it.disabled}
            onChange={(v) => onItem(v)}
            label={
              <span className="mx-radio-cards__body">
                {it.icon && <Icon name={it.icon} className="mx-radio-cards__icon" />}
                <span className="mx-radio-cards__text">
                  {it.label != null && <span className="mx-radio-cards__label">{it.label}</span>}
                  {it.description != null && (
                    <span className="mx-radio-cards__desc">{it.description}</span>
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
