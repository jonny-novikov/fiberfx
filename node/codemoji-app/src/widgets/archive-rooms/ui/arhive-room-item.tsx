import type { TFunction } from 'i18next'
import { useTranslation } from 'react-i18next'

import type { ArchiveGame } from '@/entities/rooms'
import { EmojiSetProvider, formatPriceToString } from '@/shared/libs'
import { SpriteEmoji } from '@/shared/ui'

interface ArchiveRoomItemProps {
  game: ArchiveGame
  clockOffset?: number
}

/** Format time ago from ISO timestamp with localized units */
function formatTimeAgo(isoDate: string, t: TFunction, clockOffset?: number): string {
  const date = new Date(isoDate)
  const now = new Date(Date.now() + (clockOffset ?? 0))
  const diffMs = now.getTime() - date.getTime()

  // Handle negative or very small values (less than 1 minute)
  if (diffMs < 60000) {
    return t('archive.time.justNow')
  }

  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)

  if (diffDays > 0) {
    return t('archive.time.days', { count: diffDays })
  }
  if (diffHours > 0) {
    const mins = diffMins % 60
    const hoursPart = t('archive.time.hours', { count: diffHours })
    return mins > 0 ? `${hoursPart} ${t('archive.time.minutes', { count: mins })}` : hoursPart
  }
  return t('archive.time.minutes', { count: diffMins })
}

export const ArchiveRoomItem = ({ game, clockOffset }: ArchiveRoomItemProps) => {
  const { t } = useTranslation()

  const timeAgo = game.timeAgo ?? formatTimeAgo(game.finishedAt, t, clockOffset)
  const prizeDisplay =
    game.prizeDisplay ?? formatPriceToString(parseInt(game.prizePool), '$', 'en-US')

  // Get winner display name
  const winnerDisplay = game.winnerUsername
    ? `@${game.winnerUsername}`
    : (game.winnerDisplayName ?? t('archive.noWinner'))

  return (
    <EmojiSetProvider
      config={{
        spriteUrl: game.emojiSet?.spriteUrl ?? '/emoji/01-emoji-set.png',
        cellSize: game.emojiSet?.cellSize ?? 72,
        gridCols: game.emojiSet?.gridCols ?? 10,
        gridRows: game.emojiSet?.gridRows ?? 12,
      }}
    >
      <div className="bg-card rounded-2xl p-4">
        <div className="flex items-center justify-between">
          <h3 className="text-h1 text-card-foreground">
            {t(`rooms.names.${game.roomName}`, { defaultValue: game.roomName })}
          </h3>
          <p className="text-large font-bold text-card-foreground">{prizeDisplay}</p>
        </div>
        <div className="flex items-center justify-between mt-3">
          <div className="flex gap-1">
            {game.secretCode.map((code: string, index: number) => (
              <div
                className="flex items-center justify-center rounded-md border-2 border-primary/10"
                key={index}
              >
                <SpriteEmoji code={code} size={28} />
              </div>
            ))}
          </div>
          <p className="text-[0.5625rem] text-primary/20">{game.gameId}</p>
        </div>
        <p className="text-xs text-card-foreground-secondary flex items-center gap-1 mt-4">
          <span>{t('archive.timeAgo', { time: timeAgo })}</span>
          <span>/</span>
          <span>{winnerDisplay}</span>
        </p>
      </div>
    </EmojiSetProvider>
  )
}
