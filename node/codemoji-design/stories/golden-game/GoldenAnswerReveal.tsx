import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { EmojiTile } from '../board/lib/EmojiTile';

// The "correct answer" reveal on the FINISHED Golden Room screen (1108:27589) —
// the secret code, now revealed, on a gold-texture banner. Reuses the board's
// filled EmojiTile for each slot (the same atom the guess slots use).
export interface GoldenAnswerRevealProps {
  /** the now-revealed secret code, one Unicode emoji per slot */
  code: string[];
  className?: string;
}

export function GoldenAnswerReveal({ code, className }: GoldenAnswerRevealProps) {
  const { t } = useTranslation();
  return (
    <div className={cn('rounded-2xl bg-gold-texture p-4 text-center', className)}>
      <div className="mb-2 text-2xs font-bold uppercase tracking-wide text-primary">
        {t('golden.correctAnswer')}
      </div>
      <div className="flex justify-center gap-1.5">
        {code.map((emoji, i) => (
          <EmojiTile key={i} size="sm" state="filled" emoji={emoji} />
        ))}
      </div>
    </div>
  );
}
