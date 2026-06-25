import type { PlayerGuessHistoryResponse, GuessHistoryResponse } from '../model/types/history.types'

import { api } from '@/shared/api/axios'

/**
 * Получить историю попыток текущего игрока в комнате
 *
 * @param roomCode - код комнаты
 * @returns история попыток с эмодзи, процентами и очками
 */
export async function getPlayerGuessHistory(roomCode: string) {
  const response = await api.get<PlayerGuessHistoryResponse>(`/rooms/${roomCode}/history`)
  return response.data
}

/**
 * Get player's guess history for a game
 * @param gameId - Game ID in format GAMxxxxxxxxxxx
 */
export async function getGuessHistory(gameId: string) {
  const response = await api.get<GuessHistoryResponse[]>(`/game/${gameId}/history`)
  return response.data
}
