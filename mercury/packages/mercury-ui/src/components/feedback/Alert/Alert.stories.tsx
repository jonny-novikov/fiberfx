import type { Meta, StoryObj } from "@storybook/react-vite";
import { Alert, Button } from "@mercury/ui";
import type { AlertTone } from "@mercury/ui";

// The tone language, traced from Alert.tsx (the AlertTone union) and restated in
// Alert.prompt.md — NO-INVENT (mx.4.md INV-5). An invented member is a compile error.
const TONES: AlertTone[] = ["info", "success", "warning", "danger"];

// Controls restate Alert.prompt.md: `tone` (four-value select), `title`/`children`
// (the heading + message body, text slots), `dismissible` (boolean → the × button).
// `actions` is a ReactNode slot, NOT a raw control — driven by a story arg rendering
// real <Button/>s (the Button exemplar). `onDismiss` is a callback, not a control.
const meta: Meta<typeof Alert> = {
  title: "Feedback/Alert",
  component: Alert,
  argTypes: {
    tone: { control: "select", options: TONES },
    title: { control: "text" },
    children: { control: "text" },
    dismissible: { control: "boolean" },
    actions: { control: false },
    onDismiss: { control: false },
  },
  args: {
    tone: "info",
    title: "Scheduled maintenance",
    children: "The API will be briefly unavailable at 02:00 UTC for a planned upgrade.",
    dismissible: false,
  },
};
export default meta;

type Story = StoryObj<typeof Alert>;

export const Playground: Story = {};

// Every tone with a title + body — the four status families proven whole.
export const Tones: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      <Alert tone="info" title="Scheduled maintenance">
        The API will be briefly unavailable at 02:00 UTC for a planned upgrade.
      </Alert>
      <Alert tone="success" title="Payment received">
        Your payment of $42.00 was processed successfully.
      </Alert>
      <Alert tone="warning" title="API key rotating soon">
        The current key expires in 3 days — generate a replacement before then.
      </Alert>
      <Alert tone="danger" title="Deploy failed">
        Build #4821 failed on step "test:e2e". Check logs for the stack trace.
      </Alert>
    </div>
  ),
};

// The actions slot — a real <Button/> row per Alert.prompt.md (`actions` is a
// ReactNode slot). The danger tone here mirrors the derived warning the economy
// MarginTable renders beneath its Table.
// codemojex-node/apps/economy/src/components/MarginTable.tsx
export const WithActions: Story = {
  args: {
    tone: "danger",
    title: "Pool liability exceeds net revenue",
    children: "The pool owed outruns net revenue on at least one channel.",
    dismissible: true,
    actions: (
      <>
        <Button variant="destructive" size="sm">
          Review channels
        </Button>
        <Button variant="ghost" size="sm">
          Dismiss
        </Button>
      </>
    ),
  },
};
