import { GuessHistoryDto, ScoringResultDto } from '@codemoji/types'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useSetAtom } from 'jotai'

import {
  GuessByRoomCodeRequest,
  GuessSubmitResponse,
  ClaimPrizeResponse,
  GameStateResponse,
} from '../model/game.types'
import { clearEmojisAtom } from '../model/gameplay.store'

import { submitGuess, claimPrize } from './game.api'
import { gameQueryKeys } from './game.query-keys'

import { historyQueryKeys } from '@/entities/history'
import { leaderboardQueryKeys } from '@/entities/leaderboard'
import { playerQueryKeys, type PlayerResources } from '@/entities/player'
import { useConfetti, TelegramUtils } from '@/shared/libs'
import { showFirstPlaceDialogAtom } from '@/widgets/first-place-dialog'

export function useGuessSubmitMutation(gameId: string, guessFee: number, prizePool: number) {
  const { triggerConfetti } = useConfetti()
  const queryClient = useQueryClient()
  const showFirstPlaceDialog = useSetAtom(showFirstPlaceDialogAtom)

  const clearEmojis = useSetAtom(clearEmojisAtom)

  return useMutation<GuessSubmitResponse, Error, GuessByRoomCodeRequest>({
    mutationFn: (data: GuessByRoomCodeRequest) => submitGuess(gameId, data.guessCode),
    onError: () => {
      // Re-fetch real balance from server to undo stale optimistic update
      queryClient.invalidateQueries({
        queryKey: playerQueryKeys.resources(),
      })
    },
    onSuccess: (data, variables) => {
      clearEmojis()

      if (data.isBecameLeader) {
        // Haptic feedback при достижении лидерства
        TelegramUtils.notificationOccurred('success')
        showFirstPlaceDialog({ prizePool: prizePool })
        triggerConfetti()
      }

      // Optimistic resource update: deduct keys/clips from cache
      queryClient.setQueryData<PlayerResources>(playerQueryKeys.resources(), (prev) => {
        if (!prev) return prev

        if (guessFee === 0) {
          // Free game: deduct 1 clip (bonus key)
          return {
            ...prev,
            keys: {
              ...prev.keys,
              bonusKeys: Math.max(0, prev.keys.bonusKeys - 1),
            },
          }
        }

        // Paid game: deduct only from regular keys (backend never touches bonusKeys)
        return {
          ...prev,
          keys: {
            ...prev.keys,
            balance: prev.keys.balance - guessFee,
          },
        }
      })

      queryClient.invalidateQueries({
        queryKey: historyQueryKeys.byGame(gameId),
      })

      queryClient.invalidateQueries({
        queryKey: leaderboardQueryKeys.byGame(gameId),
      })

      // queryClient.invalidateQueries({
      //   queryKey: playerQueryKeys.resources(),
      // })

      // Прямое обновление состояния игры вместо инвалидации
      queryClient.setQueryData<GameStateResponse>(gameQueryKeys.gameState(gameId), (prev) => {
        if (!prev) return prev

        // Создаем полную запись scoring с дефолтными значениями для отсутствующих полей
        const fullScoring: ScoringResultDto = {
          basePoints: data.scoring.basePoints,
          finalPoints: data.scoring.finalPoints,
          exactCount: 0,
          foundCount: 0,
          distances: [null, null, null, null, null, null],
          percentageX100: 0,
        }

        // Создаем новую запись догадки из ответа сервера
        const newGuess: GuessHistoryDto = {
          guessId: data.guessId,
          guessCode: variables.guessCode,
          scoring: fullScoring,
          attemptNumber: data.attemptNumber,
          isBestGuess: data.isBestGuess,
          lockedPositions: data.lockedPositions,
          submittedAt: data.submittedAt,
        }

        // Обновляем список догадок
        const updatedGuesses = [...prev.myGuesses, newGuess]

        // Обновляем лучший результат, если это лучшая догадка
        const updatedBestScore = data.isBestGuess ? data.scoring.finalPoints : prev.myBestScore

        return {
          ...prev,
          myGuesses: updatedGuesses,
          myBestScore: updatedBestScore,
          keyBalance: data.keysRemaining,
        }
      })
    },
  })
}

/**
 * Мутация для начисления приза победителю
 * @param gameId - ID игры
 */
export function useClaimPrizeMutation() {
  const queryClient = useQueryClient()

  return useMutation<ClaimPrizeResponse, Error, string>({
    mutationFn: (gameId: string) => claimPrize(gameId),
    onSuccess: (_data, gameId) => {
      // Обновляем состояние игры
      queryClient.invalidateQueries({
        queryKey: gameQueryKeys.gameState(gameId),
      })

      // Обновляем ресурсы игрока
      queryClient.invalidateQueries({
        queryKey: playerQueryKeys.resources(),
      })
    },
  })
}
