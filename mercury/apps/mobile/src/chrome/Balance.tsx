import { TrendUpIcon } from "../icons";
import { BALANCE } from "../data";

/** The brand-gradient balance hero — bespoke app chrome, not a Mercury Card. */
export function Balance() {
  return (
    <div className="em-balance">
      <div className="em-balance-label">{BALANCE.label}</div>
      <div className="em-balance-amount">
        <span className="em-balance-ccy">{BALANCE.ccy}</span> {BALANCE.amount}
      </div>
      <div className="em-balance-delta">
        <TrendUpIcon size={14} />
        <span>{BALANCE.delta}</span>
      </div>
    </div>
  );
}
