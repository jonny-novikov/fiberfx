import * as React from 'react';
import { cn } from '../lib/cn';
import { EmojiTile } from './lib/EmojiTile';

// The tappable emoji grid — the board's core input (94:2974). An ~8-per-row grid
// of `EmojiTile state="key"`; tapping a key calls onSelect(emoji) to fill the next
// guess slot. Re-expresses shared/ui/emoji-keyboard; the selection/used/limit
// states live in the app's gameplay store, so this documents the KEY surface (the
// tap target, the press feedback) — the design-system concern.

// A default board-flavoured set of Unicode glyphs (the app draws its set from the
// emoji-mart picker; here a fixed sample keeps the story self-contained).
const SAMPLE_EMOJIS = [
  '😀', '😂', '😍', '😎', '🤔', '😭', '😡', '🥳',
  '🐱', '🐶', '🦊', '🐸', '🐵', '🦁', '🐼', '🐧',
  '🔥', '💧', '⭐', '🌈', '🎮', '💎', '🚀', '🔑',
];

export interface EmojiKeyboardProps {
  /** the glyphs to lay out; defaults to a built-in board sample of 24 */
  emojis?: string[];
  /** fired with the tapped glyph (the app appends it to the next open slot) */
  onSelect?: (emoji: string) => void;
  className?: string;
}

export function EmojiKeyboard({ emojis = SAMPLE_EMOJIS, onSelect, className }: EmojiKeyboardProps) {
  return (
    <div className={cn('grid grid-cols-8 justify-items-center gap-1.5', className)}>
      {emojis.map((emoji, i) => (
        <EmojiTile
          key={`${emoji}-${i}`}
          emoji={emoji}
          state="key"
          size="sm"
          role="button"
          tabIndex={0}
          onClick={() => onSelect?.(emoji)}
        />
      ))}
    </div>
  );
}
