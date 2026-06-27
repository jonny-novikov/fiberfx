import type { EmojiSet, Code } from "../types";
import { cellStyle } from "./sprite";

export function EmojiSlots(props: {
  picks: Code[];
  set: EmojiSet | null;
  onClear: (i: number) => void;
  length: number;
}) {
  const { picks, set, onClear, length } = props;
  const slots = Array.from({ length }, (_v, i) => picks[i] ?? null);
  return (
    <div className="slots">
      {slots.map((code, i) => (
        <button key={i} className="slots__slot" onClick={() => code && onClear(i)} aria-label={`slot ${i + 1}`}>
          {code && set ? <span className="cell" style={cellStyle(set, code, 44)} /> : <span className="slots__empty" />}
        </button>
      ))}
    </div>
  );
}
