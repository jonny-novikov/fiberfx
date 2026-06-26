import * as React from 'react';
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

// The linear scoring scale: a score keyed to how close the guess was (Figma copy).
const SCORING: ReadonlyArray<readonly [string, string]> = [
  ['100', 'Эмоджи на своём месте'],
  ['80', '1 клетка от правильной позиции'],
  ['60', '2 клетки от правильной позиции'],
  ['40', '3 клетки от правильной позиции'],
  ['20', '4 клетки от правильной позиции'],
  ['0', '5 клеток от правильной позиции'],
];

const RULES: readonly string[] = [
  'Неограниченное количество попыток',
  'Каждая попытка стоит фиксированное количество 🔑 ключей',
  'Попытка добавляет кристаллы в призовой пул, каждый раз увеличивая его сумму',
  'После ввода кода вы получаете результат в процентах, который рассчитывается по следующей системе',
  'При одинаковом количестве набранных очков первое место достаётся тому, кто сделал это первым',
];

export function GameRules({ onHowToPlay, className }: GameRulesProps) {
  return (
    <BoardCard className={cn('font-sans', className)}>
      <h2 className="text-h1 font-bold mb-4 flex items-center gap-2">
        <span aria-hidden>🎲</span>
        <span>Правила игры</span>
      </h2>
      <p className="text-h5 text-card-foreground-secondary mb-6">
        Заполучить призовой пул, отгадав комбинацию из 6 эмодзи. Будь первым, кто наберет больше 600
        поинтов!
      </p>

      <ol className="list-decimal list-inside text-h5 space-y-1 mb-4">
        {RULES.map((rule) => (
          <li key={rule}>{rule}</li>
        ))}
      </ol>

      <ul className="text-h5 space-y-1 mb-6">
        {SCORING.map(([score, label]) => (
          <li key={score} className="flex items-baseline gap-3">
            <span className="text-dark-muted font-medium w-6 text-right shrink-0">{score}</span>
            <span>{label}</span>
          </li>
        ))}
      </ul>

      <Button variant="outline" className="w-full" onClick={onHowToPlay}>
        Как играть?
      </Button>
    </BoardCard>
  );
}
