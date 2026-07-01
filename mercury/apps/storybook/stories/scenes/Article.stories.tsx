import type { CSSProperties } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Avatar, Badge, Blockquote, Callout, Code, Divider, Heading, Icon, Separator, Text } from "@mercury/ui";

// Scenes/Article — a long-form editorial / doc layout where the FOUNDATIONS lead: a display
// Heading title, a `lead` Text intro, section Headings, `body`/`quote` Text, Divider label
// section breaks, and an Icon-led inline note carry the page; Blockquote / Callout / Badge / Code
// / Avatar add realism. Grounded in the editorial variant set the foundations already document
// (foundations/Text stories: display/lead/body/quote/code; foundations/Heading stories: the 1–9
// display size scale) + the display-type header pattern in
// packages/mercury-ds/project/ui_kits/mercury_app/screens.jsx (the `var(--font-display)` masthead
// title). Presentational; imports ONLY @mercury/ui. NO-INVENT: every Icon name (info) is a real
// ICONS key, `cx`/`mx-btn` are the real @mercury/core export + Button recipe class, and each
// component is composed per its .tsx surface.

const meta: Meta = { title: "Scenes/Article" };
export default meta;

type Story = StoryObj;

const metaLine: CSSProperties = { color: "rgb(var(--fg-tertiary))" };
const section: CSSProperties = { display: "flex", flexDirection: "column", gap: "var(--space-12)" };

export const Article: Story = {
  render: () => (
    <article
      style={{
        maxWidth: 680,
        margin: "0 auto",
        display: "flex",
        flexDirection: "column",
        gap: "var(--space-24)",
      }}
    >
      {/* Masthead — a display Heading title over a `lead` Text intro, with a Badge + byline. */}
      <header style={{ display: "flex", flexDirection: "column", gap: "var(--space-12)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-8)" }}>
          <Badge variant="brand">Engineering</Badge>
          <Text variant="small" style={metaLine}>
            6 min read · Updated Jul 2026
          </Text>
        </div>
        <Heading size={8}>Tokens all the way down</Heading>
        <Text variant="lead">
          A design system earns trust when a viewer can interrogate it — does the library hold together
          under a different brand ramp, sharper corners, a dark canvas? Mercury answers yes by keeping
          every taste decision exactly one variable deep.
        </Text>
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-8)" }}>
          <Avatar name="Grace Hopper" size={32} />
          <Text variant="small">Grace Hopper · Platform</Text>
        </div>
      </header>

      <Separator />

      {/* Section 1 — foundation prose (body Text with inline Code) closed by a branded Callout. */}
      <section style={section}>
        <Heading size={5}>One foundation, many surfaces</Heading>
        <Text variant="body">
          Every component composes the same owned foundation. Colour, type, radius, and elevation all
          resolve from a semantic alias — <Code>--bg-brand</Code> here, <Code>--radius-8</Code> there —
          so a rebrand or a theme flip is one variable deep, never a sweep through the component tree.
        </Text>
        <Text variant="body">
          The rule of thumb: a taste decision lands as a token or a recipe, never a raw value. That is
          what lets the same markup re-skin under a different palette without touching a line of it.
        </Text>
        <Callout intent="brand" title="Design flows down">
          Components translate the prototype's anatomy — its shape — not its throwaway logic. The mature
          foundation underneath is what they actually compose.
        </Callout>
      </section>

      <Divider label="the pattern" />

      {/* Section 2 — the enum→recipe idiom, shown as a real Code block + an attributed Blockquote. */}
      <section style={section}>
        <Heading size={5}>The shape of a component</Heading>
        <Text variant="body">
          A Mercury component is a thin thing: a ref forwarded onto the native element, a public enum
          prop, and a private class. The prop is the whole API; the class is the recipe that maps it to
          a token family.
        </Text>
        <Code block>{`import { cx } from "@mercury/core";

// the public prop is the enum; the private class is the recipe
const className = cx("mx-btn", \`mx-btn--\${variant}\`);`}</Code>
        <Blockquote accent="iris" cite="— the Mercury contract">
          A consumer never authors a token value by hand. Style flows through the enum, and the enum
          resolves to a token family the theme flip can move.
        </Blockquote>
      </section>

      <Divider label="in practice" />

      {/* Section 3 — a pull-quote (Text `quote`) + an Icon-led inline note back to this toolbar. */}
      <section style={section}>
        <Heading size={5}>Reading it back</Heading>
        <Text variant="body">
          Ship the thin slice, prove it under a real theme flip, and let the next surface inherit it.
          The showcase is where the story becomes browsable — and where a viewer can interrogate the
          system under a different palette or a sharper corner.
        </Text>
        <Text variant="quote">Ship it thin, prove it under the flip, let the next surface inherit it.</Text>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "var(--space-8)",
            color: "rgb(var(--fg-secondary))",
          }}
        >
          <Icon name="info" size={16} />
          <Text variant="small">Toggle the Palette and Roundings controls in the toolbar to re-skin this page.</Text>
        </div>
      </section>
    </article>
  ),
};
