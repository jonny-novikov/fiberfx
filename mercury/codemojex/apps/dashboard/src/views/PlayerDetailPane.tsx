import { useUnit } from "effector-react";
import { Card, DataList, ListRow, ScrollArea, Spinner, Stat } from "@mercury/ui";
import { $playerDetail, $selectedPlayerId, fetchPlayerDetailFx } from "@/api/client";
import type { GuessDetail } from "@/types";

// Defensive timestamp for a guess: atMs is untyped at the wire, so a non-number
// falls back to the always-present insertedAt ISO string.
function guessWhen(g: GuessDetail): string {
  if (typeof g.atMs === "number") return new Date(g.atMs).toLocaleString();
  return new Date(g.insertedAt).toLocaleString();
}

// Defensive preview for a ledger entry — the ledger is unknown[] (provisional
// server-side), so no typed field access; a safe string preview only.
function ledgerPreview(entry: unknown): string {
  if (entry == null) return "—";
  if (typeof entry === "string" || typeof entry === "number" || typeof entry === "boolean") {
    return String(entry);
  }
  try {
    const json = JSON.stringify(entry);
    return json == null ? String(entry) : json.slice(0, 120);
  } catch {
    return String(entry);
  }
}

// The side detail pane (admin.5.2-D4): reads the keyed detail stores via useUnit
// — the store is the seam, no network call in the view (admin.5.2-INV4). Every
// rendered player / guess field is public (admin.5.2-INV2).
export function PlayerDetailPane() {
  const [id, detail, loading] = useUnit([
    $selectedPlayerId,
    $playerDetail,
    fetchPlayerDetailFx.pending,
  ]);

  if (!id) {
    return (
      <Card title="Player detail">
        <p className="dsh-md__empty">Select a player to see balances, guesses, and the ledger.</p>
      </Card>
    );
  }

  if (loading || !detail) {
    return (
      <Card title="Player detail">
        <div className="dsh-md__loading">
          <Spinner label="Loading player detail" />
        </div>
      </Card>
    );
  }

  const { player, guesses, ledger } = detail;
  return (
    <Card title={player.name}>
      <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 12rem)">
        <div className="dsh-md__stats">
          <Stat label="Diamonds" value={player.diamonds} />
          <Stat label="Clips" value={player.clips} />
          <Stat label="Keys" value={player.keys} />
        </div>
        <DataList
          items={[
            { label: "Bonus diamonds", value: String(player.bonusDiamonds) },
            { label: "Locked diamonds", value: String(player.lockedDiamonds) },
            { label: "Telegram", value: player.tgUserId == null ? "—" : String(player.tgUserId) },
            { label: "Created", value: new Date(player.insertedAt).toLocaleString() },
          ]}
        />
        <div className="dsh-md__section">Recent guesses</div>
        {guesses.length === 0 ? (
          <p className="dsh-md__empty">No recent guesses.</p>
        ) : (
          guesses.map((g) => (
            <ListRow
              key={g.id}
              label={g.gameId ?? "guess"}
              description={guessWhen(g)}
              value={`${g.points} pts`}
            />
          ))
        )}
        <div className="dsh-md__section">Ledger</div>
        {ledger.length === 0 ? (
          <p className="dsh-md__empty">No ledger entries.</p>
        ) : (
          ledger.map((entry, i) => (
            <ListRow key={i} label={`Entry ${i + 1}`} description={ledgerPreview(entry)} />
          ))
        )}
      </ScrollArea>
    </Card>
  );
}
