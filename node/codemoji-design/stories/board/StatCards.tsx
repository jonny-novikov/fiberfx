import * as React from 'react';
import { cn } from '../lib/cn';

// Row 3 of the board's Info dashboard (Figma 94:2974 → "Info"/Frame 18): three
// small stat cards — total players, total attempts, and the room's best attempt so
// far. Each is a white card (big value over an emoji-tagged label) lifted off the
// gradient with the same soft blue shadow as the rest of the dashboard.
const LIFT = '0 10px 22px rgba(170,201,216,0.5)';

export interface StatCardsProps {
  /** Figma: "147 / 👥 Всего игроков" */
  totalPlayers?: number;
  /** Figma: "0 / 🎯 Всего попыток" */
  totalAttempts?: number;
  /** Figma: "0 / ⭐ Лучшая попытка" */
  bestAttempt?: number;
  className?: string;
}

export function StatCards({
  totalPlayers = 147,
  totalAttempts = 0,
  bestAttempt = 0,
  className,
}: StatCardsProps) {
  const items = [
    { value: totalPlayers, label: '👥 Всего игроков' },
    { value: totalAttempts, label: '🎯 Всего попыток' },
    { value: bestAttempt, label: '⭐ Лучшая попытка' },
  ];
  return (
    <div className={cn('flex gap-2', className)}>
      {items.map((it, i) => (
        <div
          key={i}
          className="flex flex-1 flex-col items-center justify-center gap-0.5 rounded-2xl bg-card px-1 py-2 text-card-foreground"
          style={{ boxShadow: LIFT }}
        >
          <span className="text-h2 font-bold leading-none tabular-nums">{it.value}</span>
          <span className="text-center text-2xs leading-tight text-card-foreground-secondary">
            {it.label}
          </span>
        </div>
      ))}
    </div>
  );
}
