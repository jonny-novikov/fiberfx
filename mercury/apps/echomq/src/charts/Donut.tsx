import type { DonutArc } from "../data";

/* A multi-segment donut drawn with stroke-dasharray arcs + a center label. */
export function Donut({ arcs, num, cap }: { arcs: DonutArc[]; num: string | number; cap: string }) {
  return (
    <svg className="eqd-donut" viewBox="0 0 160 160">
      <g transform="rotate(-90 80 80)">
        {arcs.map((a) => (
          <circle
            key={a.label}
            cx="80"
            cy="80"
            r="62"
            fill="none"
            strokeWidth="20"
            stroke={a.color}
            strokeDasharray={a.dash}
            strokeDashoffset={a.offset}
          />
        ))}
      </g>
      <text x="80" y="74" className="eqd-donut__num">
        {num}
      </text>
      <text x="80" y="92" className="eqd-donut__cap">
        {cap}
      </text>
    </svg>
  );
}
