import { useTranslation } from 'react-i18next'

import { useRoomsListQuery } from '../api/rooms.queries'

import { RoomItem } from './room-item'

import { cn } from '@/shared/libs'
import { AppleEmoji } from '@/shared/ui'

export const RoomsList = ({ className }: { className?: string }) => {
  const { t } = useTranslation()
  const { data, isLoading, error, refetch } = useRoomsListQuery({
    limit: 10,
    offset: 0,
    type: 'all',
  })

  const rooms = data?.rooms ?? []

  // Loading state
  if (isLoading && rooms.length === 0) {
    return (
      <div className={cn('', className)}>
        <div className="h-50 flex items-center justify-center">{t('rooms.loading')}</div>
      </div>
    )
  }

  // Error state
  if (error && rooms.length === 0) {
    return (
      <div className={cn('', className)}>
        <div className="flex flex-col items-center justify-center py-12">
          <div className="mb-4">
            <AppleEmoji id="😕" size={48} />
          </div>
          <p className="text-muted mb-4">{error.message}</p>
          <button onClick={() => refetch()} className="px-4 py-2 bg-blue-500 text-white rounded-lg">
            {t('common.tryAgain')}
          </button>
        </div>
      </div>
    )
  }

  // Empty state
  if (rooms.length === 0) {
    return (
      <div className={cn('', className)}>
        <div className="flex flex-col items-center justify-center py-12">
          <div className="mb-4">
            <AppleEmoji id="🔒" size={48} />
          </div>
          <p className="text-dark-muted font-semibold">{t('rooms.noRooms')}</p>
          <p className="text-muted text-sm mt-2">{t('rooms.tryLater')}</p>
        </div>
      </div>
    )
  }

  return (
    <div className={cn('', className)}>
      <p className="text-xl font-bold text-center text-dark-muted">{t('rooms.chooseRoom')}</p>
      <p className="text-muted text-xs text-center">{t('rooms.getKeysDescription')}</p>
      <div className="grid grid-cols-1 gap-y-2 mt-5">
        {rooms.map((room) => (
          <RoomItem key={room.roomId} room={room} />
        ))}
      </div>
    </div>
  )
}
