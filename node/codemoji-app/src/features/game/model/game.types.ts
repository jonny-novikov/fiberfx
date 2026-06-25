import {
  GuessResultDto,
  RoomResponseDto,
  GameStateDto,
  GameDetailsDto,
} from '@codemoji/types'

export type GuessSubmitResponse = GuessResultDto & {
  isBecameLeader: boolean
}
export type RoomResponse = RoomResponseDto
export type GameStateResponse = GameStateDto
export type GameDetailsResponse = GameDetailsDto & {
  secretCode: string[]
}

export interface GuessByRoomCodeRequest {
  guessCode: string[]
  lockedPositions?: number[]
  playerId?: string
  platform?: 'web' | 'telegram' | 'youtube' | 'tiktok' | 'discord' | 'api'
  sessionId?: string
  requestId?: string
}

/**
 * Ответ на запрос начисления приза
 */
export interface ClaimPrizeResponse {
  /** Успешность операции */
  success: boolean
  /** Сумма приза в долларах (для отображения) */
  prizeAmount: number
  /** Количество начисленных алмазов */
  diamondsAwarded: number
  /** Призовой фонд в центах */
  prizePoolCents: number
  /** Новый баланс алмазов */
  newDiamondBalance: number
  /** Сколько ключей можно конвертировать (10:1) */
  convertibleToKeys: number
  /** @deprecated Use diamondsAwarded instead */
  keysAwarded?: number
  /** @deprecated Use newDiamondBalance instead */
  newKeyBalance?: number
}
