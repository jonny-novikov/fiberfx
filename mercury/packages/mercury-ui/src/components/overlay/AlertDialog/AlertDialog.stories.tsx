import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { AlertDialog, Button } from "@mercury/ui";

// Controls restate AlertDialog.prompt.md: `open` (mounts/portals), `title`/
// `description` (the header slots), `confirmLabel`/`cancelLabel` (the action
// labels), `destructive` (the confirm-action variant switch). `onConfirm`/
// `onCancel` are the dismissal callbacks, driven per story.
const meta: Meta<typeof AlertDialog> = {
  title: "Overlay/AlertDialog",
  component: AlertDialog,
  argTypes: {
    open: { control: "boolean" },
    title: { control: "text" },
    description: { control: "text" },
    confirmLabel: { control: "text" },
    cancelLabel: { control: "text" },
    destructive: { control: "boolean" },
    onConfirm: { control: false },
    onCancel: { control: false },
  },
  args: {
    open: true,
    title: "Delete project?",
    description: "This permanently deletes the project and all of its data.",
    confirmLabel: "Delete permanently",
    cancelLabel: "Cancel",
    destructive: true,
  },
};
export default meta;

type Story = StoryObj<typeof AlertDialog>;

export const Playground: Story = {};

// The two confirm intents — neutral (primary confirm) vs destructive.
export const Intents: Story = {
  render: () => {
    const [intent, setIntent] = useState<"neutral" | "destructive" | null>(null);
    return (
      <div style={{ display: "flex", gap: "12px" }}>
        <Button variant="secondary" onClick={() => setIntent("neutral")}>
          Sign out
        </Button>
        <Button variant="destructive" onClick={() => setIntent("destructive")}>
          Delete
        </Button>
        <AlertDialog
          open={intent !== null}
          title={intent === "destructive" ? "Delete project?" : "Sign out?"}
          description={
            intent === "destructive"
              ? "This cannot be undone."
              : "You can sign back in at any time."
          }
          confirmLabel={intent === "destructive" ? "Delete" : "Sign out"}
          destructive={intent === "destructive"}
          onConfirm={() => setIntent(null)}
          onCancel={() => setIntent(null)}
        />
      </div>
    );
  },
};

// INV-A11Y — proves the deliberate dismissal contract: a backdrop press does
// NOT dismiss, while Escape does.
export const A11yDismiss: Story = {
  name: "a11y — dismiss contract",
  render: () => {
    const [open, setOpen] = useState(false);
    return (
      <>
        <Button variant="destructive" onClick={() => setOpen(true)}>
          Delete project
        </Button>
        <AlertDialog
          open={open}
          title="Delete project?"
          description="A backdrop press will not dismiss this — only Escape or an action."
          confirmLabel="Delete"
          destructive
          onConfirm={() => setOpen(false)}
          onCancel={() => setOpen(false)}
        />
      </>
    );
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByRole("button", { name: "Delete project" }));

    const alert = await body.findByRole("alertdialog");
    await expect(alert).toHaveAttribute("aria-modal", "true");

    // Initial focus lands on the confirm action (AlertDialog passes initialFocus: confirmRef).
    const confirm = within(alert).getByRole("button", { name: "Delete" });
    await waitFor(() => expect(confirm).toHaveFocus());

    // A backdrop press does NOT dismiss (outsideClick: false).
    const backdrop = alert.parentElement as HTMLElement;
    await userEvent.click(backdrop);
    await expect(body.queryByRole("alertdialog")).not.toBeNull();

    // Escape DOES dismiss (→ onCancel).
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(body.queryByRole("alertdialog")).toBeNull());
  },
};
