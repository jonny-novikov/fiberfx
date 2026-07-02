import { GROUP_LABEL, type ShowcaseEntry } from "../registry";

type Tab = "stories" | "docs";

type ComponentPageProps = {
  entry: ShowcaseEntry;
  tab: Tab;
  onTab: (tab: Tab) => void;
};

// Stub panels only this rung: neither loadStories nor loadPrompt is called (INV-5).
export function ComponentPage({ entry, tab, onTab }: ComponentPageProps) {
  const label = (GROUP_LABEL as Record<string, string>)[entry.group] ?? entry.group;
  return (
    <article className="showcase-page">
      <header className="showcase-page-header">
        <h2>
          {label} · {entry.name}
        </h2>
      </header>
      <div className="showcase-tabs" role="tablist" aria-label="component surfaces">
        <button
          type="button"
          role="tab"
          className="showcase-tab"
          aria-selected={tab === "stories"}
          onClick={() => onTab("stories")}
        >
          Stories
        </button>
        <button
          type="button"
          role="tab"
          className="showcase-tab"
          aria-selected={tab === "docs"}
          onClick={() => onTab("docs")}
        >
          Docs
        </button>
      </div>
      {tab === "stories" ? (
        <p className="showcase-stub">The live stories surface lands at mx.9.3.</p>
      ) : (
        <p className="showcase-stub">The contract surface lands at mx.9.4.</p>
      )}
    </article>
  );
}
