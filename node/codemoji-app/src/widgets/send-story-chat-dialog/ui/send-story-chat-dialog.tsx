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

interface SendStoryChatDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onOpenProfile?: () => void
}

export const SendStoryChatDialog: React.FC<SendStoryChatDialogProps> = ({
  open,
  onOpenChange,
  onOpenProfile,
}) => {
  const { t } = useTranslation()

  const handleOpenProfile = () => {
    onOpenProfile?.()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="pb-8 pt-10 px-6">
        <DialogClose />

        <DialogHeader className="space-y-6 text-center">
          <div className="flex justify-center">
            <img
              src="/images/up-right-arrow.png"
              alt={t('sendStoryChatDialog.shareImageAlt')}
              className="size-[72px] object-contain"
            />
          </div>

          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {t('sendStoryChatDialog.title')}
          </DialogTitle>

          <DialogDescription className="text-sm leading-[17px] font-medium text-muted">
            {t('sendStoryChatDialog.description', {
              interpolation: { escapeValue: false },
            })
              .split('<1>')
              .map((part, index) => {
                if (index === 0) return part
                const [botName, rest] = part.split('</1>')
                return (
                  <React.Fragment key={index}>
                    <span className="text-[#0050FF]">{botName}</span>
                    {rest}
                  </React.Fragment>
                )
              })}
          </DialogDescription>
        </DialogHeader>

        <DialogFooter className="mt-6 pt-0">
          <Button
            onClick={handleOpenProfile}
            className="w-full bg-[#0050FF] text-white font-bold transition-colors"
          >
            {t('sendStoryChatDialog.openProfile')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
