import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The earnings card near the top of the lobby (121:2056, Figma "Frame 166"). Copy is
// localized: lobby.promo.* preserves the Figma RU verbatim + adds EN; the CTA reuses
// the shared keys.purchase.button (+ the ⭐ literal, as the app appends a StarIcon).
// A centered "players found $N over all time" headline + an "add more keys" line, then
// the buy CTA. The CTA is a purchase role, so it rides --gradient-purchase (the orange
// buy gradient) — the design system's deliberate color for spend actions (Figma paints
// it black). Reuses BoardCard. Amount renders without thousands separators (Figma).
export interface PromoBannerProps {
  /** total winnings across all players, in whole currency units (Figma: $25693) */
  totalEarned?: number;
  onBuy?: () => void;
  className?: string;
}

export function PromoBanner({ totalEarned = 25693, onBuy, className }: PromoBannerProps) {
  const { t } = useTranslation();
  return (
    <BoardCard className={cn('text-center', className)}>
      <h2 className="text-h1 font-bold leading-tight text-card-foreground">
        {t('lobby.promo.totalEarned', { amount: totalEarned })}
      </h2>
      <p className="mt-3 text-h5 text-card-foreground-secondary">
        {t('lobby.promo.addKeys')}
      </p>
      <Button className="mt-4 w-full" variant="purchase" onClick={onBuy}>
        {t('keys.purchase.button')} ⭐
      </Button>
    </BoardCard>
  );
}
