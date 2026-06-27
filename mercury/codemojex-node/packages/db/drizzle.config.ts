import { defineConfig } from "drizzle-kit";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

// drizzle-kit does not auto-load .env — load the shared codemojex-node/.env so a
// configured DATABASE_URL is honoured for migrate/studio (no-ops if absent).
const envFile = fileURLToPath(new URL("../../.env", import.meta.url));
if (existsSync(envFile)) process.loadEnvFile(envFile);

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/schema.ts",
  out: "./drizzle",
  casing: "snake_case",
  dbCredentials: {
    url: process.env.DATABASE_URL ?? "postgres://postgres:postgres@localhost:5432/codemojex",
  },
});
