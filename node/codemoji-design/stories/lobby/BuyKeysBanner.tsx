import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The promo card repeated at the foot of the lobby (121:2056) — Figma shows the same
// earnings promo near the top (PromoBanner) and again at the bottom. Text is verbatim
// from the Figma master; the reused black check button ("Проверить" + 🔑 cost) is kept
// faithfully (a likely Figma placeholder). Reuses BoardCard; self-contained (onCta).
export interface BuyKeysBannerProps {
  /** total winnings across all players, in whole currency units (Figma: $25693) */
  totalEarned?: number;
  /** the reused check button's key-cost chip (Figma: 3) */
  keyCost?: number;
  onCta?: () => void;
  className?: string;
}

export function BuyKeysBanner({ totalEarned = 25693, keyCost = 3, onCta, className }: BuyKeysBannerProps) {
  return (
    <BoardCard className={cn('text-center', className)}>
      <h2 className="text-h3 font-bold leading-tight text-card-foreground">
        Игроки нашли ${totalEarned} в сейфах за всё время игры
      </h2>
      <p className="mt-3 text-h5 text-card-foreground-secondary">
        Добавляй больше ключей, чтобы быстрее разгадывать коды
      </p>
      <Button className="mt-4 w-full" variant="default" onClick={onCta}>
        Проверить 🔑 {keyCost}
      </Button>
    </BoardCard>
  );
}
