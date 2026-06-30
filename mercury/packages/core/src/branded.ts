/**
 * Branded (nominal) string types for BCS identities.
 *
 * These are erased at runtime (zero cost) and exist only to make the type
 * checker carry the namespace, so the compiler refuses a `GAM` id where a `PLR`
 * id is required. This module is the single owner of the identity type contract;
 * `@mercury/db` re-exports from here so the read model and the surface share one
 * definition.
 *
 * The guard below is a shape check only (length + namespace + base62 charset);
 * it is NOT a substitute for the authoritative codec. Cross-isolate minting, the
 * Snowflake decode, and the routing hash live in `@echo/fx` (Rust to wasm), kept
 * at parity with `EchoData.BrandedId` via the self-check.
 */
import {
  type Namespace,
  BRANDED_ID_RE,
  namespaceRe,
  isNamespace,
} from "./namespace.js";

declare const brand: unique symbol;

export type BrandedId<NS extends Namespace> = string & { readonly [brand]: NS };

export type AnyBrandedId = BrandedId<Namespace>;

export type PlayerId = BrandedId<"PLR">;
export type RoomId = BrandedId<"ROM">;
export type GameId = BrandedId<"GAM">;
export type GuessId = BrandedId<"GES">;
export type EmojiSetId = BrandedId<"EMS">;
export type SessionId = BrandedId<"SES">;
export type JobId = BrandedId<"JOB">;
export type TxnId = BrandedId<"TXN">;

/** Narrowing shape guard for a branded id of `ns`. */
export function isBranded<NS extends Namespace>(
  value: unknown,
  ns: NS,
): value is BrandedId<NS> {
  return typeof value === "string" && namespaceRe(ns).test(value);
}

/** The namespace of a well-formed branded id, or null. */
export function namespaceOf(value: string): Namespace | null {
  if (!BRANDED_ID_RE.test(value)) return null;
  const head = value.slice(0, 3);
  return isNamespace(head) ? head : null;
}

/** Assert a value is a branded id of `ns`, throwing otherwise. */
export function assertBranded<NS extends Namespace>(
  value: unknown,
  ns: NS,
): BrandedId<NS> {
  if (!isBranded(value, ns)) {
    throw new TypeError(`expected a ${ns} branded id, got ${String(value)}`);
  }
  return value;
}

/**
 * Brand a string already validated by other means (for example the authoritative
 * `@echo/fx` decode, or a value read straight from the system of record). Use
 * sparingly; prefer `isBranded` / `assertBranded` at trust boundaries.
 */
export function unsafeBrand<NS extends Namespace>(
  value: string,
  _ns: NS,
): BrandedId<NS> {
  return value as BrandedId<NS>;
}
