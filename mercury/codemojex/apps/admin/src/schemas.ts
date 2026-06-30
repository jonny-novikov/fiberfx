/**
 * TypeBox route schemas. Each drives validation, serialization, and the static
 * type from one definition. The game schemas list only public columns and omit
 * the secret and the keyboard snapshot, so fast-json-stringify strips them at the
 * wire even if a query ever selects them — withholding by serializer contract.
 */
import { Type, Nullable } from "@echo/core";
import { CM } from "@codemojex/domain";

// Branded-id field schemas (pattern-checked; the authoritative decode is @echo/fx).
const RomId = CM.idSchema("ROM");
const GamId = CM.idSchema("GAM");
const PlrId = CM.idSchema("PLR");
const GesId = CM.idSchema("GES");

// Uncertain numeric / decimal / bigint / jsonb columns pass through untyped but
// are still listed, so the strip-unknown behavior holds for the fields we omit.
const Loose = Type.Any();
const Ts = Type.Any(); // a Date, serialized via its ISO form

// ---- params / query / body ----
export const RoomParams = Type.Object({ id: RomId });
export const GameParams = Type.Object({ id: GamId });
export const PlayerParams = Type.Object({ id: PlrId });
export const GamesQuery = Type.Object({ status: Type.Optional(Type.String()) });
export const PlayersQuery = Type.Object({ q: Type.Optional(Type.String()) });
export const RoomStatusBody = Type.Object({
  status: Type.Union([Type.Literal("open"), Type.Literal("closed")]),
});

// ---- responses ----
export const ErrorResponse = Type.Object({ error: Type.String() });

export const RoomSummary = Type.Object({
  id: RomId,
  name: Type.String(),
  free: Type.Boolean(),
  clipCost: Loose,
  durationMs: Loose,
  status: Type.String(),
  insertedAt: Ts,
});
export const RoomsList = Type.Array(RoomSummary);

const RoomGameItem = Type.Object({
  id: GamId,
  status: Type.String(),
  free: Type.Boolean(),
  prizePool: Loose,
  endsMs: Loose,
  insertedAt: Ts,
});
export const RoomDetail = Type.Object({
  room: RoomSummary,
  games: Type.Array(RoomGameItem),
});

// Public game shape — note: no `secret`, no `keyboard`.
export const GameSummary = Type.Object({
  id: GamId,
  roomId: RomId,
  status: Type.String(),
  free: Type.Boolean(),
  guessFee: Loose,
  prizePool: Loose,
  prizeUsd: Loose,
  endsMs: Loose,
  totals: Loose,
  insertedAt: Ts,
  roomName: Type.Optional(Nullable(Type.String())),
});
export const GamesList = Type.Array(GameSummary);

export const BoardEntry = Type.Object({
  player: Type.String(),
  score: Type.Integer(),
});

export const GuessSummary = Type.Object({
  id: GesId,
  gameId: Type.Optional(GamId),
  playerId: Type.Optional(PlrId),
  percentage: Loose,
  effort: Type.Optional(Loose),
  score: Loose,
  insertedAt: Ts,
});

export const GameDetail = Type.Object({
  game: GameSummary,
  board: Type.Array(BoardEntry),
  guesses: Type.Array(GuessSummary),
});

export const PlayerSummary = Type.Object({
  id: PlrId,
  name: Type.String(),
  tgUserId: Loose,
  clips: Type.Integer(),
  diamonds: Type.Integer(),
  availableDiamonds: Type.Integer(),
  bonusDiamonds: Type.Integer(),
  lockedDiamonds: Type.Integer(),
  keys: Type.Integer(),
  availableKeys: Type.Integer(),
  insertedAt: Ts,
});
export const PlayersList = Type.Array(PlayerSummary);

export const RoomStatusResult = Type.Object({
  id: RomId,
  status: Type.String(),
});

export const PlayerDetail = Type.Object({
  player: PlayerSummary,
  guesses: Type.Array(GuessSummary),
  ledger: Type.Array(Type.Any()),
});
