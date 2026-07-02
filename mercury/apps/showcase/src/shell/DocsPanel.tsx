import { useEffect, useState } from "react";
import type { ReactNode } from "react";
import type { ShowcaseEntry } from "../registry";
import { DOC_CUTS, renderMarkdown, section } from "../lib/markdown";

type DocsState =
  | { status: "no-contract" }
  | { status: "loading" }
  | { status: "ready"; raw: string }
  | { status: "load-error"; message: string };

// FORK-1 RULED Arm A: the view grain is a nested sub-tab row INSIDE the Docs
// tab — view state LOCAL to this panel, reset per entry. The route JSON,
// ROUTE_KEY, the page Tab union, and App.tsx are untouched.
type DocsView = "docs" | "api" | "dodont" | "recipes";

const VIEWS: readonly DocsView[] = ["docs", "api", "dodont", "recipes"];

const VIEW_LABEL: Record<DocsView, string> = {
  docs: "Docs",
  api: "API",
  dodont: "Do/Don't",
  recipes: "Recipes",
};

// One fetch, one raw string, four SELECTIONS over it (INV-2) — a view is a
// cut of the same raw, never a second load and never invented content.
function renderView(raw: string, view: DocsView): ReactNode {
  if (view === "docs") return renderMarkdown(raw);
  const headings =
    view === "api" ? DOC_CUTS.api : view === "dodont" ? DOC_CUTS.dodont : DOC_CUTS.recipes;
  return headings.map((heading) => {
    const slice = section(raw, heading);
    return (
      <div key={heading}>
        {slice === null ? (
          // The explicit absent-state (INV-2): a missing section is stated,
          // never silently skipped and never filled with invented prose.
          <p className="showcase-md-empty">
            This contract has no <em>{heading}</em> section.
          </p>
        ) : (
          renderMarkdown(slice)
        )}
      </div>
    );
  });
}

export function DocsPanel({ entry }: { entry: ShowcaseEntry }): ReactNode {
  // Keyed remount per entry: the docs state AND the local sub-tab view reset
  // together when the selection changes (the Arm-A reset).
  return <DocsPanelBody key={`${entry.group}/${entry.name}`} entry={entry} />;
}

function DocsPanelBody({ entry }: { entry: ShowcaseEntry }): ReactNode {
  const entryKey = `${entry.group}/${entry.name}`;
  const [state, setState] = useState<DocsState>(() =>
    // loadPrompt ABSENT → no-contract, set WITHOUT calling any loader (S-3).
    entry.loadPrompt === undefined ? { status: "no-contract" } : { status: "loading" },
  );
  const [view, setView] = useState<DocsView>("docs");
  useEffect(() => {
    const load = entry.loadPrompt;
    if (load === undefined) return; // no-contract — nothing to fetch
    let alive = true; // the mx.9.3 alive-guard (StoriesPanel shape)
    load().then(
      (raw) => {
        if (alive) setState({ status: "ready", raw });
      },
      (error: unknown) => {
        // A rejected loader is surfaced inline, never swallowed.
        if (alive) {
          setState({
            status: "load-error",
            message: error instanceof Error ? error.message : String(error),
          });
        }
      },
    );
    return () => {
      alive = false;
    };
    // Keyed by the entry identity — only the SELECTED entry's contract loads.
  }, [entryKey]);
  if (state.status === "no-contract") {
    return (
      <p className="showcase-md-empty">
        This component has no contract — no co-located <code>.prompt.md</code>.
      </p>
    );
  }
  if (state.status === "loading") {
    return <p className="showcase-md-loading">Loading contract…</p>;
  }
  if (state.status === "load-error") {
    return (
      <p className="showcase-md-load-error" role="alert">
        Contract failed to load: {state.message}
      </p>
    );
  }
  return (
    <div className="showcase-docs">
      {/* Mirrors the page tab row's tablist a11y shape on its OWN additive
          class so mx.9.5 can skin the two rows distinctly. */}
      <div className="showcase-md-subtabs" role="tablist" aria-label="contract views">
        {VIEWS.map((candidate) => (
          <button
            key={candidate}
            type="button"
            role="tab"
            className="showcase-md-subtab"
            aria-selected={view === candidate}
            onClick={() => setView(candidate)}
          >
            {VIEW_LABEL[candidate]}
          </button>
        ))}
      </div>
      <div className="showcase-md">{renderView(state.raw, view)}</div>
    </div>
  );
}
