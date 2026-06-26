import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The earnings card near the top of the lobby (121:2056, Figma "Frame 166"). Text is
// verbatim from the Figma master: a centered "players found $N over all time" headline
// + a "add more keys" line, then the card's CTA. Figma reuses the black check button
// component here ("Проверить" + a 🔑 key-cost) — matched faithfully (a likely Figma
// placeholder); kept black to match (not a purchase/entry role). Reuses BoardCard.
export interface PromoBannerProps {
  /** total winnings across all players, in whole currency units (Figma: $25693) */
  totalEarned?: number;
  /** the reused check button's key-cost chip (Figma: 3) */
  keyCost?: number;
  onCta?: () => void;
  className?: string;
}

export function PromoBanner({ totalEarned = 25693, keyCost = 3, onCta, className }: PromoBannerProps) {
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
