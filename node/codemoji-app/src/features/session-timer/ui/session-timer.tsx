import { FC, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { cn } from '@/shared/libs'

interface SessionTimerProps {
  className?: string
  endTime: string
  variant?: 'default' | 'golden'
}

export const SessionTimer: FC<SessionTimerProps> = ({ className, endTime, variant = 'default' }) => {
  const { t } = useTranslation()
  const [timeLeft, setTimeLeft] = useState({
    hours: 0,
    minutes: 0,
    seconds: 0,
  })

  useEffect(() => {
    const updateTimer = () => {
      const now = new Date().getTime()
      const end = new Date(endTime ?? 0).getTime()
      const distance = end - now

      if (distance > 0) {
        const hours = Math.floor(distance / (1000 * 60 * 60))
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
        const seconds = Math.floor((distance % (1000 * 60)) / 1000)

        setTimeLeft({ hours, minutes, seconds })
      } else {
        setTimeLeft({ hours: 0, minutes: 0, seconds: 0 })
      }
    }

    updateTimer()
    const interval = setInterval(updateTimer, 1000)

    return () => clearInterval(interval)
  }, [endTime])

  const formatTime = (value: number) => String(value).padStart(2, '0')
  const textColor = variant === 'golden' ? 'text-white' : 'text-primary'

  return (
    <div className={className}>
      <span className={cn('font-bold text-2xl', textColor)}>
        {formatTime(timeLeft.hours)}:{formatTime(timeLeft.minutes)}:{formatTime(timeLeft.seconds)}
      </span>
      <p className={cn('text-xs text-center font-medium', textColor)}>{t('game.roundEnd')}</p>
    </div>
  )
}
