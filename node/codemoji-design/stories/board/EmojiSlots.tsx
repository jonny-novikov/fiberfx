import * as React from 'react';
import { cn } from '../lib/cn';
import { EmojiTile } from './lib/EmojiTile';

// The 6-emoji guess row — the heart of the board (94:2974). The first empty,
// unlocked slot is "active" (a pulsing "?"); pinned slots show a lock badge.
// Re-expresses widgets/emoji-slots; the drag-reorder + lock-toggle behaviour is
// omitted (this documents the slot STATES, the design-system concern).
export interface EmojiSlotsProps {
  /** chosen emojis, left to right; a hole (undefined) is an empty slot */
  emojis?: (string | undefined)[];
  total?: number;
  /** indices the player pinned (rendered with a lock badge) */
  locked?: number[];
  className?: string;
}

export function EmojiSlots({ emojis = [], total = 6, locked = [], className }: EmojiSlotsProps) {
  const firstEmpty = Array.from({ length: total }).findIndex(
    (_, i) => !emojis[i] && !locked.includes(i)
  );
  return (
    <div className={cn('flex items-center justify-center gap-1.5', className)}>
      {Array.from({ length: total }).map((_, i) => {
        const emoji = emojis[i];
        const isLocked = locked.includes(i);
        const state = emoji
          ? isLocked
            ? 'locked'
            : 'filled'
          : i === firstEmpty
            ? 'active'
            : 'empty';
        return <EmojiTile key={i} emoji={emoji} state={state} locked={isLocked} />;
      })}
    </div>
  );
}
