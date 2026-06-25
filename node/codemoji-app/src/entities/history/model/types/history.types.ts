import { GuessHistoryDto } from '@codemoji/types'

export type GuessHistoryResponse = GuessHistoryDto
/**
 * Одна попытка угадывания в истории
 */
export interface HistoryEntry {
  guessId: string
  attemptNumber: number
  keysRemaining: number
  guessCode: string[]
  selectedPositions: number[]
  percentage: number
  points: number
  isBestGuess: boolean
  submittedAt: string
}

/**
 * Ответ API для истории попыток игрока в комнате
 */
export interface PlayerGuessHistoryResponse {
  roomCode: string
  roundId: string | null
  playerId: string
  entries: HistoryEntry[]
  totalGuesses: number
  currentKeysRemaining: number
  capturedAt: string
}
