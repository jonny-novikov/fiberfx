import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fireEvent, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { ContextMenu } from "@mercury/ui";
import type { ContextMenuItem } from "@mercury/ui";

// A representative editing menu — item rows with icon + shortcut, a separator,
// and a `danger` (destructive) row.
const ITEMS: ContextMenuItem[] = [
  { type: "label", label: "Edit" },
  { type: "item", label: "Copy", icon: "copy", shortcut: "⌘C" },
  { type: "item", label: "Download", icon: "download" },
  { type: "item", label: "Refresh", icon: "refresh" },
  { type: "separator" },
  { type: "item", label: "Delete", icon: "trash", shortcut: "⌫", danger: true },
];

// The wrapped right-click surface. `border: "1px dashed"` inherits currentColor —
// no color literal (INV-3).
function Zone({ label = "Right-click inside this area" }: { label?: string }) {
  return (
    <div
      data-testid="ctx-area"
      style={{ display: "grid", placeItems: "center", height: 160, border: "1px dashed", borderRadius: 12, padding: 24 }}
    >
      {label}
    </div>
  );
}

// Controls restate ContextMenu.prompt.md: `width` (px). `children` is the
// right-click surface and `items` a structured array — not raw controls.
const meta: Meta<typeof ContextMenu> = {
  title: "Overlay/ContextMenu",
  component: ContextMenu,
  argTypes: {
    width: { control: "number" },
    children: { control: false },
    items: { control: false },
  },
  args: { width: 220, items: ITEMS },
};
export default meta;

type Story = StoryObj<typeof ContextMenu>;

export const Playground: Story = {
  render: (args) => (
    <div style={{ padding: "40px" }}>
      <ContextMenu {...args}>
        <Zone />
      </ContextMenu>
    </div>
  ),
};

// INV-A11Y — proves a right-click opens the portaled menu at the pointer, the
// `danger` row carries its recolour class, and Escape dismisses.
export const A11yContext: Story = {
  name: "a11y — right-click opens + danger + dismiss",
  render: () => (
    <div style={{ padding: "40px" }}>
      <ContextMenu items={ITEMS}>
        <Zone />
      </ContextMenu>
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);

    // fireEvent.contextMenu is reliable for React's synthetic onContextMenu.
    fireEvent.contextMenu(canvas.getByTestId("ctx-area"), { clientX: 120, clientY: 120 });
    const menu = await body.findByRole("menu");

    // The danger row renders with its token-based recolour.
    await expect(within(menu).getByRole("menuitem", { name: /Delete/ })).toHaveClass("mx-ctx__item--danger");

    // Escape dismisses.
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(body.queryByRole("menu")).toBeNull());
  },
};
