import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { Tabs } from "@mercury/ui";
import type { Tab, TabsProps } from "@mercury/ui";

// `variant` restated from TabsProps (source-typed) — NO-INVENT (mx.4.md INV-5).
// `Tabs<T>` is generic over the value union; the stories pin `T = string` via the
// instantiation expression `typeof Tabs<string>`.
const VARIANTS: NonNullable<TabsProps<string>["variant"]>[] = ["underline", "pills"];

// Page-level sections (the underline example).
// apps/showcase/src/pages/components/TabsPage.tsx
const SECTIONS: Tab<string>[] = [
  { label: "Overview", value: "overview" },
  { label: "Activity", value: "activity" },
  { label: "Settings", value: "settings" },
  { label: "Billing", value: "billing" },
];

// A compact view toggle (the pills example).
// apps/showcase/src/pages/components/TabsPage.tsx + codemojex-node/apps/economy/src/App.tsx
const RANGES: Tab<string>[] = [
  { label: "Daily", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
];

// A disabled tab in the strip — restates the `Tab<T>.disabled?` member.
const WITH_DISABLED: Tab<string>[] = [
  { label: "Overview", value: "overview" },
  { label: "Activity", value: "activity" },
  { label: "Archived", value: "archived", disabled: true },
];

// Tabs is controlled (no internal state); a small stateful wrapper holds the
// active value so the strip is interactive in the story.
function ControlledTabs(props: TabsProps<string>) {
  const [value, setValue] = useState(props.value);
  return <Tabs {...props} value={value} onChange={setValue} />;
}

// Controls restate Tabs.prompt.md: `variant` (underline|pills), `tabs`/`value`
// are structured data driven by the render (control: false), `onChange` is the
// controlled callback.
const meta: Meta<typeof Tabs<string>> = {
  title: "Navigation/Tabs",
  component: Tabs,
  argTypes: {
    variant: { control: "inline-radio", options: VARIANTS },
    tabs: { control: false },
    value: { control: false },
    onChange: { control: false },
  },
  args: {
    tabs: SECTIONS,
    value: "overview",
    variant: "underline",
  },
  render: (args) => <ControlledTabs {...args} />,
};
export default meta;

type Story = StoryObj<typeof Tabs<string>>;

export const Playground: Story = {};

// Both variants, each with its real-call-site sample data.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px" }}>
      {VARIANTS.map((variant) => (
        <div key={variant} style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
          <span
            style={{
              fontFamily: "var(--font-secondary)",
              fontSize: "var(--text-body-100-size)",
              lineHeight: "var(--text-body-100-lh)",
              color: "rgb(var(--fg-secondary))",
            }}
          >
            {variant}
          </span>
          <ControlledTabs
            tabs={variant === "pills" ? RANGES : SECTIONS}
            value={variant === "pills" ? "daily" : "overview"}
            variant={variant}
          />
        </div>
      ))}
    </div>
  ),
};

// A disabled tab is rendered disabled and is inert (no toggle, no onChange).
export const WithDisabledTab: Story = {
  args: {
    tabs: WITH_DISABLED,
    value: "overview",
  },
};
