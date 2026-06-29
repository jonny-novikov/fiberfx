import type { Meta, StoryObj } from "@storybook/react-vite";
import { Text } from "@mercury/ui";
import type { TextProps, TextVariant } from "@mercury/ui";

// Enum domains traced from Text.tsx (TextVariant exported; the `accent` union is
// inline on TextProps) — NO-INVENT (mx.4 INV-5): an invented variant/accent is a
// compile error here.
const VARIANTS: TextVariant[] = [
  "display",
  "h1",
  "h2",
  "h3",
  "h4",
  "lead",
  "body",
  "small",
  "muted",
  "code",
  "quote",
];
type TextAccent = NonNullable<TextProps["accent"]>;
const ACCENTS: TextAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

// Controls restate Text.prompt.md: `variant` (the typographic role → element +
// face), `italic`, `align`, `accent` (ramp ink).
const meta: Meta<typeof Text> = {
  title: "Foundations/Text",
  component: Text,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    italic: { control: "boolean" },
    align: { control: "inline-radio", options: ["left", "center", "right"] },
    accent: { control: "select", options: ACCENTS },
    children: { control: "text" },
  },
  args: {
    variant: "body",
    children: "The quick brown fox jumps over the lazy dog.",
  },
};
export default meta;

type Story = StoryObj<typeof Text>;

export const Playground: Story = {};

// Every variant rendered in its own element + face/ink recipe.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "480px" }}>
      {VARIANTS.map((v) => (
        <Text key={v} variant={v}>
          {v} — the quick brown fox
        </Text>
      ))}
    </div>
  ),
};

// Accent inks resolve to the `--<ramp>-11` token families.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
      {ACCENTS.map((a) => (
        <Text key={a} variant="lead" accent={a}>
          {a} lead text
        </Text>
      ))}
    </div>
  ),
};
