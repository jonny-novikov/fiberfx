import { useQueryClient } from '@tanstack/react-query'
import { useAtomValue, useSetAtom } from 'jotai'
import React from 'react'
import { useTranslation } from 'react-i18next'

import {
  shareRewardDialogOpenAtom,
  hideShareRewardDialogAtom,
} from '../model/share-reward-dialog.store'

import { playerQueryKeys } from '@/entities/player'
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

export const ShareRewardDialog: React.FC = () => {
  const { t } = useTranslation()
  const open = useAtomValue(shareRewardDialogOpenAtom)

  const hideDialog = useSetAtom(hideShareRewardDialogAtom)
  const queryClient = useQueryClient()

  const handleClose = () => {
    hideDialog()
    // Инвалидируем ресурсы игрока для обновления баланса ключей
    queryClient.invalidateQueries({
      queryKey: playerQueryKeys.resources(),
    })
  }

  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen) {
      handleClose()
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="pb-8 pt-10 px-6">
        <DialogClose />

        <DialogHeader className="space-y-6 text-center">
          <div className="flex justify-center">
            <img
              src="/images/keys/clip.png"
              alt={t('shareRewardDialog.keyImage', { defaultValue: 'Clips' })}
              className="size-[100px] object-contain"
            />
          </div>

          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('shareRewardDialog.title', {
              defaultValue: '{{count}} скрепок ваши',
              count: 25,
            })}
          </DialogTitle>

          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('shareRewardDialog.description', {
              defaultValue: 'Публикуй сторис каждый день, чтобы получать больше скрепок',
            })}
          </DialogDescription>
        </DialogHeader>

        <DialogFooter className="mt-6 pt-0">
          <Button
            onClick={handleClose}
            className="w-full bg-[#00CB5B] text-white font-bold transition-colors"
          >
            {t('shareRewardDialog.continue', { defaultValue: 'Продолжить игру' })}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
