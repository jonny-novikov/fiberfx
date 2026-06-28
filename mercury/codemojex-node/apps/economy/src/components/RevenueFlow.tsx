import { useState } from "react";
import { useUnit } from "effector-react";
import { Card, Segmented, Tag } from "@mercury/ui";
import { $split, $params } from "../store/derived";
import { buildFlow } from "../model/flow";
import { usd } from "../model/format";

type Channel = "mobile" | "desktop";

/** Where one guess's gross goes: gross → net | store-fee → pool | margin. */
export function RevenueFlow() {
  const [s, p] = useUnit([$split, $params]);
  const [channel, setChannel] = useState<Channel>("mobile");
  const fee = channel === "mobile" ? p.storeFeeMobile : p.storeFeeDesktop;
  const g = buildFlow(s, fee);
  return (
    <Card variant="raised">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "var(--space-12)" }}>
        <p className="ecn-card-title" style={{ margin: 0 }}>Revenue flow / guess</p>
        <Segmented<Channel>
          size="sm"
          value={channel}
          onChange={setChannel}
          segments={[
            { label: "Mobile", value: "mobile" },
            { label: "Desktop", value: "desktop" },
          ]}
        />
      </div>
      <svg viewBox={g.viewBox} role="img" aria-label="Revenue flow from gross to pool and house" style={{ width: "100%", display: "block" }}>
        {g.rows.map((row, i) => (
          <g key={i}>
            <text x={10} y={row.barY - 6} fontSize={12} fill="rgb(var(--fg-tertiary))" style={{ fontFamily: "var(--font-secondary)" }}>
              {row.title}
            </text>
            {row.segs.map((seg, j) => (
              <g key={j}>
                <rect x={seg.x} y={row.barY} width={Math.max(0, seg.w)} height={g.rowH} rx={4} fill={seg.fill} />
                {seg.w > 70 && (
                  <text x={seg.x + 10} y={row.barY + g.rowH / 2 + 4} fontSize={12} fill="rgb(var(--fg-on-brand))" style={{ fontFamily: "var(--font-secondary)" }}>
                    {seg.label} · {usd(seg.usd)}
                  </text>
                )}
              </g>
            ))}
          </g>
        ))}
      </svg>
      <div style={{ display: "flex", gap: "var(--space-8)", marginTop: "var(--space-8)", flexWrap: "wrap" }}>
        <Tag tone="info" dot={false}>
          net {usd(g.netUsd)}
        </Tag>
        <Tag tone={g.marginNegative ? "negative" : "positive"} dot={false}>
          margin {usd(g.marginUsd)}
        </Tag>
      </div>
    </Card>
  );
}
