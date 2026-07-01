import { useMemo, useState } from "react";
import { useUnit } from "effector-react";
import { Menubar, ScrollArea, cx } from "@mercury/ui";
import type { MenubarMenu } from "@mercury/ui";
import { setTheme } from "@mercury/effector";
import {
  $health,
  gamesRequested,
  playerDeselected,
  playersRequested,
  roomDeselected,
  roomsRequested,
} from "@/api/client";
import type { Health } from "@/api/client";
import { GamesView } from "@/views/GamesView";
import { PlayersView } from "@/views/PlayersView";
import { RoomsView } from "@/views/RoomsView";

// Ruled admin.5-F1 -> Arm B: the operator shell frame is composed LOCALLY here from
// @mercury/ui pieces (Menubar / ScrollArea) + the app's own token-styled chrome —
// no new @mercury/ui primitive, the barrel untouched. The shared AppShell (± Sidebar
// / Topbar) extraction is ruled-DEFERRED to a later /mercury-ship rung once a second
// operator console (admin.6+) proves the pattern (rule of three).

type Desk = "games" | "rooms" | "players";
const NAV: { label: string; value: Desk; enabled: boolean; hint?: string }[] = [
  { label: "Games", value: "games", enabled: true },
  { label: "Rooms", value: "rooms", enabled: true },
  { label: "Players", value: "players", enabled: true },
];

const HEALTH_LABEL: Record<Health, string> = {
  idle: "idle",
  loading: "syncing…",
  ok: "connected",
  error: "unreachable",
};

// Operator actions — a topbar Menubar composed from @mercury/ui. Refresh is
// desk-aware (admin.5.1-D5): it fires the ACTIVE desk's request event; the theme
// radios drive @mercury/effector's setTheme.
const REFRESH: Record<Desk, () => void> = {
  games: () => gamesRequested(),
  rooms: () => roomsRequested(),
  players: () => playersRequested(),
};

function buildMenus(desk: Desk): MenubarMenu[] {
  return [
    {
      label: "Console",
      items: [
        { type: "item", label: `Refresh ${desk}`, shortcut: "R", onSelect: () => REFRESH[desk]() },
        { type: "separator" },
        { type: "label", label: "Theme" },
        { type: "radio", group: "theme", value: "dark", label: "Dark", checked: true, onSelect: () => setTheme("dark") },
        { type: "radio", group: "theme", value: "light", label: "Light", onSelect: () => setTheme("light") },
      ],
    },
  ];
}

export function App() {
  const [desk, setDesk] = useState<Desk>("games");
  const health = useUnit($health);
  const menus = useMemo(() => buildMenus(desk), [desk]);
  return (
    <div className="dsh">
      <header className="dsh-head">
        <span className="dsh-head__brand">Codemojex · Operator Console</span>
        <Menubar menus={menus} />
        <span className="dsh-head__status" data-state={health}>
          <span className="dsh-head__dot" aria-hidden="true" />
          {HEALTH_LABEL[health]}
        </span>
      </header>
      <div className="dsh-body">
        <aside className="dsh-rail">
          <nav className="dsh-nav" aria-label="Operator desks">
            {NAV.map((n) => (
              <button
                key={n.value}
                type="button"
                className={cx("dsh-nav__item", desk === n.value && "is-active")}
                aria-current={desk === n.value ? "page" : undefined}
                disabled={!n.enabled}
                title={n.hint ? `Arrives in ${n.hint}` : undefined}
                onClick={() => {
                  if (!n.enabled || n.value === desk) return;
                  // Desk switch deselects (admin.5.2-D5) — a stale detail pane
                  // never shows on the wrong desk.
                  roomDeselected();
                  playerDeselected();
                  setDesk(n.value);
                }}
              >
                <span>{n.label}</span>
                {n.hint && <span className="dsh-nav__hint">{n.hint}</span>}
              </button>
            ))}
          </nav>
        </aside>
        <main className="dsh-main">
          <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 8.5rem)">
            {desk === "games" && <GamesView />}
            {desk === "rooms" && <RoomsView />}
            {desk === "players" && <PlayersView />}
          </ScrollArea>
        </main>
      </div>
    </div>
  );
}
