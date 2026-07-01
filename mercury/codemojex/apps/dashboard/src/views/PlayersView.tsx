import { useEffect } from "react";
import { useUnit } from "effector-react";
import { Button, Card, Pagination, Search, Table } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $players, playerSelected, playersRequested } from "@/api/client";
import type { PlayerSummary } from "@/types";
import { usePagedList } from "@/lib/usePagedList";
import { PlayerDetailPane } from "@/views/PlayerDetailPane";

// The local Record-extending display row — the GamesView precedent.
interface PlayerRow extends Record<string, unknown> {
  id: string;
  name: string;
  diamonds: string;
  clips: string;
  keys: string;
  created: string;
}

// Public read-plane columns only (admin.5.1-INV2) — every player column is public.
// Selection rides a Column.render action cell (admin.5.2-D4) — Table carries no
// row-click prop, so the barrel is untouched.
const COLUMNS: Column<PlayerRow>[] = [
  { key: "id", label: "Player" },
  { key: "name", label: "Name" },
  { key: "diamonds", label: "Diamonds", align: "right" },
  { key: "clips", label: "Clips", align: "right" },
  { key: "keys", label: "Keys", align: "right" },
  { key: "created", label: "Created", align: "right" },
  {
    key: "open",
    label: "",
    render: (r) => (
      <Button size="sm" variant="ghost" onClick={() => playerSelected(r.id)}>
        View
      </Button>
    ),
  },
];

function toRow(p: PlayerSummary): PlayerRow {
  return {
    id: p.id,
    name: p.name,
    diamonds: String(p.diamonds),
    clips: String(p.clips),
    keys: String(p.keys),
    created: new Date(p.insertedAt).toLocaleString(),
  };
}

const matchPlayer = (p: PlayerSummary, q: string) =>
  p.name.toLowerCase().includes(q) || p.id.toLowerCase().includes(q);

export function PlayersView() {
  const players = useUnit($players); // the store is the seam — no fetch in the view

  // Fire the one mount request; the raw network call stays confined to api/client.ts.
  useEffect(() => {
    playersRequested();
  }, []);

  const list = usePagedList(players, matchPlayer);
  const rows = list.paged.map(toRow);

  // The master-detail layout (admin.5.2-D5): the narrowed list region beside the
  // side detail pane, app-local dsh-md* chrome.
  return (
    <div className="dsh-md">
      <div className="dsh-md__list">
        <Card title="Players">
          <div className="dsh-desk__bar">
            <div className="dsh-desk__tools">
              <Search value={list.query} onChange={list.setQuery} placeholder="Search players" />
            </div>
            <span className="dsh-desk__count">{list.filteredCount} shown</span>
          </div>
          <Table<PlayerRow> columns={COLUMNS} data={rows} striped getRowKey={(r) => r.id} />
          <div className="dsh-desk__pager">
            <Pagination
              page={list.page}
              count={list.pageCount}
              onPageChange={list.setPage}
              caption={list.caption}
            />
          </div>
        </Card>
      </div>
      <aside className="dsh-md__pane">
        <PlayerDetailPane />
      </aside>
    </div>
  );
}
