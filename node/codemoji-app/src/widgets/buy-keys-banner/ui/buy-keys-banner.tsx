import { useSetAtom } from 'jotai'
import { FC } from 'react'
import { useTranslation } from 'react-i18next'

import { keysPurchaseDrawerAtom } from '@/features/keys-purchase'
import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface BuyKeysBannerProps {
  totalEarned?: number
  className?: string
}

export const BuyKeysBanner: FC<BuyKeysBannerProps> = ({ totalEarned = 25693, className }) => {
  const { t } = useTranslation()
  const setDrawerOpen = useSetAtom(keysPurchaseDrawerAtom)

  const handleBuyKeys = () => {
    setDrawerOpen(true)
  }

  return (
    <div className={cn('bg-card rounded-2xl px-5 py-5', className)}>
      <h2 className="text-center text-xl font-bold text-card-foreground mb-3 leading-tight">
        {t('banner.playersFound', { amount: totalEarned.toLocaleString() })}
      </h2>

      <p className="text-center text-xs text-card-foreground-secondary mb-5 leading-relaxed font-medium">
        {t('banner.getMoreKeys')}
      </p>

      {/* Кнопка */}
      <Button onClick={handleBuyKeys} variant="gradient" className="w-full">
        <span>{t('keys.purchase.button')}</span>
        <span className="text-xl">⭐</span>
      </Button>
    </div>
  )
}
