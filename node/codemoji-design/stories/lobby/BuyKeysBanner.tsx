import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The promo card repeated at the foot of the lobby (121:2056) — Figma shows the same
// earnings promo near the top (PromoBanner) and again at the bottom. Copy is localized
// (lobby.promo.* preserves the Figma RU verbatim + adds EN; the CTA reuses the shared
// keys.purchase.button + the ⭐ literal). The buy CTA rides --gradient-purchase (the
// orange buy gradient — the purchase role). Reuses BoardCard; self-contained (onBuy).
export interface BuyKeysBannerProps {
  /** total winnings across all players, in whole currency units (Figma: $25693) */
  totalEarned?: number;
  onBuy?: () => void;
  className?: string;
}

export function BuyKeysBanner({ totalEarned = 25693, onBuy, className }: BuyKeysBannerProps) {
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
