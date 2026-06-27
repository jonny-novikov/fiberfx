import * as React from 'react';
import { cn } from '../../lib/cn';

// Faithful re-expression of the app's SpriteEmoji
// (codemoji-app/src/shared/ui/sprite-emoji/sprite-emoji.tsx). Every gameplay emoji
// (slots, keyboard, previous attempt) is drawn from a SPRITE SHEET via background-
// position — NOT a Unicode glyph — so the art is identical across platforms.
//
// `code` is a 4-char "XXYY": the first two digits are the COLUMN, the last two the
// ROW into the sheet. The sheet here is the app's own 01-emoji-set.png (10 cols x 15
// rows of 72px cells), copied into public/assets/emoji/. In the app the sprite config
// arrives from the server (roomState.emojiSet); the catalog has no server, so the
// standard set is baked in as the default.

export interface SpriteConfig {
  spriteUrl: string;
  /** the source cell edge in px (square) */
  cellSize: number;
  gridCols: number;
  gridRows: number;
}

// The app's standard set (public/emoji/01-emoji-set.png is 720x1080 = 10x15 @ 72px).
export const DEFAULT_SPRITE: SpriteConfig = {
  spriteUrl: '/assets/emoji/01-emoji-set.png',
  cellSize: 72,
  gridCols: 10,
  gridRows: 15,
};

export interface SpriteEmojiProps {
  /** "XXYY" sprite code: first two digits = column, last two = row */
  code: string;
  /** rendered px size (square) */
  size?: number;
  config?: SpriteConfig;
  className?: string;
  style?: React.CSSProperties;
}

function parseXXYY(code: string): { col: number; row: number } {
  if (code.length !== 4) return { col: 0, row: 0 };
  return { col: parseInt(code.slice(0, 2), 10), row: parseInt(code.slice(2, 4), 10) };
}

export function SpriteEmoji({
  code,
  size = 32,
  config = DEFAULT_SPRITE,
  className,
  style,
}: SpriteEmojiProps) {
  const { col, row } = parseXXYY(code);
  // Scale the whole sheet so one source cell renders at `size`, then offset to the cell.
  const scale = size / config.cellSize;
  return (
    <div
      role="img"
      aria-label={`Emoji ${code}`}
      className={cn('inline-block shrink-0', className)}
      style={{
        width: size,
        height: size,
        backgroundImage: `url(${config.spriteUrl})`,
        backgroundPosition: `${-(col * config.cellSize * scale)}px ${-(row * config.cellSize * scale)}px`,
        backgroundSize: `${config.gridCols * config.cellSize * scale}px ${config.gridRows * config.cellSize * scale}px`,
        backgroundRepeat: 'no-repeat',
        ...style,
      }}
    />
  );
}
