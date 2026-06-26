import * as React from 'react';
import { cn } from '../lib/cn';

// The mascot footer at the very bottom of the lobby (121:2056). The app
// (widgets/character-footer) renders a full-width raster of the mascot
// (freeman-on-throne.webp). Rasters 404 in the design system, so this stands in
// with a large Unicode mascot glyph — decorative only, props + a caption line.
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
      {caption && <p className="text-xs text-card-foreground-secondary">{caption}</p>}
    </div>
  );
}
