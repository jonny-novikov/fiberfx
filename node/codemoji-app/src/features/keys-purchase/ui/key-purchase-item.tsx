import { useTranslation } from 'react-i18next'

import { KeyPackage } from '../model/store'

interface KeyPurchaseItemProps {
  pkg: KeyPackage
  onClick: () => void
  isLoading?: boolean
  disabled?: boolean
}

/**
 * Returns the correct plural form for "key" based on i18n
 */
function useKeyLabel(count: number): string {
  const { t, i18n } = useTranslation()

  // For Russian, use custom pluralization logic
  if (i18n.language === 'ru') {
    const lastTwo = count % 100
    const lastOne = count % 10

    if (lastTwo >= 11 && lastTwo <= 19) return t('keys.key_many')
    if (lastOne === 1) return t('keys.key_one')
    if (lastOne >= 2 && lastOne <= 4) return t('keys.key_few')
    return t('keys.key_many')
  }

  // For English and other languages, use standard pluralization
  return t('keys.key', { count })
}

export const KeyPurchaseItem = ({ pkg, onClick, isLoading, disabled }: KeyPurchaseItemProps) => {
  const keyLabel = useKeyLabel(pkg.keys)

  return (
    <button
      className="bg-card rounded-lg h-12 flex items-center justify-between px-5 disabled:opacity-50 disabled:cursor-not-allowed"
      onClick={onClick}
      disabled={disabled || isLoading}
    >
      <div className="flex items-center gap-1">
        <img src="/images/keys/key.png" alt="Key" className="size-6" draggable="false" />
        <div className="font-medium text-primary">
          {pkg.keys} {keyLabel}
        </div>
        {pkg.discount && <div className="text-accent">-{pkg.discount}%</div>}
      </div>

      <div>
        <div className="flex flex-col items-end">
          <div className="flex gap-0.5 items-center">
            {isLoading ? (
              <span className="text-primary/60 animate-pulse">...</span>
            ) : (
              <>
                <img src="/images/star.png" alt="Star" className="size-4" draggable="false" />
                <span className="text-primary/60">{pkg.stars}</span>
              </>
            )}
          </div>

          {/* <span className="text-[0.5625rem] leading-none">${pkg.usd.toFixed(1)}</span> */}
        </div>
      </div>
    </button>
  )
}
