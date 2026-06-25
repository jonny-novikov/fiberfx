import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'

import { usePlayerGuessHistory } from '../api/history.queries'

import { HistoryItem } from './history-item'

import { cn } from '@/shared/libs'

export const HistoryList = ({ className }: { className?: string }) => {
  const { gameId } = useParams<{ gameId: string }>()
  const { t } = useTranslation()

  const { data: historyData, isLoading } = usePlayerGuessHistory(gameId!)

  // Loading state
  if (isLoading || !historyData) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <div className="animate-pulse space-y-4">
          <div className="h-16 bg-gray-200 rounded-lg" />
          <div className="h-16 bg-gray-200 rounded-lg" />
          <div className="h-16 bg-gray-200 rounded-lg" />
        </div>
      </div>
    )
  }

  // No gameId state
  if (!gameId) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <p className="text-gray-500 text-sm">{t('history.waitingForGame')}</p>
      </div>
    )
  }

  // Empty state
  if (historyData.length === 0) {
    return (
      <div className={cn('py-8 text-center', className)}>
        <p className="text-gray-500 text-sm">{t('history.empty')}</p>
        <p className="text-gray-400 text-xs mt-1">{t('history.makeFirstAttempt')}</p>
      </div>
    )
  }

  return (
    <div className={cn('grid grid-cols-1 gap-4 pt-5 pb-6', className)}>
      {historyData.map((item, index) => (
        <HistoryItem
          key={item.guessId}
          gameId={gameId}
          guessId={item.guessId}
          attemptNumber={historyData.length - index}
          emojis={item.guessCode ?? []}
          progress={item.scoring.percentageX100 / 100}
          points={item.scoring.basePoints}
        />
      ))}
    </div>
  )
}
