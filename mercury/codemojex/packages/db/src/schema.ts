/**
 * Drizzle schema for the codemojex system of record (Postgres).
 *
 * Reference model: `echo/apps/codemojex` Ecto schemas. The Elixir side owns the
 * migrations (`create_codemojex`, `golden_rooms`, `revenue_ledger`, `key_shop`);
 * this file is the Node read-model mirror. The four core tables below
 * (players, rooms, games, guesses) and emoji_sets are modeled from the observed
 * columns of a live game. The ledger/shop tables are scaffolded by their known
 * migration names with provisional columns — run `pnpm db:pull` against the
 * Ecto-migrated database to make them bijective with the source of record.
 *
 * Branding: every id is a 14-char BCS identity. We type the columns with the
 * phantom `BrandedId<NS>` so the compiler carries the namespace.
 */
import {
  pgTable,
  pgEnum,
  varchar,
  text,
  integer,
  bigint,
  numeric,
  boolean,
  timestamp,
  jsonb,
  index,
} from "drizzle-orm/pg-core";
import type {
  PlayerId,
  RoomId,
  GameId,
  GuessId,
  EmojiSetId,
  TxnId,
} from "./branded.js";

/** A BCS id column: char(14)-shaped varchar, nominally typed to a namespace. */
const id = <T extends string>(name: string) =>
  varchar(name, { length: 14 }).$type<T>();

/** Ecto `timestamps()` with utc_datetime_usec → timestamptz(6). */
const insertedAt = timestamp("inserted_at", {
  withTimezone: true,
  precision: 6,
  mode: "date",
})
  .notNull()
  .defaultNow();
const updatedAt = timestamp("updated_at", {
  withTimezone: true,
  precision: 6,
  mode: "date",
})
  .notNull()
  .defaultNow();

/** The three core currencies plus the golden tournament rail. */
export const currency = pgEnum("currency", [
  "clips",
  "diamonds",
  "keys",
  "golden",
]);

/** Coarse lifecycle for a room/game. Reconcile exact values via db:pull. */
export const gameStatus = pgEnum("game_status", [
  "open",
  "active",
  "closed",
  "settled",
]);

// ── players ────────────────────────────────────────────────────────────────
// The wallet is the player row: three currencies, with the diamond rail split
// into available / bonus / locked. Mutated atomically through Codemojex.Wallet.
export const players = pgTable(
  "players",
  {
    id: id<PlayerId>("id").primaryKey(),
    name: text("name").notNull(),
    tgUserId: bigint("tg_user_id", { mode: "number" }),
    tgChatId: bigint("tg_chat_id", { mode: "number" }),

    clips: integer("clips").notNull().default(0),

    diamonds: integer("diamonds").notNull().default(0),
    availableDiamonds: integer("available_diamonds").notNull().default(0),
    bonusDiamonds: integer("bonus_diamonds").notNull().default(0),
    lockedDiamonds: integer("locked_diamonds").notNull().default(0),

    keys: integer("keys").notNull().default(0),
    availableKeys: integer("available_keys").notNull().default(0),

    insertedAt,
    updatedAt,
  },
  (t) => [index("players_tg_user_id_idx").on(t.tgUserId)],
);

// ── emoji_sets ───────────────────────────────────────────────────────────────
// The keyboard sprite + cell codes. Also held in the EchoStore near-cache
// (ValKey); Postgres is the durable copy.
export const emojiSets = pgTable("emoji_sets", {
  id: id<EmojiSetId>("id").primaryKey(),
  name: text("name").notNull(),
  rows: integer("rows").notNull(),
  cols: integer("cols").notNull(),
  cellSize: integer("cell_size").notNull(),
  spriteUrl: text("sprite_url"),
  codes: jsonb("codes").$type<string[]>().notNull(),
  insertedAt,
  updatedAt,
});

// ── rooms ────────────────────────────────────────────────────────────────────
// A room templates games. `golden_rooms` (below) is the tournament tier.
export const rooms = pgTable(
  "rooms",
  {
    id: id<RoomId>("id").primaryKey(),
    name: text("name").notNull(),
    emojiSetId: id<EmojiSetId>("emoji_set_id").references(() => emojiSets.id),
    free: boolean("free").notNull(),
    clipCost: integer("clip_cost"),
    durationMs: bigint("duration_ms", { mode: "number" }),
    status: gameStatus("status").notNull().default("open"),
    insertedAt,
    updatedAt,
  },
  (t) => [index("rooms_status_idx").on(t.status)],
);

// ── games ────────────────────────────────────────────────────────────────────
// The playable entity inside a room. Secret + keyboard are snapshotted at join.
export const games = pgTable(
  "games",
  {
    id: id<GameId>("id").primaryKey(),
    roomId: id<RoomId>("room_id")
      .references(() => rooms.id)
      .notNull(),
    emojiSetId: id<EmojiSetId>("emoji_set_id").references(() => emojiSets.id),
    free: boolean("free").notNull(),
    guessFee: integer("guess_fee"),
    prizePool: bigint("prize_pool", { mode: "number" }),
    prizeUsd: numeric("prize_usd", { precision: 12, scale: 2 }),
    endsMs: bigint("ends_ms", { mode: "number" }).notNull(),
    status: gameStatus("status").notNull().default("active"),
    totals: jsonb("totals").$type<Record<string, number>>(),
    // snapshotted at join; withheld from player reads by Codemojex.View
    secret: jsonb("secret").$type<string[]>(),
    keyboard: jsonb("keyboard").$type<string[]>(),
    insertedAt,
    updatedAt,
  },
  (t) => [
    index("games_room_id_idx").on(t.roomId),
    index("games_status_idx").on(t.status),
  ],
);

// ── guesses ──────────────────────────────────────────────────────────────────
// Append-only. Written by the scoring consumer (the single authority), not by
// the surface that accepts the guess. `pct` and `eff` mirror the scored event.
export const guesses = pgTable(
  "guesses",
  {
    id: id<GuessId>("id").primaryKey(),
    gameId: id<GameId>("game_id")
      .references(() => games.id)
      .notNull(),
    playerId: id<PlayerId>("player_id")
      .references(() => players.id)
      .notNull(),
    codes: jsonb("codes").$type<string[]>().notNull(),
    score: integer("score"),
    percentage: integer("percentage"),
    effort: integer("effort"),
    breakdown: jsonb("breakdown").$type<unknown[]>(),
    insertedAt,
  },
  (t) => [
    index("guesses_game_id_idx").on(t.gameId),
    index("guesses_player_id_idx").on(t.playerId),
  ],
);

// ── PROVISIONAL — reconcile column sets via `pnpm db:pull` ────────────────────
// The migration names are known (`golden_rooms`, `revenue_ledger`, `key_shop`)
// and the wallet ledger is cited by the component reference, but their exact
// columns are not yet mirrored from source. Declared here so the read model and
// the admin compile against stable names; introspect the Ecto-migrated database
// to lock the columns. Do NOT treat these column lists as authoritative.

export const goldenRooms = pgTable("golden_rooms", {
  id: id<RoomId>("id").primaryKey(),
  roomId: id<RoomId>("room_id").references(() => rooms.id),
  goldenCost: integer("golden_cost"),
  prizePool: bigint("prize_pool", { mode: "number" }),
  status: gameStatus("status").notNull().default("open"),
  insertedAt,
  updatedAt,
});

export const revenueLedger = pgTable(
  "revenue_ledger",
  {
    id: id<TxnId>("id").primaryKey(),
    gameId: id<GameId>("game_id").references(() => games.id),
    playerId: id<PlayerId>("player_id").references(() => players.id),
    currency: currency("currency").notNull(),
    amount: bigint("amount", { mode: "number" }).notNull(),
    reason: text("reason"),
    insertedAt,
  },
  (t) => [index("revenue_ledger_game_id_idx").on(t.gameId)],
);

export const walletLedger = pgTable(
  "wallet_ledger",
  {
    id: id<TxnId>("id").primaryKey(),
    playerId: id<PlayerId>("player_id")
      .references(() => players.id)
      .notNull(),
    currency: currency("currency").notNull(),
    delta: integer("delta").notNull(),
    balanceAfter: integer("balance_after"),
    reason: text("reason"),
    refId: varchar("ref_id", { length: 14 }),
    insertedAt,
  },
  (t) => [index("wallet_ledger_player_id_idx").on(t.playerId)],
);

export const keyShop = pgTable("key_shop", {
  id: varchar("id", { length: 14 }).primaryKey(),
  sku: text("sku").notNull(),
  priceUsd: numeric("price_usd", { precision: 12, scale: 2 }).notNull(),
  keysGranted: integer("keys_granted").notNull(),
  active: boolean("active").notNull().default(true),
  insertedAt,
  updatedAt,
});

export const schema = {
  players,
  emojiSets,
  rooms,
  games,
  guesses,
  goldenRooms,
  revenueLedger,
  walletLedger,
  keyShop,
};
