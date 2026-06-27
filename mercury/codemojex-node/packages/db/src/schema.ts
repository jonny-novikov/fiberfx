import { sql } from "drizzle-orm";
import { pgTable, text, integer, bigint, boolean, timestamp, check, index, uniqueIndex } from "drizzle-orm/pg-core";
import type { GameStatus, GameType, RoomType, Currency } from "@codemojex/types";

// Ecto `timestamps(type: :utc_datetime_usec)` -> timestamptz(6). Column names are snake_case to
// match the Ecto-created database exactly; Drizzle uses each property key as the column name.
const tsUsec = () => timestamp({ withTimezone: true, precision: 6, mode: "string" });

/** Player balances. The non-negative CHECK is the wallet's DB backstop. */
export const players = pgTable(
  "players",
  {
    id: text().primaryKey(),
    name: text().notNull(),
    tg_chat_id: bigint({ mode: "number" }),
    // cm.4: the verified Telegram USER id; nullable, unique-when-present.
    tg_user_id: bigint({ mode: "number" }),
    keys: bigint({ mode: "number" }).notNull().default(0),
    clips: bigint({ mode: "number" }).notNull().default(0),
    diamonds: bigint({ mode: "number" }).notNull().default(0),
    bonus_diamonds: bigint({ mode: "number" }).notNull().default(0),
    locked_diamonds: bigint({ mode: "number" }).notNull().default(0),
    inserted_at: tsUsec().notNull().defaultNow(),
    updated_at: tsUsec().notNull().defaultNow(),
  },
  (t) => [
    check(
      "players_non_negative",
      sql`${t.keys} >= 0 AND ${t.clips} >= 0 AND ${t.diamonds} >= 0 AND ${t.bonus_diamonds} >= 0 AND ${t.locked_diamonds} >= 0`,
    ),
    index("players_tg_chat_id_index").on(t.tg_chat_id),
    uniqueIndex("players_tg_user_id_index").on(t.tg_user_id).where(sql`${t.tg_user_id} IS NOT NULL`),
  ],
);

/** Append-only ledger: one row per balance mutation. */
export const transactions = pgTable(
  "transactions",
  {
    id: text().primaryKey(),
    player: text().notNull(),
    currency: text().$type<Currency>().notNull(),
    delta: bigint({ mode: "number" }).notNull(),
    reason: text().notNull(),
    ref: text(),
    inserted_at: tsUsec().notNull().defaultNow(),
  },
  (t) => [
    index("transactions_player_inserted_at_index").on(t.player, t.inserted_at),
    // cm.5: the buy-in exactly-once guard (partial unique on the buy_in reason).
    uniqueIndex("transactions_buy_in_once_index").on(t.player, t.ref).where(sql`reason = 'buy_in'`),
    index("transactions_ref_reason_index").on(t.ref, t.reason),
  ],
);

/** An emoji set: a sprite grid plus the code subset a room exposes. */
export const emoji_sets = pgTable("emoji_sets", {
  id: text().primaryKey(),
  name: text().notNull(),
  cols: integer().notNull(),
  rows: integer().notNull(),
  cell_size: integer().notNull(),
  sprite_url: text(),
  codes: text().array().notNull().default([]),
  inserted_at: tsUsec().notNull().defaultNow(),
  updated_at: tsUsec().notNull().defaultNow(),
});

/** A room template and its at-most-one active game. */
export const rooms = pgTable(
  "rooms",
  {
    id: text().primaryKey(),
    name: text().notNull(),
    emojiset: text().notNull(),
    type: text().$type<RoomType>().notNull().default("classic"),
    duration_ms: bigint({ mode: "number" }).notNull(),
    seed_pool: bigint({ mode: "number" }).notNull().default(0),
    guess_fee: integer().notNull().default(1),
    free: boolean().notNull().default(false),
    clip_cost: integer().notNull().default(1),
    status: text().notNull().default("waiting"),
    game: text(),
    golden: boolean().notNull().default(false),
    payout_split: integer().array().notNull().default([40, 25, 15, 12, 8]),
    cell_count: integer(),
    // Golden Room levers (cm.5), snapshotted to a game at start. All nullable.
    start_threshold: integer(),
    entry_fee_keys: integer(),
    virtual_deposit: bigint({ mode: "number" }),
    first_movers: integer(),
    entry_fee_revenue_percentage: integer(),
    room_deadline: timestamp({ withTimezone: true, mode: "string" }),
    inserted_at: tsUsec().notNull().defaultNow(),
    updated_at: tsUsec().notNull().defaultNow(),
  },
  (t) => [
    check(
      "rooms_revenue_pct_range",
      sql`${t.entry_fee_revenue_percentage} IS NULL OR (${t.entry_fee_revenue_percentage} >= 0 AND ${t.entry_fee_revenue_percentage} <= 100)`,
    ),
  ],
);

/**
 * A game: one play in a room. `secret`, `commitment` and `nonce` are server-side columns —
 * never serialized to players (see the public DTO in @codemojex/dto).
 */
export const games = pgTable(
  "games",
  {
    id: text().primaryKey(),
    room: text(),
    emojiset: text(),
    type: text().$type<GameType>().notNull().default("classic"),
    feedback: text().notNull().default("score"),
    scoring: text().notNull().default("linear"),
    settlement: text().notNull().default("live"),
    economy: text().notNull().default("winner_take_all"),
    secret: text().array().notNull(),
    cell_codes: text().array().notNull().default([]),
    // blind-mode columns — NULL for classic, written for golden (commit-reveal).
    commitment: text(),
    nonce: text(),
    revealed_ms: bigint({ mode: "number" }),
    top_k: integer().notNull().default(5),
    payout_split: integer().array().notNull().default([40, 25, 15, 12, 8]),
    started_ms: bigint({ mode: "number" }).notNull(),
    // cm.5: nullable — a :gathering game holds it nil until the gather completes.
    ends_ms: bigint({ mode: "number" }),
    prize_pool: bigint({ mode: "number" }).notNull().default(0),
    guess_fee: integer().notNull().default(1),
    free: boolean().notNull().default(false),
    clip_cost: integer().notNull().default(1),
    status: text().$type<GameStatus>().notNull().default("open"),
    golden: boolean().notNull().default(false),
    start_threshold: integer(),
    entry_fee_keys: integer(),
    virtual_deposit: bigint({ mode: "number" }),
    first_movers: integer(),
    entry_fee_revenue_percentage: integer(),
    room_deadline: timestamp({ withTimezone: true, mode: "string" }),
    inserted_at: tsUsec().notNull().defaultNow(),
    updated_at: tsUsec().notNull().defaultNow(),
  },
  (t) => [
    index("games_room_index").on(t.room),
    check("games_type", sql`${t.type} IN ('classic', 'golden')`),
    check(
      "games_status",
      sql`${t.status} IN ('gathering', 'scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')`,
    ),
    check(
      "games_revenue_pct_range",
      sql`${t.entry_fee_revenue_percentage} IS NULL OR (${t.entry_fee_revenue_percentage} >= 0 AND ${t.entry_fee_revenue_percentage} <= 100)`,
    ),
  ],
);

/** One scored attempt. Linear-only: `points` is the sole stored score. Append-only. */
export const guesses = pgTable(
  "guesses",
  {
    id: text().primaryKey(),
    game: text().notNull(),
    player: text().notNull(),
    emojis: text().array().notNull(),
    points: integer().notNull(),
    at_ms: bigint({ mode: "number" }),
    inserted_at: tsUsec().notNull().defaultNow(),
  },
  (t) => [index("guesses_game_player_index").on(t.game, t.player)],
);

export const schema = { players, transactions, emoji_sets, rooms, games, guesses };
