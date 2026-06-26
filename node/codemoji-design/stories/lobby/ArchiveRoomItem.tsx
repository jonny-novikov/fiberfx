import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from '../board/lib/BoardCard';
import { EmojiTile } from '../board/lib/EmojiTile';

// One finished room in the lobby's "Room archive" (121:2056) — a settled safe
// with its secret code now revealed and a winner named. Re-expresses
// widgets/archive-rooms/arhive-room-item: the room name + prize header, the
// revealed code row beside a faint gameId, and a "{timeAgo} / {winner}" footer.
// Reuses the shared BoardCard surface + the filled EmojiTile for each code slot
// (the app's SpriteEmoji becomes a Unicode glyph here); self-contained, no time
// math or i18n — timeAgo/winner arrive as plain strings.
export interface ArchiveRoomItemProps {
  name: string;
  /** prize pool in whole currency units; rendered as $N */
  prize: number;
  /** the now-revealed secret code, one Unicode emoji per slot */
  code: string[];
  /** pre-formatted relative time, e.g. "2h ago" */
  timeAgo: string;
  /** winner display name, e.g. "@ivan" */
  winner: string;
  gameId?: string;
  className?: string;
}

export function ArchiveRoomItem({
  name,
  prize,
  code,
  timeAgo,
  winner,
  gameId,
  className,
}: ArchiveRoomItemProps) {
  return (
    <BoardCard className={className}>
      <div className="flex items-center justify-between">
        <h3 className="text-h1 text-card-foreground">{name}</h3>
        <p className="text-large font-bold">${prize.toLocaleString()}</p>
      </div>

      {/* the revealed secret code (left) + the faint game id (right) */}
      <div className="mt-3 flex items-center justify-between">
        <div className="flex gap-1">
          {code.map((emoji, index) => (
            <EmojiTile key={index} size="sm" state="filled" emoji={emoji} />
          ))}
        </div>
        {gameId && <p className="text-2xs text-muted">{gameId}</p>}
      </div>

      <p className="mt-4 flex items-center gap-1 text-xs text-card-foreground-secondary">
        <span>{timeAgo}</span>
        <span>/</span>
        <span>{winner}</span>
      </p>
    </BoardCard>
  );
}
