import { useTranslation } from 'react-i18next'

import { useMyResources } from '@/entities/player'
import { cn } from '@/shared/libs'

interface BalanceKeyWidgetProps {
  className?: string
  actionButton?: React.ReactNode
}
export const BalanceKeyWidget = ({ className, actionButton }: BalanceKeyWidgetProps) => {
  const { t } = useTranslation()
  const { data: resources } = useMyResources()

  return (
    <div className={cn('bg-card rounded-2xl p-5 text-center', className)}>
      <h2 className="text-h1">
        {t('balance.keys.title')}: {resources?.keys.balance}
      </h2>
      <p className="mt-3 text-xs text-card-foreground-secondary font-medium">
        {t('balance.keys.description')}
      </p>
      {actionButton && <div className="mt-4">{actionButton}</div>}
    </div>
  )
}
