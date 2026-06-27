import type { ReactNode } from "react";
import { ChevronRightIcon } from "../icons";

/** A tappable settings/list row — lives inside a @mercury/ui Card. */
export function Row({ icon, label, value }: { icon: ReactNode; label: string; value?: ReactNode }) {
  return (
    <button className="em-prow">
      <span className="em-prow-ic">{icon}</span>
      <span className="em-prow-l">{label}</span>
      <span className="em-prow-v">{value}</span>
      <ChevronRightIcon size={18} />
    </button>
  );
}
