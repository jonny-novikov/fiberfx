import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { SpriteEmoji } from './lib/SpriteEmoji';

// The player's own guess history — the FIRST board tab (94:2974, the app's
// default `defaultValue="history"`). Re-expresses entities/history/history-item +
// history-list (codemoji-app): each row is the attempt number (🔖 N), the guessed
// emoji row, then a right-aligned points-over-progress-bar pair. The emojis carry
// the app's per-peg ANNOTATION states — a player taps an emoji to cycle it through
// idle → green (right place) → yellow (right emoji, wrong place) → red (absent) as
// a private deduction aid. Those four colours are FIXED (the app's literals), not
// the themeable accent, like the leaderboard's Main Blue. The right column shares
// the Leaderboard row's width + bar so the two tabs line up when switched.
const DEFAULT_MAX_POINTS = 600;

// A per-emoji annotation. `idle` = unmarked; the rest mirror the app's peg colours.
export type GuessMark = 'idle' | 'green' | 'yellow' | 'red';

// The fixed peg palette — verbatim from codemoji-app history-item (border + fill).
const MARK_CLASS: Record<GuessMark, string> = {
  idle: 'border-transparent',
  green: 'border-[#4CAF50] bg-[#E8F5E9]',
  yellow: 'border-[#FFC107] bg-[#FFF8E1]',
  red: 'border-[#F44336] bg-[#FFEBEE]',
};

export interface GuessHistoryEntry {
  /** the attempt's number, shown after the 🔖 (the app counts newest-first) */
  attemptNumber: number;
  /** the guessed code as XXYY sprite codes (drawn from the sprite sheet) */
  emojis: string[];
  /** points scored on this attempt (right column, over the bar) */
  points: number;
  /** match share 0–100 that fills the bar; defaults to points/maxPoints */
  percent?: number;
  /** optional per-emoji annotation (same length/order as `emojis`) */
  marks?: GuessMark[];
  className?: string;
}

export interface GuessHistoryRowProps {
  item: GuessHistoryEntry;
  /** the points value that maps to a full bar when `percent` is absent */
  maxPoints?: number;
  className?: string;
}

// One attempt row. Exported so a single row can be documented in isolation.
export function GuessHistoryRow({
  item,
  maxPoints = DEFAULT_MAX_POINTS,
  className,
}: GuessHistoryRowProps) {
  const pct =
    item.percent != null
      ? Math.min(item.percent, 100)
      : Math.min((item.points / maxPoints) * 100, 100);
  return (
    <div className={cn('flex items-center gap-2 px-2 py-1.5', className)}>
      {/* attempt number — 🔖 N (matches the leaderboard avatar's left slot) */}
      <p className="flex w-9 shrink-0 items-center gap-1">
        <span aria-hidden className="text-base leading-none">🔖</span>
        <span className="text-sm font-medium text-dark-muted tabular-nums">
          {item.attemptNumber}
        </span>
      </p>

      {/* the guessed emoji row — each peg in a bordered cell, coloured by its mark */}
      <div className="flex min-w-0 flex-1 items-center justify-center gap-0.5">
        {item.emojis.map((code, i) => (
          <span
            key={`${code}-${i}`}
            className={cn(
              'flex items-center justify-center rounded-lg border-2 p-0.5',
              MARK_CLASS[item.marks?.[i] ?? 'idle']
            )}
          >
            <SpriteEmoji code={code} size={22} />
          </span>
        ))}
      </div>

      {/* points over a thin Main-Blue bar — same width as the leaderboard column */}
      <div className="flex w-[88px] shrink-0 flex-col justify-center gap-1">
        <span className="text-right text-sm font-medium leading-none text-dark-muted tabular-nums">
          {item.points}
        </span>
        <div className="h-[7px] w-full overflow-hidden rounded-full bg-slot">
          <div className="h-full rounded-full bg-main-blue" style={{ width: `${pct}%` }} />
        </div>
      </div>
    </div>
  );
}

export interface GuessHistoryProps {
  items: GuessHistoryEntry[];
  maxPoints?: number;
  className?: string;
}

// The full attempt list (already ordered newest-first by the caller). With no
// attempts it shows the app's empty prompt (history.empty + makeFirstAttempt).
export function GuessHistory({ items, maxPoints = DEFAULT_MAX_POINTS, className }: GuessHistoryProps) {
  const { t } = useTranslation();
  if (items.length === 0) {
    return (
      <div className={cn('font-sans py-8 text-center', className)}>
        <p className="text-sm text-muted">{t('history.empty')}</p>
        <p className="mt-1 text-xs text-muted/70">{t('history.makeFirstAttempt')}</p>
      </div>
    );
  }
  return (
    <div className={cn('font-sans flex flex-col gap-1', className)}>
      {items.map((item, i) => (
        <GuessHistoryRow key={i} item={item} maxPoints={maxPoints} />
      ))}
    </div>
  );
}
