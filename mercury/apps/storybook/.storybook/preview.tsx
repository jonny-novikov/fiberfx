import type { Decorator, Preview } from "@storybook/react-vite";
// Side-effect: the @mercury/ui barrel imports `styles/index.css`, so every
// story (incl. Tokens) resolves `rgb(var(--token))` (mx.3.md INV-5).
import "@mercury/ui";

// The canon §0 dark flip is a `dark-theme` class on an ancestor (the token
// override block is packages/mercury-ui/src/styles/tokens.css `.dark-theme`).
// A scoped wrapper div carries it — no cross-story leakage, and no dependency
// on @mercury/effector's initTheme() (mx.3.llms.md guidance).
const withTheme: Decorator = (Story, context) => {
  const theme = context.globals.theme === "dark" ? "dark" : "light";
  return (
    <div
      className={`${theme}-theme`}
      style={{
        background: "rgb(var(--bg-primary))",
        color: "rgb(var(--fg-primary))",
        minHeight: "100vh",
        padding: "24px",
        fontFamily: "var(--font-primary)",
      }}
    >
      <Story />
    </div>
  );
};

const preview: Preview = {
  initialGlobals: { theme: "light" },
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
  },
  decorators: [withTheme],
  parameters: {
    controls: { expanded: true },
  },
};

export default preview;
