export const playerQueryKeys = {
  /** Базовый ключ для всех player запросов */
  all: ['player'] as const,
  profile: () => [...playerQueryKeys.all, 'profile'] as const,
  /** Ключ для ресурсов игрока */
  resources: () => [...playerQueryKeys.all, 'resources'] as const,
  /** Ключ для истории daily rewards */
  dailyRewardHistory: (playerId: string) =>
    [...playerQueryKeys.all, 'daily-reward-history', playerId] as const,
  /** Ключ для истории покупок */
  purchaseHistory: (playerId: string) =>
    [...playerQueryKeys.all, 'purchase-history', playerId] as const,
} as const
