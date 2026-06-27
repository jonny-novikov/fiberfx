import * as React from 'react';
import { cn } from '../lib/cn';
import { SpriteEmoji } from './lib/SpriteEmoji';

// The tappable emoji grid — the board's core input. Faithful re-expression of the app's
// shared/ui/emoji-keyboard (codemoji-app): a 7-column grid of square white keys, each
// drawing a sprite-sheet emoji. Keys carry the app's states:
//   - default (selectable) → bg-white ring-1 ring-black/10 border border-black/10
//   - SELECTED (in the current guess) → bg-green-100 ring-2 ring-green-400 shadow-md
//   - USED (appeared in a previous guess) → bg-white/40 (faded)
// The full set is more than fits, so the grid SCROLLS: it sits in a viewport that is
// `visibleRows` rows tall (the Figma board shows 5) and scrolls to reveal the rest, with
// momentum + touch on mobile. This mirrors the app, whose keyboard is a flex-1
// overflow-y-auto window inside a viewport-height parent; here the window is pinned to a
// row count instead of the screen. Emoji are XXYY sprite codes; the app's jotai
// selection + entrance animations are omitted — this documents the KEY surface + scroll.

// A curated sample of the standard set (01-emoji-set.png — a filled 10x15 grid), 8 rows
// x 7 cols = 56 recognisable emoji, each as its "XXYY" (column, row) sprite code. That is
// 3 rows beyond the 5-row window, so the grid scrolls.
const SAMPLE_CODES = [
  '0800', '0005', '0507', '0902', '0403', '0603', '0904', // 🐶 🦊 🐯 🐼 🐵 🦁 🐸
  '0302', '0104', '0407', '0003', '0506', '0805', '0101', // 🐰 🐝 🦄 🐙 🦋 🐲 🦓
  '0300', '0500', '0200', '0604', '0606', '0903', '0505', // 🔥 💎 🍕 🍓 🍒 🍉 🍄
  '0707', '0510', '0308', '0011', '0613', '0213', '0700', // 🌈 🎈 ⚡ ❤ 🎮 🎲 🏎
  '0100', '0600', '0400', '0900', '0201', '0301', '0401', // 🛸 🥝 🧀 🧲 🦖 🍋 🚕
  '0701', '0801', '0102', '0502', '0602', '0702', '0203', // 🌽 🛵 🍆 🥐 🍌 🚢 🦴
  '0503', '0803', '0004', '0204', '0404', '0504', '0205', // 🦎 🦘 🚁 🦏 🦞 🥨 🐘
  '0305', '0107', '0207', '0208', '0608', '0708', '0706', // 🍍 🍺 🥑 🌵 🗽 👑 🍬
];

export interface EmojiKeyboardProps {
  /** the available emoji as XXYY sprite codes; defaults to a built-in 56-key sample */
  emojis?: string[];
  /** codes already picked into the current guess (rendered selected/green) */
  selected?: string[];
  /** codes used in a previous guess (rendered faded) */
  used?: string[];
  /** grid columns (the app uses 7 in-game) */
  columns?: 6 | 7 | 8;
  /** rows visible before the grid scrolls (Figma board: 5) */
  visibleRows?: number;
  /** fired with the tapped code (the app appends it to the next open slot) */
  onSelect?: (code: string) => void;
  className?: string;
}

export function EmojiKeyboard({
  emojis = SAMPLE_CODES,
  selected = [],
  used = [],
  columns = 7,
  visibleRows = 5,
  onSelect,
  className,
}: EmojiKeyboardProps) {
  const selectedSet = new Set(selected);
  const usedSet = new Set(used);
  return (
    // The scroll viewport — a window `visibleRows` rows tall. The keys are square, so the
    // window's height tracks its width through a columns : rows aspect-ratio, and the rest
    // of the grid scrolls inside it. Mobile-friendly:
    // momentum scrolling + `touch-action: pan-y` (a vertical drag scrolls the grid, taps
    // still register) + `overscroll-contain` (no scroll-chaining to the page). A slim
    // scrollbar is styled inline so no global CSS is needed.
    <div
      className={cn(
        'overflow-y-auto overscroll-contain',
        '[&::-webkit-scrollbar]:w-1.5 [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-black/15',
        className
      )}
      style={{
        // columns : (visibleRows + a 0.4-row peek) — shows the 5 full rows the Figma
        // board calls for, plus a sliver of the next row so the scroll is discoverable.
        aspectRatio: `${columns} / ${visibleRows + 0.4}`,
        WebkitOverflowScrolling: 'touch',
        touchAction: 'pan-y',
      }}
    >
      <div
        className={cn(
          'grid justify-items-center gap-1.5',
          columns === 6 && 'grid-cols-6',
          columns === 7 && 'grid-cols-7',
          columns === 8 && 'grid-cols-8'
        )}
      >
        {emojis.map((code, i) => {
          const isSelected = selectedSet.has(code);
          const isUsed = usedSet.has(code);
          return (
            <button
              key={`${code}-${i}`}
              type="button"
              onClick={() => onSelect?.(code)}
              className={cn(
                'flex aspect-square w-full items-center justify-center rounded-[10px] transition-all duration-150 active:scale-90',
                isSelected && 'bg-green-100 ring-2 ring-green-400 shadow-md',
                !isSelected && isUsed && 'bg-white/40',
                !isSelected &&
                  !isUsed &&
                  'bg-white border border-black/10 ring-1 ring-black/10 hover:bg-gray-100'
              )}
            >
              <SpriteEmoji code={code} size={34} />
            </button>
          );
        })}
      </div>
    </div>
  );
}
