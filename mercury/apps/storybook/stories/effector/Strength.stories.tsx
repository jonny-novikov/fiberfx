import type { Meta, StoryObj } from "@storybook/react-vite";
import { createEvent, createStore } from "effector";
import type { EventCallable, Store } from "effector";
import { useUnit } from "effector-react";
import { passwordStrength } from "@mercury/effector";
import { Input, PasswordStrength, Checklist } from "@mercury/ui";

// "Effector/Strength" — passwordStrength (a PURE scorer) over a live Effector
// field, feeding the PasswordStrength meter + a Checklist of rules. NO-INVENT:
// passwordStrength traced from packages/mercury-effector/src/strength.ts
// (→ { score, label, variant, rules:{length,mixedCase,number,symbol} });
// because it has NO store, the story supplies the effector state (an inline
// createStore<string> + createEvent<string>, mx.5 Arm-C note). PasswordStrength
// props traced from PasswordStrength.tsx (score/label/variant — its
// StrengthVariant is the identical "negative"|"caution"|"positive" union, so
// s.variant types straight in); Checklist props from Checklist.tsx
// (items: { label, met }[]); Input from Input.tsx (type/value/onChange DOM
// event). Stores live at module scope. Cross-component story — no `component:`.

const $pwd = createStore<string>("");
const setPwd = createEvent<string>();
$pwd.on(setPwd, (_, v) => v);

const $strong = createStore<string>("Sup3r-Secret!");
const setStrong = createEvent<string>();
$strong.on(setStrong, (_, v) => v);

const meta: Meta = {
  title: "Effector/Strength",
};
export default meta;

type Story = StoryObj;

function StrengthPanel({ store, set }: { store: Store<string>; set: EventCallable<string> }) {
  const pwd = useUnit(store);
  const s = passwordStrength(pwd);
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "320px" }}>
      <Input
        label="Password"
        type="password"
        value={pwd}
        onChange={(e) => set(e.target.value)}
      />
      <PasswordStrength score={s.score} label={s.label} variant={s.variant} />
      <Checklist
        items={[
          { label: "8+ characters", met: s.rules.length },
          { label: "Upper & lower case", met: s.rules.mixedCase },
          { label: "A number", met: s.rules.number },
          { label: "A symbol", met: s.rules.symbol },
        ]}
      />
    </div>
  );
}

export const Playground: Story = {
  render: () => <StrengthPanel store={$pwd} set={setPwd} />,
};

// A pre-filled strong value — the meter reads "positive" and every rule is met.
export const Strong: Story = {
  render: () => <StrengthPanel store={$strong} set={setStrong} />,
};
