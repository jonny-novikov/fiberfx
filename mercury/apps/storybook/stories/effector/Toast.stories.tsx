import type { Meta, StoryObj } from "@storybook/react-vite";
import { toast, clearToasts, Toaster } from "@mercury/effector";
import { Button } from "@mercury/ui";

// "Effector/Toast" — the toast model + <Toaster/> plugged into Buttons.
// NO-INVENT: symbols traced from packages/mercury-effector/src/toast.tsx
// (toast.{success,error,warning,info} · clearToasts · Toaster, position union
// "top-end"|"bottom-end"|"bottom-center"; toast.error maps to the "danger"
// Alert tone). Button props traced from Button.tsx (variant/onClick). The
// <Toaster/> renders live toasts as Mercury <Alert/>s and auto-dismisses them
// (the adapter's autoDismissFx). A cross-component story — no `component:`.

const meta: Meta = {
  title: "Effector/Toast",
};
export default meta;

type Story = StoryObj;

// The trigger row — fires the imperative helpers. onClick is void-compatible
// (the helper's return value is discarded).
function Triggers() {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
      <Button variant="primary" onClick={() => toast.success("Saved your changes")}>
        Success
      </Button>
      <Button variant="destructive" onClick={() => toast.error("Something broke")}>
        Error
      </Button>
      <Button variant="secondary" onClick={() => toast.warning("Heads up — check this")}>
        Warning
      </Button>
      <Button variant="secondary" onClick={() => toast.info("Just so you know")}>
        Info
      </Button>
      <Button variant="ghost" onClick={() => clearToasts()}>
        Clear all
      </Button>
    </div>
  );
}

export const Playground: Story = {
  render: () => (
    <>
      <Triggers />
      <Toaster position="bottom-end" />
    </>
  ),
};

// The same triggers with the toaster anchored top-end — the position union.
export const TopEnd: Story = {
  render: () => (
    <>
      <Triggers />
      <Toaster position="top-end" />
    </>
  ),
};
