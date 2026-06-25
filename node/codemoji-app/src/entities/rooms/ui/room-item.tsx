import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'

import { useJoinRoomMutation } from '../api/rooms.mutation'
import { RoomListItem } from '../model/types/rooms.types'

import { formatPriceToString } from '@/shared/libs/utils/price'
import { AppleEmoji, Button, ProgressBar } from '@/shared/ui'

export interface RoomItemProps {
  room: RoomListItem
}

export const RoomItem = (props: RoomItemProps) => {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { room } = props
  const { mutate: joinRoom, isPending } = useJoinRoomMutation()

  const handleJoinGame = () => {
    joinRoom(room.roomId, {
      onSuccess: (response) => {
        navigate(`/game/${room.roomId}/${response.game?.gameId}`)
      },
      onError: () => {
        // UI-логика: показать тост, ошибку и т.п.
      },
    })
  }

  const canJoin = room.isJoinable

  return (
    <div className="bg-card rounded-2xl p-4 flex flex-col gap-4">
      <div className="flex flex-col gap-2">
        <div className="flex justify-between items-center">
          <h2 className="text-xl font-bold leading-none">
            {t(`rooms.names.${room.roomName}`, { defaultValue: room.roomName })}
          </h2>
          <h2 className="text-2xl font-bold leading-none">
            {formatPriceToString(parseInt(room.gamePrizePool))}
          </h2>
        </div>

        <p className="flex items-center gap-2 text-card-foreground-secondary text-xs">
          <span>
            <img src="/images/star.png" alt="Star" className="size-3" />
          </span>
          <span>/</span>
          <span>
            {room.emojiCount} {t('rooms.emoji')}
          </span>
          <span>/</span>
          <span>6 {t('rooms.cells')}</span>
        </p>
      </div>
      <ProgressBar label={`${room.maxPercentX100 / 100}%`} progress={room.maxPercentX100 / 100} />
      <Button
        variant={room.roomType === 'golden' ? 'golden' : undefined}
        onClick={handleJoinGame}
        disabled={!canJoin}
      >
        <AppleEmoji id="💸" size={20} />
        {isPending ? t('rooms.joining') : t('rooms.joinGame')}
      </Button>
    </div>
  )
}
