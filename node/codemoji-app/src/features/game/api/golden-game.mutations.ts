import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useSetAtom } from 'jotai'

import type { GuessByRoomCodeRequest } from '../model/game.types'
import type { BlindGuessSubmitResponse } from '../model/golden-game.types'
import { clearEmojisAtom } from '../model/gameplay.store'

import { submitGuess } from './game.api'

import { goldenGamesQueryKeys } from '@/entities/golden-games'
import { playerQueryKeys, type PlayerResources } from '@/entities/player'

export function useGoldenGuessSubmitMutation(gameId: string, guessFee: number) {
  const queryClient = useQueryClient()
  const clearEmojis = useSetAtom(clearEmojisAtom)

  return useMutation<BlindGuessSubmitResponse, Error, GuessByRoomCodeRequest>({
    mutationFn: (data) => submitGuess(gameId, data.guessCode),
    onSuccess: () => {
      clearEmojis()

      // Optimistic key deduction (golden rooms are always paid, D-25)
      queryClient.setQueryData<PlayerResources>(playerQueryKeys.resources(), (prev) => {
        if (!prev) return prev
        return {
          ...prev,
          keys: {
            ...prev.keys,
            balance: prev.keys.balance - guessFee,
          },
        }
      })

      queryClient.invalidateQueries({ queryKey: goldenGamesQueryKeys.all })
    },
    onError: () => {
      queryClient.invalidateQueries({ queryKey: playerQueryKeys.resources() })
    },
  })
}
