import { useTranslation } from 'react-i18next'

import { useTonConnect } from '@/app/providers'
import { ConnectWalletButton, DisconnectWalletButton } from '@/features/connect-ton-wallet'
import { WithdrawButton } from '@/features/withdraw-crystals'
import { cn } from '@/shared/libs'

interface WithdrawBalanceWidgetProps {
  /** Общий баланс кристаллов */
  totalCrystals: number
  /** Доступно для вывода сейчас */
  availableForWithdraw: number
  /** Заблокированная сумма */
  lockedAmount?: number
  /** Через сколько дней разблокируется */
  lockedUntilDays?: number
  /** Режим "в разработке" */
  isUnderDevelopment?: boolean
  className?: string
}

/** Overlay "В разработке" */
const UnderDevelopmentOverlay = () => {
  const { t } = useTranslation('withdraw')

  return (
    <div className="absolute inset-0 backdrop-blur-sm bg-card/80 rounded-2xl flex flex-col items-center justify-center z-10">
      <div className="text-4xl mb-3">🚧</div>
      <h2 className="text-h2 text-card-foreground">{t('balanceWidget.underDevelopment.title')}</h2>
      <p className="mt-2 text-sm text-card-foreground-secondary">
        {t('balanceWidget.underDevelopment.message')}
      </p>
    </div>
  )
}

/** Состояние "Пустой баланс" */
const EmptyBalanceState = ({
  isConnected,
  className,
}: {
  isConnected: boolean
  className?: string
}) => {
  const { t } = useTranslation('withdraw')

  return (
    <div className={cn('bg-card rounded-2xl p-5 text-center', className)}>
      <h2 className="text-h1 flex items-center justify-center gap-2">
        0 <span className="text-2xl">💎</span>
      </h2>
      <p className="mt-2 text-sm text-card-foreground-secondary">
        {t('balanceWidget.totalBalance')}
      </p>
      <p className="mt-4 text-xs text-muted-foreground">{t('balanceWidget.emptyBalanceMessage')}</p>

      {/* Кнопка подключения/отключения кошелька */}
      <div className="mt-4">
        {isConnected ? <DisconnectWalletButton /> : <ConnectWalletButton className="w-full" />}
      </div>
    </div>
  )
}

/** Основное состояние с балансом */
const BalanceState = ({
  totalCrystals,
  availableForWithdraw,
  lockedAmount,
  lockedUntilDays,
  isConnected,
  className,
}: {
  totalCrystals: number
  availableForWithdraw: number
  lockedAmount: number
  lockedUntilDays: number
  isConnected: boolean
  className?: string
}) => {
  const { t } = useTranslation('withdraw')

  return (
    <div className={cn('bg-card rounded-2xl p-5 text-center', className)}>
      {/* Общий баланс */}
      <h2 className="text-h1 flex items-center justify-center gap-2">
        {totalCrystals.toLocaleString()} <span className="text-2xl">💎</span>
      </h2>

      {/* Информация о доступных средствах */}
      <p className="mt-2 text-sm text-card-foreground-secondary">
        {t('balanceWidget.availableForWithdraw')}
        {lockedAmount > 0 && (
          <>
            {' '}
            {t('balanceWidget.lockedInfo', {
              amount: lockedAmount.toLocaleString(),
              days: lockedUntilDays,
            })}
          </>
        )}
      </p>

      {/* Курс обмена */}
      {/* <p className="mt-1 text-xs text-muted-foreground">
      1 кристалл = {CRYSTAL_RATES.tonPerCrystal} TON
    </p> */}

      {/* Кнопка вывода */}
      <div className="mt-4">
        <WithdrawButton crystalsAmount={availableForWithdraw} />
      </div>

      {/* Кнопка отключения кошелька */}
      {isConnected && (
        <div className="mt-4">
          <DisconnectWalletButton />
        </div>
      )}
    </div>
  )
}

export const WithdrawBalanceWidget = ({
  totalCrystals,
  availableForWithdraw,
  lockedAmount = 0,
  lockedUntilDays = 0,
  isUnderDevelopment = false,
  className,
}: WithdrawBalanceWidgetProps) => {
  const { isConnected } = useTonConnect()

  // Пустой баланс
  const isEmpty = totalCrystals === 0 && availableForWithdraw === 0

  // Определяем какой контент показывать
  const content = isEmpty ? (
    <EmptyBalanceState isConnected={isConnected} />
  ) : (
    <BalanceState
      totalCrystals={totalCrystals}
      availableForWithdraw={availableForWithdraw}
      lockedAmount={lockedAmount}
      lockedUntilDays={lockedUntilDays}
      isConnected={isConnected}
    />
  )

  return (
    <div className={cn('relative', className)}>
      {content}
      {isUnderDevelopment && <UnderDevelopmentOverlay />}
    </div>
  )
}
