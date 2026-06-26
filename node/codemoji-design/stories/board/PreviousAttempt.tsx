import * as React from 'react';
import { cn } from '../lib/cn';
import { EmojiTile } from './lib/EmojiTile';

// The previous-attempt row above the guess slots (94:2974). Re-expresses
// shared/ui/previous-attempt: the last guess as six small filled tiles + the
// score it earned; tapping the row calls onClick to refill the slots with it
// (the app's fillSlots). Scoring is linear — 100 per emoji in the right place,
// so 600 is a perfect six.
const MAX_POINTS = 600;

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
        'flex w-full items-center justify-center gap-2 text-xs font-medium leading-none',
        onClick && 'cursor-pointer transition-opacity hover:opacity-70 active:opacity-50',
        className
      )}
    >
      <span className="text-card-foreground-secondary">Last guess</span>
      <span className="inline-flex items-center gap-1">
        {emojis.map((emoji, i) => (
          <EmojiTile key={i} emoji={emoji} state="filled" size="sm" />
        ))}
      </span>
      <span className="font-bold text-success">
        {points}
        <span className="text-card-foreground-secondary">/{MAX_POINTS}</span>
      </span>
      <span className="text-2xs text-muted">tap to reuse</span>
    </button>
  );
}
