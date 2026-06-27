import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// A room ("safe") card in the lobby (121:2056) — the centerpiece. Re-expresses
// entities/rooms/room-item: the room name + prize, a star / emoji-count / cells
// meta line, an optional best-guess progress bar, and the Open-safe CTA. Text and
// sizes track the Figma master (Russian copy, the "⭐ / N эмоджи / N ячеек" meta).
// COLOR is the design system's deliberate role layer (the drift the screen view
// surfaces): a non-gold room uses the `enter` Button (blue) where Figma paints it
// black; a `golden` boost-class room rides the gold variant (the gold texture) + a
// gold border, matching Figma's gild. Reuses the shared BoardCard surface; self-
// contained (onJoin is a callback).
export interface RoomCardProps {
  name: string;
  /** prize pool in whole currency units; rendered as $N */
  prize: number;
  /** difficulty stars, rendered as a run of ⭐ (Figma: ⭐ / ⭐⭐) */
  stars?: number;
  emojiCount?: number;
  cells?: number;
  /** best-guess progress so far, 0–100 (e.g. 24.32); omit to hide the bar */
  bestPercent?: number;
  /** the Open-safe CTA label, verbatim from Figma (e.g. "Открыть 🔑 бесплатно") */
  ctaLabel?: string;
  golden?: boolean;
  disabled?: boolean;
  onJoin?: () => void;
  className?: string;
}

export function RoomCard({
  name,
  prize,
  stars = 1,
  emojiCount = 80,
  cells = 6,
  bestPercent,
  ctaLabel,
  golden = false,
  disabled = false,
  onJoin,
  className,
}: RoomCardProps) {
  const { t } = useTranslation();
  // A caller-provided CTA (the Figma-curated sample labels) wins; otherwise the
  // localized default room-entry label.
  const resolvedCta = ctaLabel ?? t('rooms.joinGame');
  return (
    <BoardCard
      className={cn('flex flex-col gap-4', golden && 'border-2 border-gold-border', className)}
    >
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <h2 className="text-h1 font-bold leading-none">{name}</h2>
          <h2 className="text-h1 font-bold leading-none">${prize}</h2>
        </div>
        <p className="flex items-center gap-2 text-h5 text-card-foreground-secondary">
          <span aria-hidden>{'⭐'.repeat(Math.max(1, stars))}</span>
          <span>/</span>
          <span>{emojiCount} {t('rooms.emoji')}</span>
          <span>/</span>
          <span>{cells} {t('rooms.cells')}</span>
        </p>
      </div>

      {/* best-guess progress so far (the room's current top score) — Figma 121:2056
          lays the bar out on one row with the percent inline to its right, not the
          percent stacked above a full-width bar. */}
      {bestPercent != null && (
        <div className="flex items-center gap-3">
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-slot">
            <div
              className="h-full rounded-full bg-accent"
              style={{ width: `${Math.min(bestPercent, 100)}%` }}
            />
          </div>
          <span className="shrink-0 text-[13px] font-medium text-dark-muted">
            {bestPercent}%
          </span>
        </div>
      )}

      <Button variant={golden ? 'golden' : 'enter'} disabled={disabled} onClick={onJoin}>
        {resolvedCta}
      </Button>
    </BoardCard>
  );
}
