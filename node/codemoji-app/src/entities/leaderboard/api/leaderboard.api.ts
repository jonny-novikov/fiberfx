import type { GameLeaderboardEntryResponse } from '../model/types/leaderboard.types'

import { api } from '@/shared/api/axios'

/**
 * Get game leaderboard
 * @param gameId - Game ID in format GAMxxxxxxxxxxx
 */
export async function getGameLeaderboard(gameId: string) {
  const response = await api.get<GameLeaderboardEntryResponse>(`/game/${gameId}/leaderboard`)
  return response.data
}
