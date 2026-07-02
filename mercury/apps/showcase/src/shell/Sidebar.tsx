import { REGISTRY, TOTAL } from "../registry";

type SidebarProps = {
  active: { group: string; name: string } | null;
  onSelect: (group: string, name: string) => void;
};

export function Sidebar({ active, onSelect }: SidebarProps) {
  return (
    <aside className="showcase-sidebar">
      <div className="showcase-brand">
        <span className="showcase-brand-mark" aria-hidden="true" />
        <div className="showcase-brand-text">
          <span className="showcase-brand-name">mercury</span>
          <span className="showcase-brand-ver">Design system · v2.4</span>
        </div>
      </div>
      <nav className="showcase-nav" aria-label="components">
        {REGISTRY.map((group) => (
          <section key={group.key} className="showcase-nav-group">
            <h2 className="showcase-nav-label">{group.label}</h2>
            <ul className="showcase-nav-list">
              {group.entries.map((entry) => {
                const isActive =
                  active !== null && active.group === entry.group && active.name === entry.name;
                return (
                  <li key={entry.name}>
                    <button
                      type="button"
                      className={isActive ? "showcase-nav-item is-active" : "showcase-nav-item"}
                      aria-current={isActive ? "page" : undefined}
                      onClick={() => onSelect(entry.group, entry.name)}
                    >
                      <span className="dot" aria-hidden="true" />
                      {entry.name}
                    </button>
                  </li>
                );
              })}
            </ul>
          </section>
        ))}
      </nav>
      <footer className="showcase-sidebar-footer">{TOTAL} components</footer>
    </aside>
  );
}
