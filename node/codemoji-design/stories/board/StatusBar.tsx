import * as React from 'react';
import { cn } from '../lib/cn';

// The thin resources strip atop the board (94:2974) — a single tappable row
// showing the player's handle on the left and their balances on the right.
// Re-expresses widgets/status-bar; in the app the whole strip is a button that
// navigates to withdraw, so this accepts `onClick` (the navigation itself is the
// app's concern, omitted here).
export interface StatusBarProps {
  username?: string;
  diamonds?: number;
  clips?: number;
  keys?: number;
  onClick?: () => void;
  className?: string;
}

export function StatusBar({
  username = '@player',
  diamonds = 0,
  clips = 0,
  keys = 0,
  onClick,
  className,
}: StatusBarProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex h-8 w-full items-center justify-between rounded-2xl bg-card px-3 text-h5 text-card-foreground',
        className
      )}
    >
      <span className="font-bold">{username}</span>
      <span className="flex items-center gap-3 text-card-foreground-secondary">
        <span>💎 {diamonds.toLocaleString()}</span>
        <span>📎 {clips.toLocaleString()}</span>
        <span>🔑 {keys.toLocaleString()}</span>
      </span>
    </button>
  );
}
