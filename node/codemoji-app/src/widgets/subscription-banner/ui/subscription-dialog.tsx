import React from 'react'
import { useTranslation } from 'react-i18next'

import { TelegramUtils } from '@/shared/libs'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  Button,
} from '@/shared/ui'

interface SubscriptionDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export const SubscriptionDialog: React.FC<SubscriptionDialogProps> = ({ open, onOpenChange }) => {
  const { t } = useTranslation('subscription')

  const handleClose = () => {
    onOpenChange(false)
  }

  const handleSubscribe = () => {
    TelegramUtils.openTelegramLink('https://t.me/nosignalgohome')
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="pb-8 pt-[clamp(5rem,14vh,22rem)] overflow-visible px-6 bg-card top-auto bottom-10 translate-y-0 data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom">
        <div className="absolute -top-[clamp(-2rem,17vh,17.5rem)] left-1/2 -translate-x-1/2 pointer-events-none w-[clamp(0.75rem,30vh,17.5rem)]">
          <img
            src="/images/subscription-banner/hero.webp"
            alt={t('dialog.heroAlt')}
            draggable="false"
            className="w-70"
          />
        </div>

        {/* <DialogClose /> */}

        <DialogHeader className="space-y-2 text-center mb-2">
          <DialogTitle className="text-xs font-medium text-[#1F1F1F] text-justify">
            {t('dialog.title')}
          </DialogTitle>
          <DialogDescription className="text-xs font-medium text-[#1F1F1F] text-justify">
            {t('dialog.subtitle')}
          </DialogDescription>
        </DialogHeader>

        <p className="text-xs font-medium text-[#1F1F1F]">{t('dialog.description')}</p>

        <DialogFooter className="mt-6 pt-0 space-y-2">
          <Button onClick={handleSubscribe} className="w-full text-xs">
            {t('dialog.subscribe')}
          </Button>
          <Button onClick={handleClose} variant="outline" className="w-full text-xs">
            {t('dialog.close')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
