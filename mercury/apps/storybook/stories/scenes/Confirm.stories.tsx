import type { CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Badge, Button, Card, Divider, Heading, Icon, IconButton, Link, Text } from "@mercury/ui";

// Scenes/Confirm — a confirmation / action-sheet where the ACTIONS lead: an icon-only
// IconButton header toolbar (copy · cog · close — the natural icon-only usage, each with a
// required accessible label), a Heading + a summary Text of what is being confirmed
// (presentational, NO inputs — inputs are a later slice), a footer Button action bar exercising
// the full variant spread (primary "Confirm & send" · outline "Cancel" · ghost "Save as draft" ·
// destructive "Cancel transfer"), and Link affordances. Grounded in the real screens
// apps/mobile/src/screens/Send.tsx:56-63 (the outline "Cancel" + primary "Send $X" footer action
// bar, the primary carrying style={{ flex: 1 }}) + apps/mobile/src/screens/Home.tsx:33 (the inline
// "See all" <a onClick> → Link). Presentational; imports ONLY @mercury/ui. NO-INVENT: every
// IconButton `icon` (copy · cog · close) and every Icon `name` (check) is a real ICONS key; every
// prop is composed per each component's .tsx surface; layout styles resolve through
// rgb(var(--token)) + var(--space-*) — no raw hex, so the scene re-skins under the inherited
// mx.8.1 Palette/Roundings globals.

const meta: Meta = { title: "Scenes/Confirm" };
export default meta;

type Story = StoryObj;

// The sheet column — a centred action-sheet, sections separated by the spacing ramp.
const sheet: CSSProperties = {
  maxWidth: 420,
  margin: "0 auto",
  display: "flex",
  flexDirection: "column",
  gap: "var(--space-20)",
};
// The header: the title on the left, the icon-only toolbar on the right.
const headerRow: CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  gap: "var(--space-12)",
};
const toolbar: CSSProperties = { display: "flex", alignItems: "center", gap: "var(--space-4)" };
// The summary Card body — stacked rows.
const cardBody: CSSProperties = { display: "flex", flexDirection: "column", gap: "var(--space-12)" };
const amountRow: CSSProperties = {
  display: "flex",
  alignItems: "baseline",
  justifyContent: "space-between",
  gap: "var(--space-8)",
};
const lineRow: CSSProperties = { display: "flex", justifyContent: "space-between", alignItems: "center" };
// The footer action bar — the primary decision, then the secondary split, then a set-apart abort.
const actionBar: CSSProperties = { display: "flex", flexDirection: "column", gap: "var(--space-8)" };
const splitRow: CSSProperties = { display: "flex", gap: "var(--space-8)" };
const flex1: CSSProperties = { flex: 1 };

export const Confirm: Story = {
  render: () => (
    <div style={sheet}>
      {/* Header — the actions lead the chrome: the title + an icon-only IconButton toolbar. */}
      <header style={headerRow}>
        <Heading size={4}>Confirm transfer</Heading>
        <div style={toolbar}>
          <IconButton icon="copy" label="Copy transfer details" variant="ghost" size="sm" />
          <IconButton icon="cog" label="Transfer settings" variant="ghost" size="sm" />
          <IconButton icon="close" label="Close" variant="ghost" size="sm" />
        </div>
      </header>

      {/* The summary — presentational, no inputs: what is being confirmed. */}
      <Card variant="raised">
        <div style={cardBody}>
          <div style={amountRow}>
            <Text variant="lead">$420.00</Text>
            <Badge variant="info">Instant</Badge>
          </div>
          <Text variant="muted">To Ana Ruiz · Checking ····4821</Text>
          <Divider />
          <div style={lineRow}>
            <Text variant="small">Transfer fee</Text>
            <Text variant="small">$0.00</Text>
          </div>
          <div style={lineRow}>
            <Text variant="small">Arrives</Text>
            <Text variant="small">In seconds</Text>
          </div>
        </div>
      </Card>

      {/* The footer action bar — the variant spread; the action bar IS the screen (Send.tsx:56-63). */}
      <div style={actionBar}>
        <Button variant="primary" size="lg" fullWidth leading={<Icon name="check" size={16} />}>
          Confirm &amp; send
        </Button>
        <div style={splitRow}>
          <Button variant="outline" size="lg" style={flex1}>
            Cancel
          </Button>
          <Button variant="ghost" size="lg" style={flex1}>
            Save as draft
          </Button>
        </div>
        <Divider />
        <Button variant="destructive" size="lg" fullWidth>
          Cancel transfer
        </Button>
      </div>

      {/* Link affordances — the inline in-flow anchors (Home.tsx:33 "See all" → Link). */}
      <div style={lineRow}>
        <Link href="#">Change recipient</Link>
        <Link href="#" muted>
          How fees work
        </Link>
      </div>
    </div>
  ),
};
