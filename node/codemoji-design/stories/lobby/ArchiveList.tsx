import * as React from 'react';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';
import { ArchiveRoomItem } from './ArchiveRoomItem';

// The lobby's "Room archive" section (121:2056) — the titled list of finished
// rooms below the live safes. Re-expresses widgets/archive-rooms/archive-rooms-
// list: a heading, a stack of ArchiveRoomItem cards, and a full-width "Show
// more" pager. Self-contained — paging is the onShowMore callback (no infinite-
// query / spinner / clock-tick); each item is a fully-formed ArchiveRoomItem.
export interface ArchiveListProps {
  items: React.ComponentProps<typeof ArchiveRoomItem>[];
  onShowMore?: () => void;
  className?: string;
}

export function ArchiveList({ items, onShowMore, className }: ArchiveListProps) {
  return (
    <div className={cn(className)}>
      <h2 className="text-h1 px-4 text-primary">Room archive</h2>

      <div className="mt-4 space-y-2">
        {items.map((item, index) => (
          <ArchiveRoomItem key={item.gameId ?? index} {...item} />
        ))}
      </div>

      <Button variant="outline" className="mt-4 w-full" onClick={onShowMore}>
        Show more
      </Button>
    </div>
  );
}
