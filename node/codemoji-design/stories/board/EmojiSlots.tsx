import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { SpriteEmoji } from './lib/SpriteEmoji';

// The 6-emoji guess row — the heart of the board. Faithful re-expression of the app's
// widgets/emoji-slots (codemoji-app), down to the exact tile states:
//   - filled         → bg-primary/10 (sprite at size 40)
//   - filled + locked → bg-primary/10 + border-border + a lock badge
//   - ACTIVE (the first empty, unlocked slot — "fill me next") → the DARK bg-active-slot
//     (#1F1F1F) with a pulsing white "?"
//   - empty (beyond active) → transparent (just the card behind it)
// Each tile is size-13 (52px), rounded-[0.625rem], a 2px transparent border. Emoji are
// drawn from the sprite sheet (SpriteEmoji, XXYY codes). The app's @dnd-kit drag-reorder
// + lock-toggle behaviour is omitted — this documents the slot STATES (the DS concern).
export interface EmojiSlotsProps {
  /** chosen emojis left to right as XXYY sprite codes; a hole (undefined) is empty */
  emojis?: (string | undefined)[];
  /** total slots (the code length; app/Figma = 6) */
  total?: number;
  /** indices the player pinned (rendered with a lock badge) */
  locked?: number[];
  className?: string;
}

export function EmojiSlots({ emojis = [], total = 6, locked = [], className }: EmojiSlotsProps) {
  const { t } = useTranslation();
  const selectedCount = emojis.filter(Boolean).length;
  // active = the first empty, unlocked slot (unless the guess is complete)
  let firstEmpty = -1;
  for (let i = 0; i < total; i++) {
    if (!emojis[i] && !locked.includes(i)) {
      firstEmpty = i;
      break;
    }
  }

  return (
    // matches the app container: rounded-2xl px-3, a centered slot row (gap-1.5)
    <div className={cn('relative rounded-2xl px-3', className)}>
      <div className="flex items-center justify-center gap-1.5">
        {Array.from({ length: total }).map((_, i) => {
          const code = emojis[i];
          const isEmojiLocked = locked.includes(i);
          const isActive = i === firstEmpty && selectedCount < total;
          return (
            <div
              key={i}
              className={cn(
                'relative flex size-13 shrink-0 items-center justify-center rounded-[0.625rem] border-2 border-transparent',
                code && isEmojiLocked && 'bg-primary/10 border-border',
                code && !isEmojiLocked && 'bg-primary/10',
                isActive && 'bg-active-slot border-active-slot'
              )}
            >
              {code && <SpriteEmoji code={code} size={40} />}

              {/* locked badge (a pinned slot) */}
              {code && isEmojiLocked && (
                <span
                  role="img"
                  aria-label={t('common.lock')}
                  className="absolute -top-1 -right-1 flex size-3.5 items-center justify-center rounded-sm border-2 border-border bg-card text-[8px]"
                >
                  🔒
                </span>
              )}

              {/* active slot — the pulsing white "?" */}
              <div
                className={cn(
                  'absolute inset-0 flex items-center justify-center transition-all duration-300',
                  isActive ? 'scale-100 opacity-100' : 'scale-0 opacity-0'
                )}
              >
                {isActive && (
                  <span className="text-[2rem] font-bold text-white animate-pulse">?</span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
