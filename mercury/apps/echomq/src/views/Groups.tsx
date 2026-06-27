import { GROUPS } from "../data";
import { FlowRowCard } from "../chrome/FlowRowCard";

export function Groups() {
  return (
    <>
      {GROUPS.map((g) => (
        <FlowRowCard key={g.name} row={g} icon="flow" />
      ))}
    </>
  );
}
