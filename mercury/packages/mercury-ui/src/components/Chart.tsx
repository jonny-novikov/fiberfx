import { cx } from "../cx";

/*
 * Chart — a generic, token-driven SVG curve/area primitive. It is
 * geometry-DUMB: the caller precomputes every path/scale (see an app's pure
 * geometry module) and hands ready-to-render strings. The viewBox is parsed
 * for grid/marker extents; strokes use non-scaling-stroke so they stay crisp
 * under preserveAspectRatio="none".
 */

export interface ChartSeries {
  /** Precomputed line path ("M.. L.."). */
  d: string;
  /** Optional precomputed, closed area path (filled with the gradient). */
  area?: string;
  /** A token color expression, e.g. "rgb(var(--iris-9))". */
  stroke: string;
  /** Gradient id to fill the area with. */
  fillId?: string;
  width?: number;
  dashed?: boolean;
}

export interface ChartMarker {
  /** y in viewBox units — a full-width threshold line (e.g. a zero/loss boundary). */
  y: number;
  dashed?: boolean;
}

export interface ChartProps {
  /** e.g. "0 0 1000 300". */
  viewBox: string;
  series: ChartSeries[];
  /** Horizontal grid-line y positions (viewBox units). */
  gridY?: number[];
  /** Vertical grid-line x positions (viewBox units). */
  gridX?: number[];
  /** Labels down the left rail (top → bottom). */
  yTicks?: string[];
  /** Labels along the bottom rail (left → right). */
  xTicks?: string[];
  /** Linear gradients (top → transparent) referenced by series.fillId. */
  gradients?: { id: string; stroke: string }[];
  /** Full-width threshold markers (e.g. the zero line). */
  markers?: ChartMarker[];
  /** CSS height of the chart box. */
  height?: number | string;
  ariaLabel?: string;
}

export function Chart({
  viewBox,
  series,
  gridY = [],
  gridX = [],
  yTicks,
  xTicks,
  gradients = [],
  markers = [],
  height = 240,
  ariaLabel,
}: ChartProps) {
  const [, , vw, vh] = viewBox.split(/\s+/).map(Number);
  return (
    <div className="mx-chart" style={{ height }}>
      <svg className="mx-chart__svg" viewBox={viewBox} preserveAspectRatio="none" role="img" aria-label={ariaLabel}>
        {gridY.map((y, i) => (
          <line key={`gy${i}`} className="mx-chart__grid" x1={0} x2={vw} y1={y} y2={y} />
        ))}
        {gridX.map((x, i) => (
          <line key={`gx${i}`} className="mx-chart__grid" x1={x} x2={x} y1={0} y2={vh} />
        ))}
        {series.map((s, i) => (s.area ? <path key={`a${i}`} d={s.area} fill={s.fillId ? `url(#${s.fillId})` : "none"} stroke="none" /> : null))}
        {markers.map((m, i) => (
          <line key={`m${i}`} className={cx("mx-chart__marker", m.dashed === false && "mx-chart__marker--solid")} x1={0} x2={vw} y1={m.y} y2={m.y} />
        ))}
        {series.map((s, i) => (
          <path
            key={`l${i}`}
            className="mx-chart__line"
            d={s.d}
            stroke={s.stroke}
            strokeWidth={s.width ?? 2.5}
            strokeDasharray={s.dashed ? "6 5" : undefined}
            vectorEffect="non-scaling-stroke"
          />
        ))}
        {gradients.length > 0 && (
          <defs>
            {gradients.map((g) => (
              <linearGradient key={g.id} id={g.id} x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor={g.stroke} stopOpacity="0.28" />
                <stop offset="100%" stopColor={g.stroke} stopOpacity="0" />
              </linearGradient>
            ))}
          </defs>
        )}
      </svg>
      {yTicks && (
        <div className="mx-chart__yaxis">
          {yTicks.map((t, i) => (
            <span key={i}>{t}</span>
          ))}
        </div>
      )}
      {xTicks && (
        <div className="mx-chart__xaxis">
          {xTicks.map((t, i) => (
            <span key={i}>{t}</span>
          ))}
        </div>
      )}
    </div>
  );
}
