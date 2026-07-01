import { useEffect, useMemo, useState } from "react";
import { useUnit } from "effector-react";
import { Card, Pagination, Search, Table, Tabs } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $rooms, roomsRequested } from "@/api/client";
import type { RoomSummary } from "@/types";
import { usePagedList } from "@/lib/usePagedList";

// A precise RoomSummary interface does NOT satisfy `Record<string, unknown>`
// (a TS interface gets no implicit index signature), so the live rows map to
// this local display row before <Table> — the GamesView precedent.
interface RoomRow extends Record<string, unknown> {
  id: string;
  name: string;
  status: string;
  free: string;
  clipCost: string;
  duration: string;
  created: string;
}

type Filter = "all" | "open" | "closed";
const FILTERS: { label: string; value: Filter }[] = [
  { label: "All", value: "all" },
  { label: "Open", value: "open" },
  { label: "Closed", value: "closed" },
];

// Public read-plane columns only (admin.5.1-INV2) — rooms carry no privileged
// server-side field.
const COLUMNS: Column<RoomRow>[] = [
  { key: "id", label: "Room" },
  { key: "name", label: "Name" },
  { key: "status", label: "Status" },
  { key: "free", label: "Free" },
  { key: "clipCost", label: "Clip cost", align: "right" },
  { key: "duration", label: "Duration", align: "right" },
  { key: "created", label: "Created", align: "right" },
];

function toRow(r: RoomSummary): RoomRow {
  return {
    id: r.id,
    name: r.name,
    status: r.status,
    free: r.free ? "yes" : "no",
    clipCost: String(r.clipCost),
    duration: r.durationMs == null ? "—" : `${Math.round(r.durationMs / 1000)}s`,
    created: new Date(r.insertedAt).toLocaleString(),
  };
}

const matchRoom = (r: RoomSummary, q: string) =>
  r.name.toLowerCase().includes(q) || r.id.toLowerCase().includes(q);

export function RoomsView() {
  const rooms = useUnit($rooms); // the store is the seam — no fetch in the view
  const [status, setStatus] = useState<Filter>("all");

  // Fire the one mount request; the raw network call stays confined to api/client.ts.
  useEffect(() => {
    roomsRequested();
  }, []);

  // All/Open/Closed derive from the public `status` field — no server filter param.
  const byStatus = useMemo(
    () => (status === "all" ? rooms : rooms.filter((r) => r.status === status)),
    [rooms, status],
  );

  const list = usePagedList(byStatus, matchRoom, status);
  const rows = list.paged.map(toRow);

  return (
    <Card title="Rooms">
      <div className="dsh-desk__bar">
        <div className="dsh-desk__tools">
          <Tabs<Filter> tabs={FILTERS} value={status} onChange={setStatus} variant="pills" />
          <Search value={list.query} onChange={list.setQuery} placeholder="Search rooms" />
        </div>
        <span className="dsh-desk__count">{list.filteredCount} shown</span>
      </div>
      <Table<RoomRow> columns={COLUMNS} data={rows} striped getRowKey={(r) => r.id} />
      <div className="dsh-desk__pager">
        <Pagination
          page={list.page}
          count={list.pageCount}
          onPageChange={list.setPage}
          caption={list.caption}
        />
      </div>
    </Card>
  );
}
