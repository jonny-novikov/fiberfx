import { useEffect } from "react";
import {
  createDisclosure,
  popOverlay,
  pushOverlay,
} from "@mercury/effector";
import {
  AlertDialog,
  Button,
  Card,
  Dialog,
  Heading,
  Popover,
  Text,
} from "@mercury/ui";

// The overlay demo — the showcase foundation's first live content (mx.7.4 §F.2),
// driven by the §E disclosure bridge. The pattern mirrors the shipped story
// apps/storybook/stories/effector/Overlay.stories.tsx: one createDisclosure()
// per overlay at module scope (shared + stable), read via useOpen() inside the
// render component. A MODAL overlay (Dialog · AlertDialog) registers with the
// global overlay-stack while open so the singleton locks body scroll; a
// non-modal Popover deliberately does NOT register.

const invite = createDisclosure();
const confirmRemove = createDisclosure();
const menu = createDisclosure();

// A modal consumer pushes onto the overlay stack while open and pops on close;
// the singleton (started by initOverlayLock in main.tsx) locks body scroll for
// as long as the stack is non-empty (LIFO — the last to close releases it).
function useOverlayRegistration(id: string, open: boolean): void {
  useEffect(() => {
    if (!open) return;
    pushOverlay(id);
    return () => {
      popOverlay(id);
    };
  }, [id, open]);
}

export function Overlays() {
  const inviteOpen = invite.useOpen();
  const removeOpen = confirmRemove.useOpen();
  const menuOpen = menu.useOpen();

  useOverlayRegistration("invite", inviteOpen);
  useOverlayRegistration("confirm-remove", removeOpen);

  return (
    <>
      <Text className="sc-eyebrow">Components · overlay</Text>
      <Heading size={9} className="sc-title">
        Overlays
      </Heading>
      <Text variant="lead" className="sc-lede">
        Dialog, AlertDialog, and Popover — mounted here through the{" "}
        <code>@mercury/effector</code> disclosure bridge. Opening a modal pushes onto a global
        overlay stack that locks body scroll; open the destructive confirm on top of the invite
        dialog to grow the stack to two — the lock holds until both have closed. The Popover is
        non-modal, so it never locks.
      </Text>

      <Card variant="raised" className="sc-demo">
        <div className="sc-demo-row">
          <Button leading={<span aria-hidden>+</span>} onClick={() => invite.open()}>
            Invite teammate
          </Button>

          <Popover
            trigger="Actions"
            open={menuOpen}
            onOpenChange={(o) => (o ? menu.open() : menu.close())}
            placement="bottom-start"
          >
            <div className="sc-menu">
              <button type="button" className="sc-menu-item" onClick={() => menu.close()}>
                Rename project
              </button>
              <button type="button" className="sc-menu-item" onClick={() => menu.close()}>
                Duplicate
              </button>
              <button
                type="button"
                className="sc-menu-item is-danger"
                onClick={() => {
                  menu.close();
                  confirmRemove.open();
                }}
              >
                Delete project
              </button>
            </div>
          </Popover>
        </div>
        <Text variant="small">
          A non-modal Popover menu and a modal Dialog, both driven by their own disclosure model.
        </Text>
      </Card>

      {/* Modal — registers with the stack + locks scroll while open. */}
      <Dialog
        open={inviteOpen}
        onClose={() => invite.close()}
        title="Invite teammate"
        description="Send an invitation to collaborate on this project."
        footer={
          <>
            <Button variant="secondary" onClick={() => invite.close()}>
              Cancel
            </Button>
            <Button onClick={() => invite.close()}>Send invite</Button>
          </>
        }
      >
        <Text>
          They will get access to the showcase and every composed component. Removing access opens a
          second modal on top — proof the stack lock is LIFO.
        </Text>
        <div className="sc-demo-row" style={{ marginTop: "16px" }}>
          <Button variant="destructive" onClick={() => confirmRemove.open()}>
            Remove access
          </Button>
        </div>
      </Dialog>

      {/* Modal — the destructive confirm, stacked on top of the invite dialog. */}
      <AlertDialog
        open={removeOpen}
        title="Remove access?"
        description="This revokes the teammate's access immediately. This action cannot be undone."
        destructive
        confirmLabel="Remove access"
        cancelLabel="Keep access"
        onConfirm={() => confirmRemove.close()}
        onCancel={() => confirmRemove.close()}
      />
    </>
  );
}
