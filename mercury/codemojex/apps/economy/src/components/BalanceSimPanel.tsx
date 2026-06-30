import { useState } from "react";
import type { ChangeEvent } from "react";
import { useUnit } from "effector-react";
import { Card, Input, Button, Stat, Divider } from "@mercury/ui";
import { $wac, wacBought, wacSpent, wacReset } from "../store/derived";
import { wac, wacSpend, packageAkp } from "../model/calc";
import { PACKAGES } from "../model/packages";
import { usd } from "../model/format";

const num =
  (set: (v: number) => void) =>
  (e: ChangeEvent<HTMLInputElement>): void =>
    set(Number(e.target.value));

/** Watch the weighted-average cost basis drift as a player buys packages and spends on guesses. */
export function BalanceSimPanel() {
  const state = useUnit($wac);
  const [buyKeys, setBuyKeys] = useState(100);
  const [buyCost, setBuyCost] = useState(15);
  const [spend, setSpend] = useState(5);
  const currentWac = wac(state);
  const preview = wacSpend(state, spend).costOut;

  return (
    <Card variant="raised">
      <p className="ecn-card-title">WAC balance simulator</p>
      <div className="ecn-kpis" style={{ marginBottom: "var(--space-16)" }}>
        <Stat label="Keys held" value={state.keys} />
        <Stat label="Cost basis" value={usd(state.basisUsd, 4)} />
        <Stat label="WAC / key" value={usd(currentWac, 4)} deltaTone="brand" />
      </div>

      <Divider label="buy" />
      <div style={{ display: "flex", gap: "var(--space-8)", alignItems: "flex-end" }}>
        <Input label="Keys" type="number" min={1} value={buyKeys} onChange={num(setBuyKeys)} />
        <Input label="Cost (USD)" type="number" min={0} step={0.01} value={buyCost} onChange={num(setBuyCost)} />
        <Button onClick={() => wacBought({ keys: buyKeys, costUsd: buyCost })}>Buy</Button>
      </div>
      <div style={{ display: "flex", gap: "var(--space-6)", marginTop: "var(--space-8)", flexWrap: "wrap" }}>
        {PACKAGES.map((p) => (
          <Button
            key={p.keys}
            variant="outline"
            size="sm"
            onClick={() => wacBought({ keys: p.keys, costUsd: Number((p.keys * packageAkp(p.stars, p.keys)).toFixed(4)) })}
          >
            +{p.keys}
          </Button>
        ))}
      </div>

      <Divider label="spend" />
      <div style={{ display: "flex", gap: "var(--space-8)", alignItems: "flex-end" }}>
        <Input label="Keys to spend" type="number" min={1} value={spend} onChange={num(setSpend)} />
        <Button variant="secondary" onClick={() => wacSpent(spend)} disabled={state.keys <= 0}>
          Spend
        </Button>
        <Button variant="ghost" onClick={() => wacReset()}>
          Reset
        </Button>
      </div>
      <p className="ecn-mono" style={{ marginTop: "var(--space-8)", color: "rgb(var(--fg-tertiary))", fontSize: 12 }}>
        spending {spend} keys releases {usd(preview, 4)} of cost basis · WAC stays {usd(currentWac, 4)}
      </p>
    </Card>
  );
}
