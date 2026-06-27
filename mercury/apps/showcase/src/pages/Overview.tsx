import { Button } from "@mercury/ui";
import { Page } from "../chrome/Page";
import { OVERVIEW_CARDS } from "../nav";
import { navigate } from "../store";

export function Overview() {
  return (
    <Page>
      <div className="eyebrow">v2.4 · April 2026</div>
      <h1 className="ptitle">Mercury Design System</h1>
      <p className="lede">
        A small, opinionated set of React primitives wired to the Mercury token set. Every component reads colors, type,
        radius and elevation from CSS custom properties — so switching between light and dark, or swapping an entire
        brand, is one variable deep.
      </p>

      <div className="hero">
        <div>
          <h1>Tokens in. Components out.</h1>
          <p>
            Mercury separates decisions (what iris-9 <em>means</em>) from usage (where it’s applied). Pages rebrand by
            swapping token aliases, never by touching component code.
          </p>
          <div style={{ display: "flex", gap: 8 }}>
            <Button onClick={() => navigate("components/button")}>Browse components</Button>
            <Button variant="secondary" onClick={() => navigate("foundations/colors")}>
              View tokens
            </Button>
          </div>
        </div>
        <div className="hmtx">
          <div className="m">
            <div className="n">84</div>
            <div className="l">Color tokens</div>
          </div>
          <div className="m">
            <div className="n">18</div>
            <div className="l">Components</div>
          </div>
          <div className="m">
            <div className="n">3</div>
            <div className="l">Type families</div>
          </div>
        </div>
      </div>

      <div className="sec">
        <h2>Everything inside</h2>
      </div>
      <div className="gcards">
        {OVERVIEW_CARDS.map((c) => (
          <button key={c.route} type="button" className="gcard" onClick={() => navigate(c.route)}>
            <div className="t">{c.title}</div>
            <div className="d">{c.desc}</div>
          </button>
        ))}
      </div>
    </Page>
  );
}
