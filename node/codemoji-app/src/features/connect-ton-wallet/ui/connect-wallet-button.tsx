import { WalletIcon } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { useTonConnect } from '@/app/providers'
import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface ConnectWalletButtonProps {
  className?: string
}

export const ConnectWalletButton = ({ className }: ConnectWalletButtonProps) => {
  const { t } = useTranslation('withdraw')
  const { connectWallet, isLoggingIn } = useTonConnect()

  const handleConnect = async () => {
    try {
      await connectWallet()
    } catch (error) {
      console.error(t('wallet.connectError'), error)
    }
  }

  return (
    <Button
      className={cn('', className)}
      onClick={handleConnect}
      loading={isLoggingIn}
      variant="outline"
      // disabled
    >
      <WalletIcon className="size-4" />
      {t('wallet.connect')}
    </Button>
  )
}
