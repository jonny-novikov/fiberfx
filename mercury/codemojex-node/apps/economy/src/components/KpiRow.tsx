import { useUnit } from "effector-react";
import { Stat } from "@mercury/ui";
import { $split, $marginRows, $prizePool } from "../store/derived";
import { usd, dia, pct, signedUsd, signedPct } from "../model/format";

/** The headline numbers — five Stat tiles fed by the canonical split + pool. */
export function KpiRow() {
  const [s, margins, pp] = useUnit([$split, $marginRows, $prizePool]);
  const mob = margins[0];
  return (
    <div className="ecn-kpis">
      <Stat label="Guess value" value={usd(s.guessValue)} hint="gross akp × fee" />
      <Stat label="Pool / guess" value={dia(s.poolDiamonds)} hint={usd(s.poolUsd)} />
      <Stat label="House / guess" value={usd(s.houseUsd)} delta={pct(s.housePct)} deltaTone="brand" hint="of gross" />
      <Stat
        label="Mobile margin"
        value={signedUsd(mob.margin)}
        delta={signedPct(mob.squeezePct)}
        deltaTone={mob.negative ? "negative" : "positive"}
        hint="after store fee"
      />
      <Stat label={`Pool · ${pp.players}×${pp.guessesEach}`} value={usd(pp.poolUsd)} hint={dia(pp.poolDiamonds)} />
    </div>
  );
}
