import { useEffect } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { createDisclosure, initOverlayLock, popOverlay, pushOverlay } from "@mercury/effector";
import { Button, Dialog, Popover } from "@mercury/ui";

// "Effector/Overlay" — the mx.7.4 §E disclosure bridge driving REAL @mercury/ui
// overlays from the OUTSIDE. INV-EFFECTOR: the overlays stay presentational and
// @mercury/ui never imports @mercury/effector; the bridge produces their
// controlled state + a global scroll-lock. NO-INVENT: createDisclosure →
// { $open, open, close, toggle, useOpen } and the singleton pushOverlay/
// popOverlay/initOverlayLock traced from packages/mercury-effector/src/
// disclosure.ts. Dialog props (open/onClose/title/description/footer) traced
// from Dialog.tsx; Popover props (trigger/open/onOpenChange/children) from
// Popover.tsx; Button from Button.tsx. Models live at module scope (shared,
// stable — the mx.5 pattern); the read hooks run inside the render component.
// initOverlayLock() is the idempotent singleton starter (the initTheme idiom).

const dialogA = createDisclosure();
const dialogB = createDisclosure();
const info = createDisclosure();

initOverlayLock();

// A MODAL consumer registers with the global overlay-stack while open, so the
// singleton locks body scroll (padding-compensated); the cleanup pops on close.
// A non-modal Popover deliberately does NOT register — it must not lock scroll.
function useOverlayRegistration(id: string, open: boolean): void {
  useEffect(() => {
    if (!open) return;
    pushOverlay(id);
    return () => {
      popOverlay(id);
    };
  }, [id, open]);
}

function OverlayPanel() {
  const aOpen = dialogA.useOpen();
  const bOpen = dialogB.useOpen();
  const infoOpen = info.useOpen();

  useOverlayRegistration("dialog-a", aOpen);
  useOverlayRegistration("dialog-b", bOpen);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "360px" }}>
      <div style={{ display: "flex", gap: "8px", flexWrap: "wrap", alignItems: "center" }}>
        <Button onClick={() => dialogA.open()}>Open dialog A</Button>
        <Button variant="secondary" onClick={() => dialogB.open()}>
          Open dialog B
        </Button>
        <Popover
          trigger="Popover (no lock)"
          open={infoOpen}
          onOpenChange={(o) => (o ? info.open() : info.close())}
        >
          <p style={{ margin: 0, maxWidth: "220px" }}>
            A non-modal panel — it does not register with the overlay stack, so body
            scroll is never locked.
          </p>
        </Popover>
      </div>

      <Dialog
        open={aOpen}
        onClose={() => dialogA.close()}
        title="Dialog A"
        description="Opening this modal pushes onto the overlay stack and locks body scroll."
        footer={<Button onClick={() => dialogA.close()}>Done</Button>}
      >
        <p style={{ margin: 0 }}>
          Open dialog B on top to grow the stack to two — the lock holds until both
          have closed.
        </p>
      </Dialog>

      <Dialog
        open={bOpen}
        onClose={() => dialogB.close()}
        title="Dialog B"
        description="A second modal — the stack is LIFO, so closing one leaves the lock held by the other."
        footer={<Button onClick={() => dialogB.close()}>Done</Button>}
      >
        <p style={{ margin: 0 }}>Both dialogs share one global scroll-lock singleton.</p>
      </Dialog>
    </div>
  );
}

const meta: Meta = {
  title: "Effector/Overlay",
};
export default meta;

type Story = StoryObj;

export const OverlayPlayground: Story = {
  render: () => <OverlayPanel />,
};
