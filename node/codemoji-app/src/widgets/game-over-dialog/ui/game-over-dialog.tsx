import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import React, { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import {
  gameOverDialogOpenAtom,
  gameOverDialogDataAtom,
  hideGameOverDialogAtom,
} from '../model/game-over-dialog.store'

import { useGameLeaderboard } from '@/entities/leaderboard'
import { useGameStateQuery, useGameQuery } from '@/features/game'
import { ShareStoryButton } from '@/features/share-story'
import { EmojiSetProvider, formatPriceToString } from '@/shared/libs'
import { APP_URL } from '@/shared/libs/consts'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  Button,
  DialogBody,
  SpriteEmoji,
} from '@/shared/ui'

export const GameOverDialog: React.FC = () => {
  const { t } = useTranslation()
  const [open, setOpen] = useAtom(gameOverDialogOpenAtom)
  const dialogData = useAtomValue(gameOverDialogDataAtom)
  const hideDialog = useSetAtom(hideGameOverDialogAtom)

  const { data: gameState } = useGameStateQuery(dialogData?.gameId ?? '')
  const { data: gameDetails } = useGameQuery(dialogData?.gameId ?? '')
  const { data: leaderboardData } = useGameLeaderboard(dialogData?.gameId ?? '')

  // secretCode доступен только для завершённых игр (status === 'finalized')
  const secretCode = gameDetails?.secretCode

  useEffect(() => {
    if (open && dialogData?.gameId) {
      console.log('[GameOverDialog] gameId:', dialogData.gameId)
      console.log('[GameOverDialog] secretCode:', secretCode)
    }
  }, [open, dialogData?.gameId, secretCode])

  // const handleClose = () => {
  //   hideDialog()
  // }

  const handleTryAgain = () => {
    hideDialog()
    // Здесь можно добавить логику повторной попытки
  }

  // Определяем заголовок и описание в зависимости от причины
  const getTitle = () => {
    switch (dialogData?.reason) {
      case 'winner_found':
        return t('gameOverDialog.titles.gameOver')
      case 'time_expired':
        return t('gameOverDialog.titles.timeExpired')
      case 'attempts_exceeded':
        return t('gameOverDialog.titles.attemptsExceeded')
      default:
        return t('gameOverDialog.titles.gameOver')
    }
  }

  // const getDescription = () => {
  //   if (dialogData?.winnerName) {
  //     return (
  //       <>
  //         Победитель найден! <span className="font-bold">{dialogData.winnerName}</span> первым
  //         разгадал код.
  //         <br />
  //         {dialogData.playerPosition && `Вы заняли ${dialogData.playerPosition} место.`}
  //       </>
  //     )
  //   }

  //   if (dialogData?.reason === 'time_expired') {
  //     return (
  //       <>
  //         К сожалению, время на разгадывание кода истекло.
  //         <br />
  //         Попробуйте в следующий раз!
  //       </>
  //     )
  //   }

  //   if (dialogData?.reason === 'attempts_exceeded') {
  //     return (
  //       <>
  //         У вас закончились попытки разгадать код.
  //         <br />
  //         Не расстраивайтесь, попробуйте еще раз!
  //       </>
  //     )
  //   }

  //   return (
  //     <>
  //       К сожалению, вы не успели разгадать код до победителя.
  //       <br />
  //       Продолжайте играть и совершенствуйте свои навыки!
  //     </>
  //   )
  // }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="pb-8 pt-10 px-6">
        <DialogHeader className="space-y-4 text-center pt-10">
          <div className="flex justify-center">
            <img
              src="/images/game/game-over-img.webp"
              alt={t('gameOverDialog.gameOverImage')}
              className="h-50 object-contain absolute -top-30 left-1/2 -translate-x-1/2"
            />
          </div>

          <DialogTitle className="text-xl leading-none font-bold text-dark-muted">
            {getTitle()}
          </DialogTitle>
        </DialogHeader>
        {secretCode && secretCode.length > 0 && gameDetails?.emojiSet && (
          <EmojiSetProvider
            config={{
              spriteUrl: gameDetails?.emojiSet?.spriteUrl,
              cellSize: gameDetails?.emojiSet?.cellSize,
              gridCols: gameDetails?.emojiSet?.gridCols,
              gridRows: gameDetails?.emojiSet?.gridRows,
              emojiSetId: gameDetails?.emojiSet?.emojiSetId,
            }}
          >
            <DialogBody className="mt-6">
              <div className="flex justify-center gap-1">
                {secretCode.map((code: string, index: number) => (
                  <div
                    key={index}
                    className="size-10 border-2 border-primary/10 rounded-lg bg-card flex items-center justify-center"
                  >
                    <SpriteEmoji code={code} />
                  </div>
                ))}
              </div>
            </DialogBody>
          </EmojiSetProvider>
        )}

        <DialogFooter className="mt-6 pt-0 space-y-2">
          <DialogDescription className="text-center text-xs font-medium">
            {t('gameOverDialog.player')}{' '}
            <span className="text-primary">{leaderboardData?.items?.[0]?.displayName ?? ''}</span>{' '}
            {t('gameOverDialog.opened')} {t('gameOverDialog.safe')}{' '}
            {!gameState?.prizePool && (
              <span>
                {formatPriceToString(gameState?.prizePool || 0)} {t('gameOverDialog.fasterThanYou')}
              </span>
            )}
            <br />
            {t('gameOverDialog.hurryNextTime')}
          </DialogDescription>

          <Button
            onClick={handleTryAgain}
            className="w-full bg-[#0050FF] text-white font-bold transition-colors mt-6"
          >
            {t('gameOverDialog.playAgain')}
          </Button>
          <ShareStoryButton
            className="w-full"
            storyParams={{
              mediaUrl: '/images/tg-stories/game-over-ru-1.webp',
              text: t('gameOverDialog.storyText'),
              widgetLink: {
                url: APP_URL,
                name: t('gameOverDialog.widgetLinkName'),
              },
            }}
            disabled
          >
            {t('gameOverDialog.shareToStories')}
          </ShareStoryButton>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
