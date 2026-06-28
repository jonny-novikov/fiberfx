import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Modal, Button } from "@mercury/ui";
import type { ModalProps } from "@mercury/ui";

// The size ramp, derived from ModalProps. Modal.tsx types `size` inline as
// "sm" | "md" | "lg" and exports NO named `ModalSize` union (unlike Button's
// ButtonSize). Deriving the array from the exported ModalProps keeps the
// compile-time NO-INVENT guard (mx.4.md INV-5): an invented member fails tsc.
const SIZES: NonNullable<ModalProps["size"]>[] = ["sm", "md", "lg"];

// Controls restate Modal.prompt.md: `open` (boolean — mounts/unmounts the
// dialog), `size` (the sm|md|lg max-width ramp), `title` (header text; when set
// renders the head bar + close ×). `footer` and `onClose` are NOT raw controls
// — `footer` is an action row driven per story by real <Button/>s (the Button-
// exemplar slot rule), `onClose` is the dismissal callback.
const meta: Meta<typeof Modal> = {
  title: "Overlay/Modal",
  component: Modal,
  argTypes: {
    open: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
    title: { control: "text" },
    footer: { control: false },
    onClose: { control: false },
  },
  args: {
    open: true,
    size: "md",
    title: "Invite teammates",
    children: "Add people to this workspace by email.",
  },
};
export default meta;

type Story = StoryObj<typeof Modal>;

export const Playground: Story = {};

// The showcase invite/confirm flow — a trigger Button toggles `open`, the
// footer carries real <Button/> actions, and dismissal is via the backdrop,
// Escape, or the close ×. size="sm" for a tight destructive confirm.
// showcase/src/chrome/Shell.tsx (InviteModal / DangerModal)
export const Confirm: Story = {
  render: () => {
    const [open, setOpen] = useState(false);
    return (
      <>
        <Button variant="destructive" onClick={() => setOpen(true)}>
          Delete project
        </Button>
        <Modal
          open={open}
          onClose={() => setOpen(false)}
          size="sm"
          title="Delete project?"
          footer={
            <>
              <Button variant="secondary" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button variant="destructive" onClick={() => setOpen(false)}>
                Delete permanently
              </Button>
            </>
          }
        >
          This will permanently delete <strong>Mercury Marketing</strong> and all of its data.
        </Modal>
      </>
    );
  },
};

// The max-width ramp — one trigger per size (sm 400px · md base · lg 720px),
// each opening the dialog at that width. Iterates the SIZES union so an
// invented size is a compile error.
export const Sizes: Story = {
  render: () => {
    const [openSize, setOpenSize] = useState<NonNullable<ModalProps["size"]> | null>(null);
    return (
      <div style={{ display: "flex", gap: "12px" }}>
        {SIZES.map((size) => (
          <Button key={size} variant="secondary" onClick={() => setOpenSize(size)}>
            Open {size}
          </Button>
        ))}
        <Modal
          open={openSize !== null}
          onClose={() => setOpenSize(null)}
          size={openSize ?? "md"}
          title={`Size = ${openSize ?? "md"}`}
        >
          This dialog renders at the <strong>{openSize ?? "md"}</strong> max-width.
        </Modal>
      </div>
    );
  },
};
