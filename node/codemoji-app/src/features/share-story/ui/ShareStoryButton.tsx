import { Share2 } from 'lucide-react'
import React from 'react'
import { useTranslation } from 'react-i18next'

// import { useShareStatusQuery } from '../api/share.queries'
import { useShareToStory } from '../hooks/useShareToStory'

import { APP_URL } from '@/shared/libs/consts'
import { TelegramUtils, ShareToStoryParams } from '@/shared/libs/utils/telegram'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  Button,
} from '@/shared/ui'

export interface ShareStoryButtonProps {
  storyParams: ShareToStoryParams
  children?: React.ReactNode
  iconOnly?: boolean
  variant?: 'default' | 'outline' | 'gradient' | 'ghost' | 'clear'
  size?: 'default' | 'sm' | 'lg' | 'icon'
  className?: string
  onSuccess?: () => void
  onError?: (error: Error) => void
  disabled?: boolean
}

/**
 * Two-step share button for Telegram Stories.
 *
 * Step 1: Click button -> POST /share/create -> get shareUrl.
 * Step 2: In dialog, user clicks "Publish" ->
 *         wa.shareToStory() called SYNCHRONOUSLY from fresh user gesture.
 */
export const ShareStoryButton: React.FC<ShareStoryButtonProps> = ({
  disabled = false,
  storyParams,
  children,
  iconOnly = false,
  variant = 'default',
  size = 'default',
  className,
  onSuccess,
  onError,
}) => {
  const { t, i18n } = useTranslation()
  const [dialogOpen, setDialogOpen] = React.useState(false)

  // TODO: temporarily disabled – share/status hidden, not deleted
  // const { data: statusData } = useShareStatusQuery()
  // const today = new Date().toISOString().slice(0, 10)
  // const canShareToday =
  //   !statusData || statusData.status === 'pending' || statusData.shareDate < today
  const canShareToday = true

  const lang = i18n.language === 'ru' ? 'ru' : 'en'

  const { prepareShare, confirmShare, isPreparing, shareData, error, isAvailable } =
    useShareToStory({
      onSuccess: () => {
        setDialogOpen(false)
        onSuccess?.()
      },
      onError,
    })

  /** Step 1: get shareUrl from backend and open dialog */
  const handleClick = () => {
    setDialogOpen(true)
    prepareShare()
  }

  /** Step 2: user clicks "Publish" -> share via Stories or Telegram share fallback */
  const handleConfirmShare = () => {
    const appLink = shareData?.shareUrl || APP_URL

    const shareText = t('share.storyText', {
      defaultValue: `Взломай код. Шесть эмодзи. Один приз.\nПодбери комбинацию быстрее всех и забери призовой пул`,
    })

    if (isAvailable) {
      // Telegram Stories: wa.shareToStory() called synchronously from user gesture
      const fullText = `${appLink.replace('https://', '')}\n\n${shareText}`
      confirmShare({
        ...storyParams,
        text: fullText,
        widgetLink: {
          url: appLink,
          name: storyParams.widgetLink?.name || 'Открыть',
        },
      })
    } else {
      // Fallback: Telegram share link (works on desktop + all platforms)
      TelegramUtils.share({ text: shareText, url: appLink })
      setDialogOpen(false)
      onSuccess?.()
    }
  }

  /** Forward referral link via Telegram share */
  const handleForwardLink = () => {
    const appLink = shareData?.shareUrl || APP_URL

    const shareText = t('share.forwardText', {
      defaultValue: `Взломай код. Шесть эмодзи. Один приз.\nПодбери комбинацию быстрее всех и забери призовой пул`,
    })

    TelegramUtils.share({ text: shareText, url: appLink })
    setDialogOpen(false)
    onSuccess?.()
  }

  /** Build the description text for the dialog state */
  const getDescription = (): string => {
    if (isPreparing) {
      return t('shareStoryDialog.preparing', { defaultValue: 'Подготовка...' })
    }
    if (error) {
      return t('shareStoryDialog.error', { defaultValue: 'Ошибка. Попробуйте ещё раз.' })
    }
    return (
      t('shareStoryDialog.description', {
        defaultValue: '+25 скрепок за переход друга из сториз.',
      }) +
      '\n' +
      t('shareStoryDialog.description2', {
        defaultValue: 'Доступно раз в сутки.',
      })
    )
  }

  const triggerDisabled = disabled || !canShareToday
  const triggerLoading = isPreparing && !dialogOpen

  return (
    <>
      <Button
        variant={variant}
        size={iconOnly ? 'icon' : size}
        className={className}
        onClick={handleClick}
        loading={triggerLoading}
        title={
          !canShareToday
            ? t('shareStoryDialog.errorDailyLimit', {
                defaultValue: 'Вы уже поделились сегодня.',
              })
            : undefined
        }
        disabled={triggerDisabled}
      >
        {!triggerLoading && (
          <>
            <Share2 className="w-5 h-5" />
            {!iconOnly && <span>{children || t('share.toStories')}</span>}
          </>
        )}
      </Button>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="pb-8 pt-10 px-6">
          <DialogHeader className="space-y-6 text-center">
            <div className="flex justify-center">
              <img
                src={`/images/tg-stories/story-preview-${lang}.webp`}
                alt={t('shareStoryDialog.storyPreviewAlt', { defaultValue: 'Story preview' })}
                className="max-w-80"
              />
            </div>

            <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
              {t('shareStoryDialog.title', { defaultValue: 'Играй с друзьями' })}
            </DialogTitle>

            <DialogDescription className="text-xs leading-[17px] text-muted">
              {getDescription()}
            </DialogDescription>
          </DialogHeader>

          <DialogFooter className="mt-6 pt-0 space-y-2">
            <Button
              onClick={handleConfirmShare}
              disabled={!shareData || isPreparing || disabled}
              loading={isPreparing}
              className="w-full bg-[#0050FF] hover:bg-[#0051D5] text-white font-bold rounded-lg transition-colors"
            >
              {t('shareStoryDialog.postStory', { defaultValue: 'Share to Stories' })}
            </Button>
            <Button
              onClick={handleForwardLink}
              disabled={!shareData || isPreparing || disabled}
              className="rounded-lg w-full"
              loading={isPreparing}
              // className="w-full bg-[#1A1A2E] hover:bg-[#16162a] text-white font-bold rounded-2xl transition-colors relative"
            >
              {t('shareStoryDialog.forwardLink', { defaultValue: 'Отправить ссылку корешку' })}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
