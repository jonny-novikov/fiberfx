const STORAGE_KEY = 'codemoji_emoji_highlights'
const TTL_MS = 48 * 60 * 60 * 1000

export type EmojiHighlight = 'idle' | 'green' | 'yellow' | 'red'

interface GameHighlights {
  ts: number
  items: Record<string, Record<number, EmojiHighlight>>
}

type StoredHighlights = Record<string, GameHighlights>

function readStorage(): StoredHighlights {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return {}
    return JSON.parse(raw) as StoredHighlights
  } catch {
    return {}
  }
}

function writeStorage(data: StoredHighlights): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  } catch {
    // private mode or quota exceeded
  }
}

function cleanupExpired(data: StoredHighlights): StoredHighlights {
  const now = Date.now()
  const cleaned: StoredHighlights = {}
  for (const [gameId, entry] of Object.entries(data)) {
    if (now - entry.ts < TTL_MS) {
      cleaned[gameId] = entry
    }
  }
  return cleaned
}

export function loadHighlights(gameId: string, guessId: string): Record<number, EmojiHighlight> {
  const data = cleanupExpired(readStorage())
  writeStorage(data)
  return data[gameId]?.items[guessId] ?? {}
}

export function saveHighlights(
  gameId: string,
  guessId: string,
  states: Record<number, EmojiHighlight>
): void {
  const data = cleanupExpired(readStorage())
  if (!data[gameId]) {
    data[gameId] = { ts: Date.now(), items: {} }
  }
  data[gameId].items[guessId] = states
  writeStorage(data)
}
