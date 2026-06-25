import { useSetAtom } from 'jotai'
import { StarIcon } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { keysPurchaseDrawerAtom } from '../model/store'

import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'
interface KeyPurchaseButtonProps {
  className?: string
}

export const KeyPurchaseButton = ({ className }: KeyPurchaseButtonProps) => {
  const { t } = useTranslation()
  const setIsOpen = useSetAtom(keysPurchaseDrawerAtom)

  const handlePurchaseKeys = () => {
    setIsOpen(true)
  }
  return (
    <Button className={cn('', className)} onClick={handlePurchaseKeys} variant="gradient">
      {t('keys.purchase.button')} <StarIcon className="size-4 fill-white" />
    </Button>
  )
}
