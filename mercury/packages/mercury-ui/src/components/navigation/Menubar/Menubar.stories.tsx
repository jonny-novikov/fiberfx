import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { Menubar } from "@mercury/ui";
import type { MenubarMenu } from "@mercury/ui";

// The accent ramp, traced from MenubarProps["accent"] — NO-INVENT.
const ACCENTS = ["iris", "indigo", "green", "orange", "plum", "red"] as const;

// Two top menus exercising every row kind — items with icon + shortcut, a
// separator, toggling checks, and a radio group.
const MENUS: MenubarMenu[] = [
  {
    label: "File",
    items: [
      { type: "item", label: "New File", icon: "plus", shortcut: "⌘N" },
      { type: "item", label: "Open…", shortcut: "⌘O" },
      { type: "separator" },
      { type: "item", label: "Save", shortcut: "⌘S" },
    ],
  },
  {
    label: "View",
    items: [
      { type: "check", id: "sidebar", label: "Show Sidebar", checked: true, shortcut: "⌘B" },
      { type: "check", id: "statusbar", label: "Show Status Bar" },
      { type: "separator" },
      { type: "label", label: "Density" },
      { type: "radio", group: "density", value: "comfortable", label: "Comfortable", checked: true },
      { type: "radio", group: "density", value: "compact", label: "Compact" },
    ],
  },
];

// Controls restate Menubar.prompt.md: `accent` (check-mark ink + radio-dot fill).
// `menus` is a structured array, not a raw control.
const meta: Meta<typeof Menubar> = {
  title: "Navigation/Menubar",
  component: Menubar,
  argTypes: {
    accent: { control: "inline-radio", options: ACCENTS },
    menus: { control: false },
  },
  args: { accent: "iris", menus: MENUS },
};
export default meta;

type Story = StoryObj<typeof Menubar>;

export const Playground: Story = {
  render: (args) => (
    <div style={{ padding: "40px", minHeight: 340 }}>
      <Menubar {...args} />
    </div>
  ),
};

// The accent states — the check mark + radio dot pick up the accent ink.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", padding: "40px" }}>
      {(["iris", "green", "plum"] as const).map((a) => (
        <Menubar key={a} accent={a} menus={MENUS} />
      ))}
    </div>
  ),
};

// INV-A11Y — proves a top trigger advertises a menu, click opens the portaled
// submenu (aria-expanded flips), ArrowDown moves focus onto the first row, and
// Escape dismisses. The trigger is queried in the canvas; the submenu (portaled)
// in the document body.
export const A11yMenubar: Story = {
  name: "a11y — haspopup + arrow-nav + dismiss",
  render: () => (
    <div style={{ padding: "40px", minHeight: 340 }}>
      <Menubar menus={MENUS} />
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    const file = canvas.getByRole("menuitem", { name: /File/ });

    await expect(file).toHaveAttribute("aria-haspopup", "menu");

    // Open — aria-expanded flips and the portaled submenu appears.
    await userEvent.click(file);
    await expect(file).toHaveAttribute("aria-expanded", "true");
    await body.findByRole("menu");

    // ArrowDown from the focused submenu lands on the first row.
    await userEvent.keyboard("{ArrowDown}");
    await waitFor(() => expect(body.getByRole("menuitem", { name: /New File/ })).toHaveFocus());

    // Escape dismisses.
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(body.queryByRole("menu")).toBeNull());
  },
};
