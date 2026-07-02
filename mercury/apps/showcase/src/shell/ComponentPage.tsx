import { StoriesPanel } from "../lib/storyRender";
import { GROUP_LABEL, type ShowcaseEntry } from "../registry";

type Tab = "stories" | "docs";

type ComponentPageProps = {
  entry: ShowcaseEntry;
  tab: Tab;
  onTab: (tab: Tab) => void;
};

// Stories is live (mx.9.3): StoriesPanel lazy-loads ONLY the selected entry's
// module (INV-5). Docs stays a stub — loadPrompt is not called until mx.9.4.
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
        <StoriesPanel entry={entry} />
      ) : (
        <p className="showcase-stub">The contract surface lands at mx.9.4.</p>
      )}
    </article>
  );
}
