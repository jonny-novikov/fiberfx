import { Icon, cx } from "@mercury/ui";
import { NAV } from "../nav";
import { navigate, useRoute } from "../store";

export function Sidebar() {
  const route = useRoute();
  return (
    <aside className="sidebar">
      <div className="sb-brand">
        <span className="mark">
          <Icon name="bolt" size={20} />
        </span>
        <div>
          <div className="name">mercury</div>
          <div className="ver">Design system · v2.4</div>
        </div>
      </div>
      {NAV.map((group) => (
        <div key={group.label}>
          <div className="sb-group">{group.label}</div>
          {group.items.map((item) => (
            <button
              key={item.route}
              type="button"
              className={cx("sb-link", route === item.route && "is-active")}
              onClick={() => navigate(item.route)}
            >
              <span className="dot" />
              <span>{item.label}</span>
            </button>
          ))}
        </div>
      ))}
    </aside>
  );
}
