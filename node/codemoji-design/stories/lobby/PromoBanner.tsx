import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// The earnings card near the top of the lobby (121:2056, Figma "Frame 166"). Text is
// verbatim from the Figma master: a centered "players found $N over all time" headline
// + an "add more keys" line, then the buy CTA "Приобрести ключи ⭐". The CTA is a
// purchase role, so it rides --gradient-purchase (the orange buy gradient) — the
// design system's deliberate color for spend actions (Figma paints it black). Reuses BoardCard.
export interface PromoBannerProps {
  /** total winnings across all players, in whole currency units (Figma: $25693) */
  totalEarned?: number;
  onBuy?: () => void;
  className?: string;
}

export function PromoBanner({ totalEarned = 25693, onBuy, className }: PromoBannerProps) {
  return (
    <BoardCard className={cn('text-center', className)}>
      <h2 className="text-h3 font-bold leading-tight text-card-foreground">
        Игроки нашли ${totalEarned} в сейфах за всё время игры
      </h2>
      <p className="mt-3 text-h5 text-card-foreground-secondary">
        Добавляй больше ключей, чтобы быстрее разгадывать коды
      </p>
      <Button className="mt-4 w-full" variant="purchase" onClick={onBuy}>
        Приобрести ключи ⭐
      </Button>
    </BoardCard>
  );
}
