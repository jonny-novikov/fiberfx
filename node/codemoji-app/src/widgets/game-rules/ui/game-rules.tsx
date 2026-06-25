import { useTranslation } from 'react-i18next'

import { InviteFriendButton, ShareForClips } from '@/features/share-story'
import { cn } from '@/shared/libs'
import { AppleEmoji, Button } from '@/shared/ui'
import { useOnboarding } from '@/widgets/onboarding'

export const GameRules = ({ className }: { className?: string; onShareSuccess?: () => void }) => {
  const { t } = useTranslation()
  const { show: showOnboarding } = useOnboarding()

  const handleOpenOnboarding = () => {
    showOnboarding(true) // true = можно закрыть
  }

  return (
    <div className={cn('', className)}>
      <div className="bg-white rounded-2xl pt-8 px-6 pb-6 leading-none">
        <h2 className="font-bold text-xl mb-4 flex items-center gap-2">
          <AppleEmoji id="game_die" size={24} />
          <span>{t('gameRules.title')}</span>
        </h2>
        <p className="text-xs mb-8">{t('gameRules.description')}</p>
        <ol className="list-decimal list-inside text-xs max-w-[311px] mb-4">
          <li>{t('gameRules.rules.unlimited')}</li>
          <li className="flex items-center flex-wrap gap-1">
            <span>{t('gameRules.rules.attemptCost')}</span>
            <AppleEmoji id="key" size={14} />
            <span>{t('gameRules.rules.keys')}</span>
          </li>
          <li>{t('gameRules.rules.prizePool')}</li>
          <li>{t('gameRules.rules.scoring')}</li>
        </ol>
        <ul className="text-xs mb-8">
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              100
            </span>
            <span>{t('gameRules.scoring.100')}</span>
          </li>
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              80
            </span>
            <span>{t('gameRules.scoring.80')}</span>
          </li>
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              60
            </span>
            <span>{t('gameRules.scoring.60')}</span>
          </li>
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              40
            </span>
            <span>{t('gameRules.scoring.40')}</span>
          </li>
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              20
            </span>
            <span>{t('gameRules.scoring.20')}</span>
          </li>
          <li>
            <span className="font-medium text-dark-muted w-[21px] mr-[14px] text-right inline-block">
              0
            </span>
            <span>{t('gameRules.scoring.0')}</span>
          </li>
        </ul>
        <Button className="w-full" onClick={handleOpenOnboarding}>
          {t('gameRules.howToPlay')}
        </Button>
        <p className="font-medium text-xs mb-8 mt-4">
          <span className="text-dark-muted inline-flex items-baseline gap-1">
            <AppleEmoji id="bulb" size={14} />
            {t('gameRules.tipFrom')}
          </span>{' '}
          {t('gameRules.tipText')}
        </p>
        <h2 className="font-bold text-xl text-center mb-3">{t('gameRules.getFreeKey')}</h2>
        <p className="text-xs text-center font-medium">{t('gameRules.shareForAccess')}</p>
        <p className="text-xs text-center font-medium">{t('gameRules.shareForAccess2')}</p>

        <ShareForClips className="w-full mt-4" />
        <InviteFriendButton className="w-full mt-2" />
      </div>
    </div>
  )
}
