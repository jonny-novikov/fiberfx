import type { CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Avatar, Badge, Button, Card, Heading, Icon, ListRow, Separator, Text } from "@mercury/ui";

// Scenes/Profile — an account screen where the FOUNDATIONS lead: the name Heading, the
// "Member since 2023" Text, the Separator section rules, and the inline Icon affordances carry
// the layout; Avatar / Card / ListRow / Badge / Button add realism. Grounded in the real screen
// apps/mobile/src/screens/Profile.tsx + the ProfileScreen recreation in
// packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx (avatar + name + "Verified ·
// Member since 2023", a Card of icon rows shield/credit-card/bell/globe/help-circle, a ghost
// negative-tinted Sign out). Presentational; imports ONLY @mercury/ui. NO-INVENT: every Icon
// name (user · shield · credit-card · bell · globe · help-circle · chevron-right) is a real ICONS
// key, and each component is composed per its .tsx surface.

const meta: Meta = { title: "Scenes/Profile" };
export default meta;

type Story = StoryObj;

// A small uppercase section eyebrow — the Text primitive carrying the group label.
const eyebrow: CSSProperties = {
  color: "rgb(var(--fg-tertiary))",
  textTransform: "uppercase",
  letterSpacing: "0.08em",
};
// The muted trailing chevron ink — Icon reads currentColor, so a `color` sets its stroke.
const chevron: CSSProperties = { color: "rgb(var(--fg-tertiary))" };

export const Profile: Story = {
  render: () => (
    <div
      style={{
        maxWidth: 420,
        margin: "0 auto",
        display: "flex",
        flexDirection: "column",
        gap: "var(--space-24)",
      }}
    >
      {/* Header — the foundations lead: Avatar, the name Heading, a muted Text meta line, Badges. */}
      <header
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: "var(--space-12)",
          textAlign: "center",
        }}
      >
        <Avatar name="Sam Reyes" size={88} status="positive" />
        <div style={{ display: "flex", flexDirection: "column", gap: "var(--space-4)" }}>
          <Heading size={6} align="center">
            Sam Reyes
          </Heading>
          <Text variant="muted">@samreyes · Member since 2023</Text>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-8)" }}>
          <Badge variant="positive">
            <span style={{ display: "inline-flex", alignItems: "center", gap: "var(--space-4)" }}>
              <Icon name="shield" size={12} />
              Verified
            </span>
          </Badge>
          <Badge variant="brand">Pro</Badge>
        </div>
      </header>

      <Separator />

      {/* Account — a Card of ListRows, each led by a real Icon glyph. */}
      <section style={{ display: "flex", flexDirection: "column", gap: "var(--space-8)" }}>
        <Text variant="small" style={eyebrow}>
          Account
        </Text>
        <Card variant="raised" padding={0}>
          <ListRow
            leading={<Icon name="shield" size={18} />}
            label="Security"
            description="2FA · Face ID"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
          <ListRow
            leading={<Icon name="credit-card" size={18} />}
            label="Payment methods"
            value="3"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
          <ListRow
            leading={<Icon name="bell" size={18} />}
            label="Notifications"
            value="On"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
        </Card>
      </section>

      {/* Preferences — a second grouped Card. */}
      <section style={{ display: "flex", flexDirection: "column", gap: "var(--space-8)" }}>
        <Text variant="small" style={eyebrow}>
          Preferences
        </Text>
        <Card variant="raised" padding={0}>
          <ListRow
            leading={<Icon name="user" size={18} />}
            label="Personal details"
            description="Name, email, phone"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
          <ListRow
            leading={<Icon name="globe" size={18} />}
            label="Language"
            value="English"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
          <ListRow
            leading={<Icon name="help-circle" size={18} />}
            label="Help & support"
            trailing={<Icon name="chevron-right" size={16} style={chevron} />}
          />
        </Card>
      </section>

      <Separator />

      {/* A ghost, negative-tinted Sign out — mirrors the real screen's destructive affordance. */}
      <Button variant="ghost" size="lg" fullWidth style={{ color: "rgb(var(--fg-negative))" }}>
        Sign out
      </Button>
    </div>
  ),
};
