import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';
import { ArchiveRoomItem } from './ArchiveRoomItem';

// A titled list of finished rooms in the lobby (121:2056). Re-expresses
// widgets/archive-rooms/archive-rooms-list: a heading, a stack of ArchiveRoomItem
// cards, and a full-width "Показать больше" pager. The lobby uses this twice (Figma:
// "Ваши золотые комнаты" then "Архив комнат") — so the title is a prop. The pager is
// shown only when onShowMore is given. Self-contained — each item is a fully-formed
// ArchiveRoomItem; no infinite-query / spinner / clock-tick.
export interface ArchiveListProps {
  title?: string;
  items: React.ComponentProps<typeof ArchiveRoomItem>[];
  onShowMore?: () => void;
  className?: string;
}

export function ArchiveList({ title, items, onShowMore, className }: ArchiveListProps) {
  const { t } = useTranslation();
  const resolvedTitle = title ?? t('lobby.archive.rooms');
  return (
    <div className={cn(className)}>
      <h2 className="text-h1 px-4 font-bold text-primary">{resolvedTitle}</h2>

      <div className="mt-4 space-y-2">
        {items.map((item, index) => (
          <ArchiveRoomItem key={item.gameId ?? index} {...item} />
        ))}
      </div>

      {onShowMore && (
        <Button variant="outline" className="mt-4 w-full" onClick={onShowMore}>
          {t('archive.showMore')}
        </Button>
      )}
    </div>
  );
}
