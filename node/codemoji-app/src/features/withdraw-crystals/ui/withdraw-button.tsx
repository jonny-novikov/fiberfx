import { useTranslation } from 'react-i18next'

import { calculateWithdrawAmount } from '../model/store'

import { useTonConnect } from '@/app/providers'
import { cn } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface WithdrawButtonProps {
  crystalsAmount: number
  className?: string
  onWithdraw?: () => void
}

export const WithdrawButton = ({ crystalsAmount, className, onWithdraw }: WithdrawButtonProps) => {
  const { t } = useTranslation('withdraw')
  const { ensureWalletConnected, isLoggingIn } = useTonConnect()

  const { usd } = calculateWithdrawAmount(crystalsAmount)

  const handleWithdraw = async () => {
    // Сначала убеждаемся, что кошелек подключен
    const walletAddress = await ensureWalletConnected()

    if (!walletAddress) {
      console.log(t('withdraw.notConnected'))
      return
    }

    // Здесь будет логика вывода
    console.log(t('withdraw.toWallet'), walletAddress)
    onWithdraw?.()
  }

  return (
    <Button className={cn('w-full', className)} onClick={handleWithdraw} loading={isLoggingIn}>
      {t('withdraw.button')} {Math.floor(usd)} USDT [{crystalsAmount}💎]
    </Button>
  )
}
