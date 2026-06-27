import type { EmojiSet, Code } from "../types";

// Render one sprite cell from an "XXYY" code, matching Codemojex.EmojiSet.bg_position:
// the cell sits at (-x*cell_size, -y*cell_size) on the sheet. We scale the native
// cell to a display size so the same sheet serves any board density.
export function cellStyle(set: EmojiSet, code: Code, display: number) {
  const x = parseInt(code.slice(0, 2), 10);
  const y = parseInt(code.slice(2, 4), 10);
  const scale = display / set.cell_size;
  return {
    width: `${display}px`,
    height: `${display}px`,
    backgroundImage: set.sprite_url ? `url(${set.sprite_url})` : undefined,
    backgroundPosition: `${-x * set.cell_size * scale}px ${-y * set.cell_size * scale}px`,
    backgroundSize: `${set.cols * set.cell_size * scale}px ${set.rows * set.cell_size * scale}px`,
    backgroundRepeat: "no-repeat",
  } as const;
}
