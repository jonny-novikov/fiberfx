// Public read-plane shapes — grounded in @codemojex/admin src/schemas.ts (admin.1).
// Only the operator-safe fields (admin.5-INV2): the privileged answer payload, the
// answer-cell codes, and the bot reply markup are excluded by construction. Kept a
// PRECISE interface (no index signature) so the exclusion check stays meaningful; a
// view maps to a local Record-extending display row before handing it to <Table>.
export interface GameSummary {
  id: string; // GAM branded id
  roomId: string | null; // ROM branded id
  status: string;
  free: boolean;
  guessFee: number | string; // decimal — untyped at the wire
  prizePool: number | string;
  endsMs: number | null;
  insertedAt: string; // ISO
  roomName?: string | null;
}

// The rooms / players read-plane shapes (admin.5.1-D2) — completed to the real
// apps/admin schemas.ts columns; every field is public (rooms and players carry
// no privileged column server-side).
export interface RoomSummary {
  id: string; // ROM branded id
  name: string;
  free: boolean;
  clipCost: number | string; // decimal — untyped at the wire
  durationMs: number | null;
  status: string;
  insertedAt: string; // ISO
}

export interface PlayerSummary {
  id: string; // PLR branded id
  name: string;
  tgUserId: string | number | null;
  clips: number;
  diamonds: number;
  bonusDiamonds: number;
  lockedDiamonds: number;
  keys: number;
  insertedAt: string; // ISO
}

// The detail shapes (admin.5.2-D2) — grounded in @codemojex/admin src/schemas.ts
// (RoomDetail / RoomGameItem / PlayerDetail / GuessSummary). Every declared field
// is a public read-plane column; no privileged field is declared. The ledger is
// provisional server-side, so it stays unknown[] and is rendered defensively.
export interface RoomGameItem {
  id: string; // GAM branded id
  status: string;
  free: boolean;
  prizePool: number | string; // decimal — untyped at the wire
  endsMs: number | null;
  insertedAt: string; // ISO
}

export interface RoomDetail {
  room: RoomSummary;
  games: RoomGameItem[];
}

export interface GuessDetail {
  id: string; // GES branded id
  gameId?: string;
  points: number;
  atMs?: number | null; // epoch ms — untyped at the wire
  insertedAt: string; // ISO
}

export interface PlayerDetail {
  player: PlayerSummary;
  guesses: GuessDetail[];
  ledger: unknown[];
}
