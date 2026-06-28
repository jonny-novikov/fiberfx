import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { AuthCode } from "@mercury/ui";
import type { AuthCodeProps } from "@mercury/ui";

// AuthCode's `allow` is a BEHAVIORAL enum ("numeric" | "alphanumeric") declared
// inline in AuthCodeProps — there is NO exported named union — so the option array
// is typed via the indexed access `NonNullable<AuthCodeProps["allow"]>[]`, still a
// compile-time NO-INVENT guard (an invented member fails tsc). The controls restate
// AuthCode.prompt.md's Props table: length (number), allow (inline-radio), error
// (text), disabled (boolean); value/onChange/onComplete are the controlled string
// contract (control:false). mx.4.md INV-5.
const ALLOW: NonNullable<AuthCodeProps["allow"]>[] = ["numeric", "alphanumeric"];

const meta: Meta<typeof AuthCode> = {
  title: "Inputs/AuthCode",
  component: AuthCode,
  argTypes: {
    length: { control: { type: "number", min: 4, max: 8, step: 1 } },
    allow: { control: "inline-radio", options: ALLOW },
    error: { control: "text" },
    disabled: { control: "boolean" },
    value: { control: false },
    onChange: { control: false },
    onComplete: { control: false },
  },
  args: {
    length: 6,
    allow: "numeric",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof AuthCode>;

// Controlled: AuthCode requires `value` + the string-valued `onChange`; the render
// owns the code so auto-advance, backspace-to-previous, and paste-distribution work
// live, with `onComplete` firing once `length` is reached.
// Grounded in showcase/src/pages/patterns/AuthFlowPage.tsx (the verify-code step).
export const Playground: Story = {
  render: (args) => {
    const [code, setCode] = useState("");
    return <AuthCode {...args} value={code} onChange={setCode} />;
  },
};

// The behavioral enum + states: numeric vs alphanumeric, the error row, disabled.
export const Variants: Story = {
  render: () => {
    const [numeric, setNumeric] = useState("123");
    const [alnum, setAlnum] = useState("A1B2");
    const [errored, setErrored] = useState("999999");
    return (
      <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
        {ALLOW.map((allow) => (
          <AuthCode
            key={allow}
            allow={allow}
            value={allow === "numeric" ? numeric : alnum}
            onChange={allow === "numeric" ? setNumeric : setAlnum}
          />
        ))}
        <AuthCode value={errored} onChange={setErrored} error="That code is incorrect" />
        <AuthCode value="42" onChange={() => undefined} disabled />
      </div>
    );
  },
};
