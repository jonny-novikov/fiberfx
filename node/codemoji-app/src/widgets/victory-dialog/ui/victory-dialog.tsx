import { useAtomValue, useSetAtom } from 'jotai'
import React, { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import {
  victoryDialogOpenAtom,
  victoryDialogDataAtom,
  hideVictoryDialogAtom,
} from '../model/victory-dialog.store'

import { useGameStateQuery } from '@/features/game'
import { useClaimPrizeMutation } from '@/features/game/api/game.mutations'
import { ShareStoryButton } from '@/features/share-story'
import CheckIcon from '@/shared/assets/icons/check.svg?react'
import { TelegramUtils } from '@/shared/libs'
import { APP_URL } from '@/shared/libs/consts'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
  Button,
} from '@/shared/ui'

const RewardItem = ({ text }: { text: React.ReactNode }) => {
  return (
    <div className="flex items-center gap-3">
      <div className="bg-black/60 rounded-[4px] size-6 flex items-center justify-center shrink-0">
        <CheckIcon />
      </div>
      {text}
    </div>
  )
}

export const VictoryDialog: React.FC = () => {
  const { t } = useTranslation()
  const open = useAtomValue(victoryDialogOpenAtom)
  const dialogData = useAtomValue(victoryDialogDataAtom)
  const hideDialog = useSetAtom(hideVictoryDialogAtom)
  const [prizeClaimed, setPrizeClaimed] = useState(false)
  const { data: gameState } = useGameStateQuery(dialogData?.gameId ?? '')
  const claimPrizeMutation = useClaimPrizeMutation()

  // Автоматически начисляем приз при открытии диалога
  useEffect(() => {
    if (open && dialogData?.gameId && !prizeClaimed) {
      // Haptic feedback при победе
      TelegramUtils.notificationOccurred('success')

      claimPrizeMutation
        .mutateAsync(dialogData.gameId)
        .then(() => {
          setPrizeClaimed(true)
        })
        .catch((error) => {
          console.error('Failed to claim prize:', error)
        })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, dialogData?.gameId])

  const handleClose = () => {
    hideDialog()
    setPrizeClaimed(false)
  }

  // Обработка закрытия через крестик или оверлей
  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen) {
      handleClose()
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="pb-8 pt-12 overflow-visible px-6">
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 pointer-events-none">
          <img
            src="/images/game/crown.png"
            alt={t('victoryDialog.crownAlt')}
            draggable="false"
            className="w-50"
          />
        </div>

        <DialogClose />

        <DialogHeader className="space-y-3 text-center mb-6">
          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('victoryDialog.title', { prizePool: gameState?.prizePool })}
          </DialogTitle>
          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('victoryDialog.congratulations')}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <RewardItem
            text={
              <p className="font-medium text-xs leading-[17px]">
                {t('victoryDialog.withdrawalAvailable')}
              </p>
            }
          />
          <RewardItem
            text={
              <p className="font-medium text-xs leading-[17px]">
                {t('victoryDialog.exchangeOffer')}
              </p>
            }
          />
        </div>

        <DialogFooter className="mt-6 pt-0 space-y-2">
          <ShareStoryButton
            className="w-full"
            storyParams={{
              mediaUrl: '/images/tg-stories/winner-ru-1.webp', // TODO: добавить URL изображения для сторис
              text: t('victoryDialog.storyText'),
              widgetLink: {
                url: APP_URL,
                name: t('victoryDialog.widgetLinkName'),
              },
            }}
            disabled
          >
            {t('victoryDialog.shareToStories')}
          </ShareStoryButton>
          <Button onClick={handleClose} variant="clear" className="w-full text-xs">
            {t('victoryDialog.skip')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
