import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { createCooldown } from "@mercury/effector";
import { Button, AuthCode } from "@mercury/ui";

// "Effector/Cooldown" — the createCooldown countdown gating a resend Button,
// beside an AuthCode it would gate. NO-INVENT: symbols traced from
// packages/mercury-effector/src/cooldown.ts (createCooldown → { $remaining,
// start(seconds), stop(), useCooldown() }). Button props traced from Button.tsx
// (variant/disabled/onClick); AuthCode props from AuthCode.tsx (value/onChange
// value-based, length, allow "numeric"|"alphanumeric"). Models live at module
// scope (shared, stable); the hook is read inside the render component. A
// cross-component story — no `component:`.

const cooldown = createCooldown();
const quick = createCooldown();

const meta: Meta = {
  title: "Effector/Cooldown",
};
export default meta;

type Story = StoryObj;

function CooldownPanel({
  model,
  seconds,
}: {
  model: ReturnType<typeof createCooldown>;
  seconds: number;
}) {
  const remaining = model.useCooldown();
  // The AuthCode value is local presentational context; the cooldown is the demo.
  const [code, setCode] = useState("");
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "320px" }}>
      <AuthCode value={code} onChange={setCode} length={6} allow="numeric" />
      <Button
        variant="secondary"
        disabled={remaining > 0}
        onClick={() => model.start(seconds)}
      >
        {remaining > 0 ? `Resend in ${remaining}s` : "Resend code"}
      </Button>
    </div>
  );
}

export const Playground: Story = {
  render: () => <CooldownPanel model={cooldown} seconds={30} />,
};

// A short cooldown so the decrement-to-zero re-enable is quick to watch.
export const ShortCooldown: Story = {
  render: () => <CooldownPanel model={quick} seconds={5} />,
};
