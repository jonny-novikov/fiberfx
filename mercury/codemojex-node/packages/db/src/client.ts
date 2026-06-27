import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "./schema.js";

export type DbClient = ReturnType<typeof createDb>;
export type Database = DbClient["db"];

/** Create a pg Pool + Drizzle instance bound to the full Codemojex schema. */
export function createDb(connectionString: string) {
  const pool = new Pool({ connectionString });
  const db = drizzle(pool, { schema, casing: "snake_case" });
  return { pool, db };
}
