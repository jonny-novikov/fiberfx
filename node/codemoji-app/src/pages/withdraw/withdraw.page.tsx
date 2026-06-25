import { useAtomValue } from 'jotai'
import { useTranslation } from 'react-i18next'

import { BalanceKeyWidget } from '@/entities/balance'
import { playerAtom, useMyResources } from '@/entities/player'
// import { KeysForStoryButton } from '@/features/keys-for-story'
import { KeyPurchaseButton } from '@/features/keys-purchase'
import { PageLayout } from '@/shared/layout'
import { useBackButton } from '@/shared/libs'
import { CharacterKeyBanner } from '@/widgets/character-key-banner'
// import { ShareStoryWidget } from '@/widgets/share-story-widget'
import { WithdrawBalanceWidget } from '@/widgets/withdraw-balance-widget'

const BalanceCard = ({ value, type }: { value: number; type: 'diamonds' | 'keys' }) => {
  const { t } = useTranslation('withdraw')

  const typeName = {
    diamonds: t('page.diamonds'),
    keys: t('page.keys'),
  }

  const typeIcon = {
    diamonds: '💎',
    keys: '🔑',
  }

  return (
    <div className="bg-card rounded-lg text-center py-3">
      <h2 className="text-h1">{value}</h2>
      <div className="flex items-center justify-center gap-1 text-2xs text-card-foreground-secondary font-medium mt-2">
        <span>{typeIcon[type]}</span>
        <span>{typeName[type]}</span>
      </div>
    </div>
  )
}

export const WithdrawPage = () => {
  const { t } = useTranslation('withdraw')
  const player = useAtomValue(playerAtom)
  const playerUsername = player?.username ? `@${player.username}` : '@username'
  const { data: playerResources } = useMyResources()
  useBackButton({
    navigateTo: '/rooms',
  })

  return (
    <PageLayout className="bg-primary">
      <div className="rounded-tl-4xl mt-1 flex-1 rounded-tr-4xl bg-background px-2 pt-6 text-center pb-20">
        <h1 className="">{t('page.title')}</h1>
        <p className="text-2xs mt-3">
          {player?.telegramId} / {playerUsername} / {player?.id.slice(4).toUpperCase()}
        </p>
        <div className="grid grid-cols-2 items-center justify-center gap-2 mt-5">
          {Object.entries({
            diamonds: playerResources?.diamonds?.balance ?? 0,
            keys: playerResources?.keys?.balance ?? 0,
          }).map(([type, value]) => {
            return <BalanceCard key={type} value={value} type={type as 'diamonds' | 'keys'} />
          })}
        </div>
        <CharacterKeyBanner />
        <BalanceKeyWidget actionButton={<KeyPurchaseButton className="w-full" />} />
        <WithdrawBalanceWidget
          className="mt-2"
          totalCrystals={playerResources?.diamonds?.balance ?? 0}
          availableForWithdraw={playerResources?.diamonds?.balance ?? 0}
          // totalCrystals={1234}
          // availableForWithdraw={1234}
        />
        {/* <ShareStoryWidget
          className="mt-2"
          actionButton={<KeysForStoryButton className="w-full" />}
        /> */}
      </div>
    </PageLayout>
  )
}
