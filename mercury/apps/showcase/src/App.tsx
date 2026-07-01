import { useEffect, useState } from "react";
import { Icon, type IconName } from "@mercury/ui";
import { toggleTheme, useTheme } from "@mercury/effector";
import { Overview } from "./routes/Overview";
import { Overlays } from "./routes/Overlays";

// The foundation IA (mx.7.4 §F.2). The full Foundations / Components / Patterns
// reference is deferred to mx.9 (§F.3); the nav-group shape is kept so those
// routes have a home to grow into.
type RouteKey = "overview" | "overlays";

interface NavItem {
  k: RouteKey;
  t: string;
  icon: IconName;
}

const NAV: { group: string; items: NavItem[] }[] = [
  { group: "Getting started", items: [{ k: "overview", t: "Overview", icon: "home" }] },
  { group: "Components", items: [{ k: "overlays", t: "Overlays", icon: "star" }] },
];

const ROUTES: Record<RouteKey, { title: string; render: () => React.ReactNode }> = {
  overview: { title: "Overview", render: () => <Overview /> },
  overlays: { title: "Overlays", render: () => <Overlays /> },
};

function Sidebar({ route, go }: { route: RouteKey; go: (k: RouteKey) => void }) {
  return (
    <aside className="sc-sidebar">
      <div className="sc-brand">
        <div className="sc-brand-mark" aria-hidden />
        <div className="sc-brand-text">
          <div className="sc-brand-name">mercury</div>
          <div className="sc-brand-ver">Design system · v2.4</div>
        </div>
      </div>

      {NAV.map((g) => (
        <div key={g.group} className="sc-nav-group">
          <div className="sc-group-label">{g.group}</div>
          {g.items.map((it) => (
            <button
              key={it.k}
              type="button"
              className={`sc-link${route === it.k ? " is-active" : ""}`}
              aria-current={route === it.k ? "page" : undefined}
              onClick={() => go(it.k)}
            >
              <Icon name={it.icon} size={16} />
              <span>{it.t}</span>
            </button>
          ))}
        </div>
      ))}
    </aside>
  );
}

function Topbar({ crumb }: { crumb: string }) {
  const theme = useTheme();
  const dark = theme === "dark";
  return (
    <header className="sc-topbar">
      <div className="sc-crumb">{crumb}</div>
      <div className="sc-topbar-spacer" />
      <button
        type="button"
        className="sc-theme-toggle"
        aria-pressed={dark}
        aria-label={`Switch to ${dark ? "light" : "dark"} theme`}
        onClick={() => toggleTheme()}
      >
        <Icon name={dark ? "star" : "bolt"} size={14} />
        <span>{dark ? "Dark" : "Light"}</span>
      </button>
    </header>
  );
}

export function App() {
  const [route, setRoute] = useState<RouteKey>(() => {
    const saved = localStorage.getItem("mercury.showcase.route");
    return saved === "overlays" || saved === "overview" ? saved : "overview";
  });

  useEffect(() => {
    localStorage.setItem("mercury.showcase.route", route);
    window.scrollTo({ top: 0 });
  }, [route]);

  const active = ROUTES[route];

  return (
    <div className="sc-app">
      <Sidebar route={route} go={setRoute} />
      <main className="sc-main">
        <Topbar crumb={active.title} />
        <div className="sc-page">{active.render()}</div>
      </main>
    </div>
  );
}
