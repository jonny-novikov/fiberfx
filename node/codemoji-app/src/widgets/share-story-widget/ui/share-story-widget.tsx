import React from 'react'
import { useTranslation } from 'react-i18next'

import { cn } from '@/shared/libs'
import { AppLink } from '@/shared/ui/app-link/app-link'

interface ShareStoryWidgetProps {
  className?: string
  actionButton?: React.ReactNode
}
export const ShareStoryWidget = ({ className, actionButton }: ShareStoryWidgetProps) => {
  const { t } = useTranslation()

  return (
    <div className={cn('bg-card rounded-2xl p-5 text-center', className)}>
      <h2 className="text-h1">{t('shareStoryWidget.title')}</h2>
      <p className="text-xs text-card-foreground-secondary font-medium mt-3">
        {t('shareStoryWidget.description', {
          interpolation: { escapeValue: false },
        })
          .split('<1>')
          .map((part, index) => {
            if (index === 0) return part
            const [botName, rest] = part.split('</1>')
            return (
              <React.Fragment key={index}>
                <AppLink type="telegramInternal" to="@codemoji_chat" className="text-link">
                  {botName}
                </AppLink>
                {rest}
              </React.Fragment>
            )
          })}
      </p>
      {actionButton && <div className="mt-4">{actionButton}</div>}
    </div>
  )
}
