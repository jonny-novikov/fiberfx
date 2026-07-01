import { useEffect } from "react";
import { useUnit } from "effector-react";
import { Badge, Button, Card, DataList, ListRow, ScrollArea, Spinner, Stat, Table } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import {
  $gameDetail,
  $selectedGameId,
  fetchGameDetailFx,
  gameDeselected,
  gamePollTicked,
} from "@/api/client";
import type { BoardEntry, GameGuessItem } from "@/types";

// The pinned near-live cadence (admin.5.3-D3) — conservative on the read plane.
const POLL_MS = 5000;

// The local Record-extending display row — the GamesView precedent (a precise
// interface gets no implicit index signature, so the wire shape maps to an
// all-string row before <Table>).
interface BoardRow extends Record<string, unknown> {
  player: string;
  score: string;
}

// Public read-plane columns only (admin.5.3-INV2) — the board carries player
// ids and scores, nothing privileged.
const BOARD_COLUMNS: Column<BoardRow>[] = [
  { key: "player", label: "Player" },
  { key: "score", label: "Score", align: "right" },
];

function toBoardRow(b: BoardEntry): BoardRow {
  return { player: b.player, score: String(b.score) };
}

// Defensive timestamp for a guess: atMs is untyped at the wire, so a non-number
// falls back to the always-present insertedAt ISO string (the PlayerDetailPane
// precedent).
function guessWhen(g: GameGuessItem): string {
  if (typeof g.atMs === "number") return new Date(g.atMs).toLocaleString();
  return new Date(g.insertedAt).toLocaleString();
}

// The spectator split (admin.5.3-D5, F3 -> Arm A): the game pane (summary +
// score-descending board) beside the events pane (guesses newest-first),
// composed locally from Card + ScrollArea — no new @mercury/ui primitive
// (admin.5.3-INV3). The view reads $gameDetail via useUnit only — the store is
// the seam (admin.5.3-INV4): the later engine spectator channel model samples
// into the SAME store and retires the poll with no rewrite here.
export function GameSpectatorView() {
  const [id, detail, pending] = useUnit([$selectedGameId, $gameDetail, fetchGameDetailFx.pending]);

  // ONE interval owns the poll (admin.5.3-INV6): back-to-room, room deselect,
  // and desk switch each unmount this view, so the cleanup is the structural
  // stop; a tick with no selected id fires no request (the guarded sample in
  // the client). A poll refresh replaces the detail in place — no blanking.
  useEffect(() => {
    const t = setInterval(() => gamePollTicked(), POLL_MS);
    return () => clearInterval(t);
  }, []);

  if (!detail) {
    return (
      <div className="dsh-watch">
        <div className="dsh-watch__head">
          <Button size="sm" variant="ghost" onClick={() => gameDeselected()}>
            Back to room
          </Button>
          <span className="dsh-watch__title">{id ?? "Game"}</span>
        </div>
        <Card title="Game">
          {pending ? (
            <div className="dsh-md__loading">
              <Spinner label="Loading game detail" />
            </div>
          ) : (
            <p className="dsh-md__empty">No game selected.</p>
          )}
        </Card>
      </div>
    );
  }

  const { game, board, guesses } = detail;
  const boardRows = [...board].sort((a, b) => b.score - a.score).map(toBoardRow);
  const feed = [...guesses].sort((a, b) => (a.insertedAt < b.insertedAt ? 1 : -1));

  return (
    <div className="dsh-watch">
      <div className="dsh-watch__head">
        <Button size="sm" variant="ghost" onClick={() => gameDeselected()}>
          Back to room
        </Button>
        <span className="dsh-watch__title">{game.id}</span>
      </div>
      <div className="dsh-watch__split">
        <Card title="Game">
          <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 16rem)">
            <div className="dsh-md__status">
              <Badge variant={game.status === "open" ? "positive" : "info"}>{game.status}</Badge>
            </div>
            <div className="dsh-md__stats">
              <Stat label="Prize pool" value={String(game.prizePool)} />
              <Stat label="Guess fee" value={String(game.guessFee)} />
            </div>
            <DataList
              items={[
                { label: "Game", value: game.id },
                { label: "Room", value: game.roomName ?? game.roomId ?? "—" },
                { label: "Free", value: game.free ? "yes" : "no" },
                {
                  label: "Ends",
                  value: game.endsMs == null ? "—" : new Date(game.endsMs).toLocaleString(),
                },
                { label: "Created", value: new Date(game.insertedAt).toLocaleString() },
              ]}
            />
            <div className="dsh-md__section">Board</div>
            {boardRows.length === 0 ? (
              <p className="dsh-md__empty">No scores yet.</p>
            ) : (
              <Table<BoardRow>
                columns={BOARD_COLUMNS}
                data={boardRows}
                striped
                getRowKey={(r) => r.player}
              />
            )}
          </ScrollArea>
        </Card>
        <Card title="Events">
          <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 16rem)">
            {feed.length === 0 ? (
              <p className="dsh-md__empty">No guesses yet.</p>
            ) : (
              feed.map((g) => (
                <ListRow key={g.id} label={g.id} description={guessWhen(g)} value={`${g.points} pts`} />
              ))
            )}
          </ScrollArea>
        </Card>
      </div>
    </div>
  );
}
