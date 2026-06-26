import * as React from 'react';
import { cn } from '../lib/cn';
import { RoomCard } from './RoomCard';

// The "choose a safe" room list (121:2056) — the lobby's core section. Re-expresses
// entities/rooms/rooms-list: a centered heading + description, then a single-column
// grid of RoomCards. The app version branches on react-query (loading / error /
// empty); this self-contained one renders only the populated state — rooms arrive
// as props, not a fetch.
export interface RoomListProps {
  rooms?: React.ComponentProps<typeof RoomCard>[];
  className?: string;
}

const SAMPLE_ROOMS: React.ComponentProps<typeof RoomCard>[] = [
  { name: 'Warmup box', prize: 52, emojiCount: 12, cells: 4, bestPercent: 20 },
  { name: 'Steel box', prize: 1352, bestPercent: 60 },
  { name: 'Golden room', prize: 2352, bestPercent: 80, golden: true },
  { name: 'Hardcore level', prize: 4200, emojiCount: 30, cells: 8, bestPercent: 100 },
];

export function RoomList({ rooms = SAMPLE_ROOMS, className }: RoomListProps) {
  return (
    <div className={cn(className)}>
      <p className="text-center text-xl font-bold text-dark-muted">Choose a safe to start</p>
      <p className="text-center text-xs text-muted">Crack the code and win the prize inside</p>
      <div className="mt-5 grid grid-cols-1 gap-y-2">
        {rooms.map((room, i) => (
          <RoomCard key={`${room.name}-${i}`} {...room} />
        ))}
      </div>
    </div>
  );
}
