import React from 'react'
import { useTranslation } from 'react-i18next'

import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  Button,
} from '@/shared/ui'

interface ErrorDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onClose?: () => void
  eventId?: string
}

export const ErrorDialog: React.FC<ErrorDialogProps> = ({
  open,
  onOpenChange,
  onClose,
  eventId,
}) => {
  const { t } = useTranslation()

  const handleClose = () => {
    onClose?.()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="pb-8 pt-10 px-6">
        <DialogHeader className="space-y-4 text-center">
          <div className="flex justify-center">
            <img
              src="/images/error-img.png"
              alt={t('errorDialog.errorImage')}
              className="h-[80px] object-contain"
            />
          </div>

          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('errorDialog.title')}
          </DialogTitle>

          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('errorDialog.description')}{' '}
            <a
              href="https://t.me/codemoji_chat"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#FF2F00]"
            >
              @codemoji_chat
            </a>
          </DialogDescription>

          {eventId && (
            <p className="text-xs text-muted/60">
              {t('errorDialog.eventId')} {eventId}
            </p>
          )}
        </DialogHeader>

        <DialogFooter className="mt-6 pt-0">
          <Button
            onClick={handleClose}
            className="w-full bg-[#FF2F00] text-white font-bold transition-colors"
          >
            {t('common.close')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
