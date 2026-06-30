/**
 * The branded-identity FORMAT contract — generic over the namespace.
 *
 * A BCS id is fourteen characters: a three-letter uppercase namespace followed
 * by the width-11 base62 of a 63-bit Snowflake (for example `USR0KHTOWnGLuC`).
 * This mirrors `EchoData.BrandedId`: one module owns the codec and hash, and the
 * namespace is a PARAMETER, not a closed set. Core knows nothing of any product's
 * namespaces — an application declares its own via `defineNamespaces`.
 *
 * `BrandedId<NS>` is a nominal type erased at runtime (zero cost); it exists only
 * to make the compiler carry the namespace, so a `GAM` id cannot be passed where
 * a `PLR` id is required. The guards here are SHAPE checks (length + 3-uppercase
 * namespace + base62 body); the authoritative Snowflake decode and routing hash
 * live in `@echo/fx` (Rust to wasm), kept at parity with `EchoData.BrandedId`.
 */

declare const brand: unique symbol;

/** A 14-char BCS identity in namespace `NS`. Nominal; erased at runtime. */
export type BrandedId<NS extends string> = string & { readonly [brand]: NS };

/** Any well-formed branded id, namespace unknown at the type level. */
export type AnyBrandedId = BrandedId<string>;

/** The base62 body charset (everything after the 3-char namespace). */
export const BASE62 = "0-9A-Za-z";

/** Total length of a branded id. */
export const BRANDED_ID_LENGTH = 14;

/** Matches any well-formed branded id: 3 uppercase + 11 base62. */
export const BRANDED_ID_RE = /^[A-Z]{3}[0-9A-Za-z]{11}$/;

/** A 3-letter uppercase namespace (shape only). */
export const NAMESPACE_RE = /^[A-Z]{3}$/;

/** True when `s` has the shape of a namespace (3 uppercase ASCII letters). */
export function isNamespaceShape(s: string): boolean {
  return NAMESPACE_RE.test(s);
}

/** The regex matching a branded id of a specific namespace. */
export function namespaceRe(ns: string): RegExp {
  return new RegExp(`^${ns}[0-9A-Za-z]{11}$`);
}

/** Narrowing shape guard for a branded id of `ns`. */
export function isBranded<NS extends string>(value: unknown, ns: NS): value is BrandedId<NS> {
  return typeof value === "string" && namespaceRe(ns).test(value);
}

/** The 3-char namespace of a well-formed branded id, or null. */
export function namespaceOf(value: string): string | null {
  return BRANDED_ID_RE.test(value) ? value.slice(0, 3) : null;
}

/** Assert a value is a branded id of `ns`, throwing otherwise. */
export function assertBranded<NS extends string>(value: unknown, ns: NS): BrandedId<NS> {
  if (!isBranded(value, ns)) {
    throw new TypeError(`expected a ${ns} branded id, got ${String(value)}`);
  }
  return value;
}

/**
 * Brand a string already validated by other means — the authoritative `@echo/fx`
 * decode, or a value read straight from the system of record. Prefer the gate or
 * `assertBranded` at trust boundaries.
 */
export function unsafeBrand<NS extends string>(value: string, _ns: NS): BrandedId<NS> {
  return value as BrandedId<NS>;
}
