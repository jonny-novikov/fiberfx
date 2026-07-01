import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { TabNav } from "@mercury/ui";
import type { TabNavItem, TabNavProps, TabNavSize } from "@mercury/ui";

// The size ramp, traced from TabNavSize — NO-INVENT.
const SIZES: TabNavSize[] = ["sm", "md"];

const NAV: TabNavItem[] = [
  { value: "overview", label: "Overview", href: "#overview" },
  { value: "activity", label: "Activity", href: "#activity" },
  { value: "settings", label: "Settings", href: "#settings" },
  { value: "billing", label: "Billing", href: "#billing", disabled: true },
];

// A controlled wrapper so clicking a tab moves the active marker in the demo.
function TabNavDemo(args: TabNavProps) {
  const [value, setValue] = useState(args.value);
  return <TabNav {...args} value={value} onChange={setValue} />;
}

const meta: Meta<typeof TabNav> = {
  title: "Navigation/TabNav",
  component: TabNav,
  argTypes: {
    items: { control: false },
    value: { control: false },
    onChange: { control: false },
    size: { control: "inline-radio", options: SIZES },
  },
  args: { items: NAV, value: "overview", size: "md" },
  render: (args) => <TabNavDemo {...args} />,
};
export default meta;

type Story = StoryObj<typeof TabNav>;

export const Playground: Story = {};

// Both densities.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px", padding: "24px" }}>
      {SIZES.map((s) => (
        <TabNavDemo key={s} items={NAV} value="overview" size={s} />
      ))}
    </div>
  ),
};

// INV-A11Y (S-7) — the active tab carries aria-current="page", and keyboard
// focus restores the :focus-visible ring (the source prototype's outline:none
// was dropped as an a11y regression).
export const A11yCurrentAndRing: Story = {
  name: "a11y — aria-current + focus ring",
  render: () => (
    <div style={{ padding: "40px" }}>
      <TabNav items={NAV} value="overview" />
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const overview = canvas.getByRole("link", { name: "Overview" });

    // The active tab is marked for assistive tech.
    await expect(overview).toHaveAttribute("aria-current", "page");

    // Keyboard focus lands the first link, and the focus ring is restored
    // (a real browser matches :focus-visible on Tab).
    await userEvent.tab();
    await expect(overview).toHaveFocus();
    await expect(window.getComputedStyle(overview).outlineStyle).not.toBe("none");
  },
};
