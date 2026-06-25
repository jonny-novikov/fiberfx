import { useSetAtom } from 'jotai'
import { StarIcon } from 'lucide-react'
import { FC } from 'react'
import { useTranslation } from 'react-i18next'

import { keysPurchaseDrawerAtom } from '@/features/keys-purchase'
import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface PromoBannerProps {
  totalEarned?: number
  keysCount?: number
  keyPrice?: number
  className?: string
}

export const PromoBanner: FC<PromoBannerProps> = ({
  totalEarned = 25693,
  // keysCount = 80,
  // keyPrice = 2000,
  className,
}) => {
  const { t } = useTranslation()
  const setIsOpen = useSetAtom(keysPurchaseDrawerAtom)

  const handleBuyKeys = () => {
    setIsOpen(true)
  }

  return (
    <div className={cn('px-2', className)}>
      <div className="bg-card rounded-2xl px-5 pb-4 pt-6">
        {/* Статистика */}
        <div className="text-center mb-4">
          <h2 className="text-xl font-bold mb-3 leading-[1.2]">
            {t('promoBanner.totalEarned', { amount: totalEarned.toLocaleString() })}
            <br /> {t('promoBanner.allTime')}
          </h2>
          <p className="text-xs mt-3">
            {t('promoBanner.description')} <br />
            {t('promoBanner.description2')}
          </p>
        </div>

        {/* Кнопка покупки */}
        <Button
          onClick={handleBuyKeys}
          variant="gradient"
          // className="bg-gradient-to-r from-[#FF8800] to-[#FF4800] flex items-center justify-center text-base font-bold"
          className="w-full"
        >
          {/* <span>{keysCount} ключей</span>

          <span>{keyPrice}</span> */}
          {t('promoBanner.purchaseKeys')} <StarIcon className="fill-white" />
        </Button>
      </div>
    </div>
  )
}
