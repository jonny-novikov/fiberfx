/**
 * The codemojex domain.
 *
 * codemojex declares its BCS namespace set here, against `@echo/core`'s registry.
 * This is the one place the product's namespaces live — `@echo/core` and
 * `@echo/fx` stay generic. Every app (the admin, future services) imports `CM`
 * to gate, validate, and schema its branded ids, and imports the typed id
 * aliases so the compiler carries the namespace end to end.
 *
 * These mirror the live umbrella (`echo/apps/codemojex`): `GAM` game, `ROM` room,
 * `PLR` player, `GES` guess, `EMS` emoji set, `SES` session, `JOB` queue job, and
 * `TXN` for the wallet ledger entry. `USR` is the codec's generic example in
 * `@echo/core`; it is not a codemojex namespace.
 */
import { defineNamespaces, type BrandedId } from "@echo/core";

/** The codemojex namespace registry — declare once, run all pipelines against it. */
export const CM = defineNamespaces({
  PLR: "player",
  ROM: "room",
  GAM: "game",
  GES: "guess",
  EMS: "emoji_set",
  SES: "session",
  JOB: "job",
  TXN: "wallet_ledger_entry",
} as const);

/** The union of codemojex namespace codes. */
export type CodemojexNamespace = (typeof CM)["names"][number];

export type PlayerId = BrandedId<"PLR">;
export type RoomId = BrandedId<"ROM">;
export type GameId = BrandedId<"GAM">;
export type GuessId = BrandedId<"GES">;
export type EmojiSetId = BrandedId<"EMS">;
export type SessionId = BrandedId<"SES">;
export type JobId = BrandedId<"JOB">;
export type TxnId = BrandedId<"TXN">;
