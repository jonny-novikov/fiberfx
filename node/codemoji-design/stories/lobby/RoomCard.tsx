import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';

// A room ("safe") card in the lobby (121:2056) — the centerpiece. Re-expresses
// entities/rooms/room-item: the room name + prize, a star / emoji-count / cells
// meta line, a best-guess progress bar, and the Open-safe CTA. A `golden`
// boost-class room rides the gold Button variant (--gradient-gold) + a gold
// border. Reuses the shared BoardCard surface; self-contained (no join mutation
// or router — onJoin is a callback).
export interface RoomCardProps {
  name: string;
  /** prize pool in whole currency units; rendered as $N */
  prize: number;
  emojiCount?: number;
  cells?: number;
  /** best-guess progress so far, 0–100 */
  bestPercent?: number;
  golden?: boolean;
  disabled?: boolean;
  onJoin?: () => void;
  className?: string;
}

export function RoomCard({
  name,
  prize,
  emojiCount = 20,
  cells = 6,
  bestPercent = 0,
  golden = false,
  disabled = false,
  onJoin,
  className,
}: RoomCardProps) {
  return (
    <BoardCard
      className={cn('flex flex-col gap-4', golden && 'border-2 border-gold-border', className)}
    >
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold leading-none">{name}</h2>
          <h2 className="text-2xl font-bold leading-none">${prize.toLocaleString()}</h2>
        </div>
        <p className="flex items-center gap-2 text-xs text-card-foreground-secondary">
          <span>⭐</span>
          <span>/</span>
          <span>{emojiCount} emoji</span>
          <span>/</span>
          <span>{cells} cells</span>
        </p>
      </div>

      {/* best-guess progress so far (the room's current top score) */}
      <div>
        <div className="mb-1 text-right text-2xs font-medium text-dark-muted">{bestPercent}%</div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-slot">
          <div
            className="h-full rounded-full bg-accent"
            style={{ width: `${Math.min(bestPercent, 100)}%` }}
          />
        </div>
      </div>

      <Button variant={golden ? 'golden' : 'default'} disabled={disabled} onClick={onJoin}>
        💸 Open safe
      </Button>
    </BoardCard>
  );
}
