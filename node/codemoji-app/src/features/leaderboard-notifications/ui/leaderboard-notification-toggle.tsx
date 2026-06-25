import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import { useLeaderboardNotifications } from '../model'

import { Checkbox } from '@/shared/ui'

interface LeaderboardNotificationToggleProps {
  className?: string
  defaultEnabled?: boolean
  onToggle?: (enabled: boolean) => void
}

export const LeaderboardNotificationToggle = ({
  className,
  defaultEnabled = false,
  onToggle,
}: LeaderboardNotificationToggleProps) => {
  const { t } = useTranslation()
  const { isEnabled, toggle } = useLeaderboardNotifications(defaultEnabled)

  useEffect(() => {
    // Вызываем callback при изменении состояния
    onToggle?.(isEnabled)
  }, [isEnabled, onToggle])

  return (
    <div className={className}>
      <Checkbox
        checked={isEnabled}
        onChange={toggle}
        labelLeft={
          <div className="flex items-center gap-2">
            <img src="/images/bell.png" alt="bell" className="size-8" />
            <p className="text-sm text-dark-muted">{t('leaderboard.notifications')}</p>
          </div>
        }
      />
    </div>
  )
}
