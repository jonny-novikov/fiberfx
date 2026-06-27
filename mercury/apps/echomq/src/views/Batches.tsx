import { BATCHES } from "../data";
import { FlowRowCard } from "../chrome/FlowRowCard";

export function Batches() {
  return (
    <>
      {BATCHES.map((b) => (
        <FlowRowCard key={b.name} row={b} icon="batch" />
      ))}
    </>
  );
}
