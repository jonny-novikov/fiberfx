import {
  GuessSubmitResponse,
  RoomResponse,
  GuessByRoomCodeRequest,
  GameStateResponse,
  GameDetailsResponse,
} from '../model/game.types'

import { api } from '@/shared/api/axios'

/**
 * Get room state by roomId (branded ID)
 * @param roomId - Room ID in format ROMxxxxxxxxxxx
 */
export async function getRoomState(roomId: string) {
  const response = await api.get<RoomResponse>(`/rooms/${roomId}`)
  return response.data
}

/**
 * Get game details by gameId
 * Returns game info including secretCode when game is finalized
 * @param gameId - Game ID in format GAMxxxxxxxxxxx
 */
export async function getGame(gameId: string) {
  const response = await api.get<GameDetailsResponse>(`/game/${gameId}`)
  return response.data
}

/**
 * Get game state for authenticated player
 * @param gameId - Game ID in format GAMxxxxxxxxxxx
 */
export async function getGameState(gameId: string) {
  const response = await api.get<GameStateResponse>(`/game/${gameId}/state`)
  return response.data
}

/**
 * Submit a guess for a game
 * @param gameId - Game ID in format GAMxxxxxxxxxxx (from room state)
 * @param guessCode - Array of 6 emojis
 * @param options - Optional platform, lockedPositions, etc.
 */
export async function submitGuess(
  gameId: string,
  guessCode: string[],
  options?: Omit<GuessByRoomCodeRequest, 'guessCode'>
) {
  const response = await api.post<GuessSubmitResponse>(`/game/${gameId}/guess`, {
    guessCode,
    ...options,
  })
  return response.data
}

/**
 * Claim prize for a won game
 */
export async function claimPrize(_: string) {
  const response = await api.post<{ success: boolean }>(`/bank/claim-all`)
  return response.data
}
