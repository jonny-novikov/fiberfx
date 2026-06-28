import { useState } from "react";
import type { Decorator, Meta, StoryObj } from "@storybook/react-vite";
import { AuthLayout, Button, Input, Divider, Link, AuthCode } from "@mercury/ui";

// AuthLayout has NO enum props — its surface is string / ReactNode / string[]
// only (traced from AuthLayout.tsx + restated in AuthLayout.prompt.md, NO-INVENT,
// mx.4.md INV-5). The text props (`eyebrow`/`heading`/`subheading`/`brandName`/
// `brandBadge`/`brandTagline`/`brandStatus`/`brandVersion`) restate as `text`
// controls; `brandFeatures` (`string[]`) as an `object` control; the ReactNode
// slots (`children`/`footer`/`brand`/`brandLogo`) get `control: false` and are
// driven by story args/render holding real <Button/> <Input/> <Divider/> <Link/>
// <AuthCode/> components (the Button exemplar's slot rule). `className` (a styling
// escape hatch) is omitted from the controls, as the exemplars do.

// AuthLayout fills its parent at height:100%, so each story is framed in a
// fixed-height, rounded, overflow-hidden box — exactly as the real call site
// frames it for a demo (AuthLayout.prompt.md ## Notes · "Sizing").
const Frame: Decorator = (Story) => (
  <div
    style={{
      height: "760px",
      border: "1px solid rgb(var(--border-primary))",
      borderRadius: "var(--radius-12)",
      overflow: "hidden",
      background: "rgb(var(--bg-primary))",
    }}
  >
    <Story />
  </div>
);

// A column of real form primitives — the Sign-in body the showcase AuthFlowPage
// mounts in the shell. Grounded in AuthLayout.prompt.md ## Examples.
const signInBody = (
  <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
    <Button variant="secondary" size="lg" fullWidth>
      Continue with Google
    </Button>
    <Divider label="or sign in with email" />
    <Input label="Email" type="email" defaultValue="you@company.com" />
    <Input label="Password" type="password" defaultValue="" />
    <Button size="lg" fullWidth>
      Sign in
    </Button>
  </div>
);

const signInFooter = (
  <p style={{ fontSize: "var(--text-body-100-size)", color: "rgb(var(--fg-secondary))" }}>
    New here? <Link size="sm">Create an account</Link>
  </p>
);

const meta: Meta<typeof AuthLayout> = {
  title: "Layout/AuthLayout",
  component: AuthLayout,
  decorators: [Frame],
  argTypes: {
    eyebrow: { control: "text" },
    heading: { control: "text" },
    subheading: { control: "text" },
    brandName: { control: "text" },
    brandBadge: { control: "text" },
    brandTagline: { control: "text" },
    brandStatus: { control: "text" },
    brandVersion: { control: "text" },
    brandFeatures: { control: "object" },
    // ReactNode slots — driven by real components, never a raw control.
    children: { control: false },
    footer: { control: false },
    brand: { control: false },
    brandLogo: { control: false },
  },
  args: {
    eyebrow: "Welcome back",
    heading: "Sign in to your console",
    subheading: "Manage queues, jobs and processors across your connections.",
    // Brand-panel defaults restated so the controls are populated (the component
    // defaults these; mirrored here from AuthLayout.tsx for an editable Playground).
    brandName: "Mercury",
    brandBadge: "UI",
    brandTagline: "The design system for your whole product.",
    brandFeatures: [
      "Tokens, themes and dark mode out of the box",
      "Accessible components with sensible defaults",
      "An Effector state plug for forms and toasts",
    ],
    brandStatus: "All systems operational",
    brandVersion: "v2.4.0",
    children: signInBody,
    footer: signInFooter,
  },
};
export default meta;

type Story = StoryObj<typeof AuthLayout>;

export const Playground: Story = {};

// The Verify screen — the same shell, a different body of primitives (the
// 6-digit AuthCode + a Verify button). AuthCode is controlled, so the render
// owns its state. showcase/src/pages/patterns/AuthFlowPage.tsx
export const Verify: Story = {
  render: () => {
    const [code, setCode] = useState("");
    return (
      <AuthLayout
        eyebrow="Verify it's you"
        heading="Enter your code"
        subheading="We sent a 6-digit code to you@company.com. It expires in 10 minutes."
        footer={
          <p style={{ textAlign: "center" }}>
            <Link size="sm" leading={<span aria-hidden="true">←</span>}>
              Use a different account
            </Link>
          </p>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          <AuthCode value={code} onChange={setCode} length={6} />
          <Button size="lg" fullWidth disabled={code.length < 6}>
            Verify
          </Button>
        </div>
      </AuthLayout>
    );
  },
};

// The brand panel is prop-driven — `brandName`/`brandTagline`/`brandFeatures`/
// `brandStatus`/`brandVersion` re-skin it without touching the form column
// (AuthLayout.prompt.md ## Notes · "The brand panel is prop-driven").
export const CustomBrand: Story = {
  args: {
    brandName: "Echo",
    brandBadge: "MQ",
    brandTagline: "The Valkey-native bus for your whole platform.",
    brandFeatures: [
      "Branded job ids, gated at the key builder",
      "Server-clock leases and inline Lua",
      "A retained, replayable event log",
    ],
    brandStatus: "Bus healthy · 0 stuck jobs",
    brandVersion: "v3.0.0",
  },
};
