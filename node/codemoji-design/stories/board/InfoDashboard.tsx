import * as React from 'react';
import { cn } from '../lib/cn';
import { BalancePill } from './BalancePill';
import { RoundInfo } from './RoundInfo';
import { StatCards } from './StatCards';

// The board's top Info dashboard (Figma 94:2974 → "Info", a drop-shadowed block):
// three stacked rows — the keys-balance pill, the timer + prize pair, then the
// three round-stat cards. Replaces the old StatusBar + RoundInfo + KeysBalance trio
// the board used to stack separately. Each row is its own card carrying the soft
// blue lift, so the whole block floats on the screen gradient like the master.
export interface InfoDashboardProps {
  /** key balance in the pill (Figma: "Баланс 🔑 34") */
  keys?: number;
  timeLeft?: string;
  prizeUsd?: number;
  diamonds?: number;
  totalPlayers?: number;
  totalAttempts?: number;
  bestAttempt?: number;
  className?: string;
}

export function InfoDashboard({
  keys = 34,
  timeLeft = '34:59:38',
  prizeUsd = 2352,
  diamonds = 468,
  totalPlayers = 147,
  totalAttempts = 0,
  bestAttempt = 0,
  className,
}: InfoDashboardProps) {
  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <BalancePill keys={keys} />
      <RoundInfo timeLeft={timeLeft} prizeUsd={prizeUsd} diamonds={diamonds} />
      <StatCards
        totalPlayers={totalPlayers}
        totalAttempts={totalAttempts}
        bestAttempt={bestAttempt}
      />
    </div>
  );
}
