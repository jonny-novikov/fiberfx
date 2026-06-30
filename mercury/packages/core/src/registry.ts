/**
 * The BCS namespace registry.
 *
 * Core owns the id FORMAT, the gate, and the schema builder — all generic over
 * the namespace. The namespace SET belongs to an application. `defineNamespaces`
 * is how an app declares its set once and gets a typed registry to run every
 * branded pipeline against: shape guards, the boundary gate, TypeBox schemas, and
 * branding — each constrained to the registered namespaces, so a typo of an
 * unregistered code is a compile error.
 *
 *   const APP = defineNamespaces({ USR: "user", JOB: "job" } as const);
 *   APP.gate("USR", req.params.id)   // Result<BrandedId<"USR">, GateError>
 *   APP.idSchema("JOB")              // TypeBox schema, static = BrandedId<"JOB">
 *   APP.has("XYZ")                   // false
 *
 * This mirrors the canon: `EchoData.BrandedId` takes the namespace as a
 * parameter, and consuming apps wrap that core to mint and decode their own
 * 3-letter-namespaced ids.
 */
import { type BrandedId, isBranded, namespaceRe, NAMESPACE_RE } from "./branded.js";
import { gate, type GateError } from "./bcs.js";
import { BrandedIdSchema, type TBrandedId } from "./schema.js";
import type { Result } from "neverthrow";

/** A namespace specification: 3-letter code mapped to its domain meaning. */
export type NamespaceSpec = Readonly<Record<string, string>>;

/** A typed registry over a declared namespace set `S`. */
export interface NamespaceRegistry<S extends NamespaceSpec> {
  /** The declared spec (code -> meaning). */
  readonly spec: S;
  /** The declared namespace codes. */
  readonly names: ReadonlyArray<keyof S & string>;
  /** Type guard: is `s` one of the registered namespaces? */
  has(s: string): s is keyof S & string;
  /** The regex matching a registered namespace's ids. */
  re(ns: keyof S & string): RegExp;
  /** Shape guard for an id of a registered namespace. */
  is<NS extends keyof S & string>(ns: NS, value: unknown): value is BrandedId<NS>;
  /** Boundary gate bound to a registered namespace (error-as-value). */
  gate<NS extends keyof S & string>(ns: NS, value: unknown): Result<BrandedId<NS>, GateError>;
  /** TypeBox schema for a registered namespace; static type is `BrandedId<NS>`. */
  idSchema<NS extends keyof S & string>(ns: NS, opts?: { description?: string }): TBrandedId<NS>;
  /** Brand a string already validated elsewhere (e.g. read from the system of record). */
  brand<NS extends keyof S & string>(ns: NS, value: string): BrandedId<NS>;
}

/**
 * Declare a namespace set and get a typed registry. Validates each code's shape
 * at construction (3 uppercase letters), so a malformed namespace fails fast.
 */
export function defineNamespaces<const S extends NamespaceSpec>(spec: S): NamespaceRegistry<S> {
  const names = Object.keys(spec) as Array<keyof S & string>;
  for (const ns of names) {
    if (!NAMESPACE_RE.test(ns)) {
      throw new TypeError(`namespace "${ns}" must be 3 uppercase ASCII letters`);
    }
  }
  const set = new Set<string>(names);
  return {
    spec,
    names,
    has: (s): s is keyof S & string => set.has(s),
    re: (ns) => namespaceRe(ns),
    is: (ns, value) => isBranded(value, ns),
    gate: (ns, value) => gate(value, ns),
    idSchema: (ns, opts) => BrandedIdSchema(ns, opts),
    brand: (ns, value) => value as BrandedId<typeof ns>,
  };
}
