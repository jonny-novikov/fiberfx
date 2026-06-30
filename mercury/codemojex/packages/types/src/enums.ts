/**
 * Domain value sets. The ones the Postgres model enforces with a CHECK constraint are marked
 * AUTHORITATIVE; the rest are the known values for columns that are plain `text` in the DB
 * (so the DTOs keep them as strings, but these unions give editors and callers the real set).
 */

/** AUTHORITATIVE — `games_type` CHECK: `type IN ('classic','golden')`. */
export const GAME_TYPES = ["classic", "golden"] as const;
export type GameType = (typeof GAME_TYPES)[number];

/** AUTHORITATIVE — `games_status` CHECK (cm.5 added `gathering`). */
export const GAME_STATUSES = [
  "gathering",
  "scheduled",
  "open",
  "active",
  "revealing",
  "settling",
  "settled",
  "voided",
] as const;
export type GameStatus = (typeof GAME_STATUSES)[number];

/** AUTHORITATIVE — `transactions.currency` names one of the player balance columns. */
export const CURRENCIES = ["keys", "clips", "diamonds", "bonus_diamonds", "locked_diamonds"] as const;
export type Currency = (typeof CURRENCIES)[number];

/** A room's default game type (`rooms.type`, default `classic`). Not CHECK-constrained. */
export const ROOM_TYPES = ["classic", "golden"] as const;
export type RoomType = (typeof ROOM_TYPES)[number];

// --- Known values for unconstrained `text` policy columns (column default in parentheses) ---

/** `games.feedback` (default `score`). */
export type Feedback = "score" | "none";
/** `games.scoring` (default `linear`). The engine is linear-only today. */
export type Scoring = "linear";
/** `games.settlement` (default `live`). */
export type Settlement = "live" | "live_split" | "sealed";
/** `games.economy` (default `winner_take_all`). */
export type Economy = "winner_take_all" | "proportional";
/** `rooms.status` (default `waiting`) / `games.status` mirror; rooms are not CHECK-constrained. */
export type RoomStatus = "waiting" | "open" | "active" | "closed" | "voided";
