import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from './lib/BoardCard';
import { Button } from '../components/Button';

// The rules panel from the board (94:2974) — re-expresses widgets/game-rules:
// the title row, the four-rule list, the linear-scoring table, the How-to-play
// button, and the tip line. Presentational only; the onboarding drawer the real
// button opens is omitted (this documents the panel's content + tokens).
export interface GameRulesProps {
  onHowToPlay?: () => void;
  className?: string;
}

// The linear scoring scale: a score keyed to how close the guess was. Kept as
// data so every row shares the same fixed-width number column.
const SCORING: ReadonlyArray<readonly [string, string]> = [
  ['100', 'all 6 in the right place'],
  ['80', '5 in the right place'],
  ['60', '4 in the right place'],
  ['40', '3 in the right place'],
  ['20', '2 in the right place'],
  ['0', 'no matches'],
];

export function GameRules({ onHowToPlay, className }: GameRulesProps) {
  return (
    <BoardCard className={cn('font-sans', className)}>
      <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
        <span aria-hidden>🎲</span>
        <span>Game rules</span>
      </h2>
      <p className="text-xs text-card-foreground-secondary mb-6">
        Guess the secret six-emoji combination. The closer you get, the higher
        your score — and the bigger your share of the prize pool.
      </p>

      <ol className="list-decimal list-inside text-xs space-y-1 mb-4">
        <li>You get unlimited attempts.</li>
        <li>Each attempt costs keys 🔑.</li>
        <li>The prize pool grows with every attempt.</li>
        <li>The closest guess wins, scored linearly by emojis placed.</li>
      </ol>

      <ul className="text-xs space-y-1 mb-6">
        {SCORING.map(([score, label]) => (
          <li key={score} className="flex items-baseline gap-3">
            <span className="text-dark-muted font-medium w-6 text-right shrink-0">
              {score}
            </span>
            <span>{label}</span>
          </li>
        ))}
      </ul>

      <Button className="w-full mb-4" onClick={onHowToPlay}>
        How to play?
      </Button>

      <p className="text-xs text-muted">
        💡 Tip: lock the emojis you are sure of before your next attempt.
      </p>
    </BoardCard>
  );
}
