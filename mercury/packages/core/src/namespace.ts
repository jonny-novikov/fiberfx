/**
 * The branded-identity namespace registry.
 *
 * A BCS id is fourteen characters: a three-letter uppercase namespace followed
 * by the width-11 base62 of a 63-bit Snowflake (for example `PLR0ONWgLPPGbY`).
 * The Elixir `EchoData.BrandedId` owns the codec and `@echo/fx` mirrors it in
 * Rust; this module owns only the namespace set and the shape patterns. It does
 * not decode the Snowflake — that is the kernel's job.
 */

/** The namespaces the product mints, mapped to their domain meaning. */
export const NAMESPACES = {
  PLR: "player",
  ROM: "room",
  GAM: "game",
  GES: "guess",
  EMS: "emoji_set",
  SES: "session",
  JOB: "job",
  TXN: "wallet_ledger_entry",
} as const;

export type Namespace = keyof typeof NAMESPACES;

/** The base62 body charset (everything after the 3-char namespace). */
export const BASE62 = "0-9A-Za-z";

/** Total length of a branded id. */
export const BRANDED_ID_LENGTH = 14;

/** Matches any well-formed branded id (3 uppercase + 11 base62). */
export const BRANDED_ID_RE = /^[A-Z]{3}[0-9A-Za-z]{11}$/;

/** The regex for a branded id of a specific namespace. */
export function namespaceRe(ns: Namespace): RegExp {
  return new RegExp(`^${ns}[0-9A-Za-z]{11}$`);
}

/** True when `s` is one of the registered namespaces. */
export function isNamespace(s: string): s is Namespace {
  return Object.prototype.hasOwnProperty.call(NAMESPACES, s);
}
