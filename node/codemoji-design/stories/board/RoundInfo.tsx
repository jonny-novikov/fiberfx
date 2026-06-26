import * as React from 'react';
import { cn } from '../lib/cn';

// The green round-status card near the top of the board (94:2974) — the timer
// and the prize pool. Unlike most board sections this is NOT a white BoardCard:
// it is its OWN green surface (`bg-success`), so it carries its own radius/fill
// and is shown WITHOUT a BoardCard decorator in the story.
export interface RoundInfoProps {
  /** countdown string, e.g. 'HH:MM:SS' */
  timeLeft?: string;
  /** prize pool in diamonds */
  prizePool?: number;
  className?: string;
}

export function RoundInfo({
  timeLeft = '34:55:38',
  prizePool = 52352,
  className,
}: RoundInfoProps) {
  return (
    <div
      className={cn(
        'flex items-center justify-between rounded-2xl bg-success p-4 text-white',
        className
      )}
    >
      <div className="flex flex-col gap-0.5">
        <span className="text-2xs opacity-80">Time left</span>
        <span className="text-h2 font-bold tabular-nums">⏳ {timeLeft}</span>
      </div>
      <div className="flex flex-col items-end gap-0.5">
        <span className="text-2xs opacity-80">Prize pool</span>
        <span className="text-h2 font-bold tabular-nums">{prizePool.toLocaleString()} 💎</span>
      </div>
    </div>
  );
}
