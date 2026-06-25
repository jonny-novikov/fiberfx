import type { PlayerProfile, PlayerResources } from '../model/types/player.types'

import { api } from '@/shared/api/axios'

// ─── Profile APIs ────────────────────────────────────────────────────────────

export async function getMyProfile() {
  const response = await api.get<PlayerProfile>('/my/profile')
  return response.data
}

// ─── Resource APIs ───────────────────────────────────────────────────────────

/**
 * Get authenticated player's resource balance
 * Uses the new /api/resources endpoint
 */
export async function getBalance() {
  const response = await api.get<PlayerResources>('/resources/balance')
  return response.data
}

/**
 * @deprecated Use getBalance() instead
 */
export async function getMyResources() {
  return getBalance()
}

/**
 * Get player's transaction history
 * @param limit - Max number of transactions to return (default: 20)
 * @param type - Filter by transaction type
 */
export async function getTransactions(params?: { limit?: number; type?: string }) {
  const response = await api.get<{
    transactions: Array<{
      transactionId: string
      type: string
      amount: number
      balance: number
      description: string
      createdAt: string
    }>
  }>('/resources/transactions', { params })
  return response.data
}

/**
 * Claim daily keys bonus
 * @returns Keys awarded, streak info, next claim time
 */
export async function claimDaily() {
  const response = await api.post<{
    keysAwarded: number
    bonusKeysAwarded: number
    streakBonus: number
    currentStreak: number
    newBalance: number
    nextClaimAt: string
  }>('/resources/claim-daily')
  return response.data
}

/**
 * Purchase keys with stars
 * @param amount - Number of keys to purchase
 * @param transactionId - External payment system transaction ID
 * @param price - Stars to spend
 */
export async function buyKeys(input: {
  amount: number
  transactionId: string
  price: bigint | string
}) {
  const response = await api.post<{
    keysReceived: number
    bonusKeysReceived: number
    starsSpent: number
    newKeyBalance: number
    newStarBalance: number
    purchasedAt: string
  }>('/resources/buy-keys', {
    ...input,
    price: String(input.price),
  })
  return response.data
}
