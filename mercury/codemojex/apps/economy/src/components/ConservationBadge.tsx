import { useUnit } from "effector-react";
import { Alert, Tag } from "@mercury/ui";
import { $conservation } from "../store/derived";
import { usd } from "../model/format";

/** The money-conservation identity: gross consumed == pool liability + house realized. */
export function ConservationBadge() {
  const c = useUnit($conservation);
  if (c.balanced) {
    return (
      <Tag tone="positive">
        gross {usd(c.grossConsumed)} = pool {usd(c.poolLiability)} + house {usd(c.houseRealized)}
      </Tag>
    );
  }
  return (
    <Alert tone="danger" title="Conservation broken">
      residual {usd(c.residual, 6)} — gross {usd(c.grossConsumed)} ≠ pool {usd(c.poolLiability)} + house {usd(c.houseRealized)}
    </Alert>
  );
}
