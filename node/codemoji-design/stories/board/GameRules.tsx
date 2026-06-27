import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { BoardCard } from './lib/BoardCard';
import { Button } from '../components/Button';

// The rules panel (Figma 94:2974 / 121:2056) — re-expresses widgets/game-rules: the
// title row, the rule list, the linear-scoring table, and the How-to-play button.
// Text + scoring are verbatim from the Figma master (Russian); the "Как играть?" CTA
// is Figma's outlined button. Presentational only; the onboarding drawer it opens is
// omitted. Shared by the board and the lobby (both render the same rules card).
export interface GameRulesProps {
  onHowToPlay?: () => void;
  className?: string;
}

// The linear scoring scale (score → how close the guess was), highest to lowest.
// Labels come from the board.gameRules.scoring.<score> keys; the numbers are
// language-neutral. The score "0" row's wording differs from the app's game-rules
// widget — the board keeps its own copy under the board.* namespace.
const SCORE_KEYS = ['100', '80', '60', '40', '20', '0'] as const;

// The rule list, in order. Labels come from the board.gameRules.rules.<key> keys.
const RULE_KEYS = ['unlimited', 'attemptCost', 'prizePool', 'scoring', 'firstWins'] as const;

export function GameRules({ onHowToPlay, className }: GameRulesProps) {
  const { t } = useTranslation();
  return (
    <BoardCard className={cn('font-sans', className)}>
      <h2 className="text-h1 font-bold mb-4 flex items-center gap-2">
        <span aria-hidden>🎲</span>
        <span>{t('board.gameRules.title')}</span>
      </h2>
      <p className="text-h5 text-card-foreground-secondary mb-6">
        {t('board.gameRules.description')}
      </p>

      <ol className="list-decimal list-inside text-h5 space-y-1 mb-4">
        {RULE_KEYS.map((key) => (
          <li key={key}>{t(`board.gameRules.rules.${key}`)}</li>
        ))}
      </ol>

      <ul className="text-h5 space-y-1 mb-6">
        {SCORE_KEYS.map((score) => (
          <li key={score} className="flex items-baseline gap-3">
            <span className="text-dark-muted font-medium w-6 text-right shrink-0">{score}</span>
            <span>{t(`board.gameRules.scoring.${score}`)}</span>
          </li>
        ))}
      </ul>

      <Button variant="outline" className="w-full" onClick={onHowToPlay}>
        {t('board.gameRules.howToPlay')}
      </Button>
    </BoardCard>
  );
}
