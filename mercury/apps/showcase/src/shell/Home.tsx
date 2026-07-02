import { Badge, Button, Card } from "@mercury/ui";
import { REGISTRY, TOTAL } from "../registry";

type HomeProps = {
  onSelect: (group: string, name: string) => void;
};

// The overview (the no-selection panel), skinned to the reference .hero/.gcards.
// The @mercury/ui value import keeps the barrel — and with it the stylesheet — in
// the graph; the metric values derive from the registry, never a literal count.
export function Home({ onSelect }: HomeProps) {
  const firstEntry = REGISTRY[0]?.entries[0];
  return (
    <section className="showcase-page showcase-home">
      <p className="showcase-eyebrow">Design system · v2.4</p>
      <h1 className="showcase-ptitle">Mercury Showcase</h1>
      <p className="showcase-lede">
        A small, opinionated set of React primitives wired to the Mercury token set. Every
        component reads color, type, radius and elevation from CSS custom properties — so
        switching between light and dark, or swapping an entire brand, is one variable flip.
      </p>
      <div className="showcase-hero">
        <div>
          <h2>Tokens in. Components out.</h2>
          <p>
            Mercury separates decisions (what iris-9 means) from usage (where it is applied).
            Pages rebrand by swapping token aliases, never by touching component code.
          </p>
          {/* the Card chrome is neutralized by .showcase-hero-demo so the live demo row
              sits bare on the hero surface (the reference look) while the Card value
              import stays in the graph */}
          <Card className="showcase-hero-demo">
            <Button
              onClick={() =>
                firstEntry !== undefined && onSelect(firstEntry.group, firstEntry.name)
              }
            >
              Browse components
            </Button>{" "}
            <Badge>v2.4</Badge>
          </Card>
        </div>
        <div className="showcase-hero-metrics">
          <div className="showcase-metric">
            <span className="n">{TOTAL}</span>
            <span className="l">Components</span>
          </div>
          <div className="showcase-metric">
            <span className="n">{REGISTRY.length}</span>
            <span className="l">Groups</span>
          </div>
          <div className="showcase-metric">
            <span className="n">3</span>
            <span className="l">Type families</span>
          </div>
        </div>
      </div>
      <div className="showcase-sec">
        <h2>Everything inside</h2>
        <span className="hint">{REGISTRY.length} groups, derived from the tree</span>
      </div>
      <div className="showcase-cards">
        {REGISTRY.map((group) => {
          const first = group.entries[0];
          if (first === undefined) return null;
          return (
            <button
              key={group.key}
              type="button"
              className="showcase-gcard"
              onClick={() => onSelect(group.key, first.name)}
            >
              <span className="t">{group.label}</span>
              <span className="d">
                {group.entries.length} {group.entries.length === 1 ? "component" : "components"}
              </span>
            </button>
          );
        })}
      </div>
    </section>
  );
}
