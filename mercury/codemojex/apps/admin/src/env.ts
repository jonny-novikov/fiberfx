/**
 * The admin's typed, frozen environment, parsed once at boot through the
 * @echo/core reader. A missing or malformed required value fails the boot, not
 * the first request.
 */
import { loadEnv as coreLoadEnv } from "@echo/core";

const LEVELS = ["fatal", "error", "warn", "info", "debug", "trace"] as const;
export type LogLevel = (typeof LEVELS)[number];

export interface Env {
  readonly port: number;
  readonly host: string;
  readonly logLevel: LogLevel;
  readonly databaseUrl: string;
  readonly valkeyHost: string;
  readonly valkeyPort: number;
}

export function loadEnv(): Env {
  return coreLoadEnv((r) => ({
    port: r.int("PORT", 3000),
    host: r.str("HOST", "0.0.0.0"),
    logLevel: r.oneOf("LOG_LEVEL", LEVELS, "info"),
    databaseUrl: r.str("DATABASE_URL"),
    valkeyHost: r.str("VALKEY_HOST", "localhost"),
    valkeyPort: r.int("VALKEY_PORT", 6390),
  }));
}
