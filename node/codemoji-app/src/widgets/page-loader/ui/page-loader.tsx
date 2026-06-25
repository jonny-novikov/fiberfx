import { useTranslation } from 'react-i18next'

import { AnimatedLoadingText } from '@/shared/ui/animated-loading-text'

export const PageLoader = () => {
  const { t } = useTranslation()
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4" />
        <AnimatedLoadingText text={t('common.loading')} />
      </div>
    </div>
  )
}
