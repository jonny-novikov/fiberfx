// The Engine<->board contract. GameLive sends these props (from Codemojex.View);
// the board sends "submit_guess"/"lock"/"unlock" back over bridge.pushEvent. Keep
// this file and GameLive.board_props/3 in lockstep across an edge swap.

export type Code = string; // "XXYY" — column,row, two digits each (Codemojex.EmojiSet)

export interface EmojiSet {
  id: string;
  sprite_url: string | null;
  cell_size: number;
  cols: number;
  rows: number;
  codes: Code[];
}

export interface GameView {
  game: string; // GAM
  room: string | null; // ROM
  emojiset: EmojiSet | null;
  ends_ms: number | null;
  prize_pool: number;
  prize_usd: number | string;
  guess_fee: number;
  free: boolean;
  status: "open" | "gathering" | "revealing" | "settled" | "voided" | string;
  totals?: { players?: number; attempts?: number; best?: number; best_pct?: number };
  gather?: { paid: number; threshold: number | null };
  commitment?: string;
}

export interface LeaderRow {
  player: string; // PLR
  name: string;
  score: number;
  is_me: boolean;
}

export interface HistoryRow {
  emojis: Code[];
  points?: number; // withheld for a golden game pre-reveal
  at_ms: number;
}

export interface BoardProps {
  view: GameView;
  leaderboard: LeaderRow[];
  history: HistoryRow[];
  me: string; // PLR
}

export interface Bridge {
  pushEvent: (event: string, payload: unknown) => void;
  onServerEvent: (cb: (name: string, payload: any) => void) => () => void;
}
