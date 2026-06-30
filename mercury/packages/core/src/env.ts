/**
 * A typed, frozen environment reader. Parsing happens once at boot; a missing or
 * malformed required value fails the boot rather than the first request. Values
 * may carry a trailing `# comment` (for example `6390 # passwordless`), which is
 * stripped before parsing.
 */
export class EnvError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EnvError";
  }
}

export interface EnvReader {
  str(key: string, fallback?: string): string;
  int(key: string, fallback?: number): number;
  bool(key: string, fallback?: boolean): boolean;
  oneOf<T extends string>(key: string, values: readonly T[], fallback?: T): T;
}

function stripComment(raw: string): string {
  const hash = raw.indexOf("#");
  return (hash >= 0 ? raw.slice(0, hash) : raw).trim();
}

function present(src: Record<string, string | undefined>, key: string): string | undefined {
  const v = src[key];
  return v === undefined || v === "" ? undefined : v;
}

function makeReader(src: Record<string, string | undefined>): EnvReader {
  return {
    str(key, fallback) {
      const v = present(src, key);
      if (v === undefined) {
        if (fallback !== undefined) return fallback;
        throw new EnvError(`missing required env ${key}`);
      }
      return v;
    },
    int(key, fallback) {
      const v = present(src, key);
      if (v === undefined) {
        if (fallback !== undefined) return fallback;
        throw new EnvError(`missing required env ${key}`);
      }
      const n = Number(stripComment(v));
      if (!Number.isFinite(n)) throw new EnvError(`env ${key} is not a number: ${v}`);
      return n;
    },
    bool(key, fallback) {
      const v = present(src, key);
      if (v === undefined) {
        if (fallback !== undefined) return fallback;
        throw new EnvError(`missing required env ${key}`);
      }
      const s = stripComment(v).toLowerCase();
      return s === "1" || s === "true" || s === "yes" || s === "on";
    },
    oneOf(key, values, fallback) {
      const v = present(src, key);
      if (v === undefined) {
        if (fallback !== undefined) return fallback;
        throw new EnvError(`missing required env ${key}`);
      }
      const s = stripComment(v);
      if (!values.includes(s as (typeof values)[number])) {
        throw new EnvError(`env ${key} must be one of ${values.join(", ")}`);
      }
      return s as (typeof values)[number];
    },
  };
}

/** Build a frozen, typed env object from a reader. */
export function loadEnv<T>(
  build: (read: EnvReader) => T,
  src: Record<string, string | undefined> = process.env,
): Readonly<T> {
  return Object.freeze(build(makeReader(src)));
}
