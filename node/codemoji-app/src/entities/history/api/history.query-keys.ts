export const historyQueryKeys = {
  /** Базовый ключ для всех history запросов */
  all: ['history'] as const,

  /** Ключ для истории попыток в конкретной игре */
  byGame: (gameId: string) => [...historyQueryKeys.all, 'game', gameId] as const,
} as const
