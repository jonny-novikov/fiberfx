import React from 'react'
import { useTranslation } from 'react-i18next'

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

interface KeysAddedDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onContinue?: () => void
}

export const KeysAddedDialog: React.FC<KeysAddedDialogProps> = ({
  open,
  onOpenChange,
  onContinue,
}) => {
  const { t } = useTranslation()

  const handleContinue = () => {
    onContinue?.()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="pb-8 pt-10 px-6">
        <DialogClose />

        <DialogHeader className="space-y-6 text-center">
          <div className="flex justify-center">
            <img
              src="/images/game/key.png"
              alt={t('keysAddedDialog.keyImage')}
              className="size-[100px] object-contain"
            />
          </div>

          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('keysAddedDialog.title')}
          </DialogTitle>

          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('keysAddedDialog.description')}
          </DialogDescription>
        </DialogHeader>

        <DialogFooter className="mt-6 pt-0">
          <Button
            onClick={handleContinue}
            className="w-full bg-[#00CB5B] text-white font-bold transition-colors"
          >
            {t('keysAddedDialog.continueGame')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
