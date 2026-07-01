import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath — zero new dependency
import { Dialog, Button } from "@mercury/ui";
import type { DialogSize } from "@mercury/ui";

// The size ramp, traced from DialogProps["size"] — NO-INVENT (an invented
// member fails sb:typecheck).
const SIZES: DialogSize[] = ["sm", "md", "lg"];

// Controls restate Dialog.prompt.md: `open` (mounts/portals), `size` (the
// sm|md|lg max-width ramp), `title`/`description` (the header slots), `showClose`
// (the corner IconButton). `footer`/`onClose` are driven per story (real Buttons
// + the dismissal callback), not raw controls.
const meta: Meta<typeof Dialog> = {
  title: "Overlay/Dialog",
  component: Dialog,
  argTypes: {
    open: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
    title: { control: "text" },
    description: { control: "text" },
    showClose: { control: "boolean" },
    footer: { control: false },
    onClose: { control: false },
  },
  args: {
    open: true,
    size: "md",
    title: "Invite teammates",
    description: "They will receive an email with a link to join the workspace.",
    showClose: true,
    children: "Add people to this workspace by email.",
  },
};
export default meta;

type Story = StoryObj<typeof Dialog>;

export const Playground: Story = {};

// The size states — a row of triggers, each opening the dialog at that width
// (one open at a time; a grid of open modals would overlap at body-center).
export const Sizes: Story = {
  render: () => {
    const [size, setSize] = useState<DialogSize | null>(null);
    return (
      <div style={{ display: "flex", gap: "12px" }}>
        {SIZES.map((s) => (
          <Button key={s} variant="secondary" onClick={() => setSize(s)}>
            Open {s}
          </Button>
        ))}
        <Dialog
          open={size !== null}
          onClose={() => setSize(null)}
          size={size ?? "md"}
          title={`A ${size ?? "md"} dialog`}
          description="The panel width follows the size prop."
          footer={<Button onClick={() => setSize(null)}>Done</Button>}
        >
          Reuses the .mx-modal surface at the dialog widths (420 / 496 / 640).
        </Dialog>
      </div>
    );
  },
};

// INV-A11Y §8 — proves ALL THREE: role + aria-modal present, Tab from the last
// focusable wraps to the first, AND focus returns to the trigger on close.
export const A11yTrap: Story = {
  name: "a11y — focus trap",
  render: () => {
    const [open, setOpen] = useState(false);
    return (
      <>
        <Button onClick={() => setOpen(true)}>Open dialog</Button>
        <Dialog
          open={open}
          onClose={() => setOpen(false)}
          title="Confirm changes"
          description="Focus is trapped inside while open."
          footer={
            <>
              <Button variant="secondary" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button onClick={() => setOpen(false)}>Save</Button>
            </>
          }
        >
          Tab from the last control wraps back to the first.
        </Dialog>
      </>
    );
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    // Open from a real trigger so the trigger is the focus origin (focus starts on it).
    const trigger = canvas.getByRole("button", { name: "Open dialog" });
    await userEvent.click(trigger);

    const dialog = await body.findByRole("dialog");
    await expect(dialog).toHaveAttribute("aria-modal", "true");

    // (1) The trap WRAPS — focusable order is [Close, Cancel, Save]; from the last, Tab wraps to the first.
    const close = within(dialog).getByRole("button", { name: "Close" });
    const save = within(dialog).getByRole("button", { name: "Save" });
    save.focus();
    await expect(save).toHaveFocus();
    await userEvent.tab();
    await expect(close).toHaveFocus();

    // (2) Focus RETURNS to the trigger on close — Escape dismisses (useDismiss),
    // useFocusTrap restores previouslyFocused (the trigger). waitFor: focus can
    // settle a tick after the unmount.
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(trigger).toHaveFocus());
  },
};
