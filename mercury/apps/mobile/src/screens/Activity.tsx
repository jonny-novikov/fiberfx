import { Chip } from "@mercury/ui";
import { ActivityList } from "../chrome/ActivityList";
import { FILTERS, ALL_ACTIVITY } from "../data";
import { setFilter, useFilter } from "../store";

export function Activity() {
  const filter = useFilter();
  return (
    <div className="em-screen">
      <div className="em-chiprow">
        {FILTERS.map((f) => (
          <Chip key={f.value} selected={filter === f.value} onClick={() => setFilter(f.value)}>
            {f.label}
          </Chip>
        ))}
      </div>
      <ActivityList rows={ALL_ACTIVITY} />
    </div>
  );
}
