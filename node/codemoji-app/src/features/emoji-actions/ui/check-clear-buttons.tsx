import { useAtomValue, useSetAtom } from 'jotai'
import { useTranslation } from 'react-i18next'
import { useParams } from 'react-router-dom'

import { useMyResources } from '@/entities/player'
import {
  useGuessSubmitMutation,
  selectedEmojisAtom,
  cleanSelectedEmojisAtom,
  useRoomStateQuery,
  triggerDisintegrateAtom,
} from '@/features/game'
import {
  clearEmojisAtom,
  isSelectionReadyAtom,
  lockedEmojisAtom,
} from '@/features/game/model/gameplay.store'
import { KeyPurchaseButton } from '@/features/keys-purchase'
import { ShareForClips } from '@/features/share-story'
import { cn, TelegramUtils } from '@/shared/libs'
import { Button } from '@/shared/ui'

export interface CheckClearButtonsProps {
  className?: string
  gameId?: string
}

export const CheckClearButtons = ({ className, gameId }: CheckClearButtonsProps) => {
  const { t } = useTranslation()
  const { roomId } = useParams<{ roomId: string }>()
  const { data: resources } = useMyResources()
  const { data: roomState, isLoading: isRoomLoading } = useRoomStateQuery(roomId!)
  const { mutate: submitGuess, isPending: isSubmitting } = useGuessSubmitMutation(
    gameId!,
    roomState?.guessFee ?? 0,
    Number(roomState?.prizePool ?? 0)
  )
  const clearEmojis = useSetAtom(clearEmojisAtom)
  const triggerDisintegrate = useSetAtom(triggerDisintegrateAtom)

  const selectedEmojis = useAtomValue(selectedEmojisAtom)
  const cleanSelectedEmojis = useAtomValue(cleanSelectedEmojisAtom)
  const lockedEmojis = useAtomValue(lockedEmojisAtom)
  const isSelectionReady = useAtomValue(isSelectionReadyAtom)
  const keysBalance = resources?.keys.balance ?? 0
  const bonusKeys = resources?.keys.bonusKeys ?? 0
  const isFreeGame = (roomState?.guessFee ?? 0) === 0

  // Проверяем, есть ли что стирать (незаблокированные эмодзи)
  const hasUnlockedEmojis = selectedEmojis.some(
    (emoji, index) => emoji && !lockedEmojis.includes(index)
  )

  const handleClear = () => {
    if (hasUnlockedEmojis) {
      // Сначала запускаем эффект распада
      triggerDisintegrate()
      // Очищаем эмодзи с задержкой для анимации
      setTimeout(() => {
        clearEmojis()
      }, 400)
    } else {
      clearEmojis()
    }
  }

  const handleCheck = () => {
    // Haptic feedback при проверке
    TelegramUtils.impactOccurred('medium')

    submitGuess({
      guessCode: cleanSelectedEmojis,
      lockedPositions: lockedEmojis,
    })
  }

  // Free games: need at least 1 clip (bonus key). Paid games: need enough keys.
  const cannotAfford = isFreeGame
    ? bonusKeys < 1
    : keysBalance < (roomState?.guessFee ?? 0)

  if (cannotAfford) {
    if (isFreeGame) {
      return (
        <ShareForClips
          variant="gradient"
          className="w-full"
          showDescription
          descriptionText={t('game.actions.shareForClips')}
        />
      )
    }

    return (
      <div className="flex flex-col gap-4">
        <KeyPurchaseButton />
        <p className="text-xs font-medium text-center leading-none">
          {t('game.actions.notEnoughKeys')}
        </p>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <div className={cn('flex gap-3', className)}>
        <Button
          onClick={handleClear}
          // disabled={!hasUnlockedEmojis || isSubmitting}
          variant="outline"
          className="w-fit"
        >
          {t('game.actions.clear')}
        </Button>

        {/* Кнопка "Проверить" */}
        <Button
          onClick={handleCheck}
          disabled={!isSelectionReady || isSubmitting}
          className="flex-1 bg-[#0050FF]"
          loading={isRoomLoading}
        >
          {isSubmitting
            ? t('game.actions.checking')
            : isFreeGame
              ? `${t('game.actions.check')} 📎 1`
              : `${t('game.actions.check')} 🔑 ${roomState?.guessFee}`}
        </Button>
      </div>
      {/* <p className="text-xs font-medium text-center leading-none text-gray-500 flex items-center justify-center gap-1">
        <AppleEmoji id="bulb" size={14} />
        <span>Нажми на эмодзи, чтобы заблокировать позицию</span>
      </p> */}
    </div>
  )
}
