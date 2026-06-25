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

interface ShareStoryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onShare?: () => void
  storyContent?: React.ReactNode
  storyTitle?: string
  prizePool?: number
  playerCount?: number
}

export const ShareStoryDialog: React.FC<ShareStoryDialogProps> = ({
  open,
  onOpenChange,
  onShare,
  storyTitle,
}) => {
  const { t } = useTranslation()

  const handleShare = () => {
    onShare?.()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="p-0 overflow-hidden">
        <DialogClose />

        {/* Story Preview */}
        <div className="pt-9 flex justify-center">
          <img
            src="/images/story-preview.png"
            alt={storyTitle || t('shareStoryDialog.storyPreviewAlt')}
            className="max-w-[216px]"
          />
        </div>

        {/* Dialog Content */}
        <div className="pb-6 pt-6">
          <DialogHeader className="space-y-6 text-center">
            <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
              {t('shareStoryDialog.title')}
            </DialogTitle>
            <DialogDescription className="text-xs leading-[17px] text-muted">
              {t('shareStoryDialog.description')}
              <br /> {t('shareStoryDialog.description2')}
            </DialogDescription>
          </DialogHeader>

          <DialogFooter className="mt-6 pt-0 px-6">
            <Button
              onClick={handleShare}
              className="w-full bg-[#0050FF] hover:bg-[#0051D5] text-white font-bold rounded-2xl transition-colors"
            >
              {t('shareStoryDialog.postStory')}
            </Button>
          </DialogFooter>
        </div>
      </DialogContent>
    </Dialog>
  )
}
