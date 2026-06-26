import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { cn } from '../../lib/cn';

// The shared emoji tile — the atom both the guess slots and the emoji keyboard are
// built from. A SELF-CONTAINED re-expression of the app's slot/key styling
// (widgets/emoji-slots + shared/ui/emoji-keyboard); emojis are Unicode glyphs, NOT
// the app's SpriteEmoji sprite sheet, so the design system carries no binary.
//
//   empty  — an unfilled slot (light)
//   active — the next slot to fill (light-blue, a pulsing "?" when no emoji)
//   filled — holds a chosen emoji
//   locked — a pinned emoji (dark border + a lock badge)
//   key    — a tappable keyboard key (hover + press feedback)
export const emojiTileVariants = cva(
  'relative inline-flex items-center justify-center rounded-[0.625rem] border-2 select-none transition-colors',
  {
    variants: {
      state: {
        empty: 'bg-slot border-transparent',
        active: 'bg-slot-active border-slot-active',
        filled: 'bg-primary/10 border-transparent',
        locked: 'bg-primary/10 border-border',
        key: 'bg-slot border-transparent hover:bg-primary/10 active:scale-95 cursor-pointer',
      },
      size: {
        sm: 'size-9 text-2xl',
        md: 'size-13 text-[2rem]',
      },
    },
    defaultVariants: { state: 'empty', size: 'md' },
  }
);

export interface EmojiTileProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof emojiTileVariants> {
  emoji?: string;
  /** show the pinned-lock badge (the player locked this slot in place) */
  locked?: boolean;
}

export function EmojiTile({ emoji, state, size, locked, className, ...rest }: EmojiTileProps) {
  return (
    <div className={cn(emojiTileVariants({ state, size, className }))} {...rest}>
      {emoji ? (
        <span>{emoji}</span>
      ) : state === 'active' ? (
        <span className="font-bold text-primary animate-pulse">?</span>
      ) : null}
      {locked && (
        <span className="absolute -top-1 -right-1 flex size-3.5 items-center justify-center rounded-sm border-2 border-border bg-card text-[8px]">
          🔒
        </span>
      )}
    </div>
  );
}
