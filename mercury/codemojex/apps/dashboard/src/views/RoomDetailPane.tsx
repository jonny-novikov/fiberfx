import { useUnit } from "effector-react";
import { Badge, Button, Card, DataList, ScrollArea, Spinner, Table } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $roomDetail, $selectedRoomId, fetchRoomDetailFx, gameSelected } from "@/api/client";
import type { RoomGameItem } from "@/types";

// The local Record-extending display row — the GamesView precedent (a precise
// interface gets no implicit index signature, so the wire shape maps to an
// all-string row before <Table>).
interface RoomGameRow extends Record<string, unknown> {
  id: string;
  status: string;
  free: string;
  prizePool: string;
  ends: string;
  created: string;
}

// Public read-plane columns only (admin.5.2-INV2) — the room's games carry no
// privileged field on the detail wire. The room -> game navigation rides a
// Column.render action cell (admin.5.3-D4) — Table carries no row-click prop,
// so the barrel is untouched.
const GAME_COLUMNS: Column<RoomGameRow>[] = [
  { key: "id", label: "Game" },
  { key: "status", label: "Status" },
  { key: "free", label: "Free" },
  { key: "prizePool", label: "Prize", align: "right" },
  { key: "ends", label: "Ends", align: "right" },
  { key: "created", label: "Created", align: "right" },
  {
    key: "watch",
    label: "",
    render: (g) => (
      <Button size="sm" variant="ghost" onClick={() => gameSelected(g.id)}>
        Watch
      </Button>
    ),
  },
];

function toGameRow(g: RoomGameItem): RoomGameRow {
  return {
    id: g.id,
    status: g.status,
    free: g.free ? "yes" : "no",
    prizePool: String(g.prizePool),
    ends: g.endsMs == null ? "—" : new Date(g.endsMs).toLocaleString(),
    created: new Date(g.insertedAt).toLocaleString(),
  };
}

// The side detail pane (admin.5.2-D3): reads the keyed detail stores via useUnit
// — the store is the seam, no network call in the view (admin.5.2-INV4).
export function RoomDetailPane() {
  const [id, detail, loading] = useUnit([$selectedRoomId, $roomDetail, fetchRoomDetailFx.pending]);

  if (!id) {
    return (
      <Card title="Room detail">
        <p className="dsh-md__empty">Select a room to see its summary and games.</p>
      </Card>
    );
  }

  if (loading || !detail) {
    return (
      <Card title="Room detail">
        <div className="dsh-md__loading">
          <Spinner label="Loading room detail" />
        </div>
      </Card>
    );
  }

  const { room, games } = detail;
  return (
    <Card title={room.name}>
      <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 12rem)">
        <div className="dsh-md__status">
          <Badge variant={room.status === "open" ? "positive" : "info"}>{room.status}</Badge>
        </div>
        <DataList
          items={[
            { label: "Free", value: room.free ? "yes" : "no" },
            { label: "Clip cost", value: String(room.clipCost) },
            {
              label: "Duration",
              value: room.durationMs == null ? "—" : `${Math.round(room.durationMs / 1000)}s`,
            },
            { label: "Created", value: new Date(room.insertedAt).toLocaleString() },
          ]}
        />
        <div className="dsh-md__section">Games</div>
        {games.length === 0 ? (
          <p className="dsh-md__empty">No games in this room.</p>
        ) : (
          <Table<RoomGameRow>
            columns={GAME_COLUMNS}
            data={games.map(toGameRow)}
            striped
            getRowKey={(g) => g.id}
          />
        )}
      </ScrollArea>
    </Card>
  );
}
