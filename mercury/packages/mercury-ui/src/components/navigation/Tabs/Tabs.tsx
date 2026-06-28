import { cx } from "@mercury/core";

export interface Tab<T extends string> {
  label: string;
  value: T;
  disabled?: boolean;
}

export interface TabsProps<T extends string> {
  tabs: Tab<T>[];
  value: T;
  onChange?: (value: T) => void;
  variant?: "underline" | "pills";
}

export function Tabs<T extends string>({ tabs, value, onChange, variant = "underline" }: TabsProps<T>) {
  return (
    <div className={cx("mx-tabs", variant === "pills" && "mx-tabs--pills")} role="tablist">
      {tabs.map((t) => (
        <button
          key={t.value}
          type="button"
          role="tab"
          aria-selected={t.value === value}
          disabled={t.disabled}
          className={cx("mx-tab", t.value === value && "is-active")}
          onClick={() => !t.disabled && onChange?.(t.value)}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}
