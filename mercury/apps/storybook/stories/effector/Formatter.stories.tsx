import type { Meta, StoryObj } from "@storybook/react-vite";
import { createFormatterModel } from "@mercury/effector";
import { Stat, Select } from "@mercury/ui";
import type { MonthFormat, YearFormat, SelectOption } from "@mercury/ui";

// "Effector/Formatter" — createFormatterModel (an Effector-backed wrapper over
// @mercury/ui's createFormatter) driving a Stat that shows a live, locale-aware
// date. NO-INVENT: symbols traced from packages/mercury-effector/src/formatter.ts
// (createFormatterModel → { setLocale, setMonthFormat, setYearFormat,
// useFormatter, ... }); Formatter.{fullMonthAndYear,fullMonth,fullYear,dayOfWeek}
// traced from @mercury/core's date-time/formatter.ts (re-exported by @mercury/ui).
// mx.5 §6.6 RECONCILE: the formatter is a DATE/locale formatter — it wires a
// Stat, NOT MoneyInput (which takes no formatter). Stat props traced from
// Stat.tsx (label/value); Select props from Select.tsx (options: SelectOption[],
// onChange DOM event). The model + the SAMPLE Date live at module scope; SAMPLE
// is FIXED (a constant, never a runtime clock read at load — determinism).
// Cross-component story — no `component:`.

// Locale pinned at "en-US" so the controls and the rendered Stat start in sync
// (and the output is deterministic, not navigator.language-dependent).
const model = createFormatterModel({ locale: "en-US" });
const SAMPLE = new Date(2026, 0, 15);

const LOCALES: SelectOption[] = [
  { label: "English (US)", value: "en-US" },
  { label: "Français", value: "fr-FR" },
  { label: "日本語", value: "ja-JP" },
  { label: "Deutsch", value: "de-DE" },
];

// Each literal is checked against the real MonthFormat / YearFormat unions
// (the compile-time NO-INVENT guard); `as const` keeps the values string-typed
// for SelectOption.value.
const MONTH_STYLES = ["long", "short", "narrow", "numeric", "2-digit"] as const satisfies readonly MonthFormat[];
const YEAR_STYLES = ["numeric", "2-digit"] as const satisfies readonly YearFormat[];
const MONTH_OPTIONS: SelectOption[] = MONTH_STYLES.map((m) => ({ label: m, value: m }));
const YEAR_OPTIONS: SelectOption[] = YEAR_STYLES.map((y) => ({ label: y, value: y }));

const meta: Meta = {
  title: "Effector/Formatter",
};
export default meta;

type Story = StoryObj;

function FormatterDemo() {
  // useFormatter() subscribes to $locale/$monthFormat/$yearFormat, so changing
  // any control re-renders the Stat with the live-formatted value.
  const fmt = model.useFormatter();
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "460px" }}>
      <div style={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
        <Select
          label="Locale"
          options={LOCALES}
          defaultValue="en-US"
          onChange={(e) => model.setLocale(e.target.value)}
        />
        <Select
          label="Month style"
          options={MONTH_OPTIONS}
          defaultValue="long"
          onChange={(e) => model.setMonthFormat(e.target.value as MonthFormat)}
        />
        <Select
          label="Year style"
          options={YEAR_OPTIONS}
          defaultValue="numeric"
          onChange={(e) => model.setYearFormat(e.target.value as YearFormat)}
        />
      </div>
      <Stat label="Member since" value={fmt.fullMonthAndYear(SAMPLE)} />
      <p style={{ margin: 0, fontFamily: "var(--font-secondary)", color: "rgb(var(--fg-secondary))" }}>
        {fmt.fullMonthAndYear(SAMPLE)} — formatted live from the Effector locale
        store; change a control and the Stat re-renders.
      </p>
    </div>
  );
}

// More of the formatter surface over the same fixed SAMPLE, all reading the live
// locale store.
function ComparisonDemo() {
  const fmt = model.useFormatter();
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
        gap: "12px",
        maxWidth: "560px",
      }}
    >
      <Stat label="Full" value={fmt.fullMonthAndYear(SAMPLE)} />
      <Stat label="Month" value={fmt.fullMonth(SAMPLE)} />
      <Stat label="Year" value={fmt.fullYear(SAMPLE)} />
      <Stat label="Weekday" value={fmt.dayOfWeek(SAMPLE, "long")} />
    </div>
  );
}

export const Playground: Story = {
  render: () => <FormatterDemo />,
};

export const Comparison: Story = {
  render: () => <ComparisonDemo />,
};
