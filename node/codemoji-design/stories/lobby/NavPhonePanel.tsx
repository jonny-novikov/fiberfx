import * as React from 'react';
import { cn } from '../lib/cn';

// The phone chrome atop a screen (Figma "Header old (iOS)", 375×92) — the iOS status
// row (system time + signal / wi-fi / battery) over the app header (a "‹ Back" pill,
// the CODEMOJI wordmark, and the extra-controls cluster: collapse chevron + overflow
// menu). Background is TRANSPARENT by default so it floats on the screen-fill gradient;
// pass `solid` for an opaque card surface. Self-contained — onBack is a callback, the
// status glyphs are Unicode (no SpriteEmoji / SVG icons).
export interface NavPhonePanelProps {
  /** system clock, left of the status row */
  time?: string;
  /** the centered wordmark; defaults to the CODEMOJI logo */
  logo?: React.ReactNode;
  onBack?: () => void;
  onMenu?: () => void;
  /** opaque card surface instead of the default transparent background */
  solid?: boolean;
  className?: string;
}

export function NavPhonePanel({
  time = '9:41',
  logo,
  onBack,
  onMenu,
  solid = false,
  className,
}: NavPhonePanelProps) {
  return (
    <div className={cn('flex flex-col gap-2', solid && 'rounded-2xl bg-card p-2', className)}>
      {/* iOS status row — time · signal / wi-fi / battery */}
      <div className="flex h-6 items-center justify-between px-1 text-h5 font-semibold text-dark-muted">
        <span>{time}</span>
        <span className="flex items-center gap-1" aria-label="status">
          <span aria-hidden>📶</span>
          <span aria-hidden>🛜</span>
          <span aria-hidden>🔋</span>
        </span>
      </div>

      {/* app header — back · logo · extra controls (same-height row) */}
      <div className="flex h-10 items-center justify-between">
        <button
          type="button"
          onClick={onBack}
          className="flex h-9 items-center gap-1 rounded-full bg-primary px-3 text-h5 font-medium text-primary-foreground"
        >
          <span aria-hidden>‹</span>
          <span>Back</span>
        </button>

        <span className="text-h2 font-bold tracking-tight text-dark-muted">
          {logo ?? (
            <>
              C<span aria-hidden>🎭</span>DEMOJI
            </>
          )}
        </span>

        <button
          type="button"
          onClick={onMenu}
          aria-label="Extra controls"
          className="flex h-9 items-center gap-3 rounded-full bg-primary px-3 text-h3 text-primary-foreground"
        >
          <span aria-hidden>⌄</span>
          <span aria-hidden>⋮</span>
        </button>
      </div>
    </div>
  );
}
