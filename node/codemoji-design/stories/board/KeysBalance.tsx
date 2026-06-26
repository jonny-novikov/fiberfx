import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from './lib/BoardCard';
import { Button } from '../components/Button';

// The keys balance card (94:2974) — the player's key count over a Buy button.
// Re-expresses entities/balance/balance-key-widget. The Buy button reuses the
// `buy` Button variant, which rides bg-accent, so the CTA recolors with the
// Theme toolbar (orange | blue | green).
export interface KeysBalanceProps {
  keys?: number;
  onBuy?: () => void;
  className?: string;
}

export function KeysBalance({ keys = 0, onBuy, className }: KeysBalanceProps) {
  return (
    <BoardCard className={cn('flex flex-col items-center gap-3 text-center', className)}>
      <div className="text-h1 font-bold">🔑 Keys: {keys.toLocaleString()}</div>
      <p className="text-xs text-card-foreground-secondary">
        Spend a key to lock in a guess. Buy more to keep playing.
      </p>
      <Button variant="buy" className="w-full" onClick={onBuy}>
        Buy keys
      </Button>
    </BoardCard>
  );
}
