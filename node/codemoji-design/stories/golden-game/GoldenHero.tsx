import * as React from 'react';
import { cn } from '../lib/cn';

// The signature golden surface — the gold-gradient hero on the Golden Room
// screens (1089:19410 / 1108:27589). Re-expresses the golden variant of
// widgets/lobby-info: the round timer + the BOOSTED prize pool (the base pool ×
// gold_multiplier) on a --gradient-gold card, over a "Golden Room / Read rules"
// banner. The gild is the --gradient-gold token (via the `bg-gradient-gold`
// utility + a clip-text fill), not the app's gold.png raster.
export interface GoldenHeroProps {
  timeLeft?: string;
  prizePool?: number;
  /** the gold_multiplier applied to the base pool */
  boost?: number;
  onReadRules?: () => void;
  className?: string;
}

// gold gradient clipped to the text (the app does this inline on the golden
// banner); uses the --gradient-gold token, not a raw hex.
const goldText: React.CSSProperties = {
  background: 'var(--gradient-gold)',
  WebkitBackgroundClip: 'text',
  backgroundClip: 'text',
  color: 'transparent',
};

export function GoldenHero({
  timeLeft = '48:00:00',
  prizePool = 2352,
  boost = 3,
  onReadRules,
  className,
}: GoldenHeroProps) {
  return (
    <div className={cn('overflow-hidden rounded-2xl', className)}>
      <div className="grid grid-cols-2 gap-3 bg-gradient-gold p-4 text-primary">
        <div className="text-center">
          <div className="text-2xl font-bold leading-none">{timeLeft}</div>
          <div className="mt-1 text-2xs font-medium">Round time</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold leading-none">{prizePool.toLocaleString()} 💎</div>
          <div className="mt-1 text-2xs font-medium">Prize pool · {boost}× boost</div>
        </div>
      </div>
      <button
        type="button"
        onClick={onReadRules}
        className="flex w-full items-center justify-between bg-primary px-4 py-3"
      >
        <span className="font-bold" style={goldText}>
          Golden Room
        </span>
        <span className="text-xs font-medium text-primary-foreground">Read rules ›</span>
      </button>
    </div>
  );
}
