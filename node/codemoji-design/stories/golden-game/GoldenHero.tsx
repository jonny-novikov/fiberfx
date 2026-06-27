import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';

// The signature golden surface — the gold hero on the Golden Room screens
// (1089:19410 / 1108:27589). Re-expresses the golden variant of widgets/lobby-info:
// the round timer + the BOOSTED prize pool (the base pool × gold_multiplier) on a
// gold-texture card, over a "Golden Room / Read rules" banner. The gild is the gold
// TEXTURE (the `bg-gold-texture` utility + a clip-text fill) = the app's gold.png.
export interface GoldenHeroProps {
  timeLeft?: string;
  prizePool?: number;
  /** the gold_multiplier applied to the base pool */
  boost?: number;
  onReadRules?: () => void;
  className?: string;
}

// gold TEXTURE clipped to the text (the app does this inline on the golden banner);
// uses the --gold-texture token (gold.png), covered to the text box.
const goldText: React.CSSProperties = {
  backgroundImage: 'var(--gold-texture)',
  backgroundSize: 'cover',
  backgroundPosition: 'center',
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
  const { t } = useTranslation();
  return (
    <div className={cn('overflow-hidden rounded-2xl', className)}>
      <div className="grid grid-cols-2 gap-3 bg-gold-texture p-4 text-primary">
        <div className="text-center">
          <div className="text-2xl font-bold leading-none">{timeLeft}</div>
          <div className="mt-1 text-2xs font-medium">{t('golden.roundTime')}</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold leading-none">{prizePool.toLocaleString()} 💎</div>
          <div className="mt-1 text-2xs font-medium">{t('golden.prizePoolBoost', { boost })}</div>
        </div>
      </div>
      <button
        type="button"
        onClick={onReadRules}
        className="flex w-full items-center justify-between bg-primary px-4 py-3"
      >
        <span className="font-bold" style={goldText}>
          {t('golden.roomTitle')}
        </span>
        <span className="text-xs font-medium text-primary-foreground">{t('golden.readRules')} ›</span>
      </button>
    </div>
  );
}
