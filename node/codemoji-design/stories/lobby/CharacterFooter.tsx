import * as React from 'react';
import { cn } from '../lib/cn';

// The mascot footer at the very bottom of the lobby (121:2056, Figma "Frame 226").
// The app renders a full-width raster of the mascot (freeman-on-throne.webp) with a
// 🔑 key glyph; rasters 404 in the design system, so this stands in with a large
// Unicode mascot + the key — decorative only (Figma carries no body text here).
// `caption` stays optional for catalog/demo use but is unset on the real screen.
export interface CharacterFooterProps {
  caption?: string;
  className?: string;
}

export function CharacterFooter({ caption, className }: CharacterFooterProps) {
  return (
    <div className={cn('flex flex-col items-center gap-2 text-center', className)}>
      <span className="text-[96px] leading-none" role="img" aria-label="mascot">
        🤴
      </span>
      <span className="text-[40px] leading-none" role="img" aria-label="key">
        🔑
      </span>
      {caption && <p className="text-h5 text-card-foreground-secondary">{caption}</p>}
    </div>
  );
}
