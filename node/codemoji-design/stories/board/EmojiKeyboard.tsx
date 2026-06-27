import * as React from 'react';
import { cn } from '../lib/cn';
import { SpriteEmoji } from './lib/SpriteEmoji';

// The tappable emoji grid — the board's core input. Faithful re-expression of the app's
// shared/ui/emoji-keyboard (codemoji-app): a 7-column grid of square white keys, each
// drawing a sprite-sheet emoji. Keys carry the app's states:
//   - default (selectable) → bg-white ring-1 ring-black/10 border border-black/10
//   - SELECTED (in the current guess) → bg-green-100 ring-2 ring-green-400 shadow-md
//   - USED (appeared in a previous guess) → bg-white/40 (faded)
// Emoji are XXYY sprite codes (the app's room emojiSet; a curated sample here). The app's
// entrance animations + jotai selection are omitted — this documents the KEY surface.

// A curated sample of the standard set (01-emoji-set.png), 4 rows x 7 cols of
// recognisable emoji, each as its "XXYY" (column, row) sprite code.
const SAMPLE_CODES = [
  '0800', '0005', '0507', '0902', '0403', '0603', '0904', // 🐶 🦊 🐯 🐼 🐵 🦁 🐸
  '0302', '0104', '0407', '0003', '0506', '0805', '0101', // 🐰 🐝 🦄 🐙 🦋 🐲 🦓
  '0300', '0500', '0200', '0604', '0606', '0903', '0505', // 🔥 💎 🍕 🍓 🍒 🍉 🍄
  '0707', '0510', '0308', '0011', '0613', '0213', '0700', // 🌈 🎈 ⚡ ❤ 🎮 🎲 🏎
];

export interface EmojiKeyboardProps {
  /** the available emoji as XXYY sprite codes; defaults to a built-in 28-key sample */
  emojis?: string[];
  /** codes already picked into the current guess (rendered selected/green) */
  selected?: string[];
  /** codes used in a previous guess (rendered faded) */
  used?: string[];
  /** grid columns (the app uses 7 in-game) */
  columns?: 6 | 7 | 8;
  /** fired with the tapped code (the app appends it to the next open slot) */
  onSelect?: (code: string) => void;
  className?: string;
}

export function EmojiKeyboard({
  emojis = SAMPLE_CODES,
  selected = [],
  used = [],
  columns = 7,
  onSelect,
  className,
}: EmojiKeyboardProps) {
  const selectedSet = new Set(selected);
  const usedSet = new Set(used);
  return (
    <div
      className={cn(
        'grid justify-items-center gap-1.5',
        columns === 6 && 'grid-cols-6',
        columns === 7 && 'grid-cols-7',
        columns === 8 && 'grid-cols-8',
        className
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
  );
}
