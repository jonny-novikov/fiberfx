import { createContext, useContext, type ReactNode } from 'react'

/**
 * Type guard to check if emojiSet is a snapshot (sprite-based) vs legacy array
 */
export function isEmojiSetSnapshot(
  emojiSet: string[] | EmojiSetConfig | undefined | null
): emojiSet is EmojiSetConfig {
  return (
    emojiSet !== null &&
    emojiSet !== undefined &&
    typeof emojiSet === 'object' &&
    !Array.isArray(emojiSet) &&
    'codes' in emojiSet &&
    'spriteUrl' in emojiSet
  )
}

/**
 * Extract emoji codes from emojiSet (works for both snapshot and legacy)
 */
export function getEmojiCodes(emojiSet: string[] | EmojiSetConfig | undefined | null): string[] {
  if (!emojiSet) return []
  if (Array.isArray(emojiSet)) return emojiSet
  return emojiSet.codes
}

/**
 * Sprite-based emoji set configuration
 * Matches EmojiSetSnapshot from backend
 */
export interface EmojiSetConfig {
  /** Sprite sheet image URL */
  spriteUrl: string
  /** Cell size in pixels */
  cellSize: number
  /** Number of columns in sprite grid */
  gridCols: number
  /** Number of rows in sprite grid */
  gridRows: number
  /** Original emoji set ID */
  emojiSetId?: string
}

interface EmojiSetContextValue {
  /** Sprite configuration (null before joinRoom response) */
  config: EmojiSetConfig | null
}

const EmojiSetContext = createContext<EmojiSetContextValue>({
  config: null,
})

interface EmojiSetProviderProps {
  children: ReactNode
  config: EmojiSetConfig | null
}

/**
 * Provider for emoji set sprite configuration
 * Wrap game components to enable sprite-based emoji rendering
 */
export function EmojiSetProvider({ children, config }: EmojiSetProviderProps) {
  return <EmojiSetContext.Provider value={{ config }}>{children}</EmojiSetContext.Provider>
}

/**
 * Hook to access emoji set configuration
 * Returns config with sprite sheet URL and grid dimensions
 */
export function useEmojiSet() {
  return useContext(EmojiSetContext)
}

/**
 * Parse XXYY code to column and row indices
 * @param code - 4-character XXYY code (e.g., "0305")
 * @returns Column and row indices (0-indexed)
 */
export function parseXXYYCode(code: string): { col: number; row: number } {
  if (code.length !== 4) {
    console.warn(`Invalid XXYY code: ${code}`)
    return { col: 0, row: 0 }
  }
  const col = parseInt(code.slice(0, 2), 10)
  const row = parseInt(code.slice(2, 4), 10)
  return { col, row }
}

/**
 * Calculate CSS background position for sprite rendering
 * @param col - Column index (0-indexed)
 * @param row - Row index (0-indexed)
 * @param config - Sprite configuration
 * @param displaySize - Target display size in pixels
 */
export function getSpriteStyles(
  col: number,
  row: number,
  config: EmojiSetConfig,
  displaySize: number
) {
  const scale = displaySize / config.cellSize
  const scaledSpriteWidth = config.gridCols * config.cellSize * scale
  const scaledSpriteHeight = config.gridRows * config.cellSize * scale
  const scaledX = -(col * config.cellSize * scale)
  const scaledY = -(row * config.cellSize * scale)

  return {
    width: displaySize,
    height: displaySize,
    backgroundImage: `url(${config.spriteUrl}?v=3)`,
    backgroundPosition: `${scaledX}px ${scaledY}px`,
    backgroundSize: `${scaledSpriteWidth}px ${scaledSpriteHeight}px`,
    backgroundRepeat: 'no-repeat' as const,
  }
}
