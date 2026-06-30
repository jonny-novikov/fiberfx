/**
 * The shared Drizzle client. One connection pool, built from `DATABASE_URL`.
 * Consumers import `{ db, schema }` and never construct their own pool.
 */
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import { schema } from "./schema.js";

const url = process.env.DATABASE_URL;
if (!url) {
  throw new Error(
    "DATABASE_URL is not set. Copy db/.env.example to db/.env (codemojex_dev).",
  );
}

// postgres-js: a small, pure-ish pool. `max` is conservative for the dev bench.
export const sql = postgres(url, { max: 10, prepare: true });

export const db = drizzle(sql, { schema, casing: "snake_case" });

export { schema };
export type Db = typeof db;
