import "dotenv/config";
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  casing: "snake_case",
  dbCredentials: {
    url: process.env.DATABASE_URL ?? "",
  },
  // The Ecto migrations own the live schema. Treat strictly:
  // `generate` to diff the read-model, `pull` to mirror the source of record.
  strict: true,
  verbose: true,
});
