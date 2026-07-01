import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { Dropdown } from "@mercury/ui";
import type { DropdownItem } from "@mercury/ui";

// The accent ramp, traced from DropdownProps["accent"] — NO-INVENT.
const ACCENTS = ["iris", "indigo", "green", "orange", "plum", "red"] as const;

// A representative menu — a group label, item rows with icon + shortcut, a
// toggling `check` row, and a separator.
const ITEMS: DropdownItem[] = [
  { type: "label", label: "Account" },
  { type: "item", label: "Profile", icon: "user", shortcut: "⌘P" },
  { type: "item", label: "Settings", icon: "cog" },
  { type: "check", id: "notify", label: "Notifications", checked: true },
  { type: "separator" },
  { type: "item", label: "Sign out", icon: "arrow-up-right" },
];

// Controls restate Dropdown.prompt.md: `trigger` (button content), `accent`
// (check-mark ink family), `align` (which trigger edge the panel aligns to),
// `width` (px). `items` is a structured array, not a raw control.
const meta: Meta<typeof Dropdown> = {
  title: "Overlay/Dropdown",
  component: Dropdown,
  argTypes: {
    trigger: { control: "text" },
    accent: { control: "inline-radio", options: ACCENTS },
    align: { control: "inline-radio", options: ["start", "end"] },
    width: { control: "number" },
    items: { control: false },
  },
  args: {
    trigger: "Open menu",
    accent: "iris",
    align: "start",
    width: 220,
    items: ITEMS,
  },
};
export default meta;

type Story = StoryObj<typeof Dropdown>;

export const Playground: Story = {};

// The accent + align states — a row of triggers, each opens the same menu with a
// different check-mark ink; the last aligns to the trigger's end edge.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "16px", padding: "40px" }}>
      {ACCENTS.map((a) => (
        <Dropdown key={a} trigger={`accent ${a}`} accent={a} items={ITEMS} />
      ))}
      <Dropdown trigger="align end" align="end" items={ITEMS} />
    </div>
  ),
};

// INV-A11Y — proves the trigger advertises a menu, click toggles aria-expanded,
// ArrowDown moves focus onto the first row (the arrow-nav floor), and Escape
// dismisses. The panel is portaled, so it is queried through the document body.
export const A11yArrowNav: Story = {
  name: "a11y — haspopup + arrow-nav + dismiss",
  render: () => (
    <div style={{ padding: "80px" }}>
      <Dropdown trigger="Open menu" items={ITEMS} />
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    const trigger = canvas.getByRole("button", { name: "Open menu" });

    await expect(trigger).toHaveAttribute("aria-haspopup", "menu");
    await expect(trigger).toHaveAttribute("aria-expanded", "false");

    // Open — aria-expanded flips and the portaled menu appears.
    await userEvent.click(trigger);
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await body.findByRole("menu");

    // ArrowDown from the focused panel lands on the first menuitem.
    await userEvent.keyboard("{ArrowDown}");
    await waitFor(() => expect(body.getByRole("menuitem", { name: /Profile/ })).toHaveFocus());

    // Escape dismisses; aria-expanded returns to false.
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(body.queryByRole("menu")).toBeNull());
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  },
};
