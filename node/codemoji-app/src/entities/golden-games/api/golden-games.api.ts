import type { GoldenGamesListParams, GoldenGamesResponse } from '../model/types/golden-games.types'

import { api } from '@/shared/api/axios'

export async function getGoldenGames(params?: GoldenGamesListParams) {
  const response = await api.get<GoldenGamesResponse>('/rooms/games/golden', { params })
  return response.data
}
