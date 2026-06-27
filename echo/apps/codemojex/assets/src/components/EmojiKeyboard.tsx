import type { EmojiSet, Code } from "@/types";
import { cellStyle } from "@/components/sprite";

export function EmojiKeyboard(props: {
  set: EmojiSet;
  used: Set<Code>;
  onTap: (code: Code) => void;
  disabled?: boolean;
}) {
  const { set, used, onTap, disabled } = props;
  return (
    <div className="keyboard" data-disabled={disabled ? "1" : "0"}>
      {set.codes.map((code) => (
        <button
          key={code}
          className="keyboard__key"
          aria-label={code}
          disabled={disabled || used.has(code)}
          onClick={() => onTap(code)}
        >
          <span className="cell" style={cellStyle(set, code, 40)} />
        </button>
      ))}
    </div>
  );
}
