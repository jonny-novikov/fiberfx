import { useEffect, useMemo, useState } from "react";
import { useUnit } from "effector-react";
import { Card, Table, Tabs } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $games, gamesRequested } from "@/api/client";
import type { GameSummary } from "@/types";

// A precise GameSummary interface does NOT satisfy `Record<string, unknown>`
// (a TS interface gets no implicit index signature), so the live rows map to this
// local display row before <Table> — the economy SplitLadderTable precedent.
interface GameRow extends Record<string, unknown> {
  id: string;
  room: string;
  status: string;
  prize: string;
  ends: string;
}

type Filter = "all" | "live" | "ended";
const FILTERS: { label: string; value: Filter }[] = [
  { label: "All", value: "all" },
  { label: "Live", value: "live" },
  { label: "Ended", value: "ended" },
];

// Public read-plane columns only (admin.5-INV2) — operator-safe fields, never the
// privileged answer payload or the answer-cell codes.
const COLUMNS: Column<GameRow>[] = [
  { key: "id", label: "Game" },
  { key: "room", label: "Room" },
  { key: "status", label: "Status" },
  { key: "prize", label: "Prize", align: "right" },
  { key: "ends", label: "Ends", align: "right" },
];

function toRow(g: GameSummary): GameRow {
  return {
    id: g.id,
    room: g.roomName ?? g.roomId ?? "—",
    status: g.status,
    prize: String(g.prizePool),
    ends: g.endsMs == null ? "—" : new Date(g.endsMs).toLocaleString(),
  };
}

export function GamesView() {
  const games = useUnit($games); // the store is the seam — no fetch in the view
  const [filter, setFilter] = useState<Filter>("all");

  // Fire the one mount request; the raw network call stays confined to api/client.ts.
  useEffect(() => {
    gamesRequested();
  }, []);

  // "Live" / "Ended" derive only from `endsMs` (already in the public shape) — no
  // invented server filter param; "All" preserves the full live list (admin.5-AS4).
  const rows = useMemo(() => {
    const now = Date.now();
    return games
      .filter((g) => {
        if (filter === "all") return true;
        const ended = g.endsMs != null && g.endsMs < now;
        return filter === "ended" ? ended : !ended;
      })
      .map(toRow);
  }, [games, filter]);

  return (
    <Card title="Games">
      <div className="dsh-desk__bar">
        <Tabs<Filter> tabs={FILTERS} value={filter} onChange={setFilter} variant="pills" />
        <span className="dsh-desk__count">{rows.length} shown</span>
      </div>
      <Table<GameRow> columns={COLUMNS} data={rows} striped getRowKey={(r) => r.id} />
    </Card>
  );
}
