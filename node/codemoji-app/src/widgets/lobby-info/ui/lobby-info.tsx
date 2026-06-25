import { useSetAtom } from 'jotai'
import { FC, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { useMyResources } from '@/entities/player'
import { useGameStateQuery, useRoomStateQuery } from '@/features/game'
import { keysPurchaseDrawerAtom } from '@/features/keys-purchase'
import { SessionTimer } from '@/features/session-timer'
import { useShareToStory } from '@/features/share-story'
import { cn, currencyConverter, formatPriceToString } from '@/shared/libs'
import { APP_URL } from '@/shared/libs/consts'
import { TelegramUtils } from '@/shared/libs/utils/telegram'
import {
  AppleEmoji,
  Button,
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/shared/ui'

interface LobbyInfoProps {
  className?: string
  gameId: string
  roomId: string
}

const STORIES_COUNT = 6

export const LobbyInfo: FC<LobbyInfoProps> = ({ className, gameId, roomId }) => {
  const { t, i18n } = useTranslation()
  const setDrawerOpen = useSetAtom(keysPurchaseDrawerAtom)
  const { data: gameState } = useGameStateQuery(gameId)
  const { data: roomState } = useRoomStateQuery(roomId)
  const { data: resources } = useMyResources()
  const keysBalance = resources?.keys.balance
  const bonusKeys = resources?.keys.bonusKeys ?? 0
  const isFreeRoom = (roomState?.guessFee ?? 0) === 0
  const isGolden = roomState?.roomType === 'golden'
  const diamondsStr = currencyConverter.formatDiamonds(
    currencyConverter.centsToDiamonds(gameState?.prizePool ?? 0)
  )

  const [shareDialogOpen, setShareDialogOpen] = useState(false)
  const lang = i18n.language === 'ru' ? 'ru' : 'en'

  const { prepareShare, confirmShare, isPreparing, shareData, error, isAvailable } =
    useShareToStory({
      onSuccess: () => setShareDialogOpen(false),
    })

  const handleClipsClick = () => {
    setShareDialogOpen(true)
    prepareShare()
  }

  const handleConfirmShare = () => {
    const appLink = shareData?.shareUrl || APP_URL
    const shareText = t('share.storyText', {
      defaultValue: `Взломай код. Шесть эмодзи. Один приз.\nПодбери комбинацию быстрее всех и забери призовой пул`,
    })

    if (isAvailable) {
      const randomImage = `/images/tg-stories/story-${lang}-${Math.floor(Math.random() * STORIES_COUNT) + 1}.webp`
      const fullText = `${appLink.replace('https://', '')}\n\n${shareText}`
      confirmShare({
        mediaUrl: randomImage,
        text: fullText,
        widgetLink: { url: appLink, name: t('gameRules.playCodemoji') },
      })
    } else {
      TelegramUtils.share({ text: shareText, url: appLink })
      setShareDialogOpen(false)
    }
  }

  const handleForwardLink = () => {
    const appLink = shareData?.shareUrl || APP_URL
    const shareText = t('share.forwardText', {
      defaultValue: `Взломай код. Шесть эмодзи. Один приз.\nПодбери комбинацию быстрее всех и забери призовой пул`,
    })
    TelegramUtils.share({ text: shareText, url: appLink })
    setShareDialogOpen(false)
  }

  const getShareDescription = (): string => {
    if (isPreparing) return t('shareStoryDialog.preparing', { defaultValue: 'Подготовка...' })
    if (error) return t('shareStoryDialog.error', { defaultValue: 'Ошибка. Попробуйте ещё раз.' })
    return (
      t('shareStoryDialog.description', {
        defaultValue: '+25 скрепок за переход друга из сториз.',
      }) +
      '\n' +
      t('shareStoryDialog.description2', { defaultValue: 'Доступно раз в сутки.' })
    )
  }

  return (
    <div className={cn('px-2 grid grid-cols-12 gap-1', className)}>
      {/* Кнопка ресурсов: скрепки (бесплатная комната) или ключи (платная) */}

      {isFreeRoom ? (
        <>
          <button
            onClick={handleClipsClick}
            className="col-span-12 bg-card rounded-t-2xl rounded-b-lg px-4 py-3 flex items-center justify-between text-[0.625rem] cursor-pointer"
          >
            <p className="card-foreground font-medium">{t('lobbyInfo.earnClips')}</p>
            <p className="card-foreground-secondary flex items-center gap-1">
              <img src="/images/keys/clip.png" alt="clip" className="size-3.5" />
              <span>{bonusKeys}</span>
            </p>
          </button>

          <Dialog open={shareDialogOpen} onOpenChange={setShareDialogOpen}>
            <DialogContent className="pb-8 pt-10 px-6">
              <DialogHeader className="space-y-6 text-center">
                <div className="flex justify-center">
                  <img
                    src={`/images/tg-stories/story-preview-${lang}.webp`}
                    alt={t('shareStoryDialog.storyPreviewAlt', { defaultValue: 'Story preview' })}
                    className="max-w-80"
                  />
                </div>

                <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
                  {t('shareStoryDialog.title', { defaultValue: 'Играй с друзьями' })}
                </DialogTitle>

                <DialogDescription className="text-xs leading-[17px] text-muted">
                  {getShareDescription()}
                </DialogDescription>
              </DialogHeader>

              <DialogFooter className="mt-6 pt-0 space-y-2">
                <Button
                  onClick={handleConfirmShare}
                  disabled={!shareData || isPreparing}
                  loading={isPreparing}
                  className="w-full bg-[#0050FF] hover:bg-[#0051D5] text-white font-bold rounded-lg transition-colors"
                >
                  {t('shareStoryDialog.postStory', { defaultValue: 'Share to Stories' })}
                </Button>
                <Button
                  onClick={handleForwardLink}
                  disabled={!shareData || isPreparing}
                  loading={isPreparing}
                  className="rounded-lg w-full"
                >
                  {t('shareStoryDialog.forwardLink', { defaultValue: 'Отправить ссылку корешку' })}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </>
      ) : (
        <button
          onClick={() => setDrawerOpen(true)}
          className="col-span-12 bg-card rounded-t-2xl rounded-b-lg px-4 py-3 flex items-center justify-between text-[0.625rem] cursor-pointer"
        >
          <p className="card-foreground font-medium">{t('lobbyInfo.addKeys')}</p>
          <p className="card-foreground-secondary flex items-center gap-1">
            <span>{t('lobbyInfo.balance')}</span>
            <img
              src="/images/keys/dark-key.png"
              alt={t('lobbyInfo.keyImage')}
              className="size-3.5"
            />
            <span>{keysBalance}</span>
          </p>
        </button>
      )}

      {/* Таймер */}
      <div
        className={cn(
          'col-span-6 rounded-lg flex flex-col items-center justify-center h-14.5 overflow-hidden',
          isGolden ? 'bg-cover bg-center' : 'bg-card'
        )}
        style={isGolden ? { backgroundImage: 'url(/images/rooms/gold.png)' } : undefined}
      >
        <SessionTimer endTime={gameState?.endsAt ?? ''} variant={isGolden ? 'golden' : 'default'} />
      </div>

      {/* Призовой пул */}
      <div
        className={cn(
          'col-span-6 rounded-lg flex flex-col items-center justify-center h-14.5',
          isGolden ? 'bg-cover bg-center' : 'bg-success'
        )}
        style={isGolden ? { backgroundImage: 'url(/images/rooms/gold.png)' } : undefined}
      >
        <span className="text-primary-foreground text-2xl font-bold">
          {formatPriceToString(gameState?.prizePool ?? 0)}
        </span>
        <div className="flex justify-center gap-0.5">
          <p className="text-xs text-primary-foreground text-center font-medium">
            {t('lobbyInfo.prizePool')}
          </p>
          <img src="/images/common/diamond.png" alt={t('lobbyInfo.coinImage')} className="size-4" />
          <p className="text-xs text-primary-foreground text-center font-medium">{diamondsStr}</p>
        </div>
      </div>

      {/* Всего игроков */}
      <div className="col-span-4 bg-card rounded-lg rounded-bl-2xl flex flex-col gap-1 items-center justify-center h-13">
        <h3 className="text-xl font-bold leading-none">
          {gameState?.totalParticipants === 0 ? 1 : gameState?.totalParticipants || 1}
        </h3>
        <p className="text-[0.5625rem] leading-none text-card-foreground-secondary text-center font-medium flex gap-1">
          <AppleEmoji id="busts_in_silhouette" size={12} />
          <span>{t('lobbyInfo.totalPlayers')}</span>
        </p>
      </div>

      {/* Всего попыток */}
      <div className="col-span-4 bg-card rounded-lg flex flex-col gap-1 items-center justify-center h-13">
        <h3 className="text-xl font-bold leading-none">{gameState?.myGuesses.length ?? 0}</h3>
        <p className="text-[0.5625rem] leading-none text-card-foreground-secondary text-center font-medium flex gap-1">
          <AppleEmoji id="dart" size={12} />
          <span>{t('lobbyInfo.totalAttempts')}</span>
        </p>
      </div>

      {/* Лучшая попытка */}
      <div className="col-span-4 bg-card rounded-lg rounded-br-2xl flex flex-col gap-1 items-center justify-center h-13">
        <h3 className="text-xl font-bold leading-none">{gameState?.myBestScore ?? 0}</h3>

        <p className="text-[0.5625rem] leading-none text-card-foreground-secondary text-center font-medium flex gap-1">
          <AppleEmoji id="star" size={12} />
          <span>{t('lobbyInfo.bestAttempt')}</span>
        </p>
      </div>

      {isGolden && (
        <button
          onClick={() => {
            const el = document.getElementById('golden-rules-btn')
            if (el) {
              const y = el.getBoundingClientRect().top + window.scrollY - 400
              window.scrollTo({ top: Math.max(0, y), behavior: 'smooth' })
            }
          }}
          className="col-span-12 bg-black rounded-b-2xl rounded-t-lg px-4 py-3 flex items-center justify-between text-sm cursor-pointer"
        >
          <span
            className="font-bold bg-clip-text text-transparent"
            style={{
              backgroundImage:
                'linear-gradient(269.06deg, #FFE8C1 0.09%, #CC7500 20.15%, #FFD8AB 37.5%, #FFF1D6 55.93%, #E6A900 73.27%, #FFE8BD 92.25%, #FFC88A 112.85%)',
            }}
          >
            {t('lobbyInfo.goldenRoom', { defaultValue: 'Золотая комната' })}
          </span>
          <span className="text-white text-xs font-medium">
            {t('lobbyInfo.readRules', { defaultValue: 'Читать правила' })} &gt;
          </span>
        </button>
      )}
    </div>
  )
}
