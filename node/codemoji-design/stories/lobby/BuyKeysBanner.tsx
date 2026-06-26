import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The "players found / get more keys" card at the foot of the lobby (121:2056).
// Re-expresses widgets/buy-keys-banner: a centered headline tallying players who
// won, a secondary nudge line, and a full-width buy CTA. The app's
// `variant="gradient"` (an orange raster gild) does NOT exist here — the CTA
// rides `Button variant="buy"` (bg-accent), the single themeable accent channel,
// so the highlight recolors with the toolbar. Self-contained: the app's i18n +
// the keys-purchase drawer atom become an English label + an `onBuy` callback.
export interface BuyKeysBannerProps {
  /** how many players have won so far; rendered with thousands separators */
  players?: number;
  onBuy?: () => void;
  className?: string;
}

export function BuyKeysBanner({ players = 25693, onBuy, className }: BuyKeysBannerProps) {
  return (
    <BoardCard className={cn('flex flex-col gap-4 text-center', className)}>
      <h2 className="text-xl font-bold leading-tight text-card-foreground">
        {players.toLocaleString()} players found their win
      </h2>
      <p className="text-xs text-card-foreground-secondary">Get more keys to play more</p>
      <Button variant="buy" className="w-full" onClick={onBuy}>
        Buy keys ⭐
      </Button>
    </BoardCard>
  );
}
