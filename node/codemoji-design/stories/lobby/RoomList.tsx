import * as React from 'react';
import { cn } from '../lib/cn';
import { RoomCard } from './RoomCard';

// The "choose a safe" room list (121:2056) — the lobby's core section. Re-expresses
// entities/rooms/rooms-list: a centered heading + description, then a single-column
// grid of RoomCards. Heading copy is verbatim from the Figma master. The app version
// branches on react-query (loading / error / empty); this self-contained one renders
// only the populated state — rooms arrive as props, not a fetch.
export interface RoomListProps {
  rooms?: React.ComponentProps<typeof RoomCard>[];
  className?: string;
}

const SAMPLE_ROOMS: React.ComponentProps<typeof RoomCard>[] = [
  { name: 'Бокс для разминки', prize: 52, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть 🔑 бесплатно' },
  { name: 'Золотая комната', prize: 10, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть сейф 🔑 1', golden: true },
  { name: 'Стальной ящик', prize: 1352, stars: 2, emojiCount: 140, cells: 6, bestPercent: 24.32, ctaLabel: 'Открыть 🔑 сейф' },
];

export function RoomList({ rooms = SAMPLE_ROOMS, className }: RoomListProps) {
  return (
    <div className={cn(className)}>
      <p className="text-center text-h1 font-bold text-dark-muted">Выбери сейф, чтобы начать</p>
      <p className="text-center text-h5 text-muted">Получай ключи, чтобы подобрать эмоджи код</p>
      <div className="mt-5 grid grid-cols-1 gap-y-2">
        {rooms.map((room, i) => (
          <RoomCard key={`${room.name}-${i}`} {...room} />
        ))}
      </div>
    </div>
  );
}
