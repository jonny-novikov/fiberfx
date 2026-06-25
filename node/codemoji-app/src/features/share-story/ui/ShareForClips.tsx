import React from 'react'
import { useTranslation } from 'react-i18next'

import { ShareStoryButton } from './ShareStoryButton'

import { APP_URL } from '@/shared/libs/consts'

export interface ShareForClipsProps {
  className?: string
  variant?: 'default' | 'gradient' | 'outline' | 'ghost' | 'clear'
  showDescription?: boolean
  descriptionText?: string
  onSuccess?: () => void
  onError?: (error: Error) => void
}

const STORIES_COUNT = 6

/**
 * Компонент-прослойка между кнопкой «Выложить сторис» и логикой награждения за шаринг.
 * Инкапсулирует формирование storyParams (случайная картинка, текст, widgetLink).
 */
export const ShareForClips: React.FC<ShareForClipsProps> = ({
  className,
  variant = 'default',
  showDescription = false,
  descriptionText,
  onSuccess,
  onError,
}) => {
  const { t, i18n } = useTranslation()

  const lang = i18n.language === 'ru' ? 'ru' : 'en'
  const randomImage = `/images/tg-stories/story-${lang}-${Math.floor(Math.random() * STORIES_COUNT) + 1}.webp`

  const storyParams = {
    mediaUrl: randomImage,
    text: t('gameRules.playCodemoji'),
    widgetLink: { url: APP_URL, name: t('gameRules.playCodemoji') },
  }

  const button = (
    <ShareStoryButton
      variant={variant}
      className={className}
      storyParams={storyParams}
      onSuccess={onSuccess}
        onError={onError}
      />
  )

  if (showDescription && descriptionText) {
    return (
      <div className="flex flex-col gap-4">
        {button}
        <p className="text-xs font-medium text-center leading-none">{descriptionText}</p>
      </div>
    )
  }

  return button
}
