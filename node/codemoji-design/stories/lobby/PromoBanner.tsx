import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The earnings / buy-keys card in the lobby (121:2056). Re-expresses
// widgets/promo-banner: a white card with a centered "earned over all time"
// headline + a description, then a full-width buy CTA. The app uses
// `variant="gradient"` (an orange gradient) + a lucide <StarIcon>; here the CTA
// is the themeable `buy` Button (rides bg-accent) and the star is a Unicode "⭐".
// Reuses the shared BoardCard surface; self-contained (onBuy is a callback).
export interface PromoBannerProps {
  /** total winnings across all players, in whole currency units */
  totalEarned?: number;
  onBuy?: () => void;
  className?: string;
}

export function PromoBanner({ totalEarned = 25693, onBuy, className }: PromoBannerProps) {
  return (
    <BoardCard className={cn('text-center', className)}>
      <h2 className="text-xl font-bold leading-tight">
        Players have earned ${totalEarned.toLocaleString()} over all time
      </h2>
      <p className="mt-3 text-xs text-card-foreground-secondary">
        Buy keys to crack more safes and grow the pool
      </p>
      <Button className="mt-4 w-full" variant="buy" onClick={onBuy}>
        Buy keys ⭐
      </Button>
    </BoardCard>
  );
}
