import { useSetAtom } from 'jotai'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'

import { usePlayerGuessHistory } from '@/entities/history'
import { CheckClearButtons } from '@/features/emoji-actions'
import { fillSlotsAtom } from '@/features/game/model/gameplay.store'
import { cn } from '@/shared/libs'
import { PreviousAttempt } from '@/shared/ui'
import { EmojiSlots } from '@/widgets/emoji-slots'

export interface EmotionPickerProps {
  className?: string
}

export const EmotionPicker = ({ className }: EmotionPickerProps) => {
  const { t } = useTranslation()
  const { gameId } = useParams<{ roomCode: string; gameId: string }>()
  const { data: history } = usePlayerGuessHistory(gameId!)
  const lastAttempt = history?.[0]
  const fillSlots = useSetAtom(fillSlotsAtom)

  const handlePreviousAttemptClick = () => {
    if (lastAttempt?.guessCode) {
      fillSlots(lastAttempt.guessCode)
    }
  }

  return (
    <div className="px-2">
      <div className={cn('bg-card rounded-2xl px-3 pt-5 pb-4', className)}>
        <h2 className="text-xl font-bold text-center leading-none mb-3">
          {t('game.guessTheCode')}
        </h2>
        {lastAttempt && (
          <PreviousAttempt
            emojis={lastAttempt.guessCode}
            className="mb-3"
            points={lastAttempt.scoring.finalPoints}
            onClick={handlePreviousAttemptClick}
          />
        )}

        {/* Слоты для выбранных эмодзи */}
        <EmojiSlots totalSlots={6} className="mb-4" />

        <CheckClearButtons gameId={gameId!} />
      </div>
    </div>
  )
}
