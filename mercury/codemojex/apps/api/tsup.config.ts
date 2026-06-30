import { defineConfig } from "tsup";

// Bundles the internal @codemojex/* and @echo/* source packages into a single
// dist output (neither ships a compiled dist — both are consumed from source).
export default defineConfig({
  entry: ["src/server.ts"],
  format: ["esm"],
  target: "node20",
  platform: "node",
  bundle: true,
  noExternal: [/@codemojex\//, /@echo\//],
  clean: true,
});
