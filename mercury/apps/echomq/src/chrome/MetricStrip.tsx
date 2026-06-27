import { META } from "../data";
import { Bolt } from "./Bolt";

/* The bus-wide metric strip (version, mode, memory, clients). */
export function MetricStrip() {
  return (
    <div className="eqd-metastrip">
      <span className="eqd-bolt">
        <Bolt size={26} />
      </span>
      <div className="eqd-vsep" />
      {META.map((m) => (
        <div key={m.label} className="eqd-meta">
          <span className="l">{m.label}</span>
          <span className="v">{m.value}</span>
        </div>
      ))}
    </div>
  );
}
