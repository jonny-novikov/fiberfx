import * as React from 'react';
import { cn } from '../lib/cn';

// The ranked player list under the Leaderboard tab (94:2974). Re-expresses
// entities/leaderboard/leaderboard-item in the Figma master's shape: an avatar, the
// player's @handle, then a right-aligned metric-over-score pair with a thin progress
// bar (the bar tracks score/maxScore). The metric is verbatim from the data — the
// achievement TIME for the top scorers (ties broken by who got there first), else a
// match percent. A "leader-change notifications" toggle closes the list. The metric +
// bar are the app's FIXED "Main Blue" token (--color-main-blue #54C0EC), NOT the
// themeable accent — pinned by Operator ruling so the leaderboard's blue is constant.
const DEFAULT_MAX_SCORE = 600;

export interface LeaderboardEntry {
  /** the player's @-handle (Figma: "@phantomblade") */
  handle: string;
  /** points scored; drives the progress bar (out of maxScore) and the right number */
  score: number;
  /** the label left of the score, verbatim (a time like "21:49" or a percent "11.2%") */
  metric?: string;
  /** an emoji avatar (the master uses photos; the design system approximates) */
  avatar?: string;
  isCurrentPlayer?: boolean;
  className?: string;
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
  const pct = Math.min((item.score / maxScore) * 100, 100);
  // Avatar: the given emoji, else the handle's first letter (stripping a leading @).
  const fallback = item.handle.replace(/^@/, '').charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        'flex items-center gap-3 px-2 py-2',
        item.isCurrentPlayer && 'rounded-xl bg-primary/10',
        className
      )}
    >
      {/* avatar circle — emoji (or the handle's initial) */}
      <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-base font-medium text-card-foreground">
        {item.avatar ?? fallback}
      </div>

      {/* the @handle */}
      <p className="min-w-0 flex-1 truncate text-sm font-medium text-card-foreground">
        {item.handle}
      </p>

      {/* metric over score, then a thin accent-filled progress bar */}
      <div className="flex w-[88px] shrink-0 flex-col justify-center gap-1">
        <div className="flex items-center justify-between leading-none">
          <span className="text-2xs font-medium text-main-blue">{item.metric}</span>
          <span className="text-sm font-medium text-dark-muted tabular-nums">{item.score}</span>
        </div>
        <div className="h-[7px] w-full overflow-hidden rounded-full bg-slot">
          <div className="h-full rounded-full bg-main-blue" style={{ width: `${pct}%` }} />
        </div>
      </div>
    </div>
  );
}

export interface LeaderboardProps {
  items: LeaderboardEntry[];
  maxScore?: number;
  /** show the "leader-change notifications" toggle row under the list (Figma) */
  showNotify?: boolean;
  className?: string;
}

// The full ranked list: rows in the given order (already sorted by the caller),
// closed by the leader-change notifications toggle.
export function Leaderboard({
  items,
  maxScore = DEFAULT_MAX_SCORE,
  showNotify = true,
  className,
}: LeaderboardProps) {
  return (
    <div className={cn('font-sans flex flex-col gap-1', className)}>
      {items.map((item, i) => (
        <LeaderboardRow key={i} item={item} maxScore={maxScore} />
      ))}
      {showNotify && (
        <div className="mt-1 flex items-center justify-between gap-2 px-2 py-2 text-sm">
          <span className="flex items-center gap-2 text-card-foreground-secondary">
            <span aria-hidden>🔔</span>
            <span>Уведомления о смене лидеров</span>
          </span>
          <span
            aria-hidden
            className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-success text-xs font-bold text-white"
          >
            ✓
          </span>
        </div>
      )}
    </div>
  );
}
