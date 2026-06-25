import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'

import { useGameLeaderboard } from '../api/leaderboard.queries'

import { LeaderboardItem } from './leaderboard-item'

import { cn } from '@/shared/libs'

export interface LeaderboardListProps {
  className?: string

  limit?: number
  showEmptyState?: boolean
  compact?: boolean

  refreshInterval?: number
}

export const LeaderboardList = ({ className, compact = false }: LeaderboardListProps) => {
  const { gameId } = useParams<{ gameId: string }>()
  const { t } = useTranslation()
  const { data: leaderboardData, isLoading, error, refetch } = useGameLeaderboard(gameId!)

  const fetchData = () => {
    refetch()
  }

  // Loading state
  if (isLoading || !leaderboardData) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <div className="animate-pulse">
          <div className="h-12 bg-gray-200 rounded-lg mb-2" />
          <div className="h-12 bg-gray-200 rounded-lg mb-2" />
          <div className="h-12 bg-gray-200 rounded-lg" />
        </div>
      </div>
    )
  }

  // Error state
  if (error) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <p className="text-red-500 text-sm">{t('common.error')}</p>
        <button onClick={fetchData} className="mt-2 text-blue-500 text-xs underline">
          {t('common.tryAgain')}
        </button>
      </div>
    )
  }

  // No roundId state
  if (!gameId) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <p className="text-gray-500 text-sm">{t('leaderboard.waitingForRound')}</p>
      </div>
    )
  }

  // Empty state
  if (leaderboardData.items.length === 0) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <p className="text-gray-500 text-sm">{t('leaderboard.noParticipants')}</p>
        <p className="text-gray-400 text-xs mt-1">{t('leaderboard.beFirst')}</p>
      </div>
    )
  }

  return (
    <div className={cn('grid grid-cols-1 gap-1', compact ? 'pt-2 pb-3' : 'pt-4 pb-5', className)}>
      {leaderboardData.items.map((entry) => (
        <LeaderboardItem key={entry.guessId} item={entry} />
      ))}
    </div>
  )
}
