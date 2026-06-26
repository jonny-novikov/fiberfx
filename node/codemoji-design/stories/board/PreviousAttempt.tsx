import * as React from 'react';
import { cn } from '../lib/cn';
import { EmojiTile } from './lib/EmojiTile';

// The previous-attempt row above the guess slots (94:2974). Re-expresses
// shared/ui/previous-attempt in the Figma master's shape: the label "Предыдущая
// попытка" on the left, the last guess as small filled tiles in the middle, and
// the score it earned on the right. Tapping the row calls onClick to refill the
// slots with it (the app's fillSlots). Scoring is linear — 100 per emoji in the
// right place — so the score rides as a bare number (no /600 in the master).
export interface PreviousAttemptProps {
  /** the six glyphs of the last guess, left to right */
  emojis: string[];
  /** points it scored (0–600; 100 per correctly-placed emoji) */
  points: number;
  /** fired when the row is tapped (refills the slots with this guess) */
  onClick?: () => void;
  className?: string;
}

export function PreviousAttempt({ emojis, points, onClick, className }: PreviousAttemptProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-center justify-between gap-2 text-xs font-medium leading-none',
        onClick && 'cursor-pointer transition-opacity hover:opacity-70 active:opacity-50',
        className
      )}
    >
      <span className="text-card-foreground-secondary">Предыдущая попытка</span>
      <span className="inline-flex items-center gap-1">
        {emojis.map((emoji, i) => (
          <EmojiTile key={i} emoji={emoji} state="filled" size="sm" />
        ))}
      </span>
      <span className="font-bold text-card-foreground tabular-nums">{points}</span>
    </button>
  );
}
