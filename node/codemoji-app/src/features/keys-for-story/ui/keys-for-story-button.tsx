import { useTranslation } from 'react-i18next'

import { Button, ButtonProps } from '@/shared/ui/button/button'

interface KeysForStoryButtonProps extends ButtonProps {
  className?: string
}

export const KeysForStoryButton = ({ className }: KeysForStoryButtonProps) => {
  const { t } = useTranslation()

  return (
    <Button className={className} disabled>
      {t('keys.purchase.keyReceived')}
    </Button>
  )
}
