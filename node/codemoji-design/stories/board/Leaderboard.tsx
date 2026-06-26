import * as React from 'react';
import { cn } from '../lib/cn';

// The ranked player list under the Leaderboard tab (94:2974). Re-expresses
// entities/leaderboard/leaderboard-item: an avatar circle, the display name
// (+ a "(you)" tag for the current player), then a right-aligned %-over-score
// pair with a thin progress bar. The app's ad-hoc #54C0EC / blue-50 tints are
// mapped onto the design system's themeable `accent` and brand `primary`.

const DEFAULT_MAX_SCORE = 600;

export interface LeaderboardEntry {
  displayName: string;
  finalPoints: number;
  isCurrentPlayer?: boolean;
}

export interface LeaderboardRowProps {
  item: LeaderboardEntry;
  /** the score that maps to 100% on the bar */
  maxScore?: number;
  className?: string;
}

// One player row. Exported so a single row can be documented in isolation.
export function LeaderboardRow({
  item,
  maxScore = DEFAULT_MAX_SCORE,
  className,
}: LeaderboardRowProps) {
  // Two-decimal percent, matching the app (e.g. 500/600 → 83.33%).
  const pct = Math.round((item.finalPoints / maxScore) * 10000) / 100;
  const initial = item.displayName.charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        'flex items-center gap-3 px-3 py-2',
        item.isCurrentPlayer && 'rounded-xl bg-primary/10',
        className
      )}
    >
      {/* avatar: the player's initial in a brand-tinted circle */}
      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-medium text-card-foreground">
        {initial}
      </div>

      {/* name + the "(you)" tag for the current player */}
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p className="truncate text-sm font-medium text-card-foreground">
            {item.displayName}
          </p>
          {item.isCurrentPlayer && (
            <span className="text-2xs font-medium text-accent">(you)</span>
          )}
        </div>
      </div>

      {/* score: % over points, then a thin accent-filled progress bar */}
      <div className="flex w-[100px] flex-col justify-center gap-1 text-right">
        <div className="flex items-center justify-between">
          <p className="text-2xs font-medium leading-none text-accent">{pct}%</p>
          <p className="text-sm font-medium leading-none text-dark-muted">
            {item.finalPoints}
          </p>
        </div>
        <div className="h-[7px] w-full overflow-hidden rounded-full bg-slot">
          <div
            className="h-full rounded-full bg-accent"
            style={{ width: `${Math.min(pct, 100)}%` }}
          />
        </div>
      </div>
    </div>
  );
}

export interface LeaderboardProps {
  items: LeaderboardEntry[];
  maxScore?: number;
  className?: string;
}

// The full ranked list: rows in the given order (already sorted by the caller).
export function Leaderboard({
  items,
  maxScore = DEFAULT_MAX_SCORE,
  className,
}: LeaderboardProps) {
  return (
    <div className={cn('font-sans flex flex-col gap-1', className)}>
      {items.map((item, i) => (
        <LeaderboardRow key={i} item={item} maxScore={maxScore} />
      ))}
    </div>
  );
}
