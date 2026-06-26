import * as React from 'react';
import { cn } from '../lib/cn';

// Row 2 of the board's Info dashboard (Figma 94:2974 → "Info"/Frame 17): the
// round timer beside the prize pool. Two cards — a WHITE countdown card ("Конец
// раунда") and a GREEN prize card (`bg-success`, the big dollar pool + the diamond
// count). Board-only (the Golden Game uses GoldenHero instead), so it owns this
// two-card shape directly. Both cards carry the dashboard's soft blue lift.
const LIFT = '0 10px 22px rgba(170,201,216,0.5)';

export interface RoundInfoProps {
  /** countdown string, e.g. 'HH:MM:SS' (Figma: "34:59:38") */
  timeLeft?: string;
  /** prize pool in dollars, shown as the big number (Figma: "$2352") */
  prizeUsd?: number;
  /** diamonds in the pool, shown in the label (Figma: "Призовой пул 💎 468") */
  diamonds?: number;
  className?: string;
}

export function RoundInfo({
  timeLeft = '34:59:38',
  prizeUsd = 2352,
  diamonds = 468,
  className,
}: RoundInfoProps) {
  return (
    <div className={cn('flex gap-2', className)}>
      {/* countdown — a white card */}
      <div
        className="flex flex-1 flex-col items-center justify-center gap-0.5 rounded-2xl bg-card p-3 text-card-foreground"
        style={{ boxShadow: LIFT }}
      >
        <span className="text-h1 font-bold leading-none tabular-nums">{timeLeft}</span>
        <span className="text-2xs text-card-foreground-secondary">Конец раунда</span>
      </div>
      {/* prize pool — the green card */}
      <div
        className="flex flex-1 flex-col items-center justify-center gap-0.5 rounded-2xl bg-success p-3 text-white"
        style={{ boxShadow: LIFT }}
      >
        <span className="text-h1 font-bold leading-none tabular-nums">${prizeUsd}</span>
        <span className="text-2xs opacity-90">Призовой пул 💎 {diamonds}</span>
      </div>
    </div>
  );
}
