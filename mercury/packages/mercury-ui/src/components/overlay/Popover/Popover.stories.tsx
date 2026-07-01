import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { Popover, Button } from "@mercury/ui";
import type { PopoverPlacement } from "@mercury/ui";

// The placement ramp, traced from PopoverPlacement — NO-INVENT.
const PLACEMENTS: PopoverPlacement[] = ["bottom-start", "bottom-end", "top-start", "top-end"];

// Controls restate Popover.prompt.md: `trigger` (the button content), `children`
// (the panel body), `placement` (the anchor enum), `width` (px), `defaultOpen`
// (uncontrolled initial). `open`/`onOpenChange` drive the controlled path and
// are not raw controls.
const meta: Meta<typeof Popover> = {
  title: "Overlay/Popover",
  component: Popover,
  argTypes: {
    trigger: { control: "text" },
    children: { control: "text" },
    placement: { control: "inline-radio", options: PLACEMENTS },
    width: { control: "number" },
    defaultOpen: { control: "boolean" },
    open: { control: false },
    onOpenChange: { control: false },
  },
  args: {
    trigger: "Open menu",
    placement: "bottom-start",
    width: 280,
    children: "Anchored to the trigger; dismissed on outside press or Escape.",
  },
};
export default meta;

type Story = StoryObj<typeof Popover>;

export const Playground: Story = {};

// The placement states — a grid of triggers, each anchoring its panel differently.
export const Placements: Story = {
  render: () => (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "80px", padding: "120px" }}>
      {PLACEMENTS.map((p) => (
        <Popover key={p} trigger={`Placement ${p}`} placement={p} width={220}>
          Anchored {p}.
        </Popover>
      ))}
    </div>
  ),
};

// INV-A11Y — proves aria-expanded toggles on the trigger and an outside press
// dismisses (the trigger itself is ignored by the dismiss floor).
export const A11yToggle: Story = {
  name: "a11y — expanded + dismiss",
  render: () => (
    <div style={{ padding: "80px", display: "flex", gap: "24px" }}>
      <Popover trigger="Open menu">
        <Button variant="ghost" fullWidth>
          Action
        </Button>
      </Popover>
      <button type="button" data-testid="outside">
        Outside
      </button>
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    const trigger = canvas.getByRole("button", { name: "Open menu" });

    await expect(trigger).toHaveAttribute("aria-expanded", "false");
    await userEvent.click(trigger);
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    await body.findByRole("dialog");

    // An outside press dismisses.
    await userEvent.click(canvas.getByTestId("outside"));
    await waitFor(() => expect(trigger).toHaveAttribute("aria-expanded", "false"));
    await waitFor(() => expect(body.queryByRole("dialog")).toBeNull());
  },
};
