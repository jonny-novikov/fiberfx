import { useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { useUnit } from "effector-react";
import { Button, Checkbox, Input, Modal } from "@mercury/ui";
import { Toaster, toast } from "@mercury/effector";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import { $dangerOpen, $inviteOpen, closeDanger, closeInvite, tick, useRoute } from "../store";

/*
 * Shell — the application frame: sidebar + topbar + scrolling page area,
 * plus the two app-level modals (wired to Effector stores) and the Toaster.
 * It also owns the global side effects: the live-progress ticker and the
 * scroll-to-top on navigation.
 */
export function Shell({ children }: { children: ReactNode }) {
  const route = useRoute();
  const scrollRef = useRef<HTMLDivElement>(null);

  // Live progress ticker — drives the Progress page demo via the Effector store.
  useEffect(() => {
    const id = setInterval(() => tick(), 1100);
    return () => clearInterval(id);
  }, []);

  // Reset scroll on every navigation.
  useEffect(() => {
    scrollRef.current?.scrollTo({ top: 0 });
  }, [route]);

  return (
    <div className="app">
      <Sidebar />
      <div className="main">
        <Topbar />
        <div className="scroll" ref={scrollRef}>
          {children}
        </div>
      </div>

      <InviteModal />
      <DangerModal />
      <Toaster position="bottom-end" />
    </div>
  );
}

function InviteModal() {
  const open = useUnit($inviteOpen);
  const [emails, setEmails] = useState("");
  const [note, setNote] = useState(false);
  return (
    <Modal
      open={open}
      onClose={closeInvite}
      title="Invite teammates"
      footer={
        <>
          <Button variant="secondary" onClick={() => closeInvite()}>
            Cancel
          </Button>
          <Button
            onClick={() => {
              closeInvite();
              toast.success("Invite sent");
            }}
          >
            Send invite
          </Button>
        </>
      }
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <p style={{ margin: 0 }}>Add people to your workspace. Separate multiple emails with commas.</p>
        <Input
          label="Emails"
          placeholder="ada@example.com, grace@example.com"
          value={emails}
          onChange={(e) => setEmails(e.target.value)}
        />
        <Checkbox checked={note} onChange={setNote} label="Send a personal note with the invite" />
      </div>
    </Modal>
  );
}

function DangerModal() {
  const open = useUnit($dangerOpen);
  return (
    <Modal
      open={open}
      onClose={closeDanger}
      size="sm"
      title="Delete project?"
      footer={
        <>
          <Button variant="secondary" onClick={() => closeDanger()}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            onClick={() => {
              closeDanger();
              toast.error("Project deleted");
            }}
          >
            Delete permanently
          </Button>
        </>
      }
    >
      This will permanently delete{" "}
      <strong style={{ color: "rgb(var(--fg-primary))" }}>Mercury Marketing</strong> and all of its data. This action
      can’t be undone.
    </Modal>
  );
}
