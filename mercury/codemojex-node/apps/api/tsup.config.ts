import { defineConfig } from "tsup";

// Bundles the internal @codemojex/* source packages into a single dist output.
export default defineConfig({
  entry: ["src/server.ts"],
  format: ["esm"],
  target: "node20",
  platform: "node",
  bundle: true,
  noExternal: [/@codemojex\//],
  clean: true,
});
