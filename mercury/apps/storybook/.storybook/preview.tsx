import type { Decorator, Preview } from "@storybook/react-vite";
import type { CSSProperties } from "react";
// Side-effect: the @mercury/ui barrel imports `styles/index.css`, so every
// story (incl. Tokens) resolves `rgb(var(--token))` (mx.3.md INV-5).
import "@mercury/ui";

// The canon §0 dark flip is a `dark-theme` class on an ancestor (the token
// override block is packages/mercury-ui/src/styles/tokens.css `.dark-theme`).
// A scoped wrapper div carries it — no cross-story leakage, and no dependency
// on @mercury/effector's initTheme() (mx.3.llms.md guidance).
//
// mx.8.1 generalizes that one wrapper: two brand-only toolbar globals (palette,
// radius) feed extra CSS-custom-property overrides onto the SAME wrapper style,
// so every descendant story re-skins with zero per-story edit — exactly how
// `.dark-theme` overrides the ramps. Brand-only: the --bg-active family and
// --radius-full are left intact (canon iris = identity / indigo = interaction).

type Ramp = "iris" | "indigo" | "green" | "orange" | "plum" | "red";
const HAS_10: Ramp[] = ["iris", "indigo"]; // the only ramps that ship a -10 step (tokens.css)

// Brand-only palette re-skin (grounded in tokens.css; iris = default ⇒ no override).
// Uses only steps the ramp defines: -3/-9/-11 for all six; -10 for iris/indigo, else the -9 fallback.
function paletteVars(palette: string): Record<string, string> {
  if (!palette || palette === "iris") return {};
  const R = palette as Ramp;
  const hover = HAS_10.includes(R) ? `rgb(var(--${R}-10))` : `rgb(var(--${R}-9))`;
  return {
    "--bg-brand": `rgb(var(--${R}-9))`,
    "--bg-brand-hover": hover,
    "--bg-brand-pressed": `rgb(var(--${R}-11))`,
    "--bg-brand-subtle": `rgb(var(--${R}-3))`,
    "--bg-brand-muted": `rgb(var(--${R}-3))`, // no -4 for status ramps → -3
    "--fg-brand": `rgb(var(--${R}-11))`,
    "--fg-brand-hover": hover,
    "--border-brand": `rgb(var(--${R}-9))`,
    "--fg-on-brand": R === "orange" ? "rgb(var(--slate-12))" : "rgb(var(--slate-1))",
    // NB: DO NOT re-point the --bg-active family (brand-only; interaction stays indigo).
  };
}

// Roundings (values = latitude; the mechanism is fixed). Default = no override; --radius-full NEVER touched.
const RADIUS_STEPS = [2, 4, 6, 8, 12, 16, 20, 24, 32] as const;
const ROUND: Record<(typeof RADIUS_STEPS)[number], string> = {
  2: "4px",
  4: "8px",
  6: "12px",
  8: "14px",
  12: "20px",
  16: "26px",
  20: "32px",
  24: "38px",
  32: "48px",
};
function radiusVars(radius: string): Record<string, string> {
  if (radius === "sharp") return Object.fromEntries(RADIUS_STEPS.map((n) => [`--radius-${n}`, "0px"]));
  if (radius === "round") return Object.fromEntries(RADIUS_STEPS.map((n) => [`--radius-${n}`, ROUND[n]]));
  return {}; // default — live values
}

const withTheme: Decorator = (Story, context) => {
  const theme = context.globals.theme === "dark" ? "dark" : "light";
  const palette = String(context.globals.palette ?? "iris");
  const radius = String(context.globals.radius ?? "default");
  return (
    <div
      className={`${theme}-theme`}
      style={
        {
          background: "rgb(var(--bg-primary))",
          color: "rgb(var(--fg-primary))",
          minHeight: "100vh",
          padding: "24px",
          fontFamily: "var(--font-primary)",
          ...paletteVars(palette),
          ...radiusVars(radius),
        } as CSSProperties
      }
    >
      <Story />
    </div>
  );
};

const preview: Preview = {
  initialGlobals: { theme: "light", palette: "iris", radius: "default" },
  globalTypes: {
    theme: {
      description: "Mercury theme (the canon light / dark-theme flip)",
      toolbar: {
        title: "Theme",
        icon: "mirror",
        items: [
          { value: "light", title: "Light" },
          { value: "dark", title: "Dark" },
        ],
        dynamicTitle: true,
      },
    },
    palette: {
      description: "Brand ramp — re-skins the --bg-brand family (brand-only; interaction stays indigo)",
      toolbar: {
        title: "Palette",
        icon: "paintbrush",
        dynamicTitle: true,
        items: [
          { value: "iris", title: "Brand (iris)" },
          { value: "indigo", title: "Indigo" },
          { value: "green", title: "Green" },
          { value: "orange", title: "Orange" },
          { value: "plum", title: "Plum" },
          { value: "red", title: "Red" },
        ],
      },
    },
    radius: {
      description: "Roundings — re-scales --radius-2…-32 (--radius-full preserved)",
      toolbar: {
        title: "Roundings",
        icon: "grid",
        dynamicTitle: true,
        items: [
          { value: "sharp", title: "Sharp" },
          { value: "default", title: "Default" },
          { value: "round", title: "Round" },
        ],
      },
    },
  },
  decorators: [withTheme],
  parameters: {
    controls: { expanded: true },
  },
};

export default preview;
