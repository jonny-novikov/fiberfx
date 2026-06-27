import { Chip, Icon, Search, cx } from "@mercury/ui";
import { QUEUES } from "../data";
import { selectQueue, setSearch, useSearch, useSelected } from "../store";
import { Bolt } from "./Bolt";

export function Sidebar() {
  const selected = useSelected();
  const search = useSearch();
  const queues = QUEUES.filter((q) => q.name.toLowerCase().includes(search.toLowerCase()));

  return (
    <aside className="eqd-side">
      <div className="eqd-brand">
        <span className="eqd-mark">
          <Bolt size={19} />
        </span>
        <span className="eqd-brandname">EchoMQ</span>
        <Chip variant="brand" size="sm">
          Bus
        </Chip>
      </div>

      <div className="eqd-connbox">
        <div className="eqd-org">
          <Icon name="bank" size={14} /> ACME CORP
        </div>
        <div className="eqd-conn">
          <span className="eqd-conn__status" />
          <span className="eqd-conn__name">Localhost</span>
          <Chip variant="positive" size="sm">
            online
          </Chip>
        </div>
        <Search className="eqd-search" value={search} onChange={setSearch} placeholder="Search queues" />
      </div>

      <div className="eqd-navlbl">
        <span>Queues</span>
        <span>{queues.length}</span>
      </div>
      <div className="eqd-queues">
        {queues.map((q) => (
          <button
            key={q.name}
            type="button"
            className={cx("eqd-q", selected === q.name && "is-active")}
            onClick={() => selectQueue(q.name)}
          >
            <span className="eqd-q__name">
              {q.name}
              <span className="eqd-q__count">{q.total || "—"}</span>
            </span>
            <span className="eqd-q__bar">
              {q.segs.map((s, i) => (
                <span key={i} className="eqd-q__seg" style={{ flex: s.flex, background: s.color }} />
              ))}
            </span>
          </button>
        ))}
      </div>
    </aside>
  );
}
