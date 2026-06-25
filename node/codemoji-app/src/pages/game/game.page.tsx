import { useSetAtom } from 'jotai'
import { useEffect, useMemo, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams, useNavigate } from 'react-router-dom'

import { GoldenGameTabs } from './golden-game-tabs'

import { HistoryList } from '@/entities/history'
import { usePlayerGuessHistory } from '@/entities/history/api/history.queries'
import { LeaderboardList } from '@/entities/leaderboard'
import { useLeaveRoomMutation } from '@/entities/rooms/api/rooms.mutation'
import { resetGameStateAtom, useGameStateQuery, useRoomStateQuery } from '@/features/game'
import { GameLayout } from '@/shared/layout'
import {
  TelegramUtils,
  cn,
  useBackButton,
  EmojiSetProvider,
  isEmojiSetSnapshot,
  getEmojiCodes,
  useConfetti,
} from '@/shared/libs'
import { AppleEmoji, EmojiKeyboard, Tabs, TabsTrigger, TabsList, TabsContent } from '@/shared/ui'
import { EmotionPicker } from '@/widgets/emotion-picker'
import { FirstPlaceDialog, useFirstPlaceDialog } from '@/widgets/first-place-dialog'
import { useGameOverDialog } from '@/widgets/game-over-dialog'
import { GameRules } from '@/widgets/game-rules'
import { LobbyInfo } from '@/widgets/lobby-info'
import { useVictoryDialog } from '@/widgets/victory-dialog'

const GameTabs = ({ className }: { className?: string }) => {
  const { t } = useTranslation()

  return (
    <Tabs
      defaultValue="history"
      className={cn('bg-white rounded-3xl px-3 pb-4 h-[50dvh] flex flex-col', className)}
    >
      <TabsList className="relative shrink-0">
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-card" />
        <TabsTrigger value="history" className="flex items-center gap-1">
          <AppleEmoji id="clipboard" size={16} />
          <span>{t('game.tabs.history')}</span>
        </TabsTrigger>
        <TabsTrigger value="leaderboard" className="flex items-center gap-1">
          <AppleEmoji id="trophy" size={16} />
          <span>{t('game.tabs.leaderboard')}</span>
        </TabsTrigger>
      </TabsList>
      <TabsContent value="history" className="flex-1 min-h-0">
        <div className="h-full overflow-y-auto scrollbar-custom">
          <HistoryList />
        </div>
      </TabsContent>
      <TabsContent value="leaderboard" className="flex-1 min-h-0">
        <div className="h-full flex flex-col overflow-hidden ">
          <div className="flex-1 overflow-y-auto scrollbar-custom">
            <LeaderboardList />
          </div>
          {/* <div className="shrink-0 pt-2">
            <LeaderboardNotificationToggle />
          </div> */}
        </div>
      </TabsContent>
    </Tabs>
  )
}

export const GamePage = () => {
  const { t } = useTranslation()
  const { roomId, gameId } = useParams<{ roomId: string; gameId: string }>()
  const { data: roomState, isLoading: isRoomLoading, error } = useRoomStateQuery(roomId!)
  const { data: gameState, isLoading: isGameLoading, error: gameError } = useGameStateQuery(gameId!)
  const { data: historyData } = usePlayerGuessHistory(gameId!)
  const { mutate: leaveRoom } = useLeaveRoomMutation()
  const { show: showGameOverDialog } = useGameOverDialog()
  const { show: showVictoryDialog } = useVictoryDialog()
  const {
    isOpen: isFirstPlaceDialogOpen,
    hide: hideFirstPlaceDialog,
    data: firstPlaceData,
  } = useFirstPlaceDialog()
  const resetGameState = useSetAtom(resetGameStateAtom)
  const navigate = useNavigate()
  const { triggerConfetti } = useConfetti()
  const isGolden = roomState?.roomType === 'golden'
  // Ref для отслеживания реального размонтирования (не из-за strict mode)
  const shouldLeaveOnUnmountRef = useRef(false)
  // Ref для отслеживания показа диалога финализации (чтобы показать только один раз)
  const finalizedDialogShownRef = useRef(false)

  // Извлекаем уникальные эмодзи из истории попыток
  const usedEmojis = useMemo(() => {
    if (!historyData) return []
    const allEmojis = historyData.flatMap((item) => item.guessCode ?? [])
    return [...new Set(allEmojis)]
  }, [historyData])

  useBackButton({ navigateTo: '/rooms' })

  const handleLeaveRoom = () => {
    if (roomId) {
      // Вызываем API выхода из комнаты
      leaveRoom(roomId, {
        onSettled: () => {
          // Очищаем состояние игры и переходим к списку комнат
          resetGameState()
          navigate('/rooms')
        },
      })
    } else {
      // Если нет roomId, просто переходим
      resetGameState()
      navigate('/rooms')
    }
  }

  // Устанавливаем флаг после успешной загрузки комнаты
  useEffect(() => {
    if (roomId && !isGameLoading && gameState && !isRoomLoading && roomState) {
      // Устанавливаем флаг с небольшой задержкой, чтобы избежать срабатывания в strict mode
      const timer = setTimeout(() => {
        shouldLeaveOnUnmountRef.current = true
      }, 100)

      return () => clearTimeout(timer)
    }
  }, [roomId, isGameLoading, gameState, isRoomLoading, roomState])

  // Cleanup при размонтировании
  useEffect(() => {
    return () => {
      // Вызываем leaveRoom только если флаг установлен (не в strict mode)
      if (shouldLeaveOnUnmountRef.current && roomId) {
        handleLeaveRoom()
      }
    }
  }, [roomId])

  // Обработка финализации игры
  useEffect(() => {
    if (gameState?.status === 'finalized' && !finalizedDialogShownRef.current) {
      finalizedDialogShownRef.current = true

      if (gameState.myRank === 1) {
        // Haptic feedback при победе
        TelegramUtils.notificationOccurred('success')
        triggerConfetti()
        showVictoryDialog({ gameId: gameId! })
      } else {
        showGameOverDialog({ gameId: gameId! })
      }
      navigate('/rooms')
    }
  }, [
    gameState?.status,
    gameState?.myRank,
    gameId,
    showVictoryDialog,
    showGameOverDialog,
    navigate,
    triggerConfetti,
  ])

  useEffect(() => {
    if (roomId && gameId) {
      resetGameState()
    }
  }, [roomId, gameId])

  // Loading state
  if (isGameLoading || isRoomLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="animate-pulse mb-4">
            <AppleEmoji id="video_game" size={64} />
          </div>
          <p className="text-lg text-gray-600">{t('game.connecting')}</p>
        </div>
      </div>
    )
  }

  // Error state
  if (gameError || error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="mb-4">
            <AppleEmoji id="warning" size={64} />
          </div>
          <p className="text-lg text-red-600">
            {gameError?.message || error?.message || t('common.error')}
          </p>
          <button
            onClick={() => navigate('/rooms')}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            {t('game.backToRooms')}
          </button>
        </div>
      </div>
    )
  }

  // No room state
  if (!roomId || !gameId) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center space-y-4">
          <div className="mb-4">
            <AppleEmoji id="confused" size={64} />
          </div>
          <p className="text-lg text-gray-600">{t('game.roomNotFound')}</p>
          <button
            onClick={() => navigate('/rooms')}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            {t('game.backToRooms')}
          </button>
        </div>
      </div>
    )
  }

  // Extract emoji set config and codes based on type
  const emojiSetRaw = roomState?.emojiSet
  const isSnapshot = isEmojiSetSnapshot(emojiSetRaw)
  const emojiCodes = getEmojiCodes(emojiSetRaw)
  const emojiConfig = isSnapshot
    ? {
        spriteUrl: emojiSetRaw.spriteUrl,
        cellSize: emojiSetRaw.cellSize,
        gridCols: emojiSetRaw.gridCols,
        gridRows: emojiSetRaw.gridRows,
        emojiSetId: emojiSetRaw.emojiSetId,
      }
    : null

  const gameContent = (
    <GameLayout>
      <div
        className={cn('h-[calc(100dvh-100px)] flex flex-col', {
          'h-[calc(100dvh-200px)]': TelegramUtils.isMobileDevice(),
        })}
      >
        <LobbyInfo gameId={gameId!} roomId={roomId!} />
        <EmotionPicker className="animate-in slide-in-from-right-4 fade-in duration-300 mt-4" />
        <EmojiKeyboard
          emojis={emojiCodes}
          usedEmojis={usedEmojis}
          loading={isRoomLoading}
          maxEmojis={6}
          columns={7}
          cellSize="auto"
          className="flex-1 overflow-hidden animate-qu"
        />
      </div>

      {isGolden ? (
        <GoldenGameTabs gameId={gameId!} className="animate-qu" />
      ) : (
        <GameTabs className="animate-qu" />
      )}

      <GameRules className="mt-6 px-2" />

      <FirstPlaceDialog
        open={isFirstPlaceDialogOpen}
        onOpenChange={(open) => !open && hideFirstPlaceDialog()}
        prizePool={firstPlaceData?.prizePool}
        bonusPoints={firstPlaceData?.bonusPoints}
      />
    </GameLayout>
  )

  // Wrap with EmojiSetProvider if using sprite mode
  return <EmojiSetProvider config={emojiConfig}>{gameContent}</EmojiSetProvider>
}

//    <ShareStoryDialog
//    open={isShareDialogOpen}
//    onOpenChange={setIsShareDialogOpen}
//    onShare={handleShareStory}
//    storyTitle="Отгадай шифр и забери весь банк себе!"
//  />

//  <SendStoryChatDialog
//    open={isSendStoryChatDialogOpen}
//    onOpenChange={setIsSendStoryChatDialogOpen}
//  />

//  <FirstPlaceDialog
//    open={isFirstPlaceDialogOpen}
//    onOpenChange={setIsFirstPlaceDialogOpen}
//    onSubscribe={handleSubscribeNotifications}
//    onDecline={handleDeclineNotifications}
//    prizePool={2325}
//    bonusPoints={1}
//  />

//  <KeysAddedDialog
//    open={isKeysAddedDialogOpen}
//    onOpenChange={setIsKeysAddedDialogOpen}
//    onContinue={() => {

//    }}
//  />

//  <ErrorDialog
//    open={isErrorDialogOpen}
//    onOpenChange={setIsErrorDialogOpen}
//    onClose={() => {
//      setIsErrorDialogOpen(false)
//    }}
//  />
