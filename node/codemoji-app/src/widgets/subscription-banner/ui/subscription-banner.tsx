import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { SubscriptionDialog } from './subscription-dialog'

import CloseIcon from '@/shared/assets/icons/close.svg?react'
import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface SubscriptionBannerProps {
  className?: string
}

export const SubscriptionBanner = ({ className }: SubscriptionBannerProps) => {
  const { t } = useTranslation('subscription')
  const [open, setOpen] = useState(false)

  const handleCloseButton = () => {
    setOpen(true)
    localStorage.setItem('subscription-banner-closed', 'true')
  }

  const isClosed = localStorage.getItem('subscription-banner-closed') === 'true'

  return (
    <>
      {!isClosed && (
        <div className={cn(className)}>
          <div
            className={cn(
              "relative p-6 bg-[url('/images/subscription-banner/bg.webp')] bg-cover bg-no-repeat border-2 border-secondary/10 rounded-2xl"
            )}
          >
            <Button
              className="absolute right-0 top-0 text-white"
              variant="clear"
              onClick={handleCloseButton}
            >
              <CloseIcon />
            </Button>
            <p className="text-xs font-medium text-white">
              {t('banner.teaser')}
              <br /> {t('banner.description')}
            </p>
            <Button className="mt-4" variant="secondary" onClick={() => setOpen(true)}>
              {t('banner.cta')}
            </Button>
          </div>
        </div>
      )}
      <SubscriptionDialog open={open} onOpenChange={setOpen} />
    </>
  )
}
