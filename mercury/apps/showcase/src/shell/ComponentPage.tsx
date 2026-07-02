import { StoriesPanel } from "../lib/storyRender";
import { GROUP_LABEL, type ShowcaseEntry } from "../registry";
import { DocsPanel } from "./DocsPanel";

type Tab = "stories" | "docs";

type ComponentPageProps = {
  entry: ShowcaseEntry;
  tab: Tab;
  onTab: (tab: Tab) => void;
};

// Stories is live (mx.9.3): StoriesPanel lazy-loads ONLY the selected entry's
// module (INV-5). Docs is live (mx.9.4): DocsPanel lazy-loads the selected
// entry's contract and renders the four views over one raw string.
export function ComponentPage({ entry, tab, onTab }: ComponentPageProps) {
  const label = (GROUP_LABEL as Record<string, string>)[entry.group] ?? entry.group;
  return (
    <article className="showcase-page">
      <header className="showcase-page-header">
        <p className="showcase-eyebrow">{label}</p>
        <h2 className="showcase-ptitle">{entry.name}</h2>
        <p className="showcase-lede">Live stories and the hand-authored contract.</p>
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
        <DocsPanel entry={entry} />
      )}
    </article>
  );
}
