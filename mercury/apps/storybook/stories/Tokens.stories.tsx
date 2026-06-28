import type { ReactNode } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";

// "Foundations/Tokens" — no single component. A render-based story of the canon
// §6 vocabulary drawn with `rgb(var(--token))`, so the theme decorator visibly
// flips every swatch dark. Every token name is real — traced from
// packages/mercury-ui/src/styles/tokens.css (NO-INVENT, mx.3.md INV-7).

const meta: Meta = {
  title: "Foundations/Tokens",
};
export default meta;

type Story = StoryObj;

function SectionHeading({ children }: { children: string }) {
  return (
    <h3
      style={{
        fontFamily: "var(--font-secondary)",
        fontSize: "var(--text-heading-100-size)",
        lineHeight: "var(--text-heading-100-lh)",
        color: "rgb(var(--fg-primary))",
        margin: "0 0 12px",
      }}
    >
      {children}
    </h3>
  );
}

function SwatchRow({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
        gap: "12px",
        marginBottom: "32px",
      }}
    >
      {children}
    </div>
  );
}

// A filled swatch (background token) with its label.
function FillSwatch({ token, fg = "--fg-primary" }: { token: string; fg?: string }) {
  return (
    <div
      style={{
        border: "1px solid rgb(var(--border-primary))",
        borderRadius: "var(--radius-8)",
        overflow: "hidden",
      }}
    >
      <div style={{ height: "56px", background: `rgb(var(${token}))` }} />
      <div
        style={{
          padding: "8px 10px",
          background: "rgb(var(--bg-secondary))",
          color: `rgb(var(${fg}))`,
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
          lineHeight: "var(--text-body-100-lh)",
        }}
      >
        {token}
      </div>
    </div>
  );
}

// A text-color token shown as text.
function TextSwatch({ token }: { token: string }) {
  return (
    <div
      style={{
        padding: "16px",
        border: "1px solid rgb(var(--border-primary))",
        borderRadius: "var(--radius-8)",
        background: "rgb(var(--bg-secondary))",
      }}
    >
      <div
        style={{
          color: `rgb(var(${token}))`,
          fontFamily: "var(--font-primary)",
          fontSize: "var(--text-body-400-size)",
          fontWeight: 600,
        }}
      >
        Aa
      </div>
      <div
        style={{
          marginTop: "8px",
          color: "rgb(var(--fg-secondary))",
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
        }}
      >
        {token}
      </div>
    </div>
  );
}

// A border token shown as a ring.
function BorderSwatch({ token }: { token: string }) {
  return (
    <div
      style={{
        padding: "16px",
        borderRadius: "var(--radius-8)",
        background: "rgb(var(--bg-secondary))",
      }}
    >
      <div
        style={{
          height: "40px",
          border: `2px solid rgb(var(${token}))`,
          borderRadius: "var(--radius-6)",
        }}
      />
      <div
        style={{
          marginTop: "8px",
          color: "rgb(var(--fg-secondary))",
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
        }}
      >
        {token}
      </div>
    </div>
  );
}

// One status family: solid bg, subtle bg, foreground.
function StatusSwatch({ family, label }: { family: string; label: string }) {
  return (
    <div
      style={{
        border: "1px solid rgb(var(--border-primary))",
        borderRadius: "var(--radius-8)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          height: "40px",
          background: `rgb(var(--bg-${family}))`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: `rgb(var(--fg-on-${family === "brand" ? "brand" : family}))`,
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
        }}
      >
        --bg-{family}
      </div>
      <div
        style={{
          height: "32px",
          background: `rgb(var(--bg-${family}-subtle))`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: `rgb(var(--fg-${family}))`,
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
        }}
      >
        {label}
      </div>
    </div>
  );
}

export const Tokens: Story = {
  render: () => (
    <div style={{ maxWidth: "1080px" }}>
      <SectionHeading>Surfaces · --bg-*</SectionHeading>
      <SwatchRow>
        <FillSwatch token="--bg-primary" />
        <FillSwatch token="--bg-secondary" />
        <FillSwatch token="--bg-tertiary" />
        <FillSwatch token="--bg-elevated" />
        <FillSwatch token="--bg-inverse" fg="--fg-inverse" />
      </SwatchRow>

      <SectionHeading>Text · --fg-*</SectionHeading>
      <SwatchRow>
        <TextSwatch token="--fg-primary" />
        <TextSwatch token="--fg-secondary" />
        <TextSwatch token="--fg-tertiary" />
        <TextSwatch token="--fg-disabled" />
        <TextSwatch token="--fg-brand" />
        <TextSwatch token="--fg-link" />
      </SwatchRow>

      <SectionHeading>Borders · --border-*</SectionHeading>
      <SwatchRow>
        <BorderSwatch token="--border-primary" />
        <BorderSwatch token="--border-secondary" />
        <BorderSwatch token="--border-strong" />
        <BorderSwatch token="--border-brand" />
        <BorderSwatch token="--border-focus" />
      </SwatchRow>

      <SectionHeading>Status families</SectionHeading>
      <SwatchRow>
        <StatusSwatch family="brand" label="brand" />
        <StatusSwatch family="info" label="info" />
        <StatusSwatch family="positive" label="positive" />
        <StatusSwatch family="negative" label="negative" />
        <StatusSwatch family="caution" label="caution" />
        <StatusSwatch family="discovery" label="discovery" />
      </SwatchRow>

      <SectionHeading>Type ramp</SectionHeading>
      <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
        <div style={{ fontFamily: "var(--font-primary)", color: "rgb(var(--fg-primary))", fontSize: "28px" }}>
          --font-primary — DM Sans · the quick brown fox
        </div>
        <div style={{ fontFamily: "var(--font-secondary)", color: "rgb(var(--fg-primary))", fontSize: "28px" }}>
          --font-secondary — DM Mono · the quick brown fox
        </div>
        <div style={{ fontFamily: "var(--font-display)", color: "rgb(var(--fg-primary))", fontSize: "40px" }}>
          --font-display — DM Serif Display
        </div>
      </div>
    </div>
  ),
};
