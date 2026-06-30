/**
 * Branded (nominal) identity types for the read model.
 *
 * The canonical contract now lives in `@echo/core`; this module re-exports it so
 * the read model and the surface share one definition (one identity contract).
 * `@echo/fx` (Rust to wasm) remains the authority for the codec and the routing
 * hash; the guards here are shape checks only.
 */
export {
  type BrandedId,
  type AnyBrandedId,
  type Namespace,
  type PlayerId,
  type RoomId,
  type GameId,
  type GuessId,
  type EmojiSetId,
  type SessionId,
  type JobId,
  type TxnId,
  NAMESPACES,
  BRANDED_ID_LENGTH,
  BRANDED_ID_RE,
  isNamespace,
  namespaceRe,
  isBranded,
  namespaceOf,
  assertBranded,
  unsafeBrand,
} from "@echo/core";
