/**
 * Branded entity ids — the BCS `{ns}{base62}` scheme `echo_data` mints (14 bytes: a
 * 3-letter uppercase namespace + 11 base62 chars). Each id is a nominal `string` brand, so a
 * `RoomId` cannot be passed where a `PlayerId` is expected, yet it serializes as a plain string.
 */

declare const __brand: unique symbol;

export type Branded<T, B extends string> = T & { readonly [__brand]: B };

export type PlayerId = Branded<string, "PLR">;
export type RoomId = Branded<string, "ROM">;
export type GameId = Branded<string, "GAM">;
export type GuessId = Branded<string, "GES">;
export type EmojiSetId = Branded<string, "EMS">;
export type TransactionId = Branded<string, "TXN">;

/** The 3-letter namespace per entity, matching `EchoData.BrandedId.generate!/1` call sites. */
export const NAMESPACES = {
  player: "PLR",
  room: "ROM",
  game: "GAM",
  guess: "GES",
  emojiSet: "EMS",
  transaction: "TXN",
} as const;

export type Namespace = (typeof NAMESPACES)[keyof typeof NAMESPACES];

const NS = /^[A-Z]{3}$/;
const BASE62 = /^[0-9A-Za-z]{11}$/;

/** Structural validity of a branded id: `NS(3) + base62(11)`. Optionally pins the namespace. */
export function isBrandedId(s: string, ns?: Namespace): boolean {
  return s.length === 14 && NS.test(s.slice(0, 3)) && BASE62.test(s.slice(3)) && (ns === undefined || s.startsWith(ns));
}

/** The namespace of any branded id string (e.g. `"ROM"` of `"ROM0KHTOWnGLuC"`). */
export function namespaceOf(id: string): string {
  return id.slice(0, 3);
}
