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

// Stubs for admin.6 (rooms / players desks) — shaped now, filled then.
export interface RoomSummary {
  id: string;
  name: string;
  free: boolean;
  status: string;
  insertedAt: string;
}

export interface PlayerSummary {
  id: string;
  name: string;
  diamonds: number;
  keys: number;
  insertedAt: string;
}
