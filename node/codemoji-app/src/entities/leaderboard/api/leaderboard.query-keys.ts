import type { RoomLeaderboardQueryParams } from '../model/types/leaderboard.types'

export const leaderboardQueryKeys = {
  /** Базовый ключ для всех leaderboard запросов */
  all: ['leaderboard'] as const,

  /** Ключ для лидерборда конкретной комнаты */
  byRoom: (roomCode: string, params?: RoomLeaderboardQueryParams) =>
    [...leaderboardQueryKeys.all, 'room', roomCode, params ?? {}] as const,

  /** Ключ для лидерборда конкретной игры */
  byGame: (gameId: string) => [...leaderboardQueryKeys.all, 'game', gameId] as const,
} as const
