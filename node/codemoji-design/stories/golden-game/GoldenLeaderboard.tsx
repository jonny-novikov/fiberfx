import * as React from 'react';
import { cn } from '../lib/cn';

// The golden standings (1089:19410 / 1108:27589). Unlike the board leaderboard,
// the Golden Room reveals every player's GUESS CODE alongside the prize they took
// (cash or keys). Re-expresses golden-game-tabs' GoldenLeaderboardList: rank ·
// avatar · name · revealed code · prize. The code is compact inline glyphs (a
// dense row), not EmojiTile tiles.
export interface GoldenStanding {
  rank: number;
  displayName: string;
  code: string[];
  /** the prize taken, pre-formatted: "$23.43" or "🔑 100" */
  prize: string;
  isCurrentPlayer?: boolean;
}

export function GoldenLeaderboardRow({ item }: { item: GoldenStanding }) {
  return (
    <div
      className={cn(
        'flex items-center gap-2 rounded-xl px-2 py-2',
        item.isCurrentPlayer && 'bg-primary/10'
      )}
    >
      <span className="w-5 shrink-0 text-center text-sm font-bold text-dark-muted">{item.rank}</span>
      {/* avatar: the player's initial in a brand-tinted circle */}
      <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-medium text-card-foreground">
        {item.displayName.charAt(0).toUpperCase()}
      </div>
      <span className="min-w-0 shrink truncate text-sm font-medium text-card-foreground">
        {item.displayName}
      </span>
      {/* the revealed guess code, compact inline glyphs */}
      <div className="flex flex-1 justify-center gap-0.5 text-base leading-none">
        {item.code.map((emoji, i) => (
          <span key={i}>{emoji}</span>
        ))}
      </div>
      <span className="shrink-0 whitespace-nowrap text-sm font-bold text-dark-muted">
        {item.prize}
      </span>
    </div>
  );
}

export interface GoldenLeaderboardProps {
  items: GoldenStanding[];
  className?: string;
}

export function GoldenLeaderboard({ items, className }: GoldenLeaderboardProps) {
  return (
    <div className={cn('font-sans flex flex-col gap-1', className)}>
      {items.map((item) => (
        <GoldenLeaderboardRow key={item.rank} item={item} />
      ))}
    </div>
  );
}
