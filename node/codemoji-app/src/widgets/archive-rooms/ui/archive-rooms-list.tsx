import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { ArchiveRoomItem } from './arhive-room-item'

import { useArchiveGamesInfinite } from '@/entities/rooms'
import { cn } from '@/shared/libs'
import { Button, Spinner } from '@/shared/ui'

interface ArchiveRoomsListProps {
  className?: string
  filter?: 'my' | 'all'
}

export const ArchiveRoomsList = ({ className, filter = 'all' }: ArchiveRoomsListProps) => {
  const { t } = useTranslation()

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isLoading, isError } =
    useArchiveGamesInfinite({ filter, limit: 10 })

  // Force re-render every 60s so time-ago values stay fresh
  const [, setTick] = useState(0)
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 60_000)
    return () => clearInterval(id)
  }, [])

  // Flatten all pages into a single array of games with clock offset per page.
  // clockOffset = serverClock - clientClock (ms). Add to Date.now() for corrected "now".
  const games =
    data?.pages.flatMap((page) => {
      const clockOffset = new Date(page.serverTime).getTime() - Date.now()
      return page.games.map((game) => ({ ...game, _clockOffset: clockOffset }))
    }) ?? []

  if (games.length === 0) return null

  return (
    <div className={cn(className)}>
      <h2 className="text-h1 px-4 text-primary">{t('archive.title')}</h2>

      {isLoading ? (
        <div className="flex justify-center py-8">
          <Spinner />
        </div>
      ) : isError ? (
        <p className="text-center text-card-foreground-secondary py-8">{t('archive.error')}</p>
      ) : games.length === 0 ? (
        <p className="text-center text-card-foreground-secondary py-8">{t('archive.empty')}</p>
      ) : (
        <>
          <div className="space-y-2 mt-4">
            {games.map((game) => (
              <ArchiveRoomItem key={game.gameId} game={game} clockOffset={game._clockOffset} />
            ))}
          </div>

          {hasNextPage && (
            <Button
              variant="clear"
              className="w-full mt-4 text-[#AFC7D6]"
              onClick={() => fetchNextPage()}
              disabled={isFetchingNextPage}
            >
              {isFetchingNextPage ? (
                <Spinner className="w-4 h-4" />
              ) : (
                <span>{t('archive.showMore')}</span>
              )}
            </Button>
          )}
        </>
      )}
    </div>
  )
}
