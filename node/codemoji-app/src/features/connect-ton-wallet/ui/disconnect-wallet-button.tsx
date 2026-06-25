import { XIcon } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { useTonConnect } from '@/app/providers'
import { WalletAddress } from '@/entities/wallet'
import { cn } from '@/shared/libs'

interface DisconnectWalletButtonProps {
  className?: string
}

export const DisconnectWalletButton = ({ className }: DisconnectWalletButtonProps) => {
  const { t } = useTranslation('withdraw')
  const { disconnectWallet, currentWallet } = useTonConnect()

  const handleDisconnect = async () => {
    try {
      await disconnectWallet()
    } catch (error) {
      console.error(t('wallet.disconnectError'), error)
    }
  }

  if (!currentWallet) return null

  return (
    <button
      className={cn(
        'inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors',
        className
      )}
      onClick={handleDisconnect}
    >
      {t('wallet.disconnect')} <WalletAddress address={currentWallet} />
      <XIcon className="size-3" />
    </button>
  )
}
