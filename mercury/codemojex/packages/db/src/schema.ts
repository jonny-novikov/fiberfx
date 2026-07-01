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
// The wallet is the player row: three currencies (keys · clips · diamonds), the
// diamond rail carrying bonus + locked sub-balances. Every balance is bigint and
// non-negative (a DB CHECK backstops the wallet). Mutated atomically through
// Codemojex.Wallet. Telegram identity is carried as `tg_user_id` and `tg_chat_id`.
export const players = pgTable(
  "players",
  {
    id: id<PlayerId>("id").primaryKey(),
    name: text("name").notNull(),
    tgUserId: bigint("tg_user_id", { mode: "number" }),
    tgChatId: bigint("tg_chat_id", { mode: "number" }),

    keys: bigint("keys", { mode: "number" }).notNull().default(0),
    clips: bigint("clips", { mode: "number" }).notNull().default(0),
    diamonds: bigint("diamonds", { mode: "number" }).notNull().default(0),
    bonusDiamonds: bigint("bonus_diamonds", { mode: "number" }).notNull().default(0),
    lockedDiamonds: bigint("locked_diamonds", { mode: "number" }).notNull().default(0),

    insertedAt,
    updatedAt,
  },
  (t) => [index("players_tg_chat_id_idx").on(t.tgChatId)],
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
// A room templates games. `status` is a plain string under a CHECK constraint
// (not a pg enum); `emojiset` holds an EmojiSetId string. The golden levers below
// are snapshotted room→game for the tournament tier (the `golden_rooms` migration).
export const rooms = pgTable(
  "rooms",
  {
    id: id<RoomId>("id").primaryKey(),
    name: text("name").notNull(),
    emojiset: text("emojiset").notNull(),
    type: text("type").notNull().default("classic"),
    durationMs: bigint("duration_ms", { mode: "number" }).notNull(),
    seedPool: bigint("seed_pool", { mode: "number" }).notNull().default(0),
    guessFee: integer("guess_fee").notNull().default(1),
    free: boolean("free").notNull().default(false),
    clipCost: integer("clip_cost").notNull().default(1),
    status: text("status").notNull().default("waiting"),
    game: text("game"),
    golden: boolean("golden").notNull().default(false),
    payoutSplit: integer("payout_split").array().notNull().default([40, 25, 15, 12, 8]),
    cellCount: integer("cell_count"),

    // golden levers (the `golden_rooms` migration; nullable = not a golden config)
    startThreshold: integer("start_threshold"),
    entryFeeKeys: integer("entry_fee_keys"),
    virtualDeposit: bigint("virtual_deposit", { mode: "number" }),
    firstMovers: integer("first_movers"),
    entryFeeRevenuePercentage: integer("entry_fee_revenue_percentage"),
    roomDeadline: timestamp("room_deadline", { withTimezone: true, mode: "date" }),

    insertedAt,
    updatedAt,
  },
  (t) => [index("rooms_status_idx").on(t.status)],
);

// ── games ────────────────────────────────────────────────────────────────────
// The playable entity. `room` is a nullable RoomId string (not a FK, not
// `room_id`); `status`/`type` are plain strings under CHECK constraints. `secret`
// and `cell_codes` are the server-side secrets (string arrays) — present here but
// held OUT of every admin response by the read-plane schemas.
export const games = pgTable(
  "games",
  {
    id: id<GameId>("id").primaryKey(),
    room: id<RoomId>("room"),
    emojiset: text("emojiset"),
    type: text("type").notNull().default("classic"),
    feedback: text("feedback").notNull().default("score"),
    scoring: text("scoring").notNull().default("linear"),
    settlement: text("settlement").notNull().default("live"),
    economy: text("economy").notNull().default("winner_take_all"),

    // server-side secrets — never selected by a player- or operator-facing read
    secret: text("secret").array().notNull(),
    cellCodes: text("cell_codes").array().notNull().default([]),

    // commit-reveal (golden games only; NULL + inert for a classic game)
    commitment: text("commitment"),
    nonce: text("nonce"),
    revealedMs: bigint("revealed_ms", { mode: "number" }),

    topK: integer("top_k").notNull().default(5),
    payoutSplit: integer("payout_split").array().notNull().default([40, 25, 15, 12, 8]),
    startedMs: bigint("started_ms", { mode: "number" }).notNull(),
    endsMs: bigint("ends_ms", { mode: "number" }),
    prizePool: bigint("prize_pool", { mode: "number" }).notNull().default(0),
    guessFee: integer("guess_fee").notNull().default(1),
    free: boolean("free").notNull().default(false),
    clipCost: integer("clip_cost").notNull().default(1),
    status: text("status").notNull().default("open"),
    golden: boolean("golden").notNull().default(false),

    // golden levers (the `golden_rooms` migration; snapshotted room→game)
    startThreshold: integer("start_threshold"),
    entryFeeKeys: integer("entry_fee_keys"),
    virtualDeposit: bigint("virtual_deposit", { mode: "number" }),
    firstMovers: integer("first_movers"),
    entryFeeRevenuePercentage: integer("entry_fee_revenue_percentage"),
    roomDeadline: timestamp("room_deadline", { withTimezone: true, mode: "date" }),

    insertedAt,
    updatedAt,
  },
  (t) => [
    index("games_room_idx").on(t.room),
    index("games_status_idx").on(t.status),
  ],
);

// ── guesses ──────────────────────────────────────────────────────────────────
// Append-only, written by the scoring consumer (the single authority). Linear
// scoring only: `points` is the sole score (no tier/percentage). `inserted_at`
// only — a guess is never updated.
export const guesses = pgTable(
  "guesses",
  {
    id: id<GuessId>("id").primaryKey(),
    game: id<GameId>("game").notNull(),
    player: id<PlayerId>("player").notNull(),
    emojis: text("emojis").array().notNull(),
    points: integer("points").notNull(),
    atMs: bigint("at_ms", { mode: "number" }),
    insertedAt,
  },
  (t) => [index("guesses_game_player_idx").on(t.game, t.player)],
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
