import type { ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useTheme, toggleTheme, setTheme } from "@mercury/effector";
import { Switch, Button, Alert } from "@mercury/ui";

// "Effector/Theme" — the theme adapter plugged into presentational components.
// NO-INVENT: symbols traced from packages/mercury-effector/src/theme.ts
// (useTheme/toggleTheme/setTheme — initTheme is deliberately NOT imported,
// mx.5 Arm A: no global <html>/localStorage mutation). Props traced from
// Switch.tsx (checked/onChange/label), Button.tsx (variant/onClick),
// Alert.tsx (tone/title). A cross-component story, like Tokens — no `component:`.

const meta: Meta = {
  title: "Effector/Theme",
};
export default meta;

type Story = StoryObj;

// The local theme surface (mx.5 Arm A): the story applies `${theme}-theme` to its
// OWN in-render wrapper from useTheme() — never initTheme() — so the token flip is
// visible without leaking onto document.documentElement or into the 41 other stories.
function ThemedCard({ children }: { children: ReactNode }) {
  const theme = useTheme();
  return (
    <div
      className={`${theme}-theme`}
      style={{
        display: "flex",
        flexDirection: "column",
        gap: "16px",
        padding: "24px",
        maxWidth: "420px",
        borderRadius: "var(--radius-12)",
        background: "rgb(var(--bg-primary))",
        border: "1px solid rgb(var(--border-primary))",
      }}
    >
      {children}
      <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
        <Button variant="primary">Primary</Button>
        <Button variant="secondary">Secondary</Button>
      </div>
      <Alert tone="info" title="Live token flip">
        These tokens are driven by the Effector theme store; the story never calls
        initTheme(), so no document or localStorage state leaks to other stories.
      </Alert>
    </div>
  );
}

// The Switch reflects the live store (checked === dark) and writes it back via the
// value-based onChange (Switch.onChange is already value-based).
function ToggleControl() {
  const theme = useTheme();
  return (
    <Switch checked={theme === "dark"} onChange={() => toggleTheme()} label="Dark theme" />
  );
}

// The explicit setter pair — setTheme("light"|"dark"), a valid Theme literal each.
function SetThemeControl() {
  return (
    <div style={{ display: "flex", gap: "8px" }}>
      <Button variant="outline" onClick={() => setTheme("light")}>
        Light
      </Button>
      <Button variant="outline" onClick={() => setTheme("dark")}>
        Dark
      </Button>
    </div>
  );
}

export const Playground: Story = {
  render: () => (
    <ThemedCard>
      <ToggleControl />
    </ThemedCard>
  ),
};

export const ExplicitButtons: Story = {
  render: () => (
    <ThemedCard>
      <SetThemeControl />
    </ThemedCard>
  ),
};
