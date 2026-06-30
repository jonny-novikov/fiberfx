/**
 * Identity types for the read model — re-exported so the read model and the
 * surface share one definition.
 *
 * The generic FORMAT contract and the BCS boundary gate come from `@echo/core`;
 * the codemojex namespace set (`CM`) and the typed ids come from
 * `@codemojex/domain`. `@echo/fx` (Rust to wasm) remains the authority for the
 * codec and routing hash; the guards here are shape checks only.
 */
export {
  type BrandedId,
  type AnyBrandedId,
  BRANDED_ID_LENGTH,
  BRANDED_ID_RE,
  namespaceRe,
  namespaceOf,
  isBranded,
  assertBranded,
  unsafeBrand,
  gate,
  gateOrThrow,
} from "@echo/core";

export {
  CM,
  type CodemojexNamespace,
  type PlayerId,
  type RoomId,
  type GameId,
  type GuessId,
  type EmojiSetId,
  type SessionId,
  type JobId,
  type TxnId,
} from "@codemojex/domain";
