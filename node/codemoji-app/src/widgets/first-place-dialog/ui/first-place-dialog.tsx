import React, { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import CheckIcon from '@/shared/assets/icons/check.svg?react'
import { formatPriceToString, TelegramUtils } from '@/shared/libs'
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

interface FirstPlaceDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSubscribe?: () => void
  onDecline?: () => void
  prizePool?: number
  bonusPoints?: number
}

const RewardItem = ({ text }: { text: React.ReactNode }) => {
  return (
    <div className="flex items-center gap-3">
      <div className="bg-[#AFC7D6] rounded-[4px] size-6 flex items-center justify-center shrink-0">
        <CheckIcon />
      </div>
      {text}
    </div>
  )
}

export const FirstPlaceDialog: React.FC<FirstPlaceDialogProps> = ({
  open,
  onOpenChange,
  onSubscribe,
  onDecline,
  prizePool,
}) => {
  const { t } = useTranslation()

  // Haptic feedback при открытии диалога первого места
  useEffect(() => {
    if (open) {
      TelegramUtils.notificationOccurred('success')
    }
  }, [open])

  const handleSubscribe = () => {
    onSubscribe?.()
    onOpenChange(false)
  }

  const handleDecline = () => {
    onDecline?.()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="pb-8 pt-12 overflow-visible px-6">
        <div className="absolute -top-24 left-1/2 -translate-x-1/2 pointer-events-none">
          <img
            src="/images/game/crown.png"
            alt={t('firstPlaceDialog.crownImage')}
            draggable="false"
            className="w-50"
          />
        </div>

        <DialogClose />

        <DialogHeader className="space-y-3 text-center mb-6">
          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('firstPlaceDialog.title')}
          </DialogTitle>
          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('firstPlaceDialog.description')}
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <RewardItem
            text={
              <p className="font-medium text-xs leading-[17px]">
                {t('firstPlaceDialog.notification')}
              </p>
            }
          />
          <RewardItem
            text={
              <p className="font-medium text-xs leading-[17px]">
                {t('firstPlaceDialog.prizeInfo')}{' '}
                <span className="text-black">{formatPriceToString(prizePool || 0)}</span>
              </p>
            }
          />
          {/* <RewardItem
            text={
              <p className="font-medium text-xs leading-[17px]">+1 бал за выход на первое место</p>
            }
          /> */}
        </div>

        <DialogFooter className="mt-6 pt-0 space-y-2">
          {/* <Button
            onClick={handleSubscribe}
            className="w-full bg-[#0050FF] text-white font-bold transition-colors"
          >
            Подписаться на уведомления <AppleEmoji id="🔔" className="ml-2" />
          </Button> */}
          <Button onClick={handleSubscribe} className="w-full">
            {t('common.continue')}
          </Button>
          <Button onClick={handleDecline} variant="clear" className="w-full text-xs">
            {t('firstPlaceDialog.declineNotifications')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
