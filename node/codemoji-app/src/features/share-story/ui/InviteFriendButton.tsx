import React, { useCallback, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { createShare } from '../api/share.api'

import { cn } from '@/shared/libs'
import { APP_URL } from '@/shared/libs/consts'
import { TelegramUtils } from '@/shared/libs/utils/telegram'
import { Button } from '@/shared/ui'

export interface InviteFriendButtonProps {
  className?: string
  variant?: 'default' | 'outline' | 'gradient' | 'ghost' | 'clear'
  size?: 'default' | 'sm' | 'lg' | 'icon'
  onSuccess?: () => void
  onError?: (error: Error) => void
  disabled?: boolean
}

export const InviteFriendButton: React.FC<InviteFriendButtonProps> = ({
  className,
  variant = 'gradient',
  size = 'default',
  onSuccess,
  onError,
  disabled = false,
}) => {
  const { t } = useTranslation()
  const [isLoading, setIsLoading] = useState(false)

  const handleClick = useCallback(async () => {
    setIsLoading(true)
    try {
      const data = await createShare()
      const appLink = data.shareUrl || APP_URL

      const shareText = t('share.forwardText', {
        defaultValue: `Взломай код. Шесть эмодзи. Один приз.\nПодбери комбинацию быстрее всех и забери призовой пул`,
      })

      TelegramUtils.share({ text: shareText, url: appLink })
      onSuccess?.()
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err))
      TelegramUtils.share({ text: '', url: APP_URL })
      onError?.(error)
    } finally {
      setIsLoading(false)
    }
  }, [t, onSuccess, onError])

  return (
    <Button
      variant={variant}
      size={size}
      className={cn(
        'bg-[#0050FF] hover:bg-[#0051D5] bg-[url(/images/freeman/invite-friends.png)] bg-contain bg-left bg-no-repeat',
        className
      )}
      onClick={handleClick}
      loading={isLoading}
      disabled={disabled}
    >
      {t('gameRules.inviteFriend', { defaultValue: 'Пригласить друга' })}
    </Button>
  )
}
