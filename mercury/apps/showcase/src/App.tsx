import { useState } from "react";
import { REGISTRY, type ShowcaseEntry } from "./registry";
import { ComponentPage } from "./shell/ComponentPage";
import { Home } from "./shell/Home";
import { Sidebar } from "./shell/Sidebar";
import { Topbar } from "./shell/Topbar";

const ROUTE_KEY = "mx-showcase.route.v1"; // JSON { group, name, tab }
const THEME_KEY = "mx-showcase.theme.v1"; // "light" | "dark" (plain string — read raw at boot)

type Tab = "stories" | "docs";
type Route = { group: string; name: string; tab: Tab };
type Theme = "light" | "dark";

function readRoute(): Route | null {
  const raw = localStorage.getItem(ROUTE_KEY);
  if (raw === null) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<Route> | null;
    if (parsed && typeof parsed.group === "string" && typeof parsed.name === "string") {
      return { group: parsed.group, name: parsed.name, tab: parsed.tab === "docs" ? "docs" : "stories" };
    }
  } catch {
    // a malformed persisted value degrades to the null route
  }
  return null;
}

function findEntry(route: Route): ShowcaseEntry | null {
  const group = REGISTRY.find((g) => g.key === route.group);
  return group?.entries.find((entry) => entry.name === route.name) ?? null;
}

function groupLabel(key: string): string {
  return REGISTRY.find((g) => g.key === key)?.label ?? key;
}

function applyThemeClass(theme: Theme) {
  document.documentElement.classList.remove("light-theme", "dark-theme");
  document.documentElement.classList.add(theme === "dark" ? "dark-theme" : "light-theme");
}

export function App() {
  const [route, setRouteState] = useState<Route | null>(readRoute);
  const [theme, setTheme] = useState<Theme>(() =>
    localStorage.getItem(THEME_KEY) === "dark" ? "dark" : "light",
  );

  const setRoute = (next: Route) => {
    setRouteState(next);
    localStorage.setItem(ROUTE_KEY, JSON.stringify(next));
  };

  const toggleTheme = () => {
    const next: Theme = theme === "dark" ? "light" : "dark";
    setTheme(next);
    localStorage.setItem(THEME_KEY, next);
    applyThemeClass(next);
  };

  // a persisted route naming an entry the tree no longer carries degrades to Home
  const entry = route === null ? null : findEntry(route);
  const crumb =
    route !== null && entry !== null ? `${groupLabel(route.group)} · ${entry.name}` : "Overview";

  return (
    <div className="showcase-layout">
      <Sidebar
        active={route}
        onSelect={(group, name) => setRoute({ group, name, tab: "stories" })}
      />
      <div className="showcase-main">
        <Topbar crumb={crumb} theme={theme} onToggleTheme={toggleTheme} />
        <main className="showcase-scroll">
          {route !== null && entry !== null ? (
            <ComponentPage entry={entry} tab={route.tab} onTab={(tab) => setRoute({ ...route, tab })} />
          ) : (
            <Home onSelect={(group, name) => setRoute({ group, name, tab: "stories" })} />
          )}
        </main>
      </div>
    </div>
  );
}
