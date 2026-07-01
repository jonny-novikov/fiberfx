import { useState } from "react";
import { useUnit } from "effector-react";
import { Menubar, ScrollArea, cx } from "@mercury/ui";
import type { MenubarMenu } from "@mercury/ui";
import { setTheme } from "@mercury/effector";
import { $health, gamesRequested } from "@/api/client";
import type { Health } from "@/api/client";
import { GamesView } from "@/views/GamesView";

// Ruled admin.5-F1 -> Arm B: the operator shell frame is composed LOCALLY here from
// @mercury/ui pieces (Menubar / ScrollArea) + the app's own token-styled chrome —
// no new @mercury/ui primitive, the barrel untouched. The shared AppShell (± Sidebar
// / Topbar) extraction is ruled-DEFERRED to a later /mercury-ship rung once a second
// operator console (admin.6+) proves the pattern (rule of three).

type Desk = "games" | "rooms" | "players";
const NAV: { label: string; value: Desk; enabled: boolean; hint?: string }[] = [
  { label: "Games", value: "games", enabled: true },
  { label: "Rooms", value: "rooms", enabled: false, hint: "admin.6" },
  { label: "Players", value: "players", enabled: false, hint: "admin.6" },
];

const HEALTH_LABEL: Record<Health, string> = {
  idle: "idle",
  loading: "syncing…",
  ok: "connected",
  error: "unreachable",
};

// Operator actions — a topbar Menubar composed from @mercury/ui. Refresh re-runs the
// one fetch effect; the theme radios drive @mercury/effector's setTheme.
const MENUS: MenubarMenu[] = [
  {
    label: "Console",
    items: [
      { type: "item", label: "Refresh games", shortcut: "R", onSelect: () => gamesRequested() },
      { type: "separator" },
      { type: "label", label: "Theme" },
      { type: "radio", group: "theme", value: "dark", label: "Dark", checked: true, onSelect: () => setTheme("dark") },
      { type: "radio", group: "theme", value: "light", label: "Light", onSelect: () => setTheme("light") },
    ],
  },
];

export function App() {
  const [desk, setDesk] = useState<Desk>("games");
  const health = useUnit($health);
  return (
    <div className="dsh">
      <header className="dsh-head">
        <span className="dsh-head__brand">Codemojex · Operator Console</span>
        <Menubar menus={MENUS} />
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
                  if (n.enabled) setDesk(n.value);
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
          </ScrollArea>
        </main>
      </div>
    </div>
  );
}
