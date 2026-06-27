import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { SpriteEmoji } from './lib/SpriteEmoji';

// The previous-attempt row above the guess slots. Faithful re-expression of the app's
// shared/ui/previous-attempt (codemoji-app): a CENTERED button — the hardcoded label
// "Предыдущая попытка:", then the last guess as small sprite emoji, then the score it
// earned (a bare integer, only shown when non-zero). Tapping refills the slots with it
// (the app's fillSlots). Emoji are XXYY sprite codes drawn at size 14, like the app.
export interface PreviousAttemptProps {
  /** the guess glyphs, left to right, as XXYY sprite codes (a hole = empty position) */
  emojis: (string | undefined)[];
  /** points it scored (shown only when non-zero) */
  points?: number;
  /** sprite size for each glyph (app default 14) */
  emojiSize?: number;
  /** fired when the row is tapped (refills the slots with this guess) */
  onClick?: () => void;
  className?: string;
}

export function PreviousAttempt({
  emojis,
  points = 0,
  emojiSize = 14,
  onClick,
  className,
}: PreviousAttemptProps) {
  const { t } = useTranslation();
  return (
    <div className="flex justify-center">
      <button
        type="button"
        onClick={onClick}
        className={cn(
          'flex items-center justify-center gap-2 text-xs font-medium leading-none',
          onClick && 'cursor-pointer transition-opacity hover:opacity-70 active:opacity-50',
          className
        )}
      >
        <span>{t('board.previousAttempt')}</span>
        <span className="inline-flex items-center gap-1">
          {emojis.map((code, i) =>
            code ? (
              <SpriteEmoji key={i} code={code} size={emojiSize} />
            ) : (
              <span key={i} style={{ width: emojiSize, display: 'inline-block' }} />
            )
          )}
        </span>
        {points !== 0 ? <span>{points}</span> : null}
      </button>
    </div>
  );
}
