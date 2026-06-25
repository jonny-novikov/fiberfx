/**
 * Connection Status Indicator Component
 *
 * Displays the current connection status and quality.
 * Uses unified connection store atoms.
 *
 * Features:
 * - Connection status badge (connected, connecting, disconnected, etc.)
 * - Quality indicator with color coding
 * - Latency display
 * - Reconnection attempt counter
 *
 * NOTE: This component is currently disabled/hidden.
 * Types are hardcoded locally until we refactor the connection system.
 *
 */

import { atom, useAtomValue } from 'jotai'
import { FC, useMemo } from 'react'

import { cn } from '@/shared/libs'

// ============================================================================
// Hardcoded types (temporary until connection system refactor)
// ============================================================================

type ConnectionStatusType = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'error'
type ConnectionQuality = 'excellent' | 'good' | 'fair' | 'poor' | 'unknown'

// Temporary mock atoms (not connected to real system)
const connectionStatusAtom = atom<ConnectionStatusType>('disconnected')
const connectionQualityAtom = atom<ConnectionQuality>('unknown')
const connectionLatencyAtom = atom<number>(0)
const isReconnectingAtom = atom<boolean>(false)
const reconnectAttemptsAtom = atom<number>(0)
const maxReconnectAttemptsAtom = atom<number>(5)

function getQualityColor(quality: ConnectionQuality): string {
  switch (quality) {
    case 'excellent':
      return '#22c55e'
    case 'good':
      return '#84cc16'
    case 'fair':
      return '#eab308'
    case 'poor':
      return '#ef4444'
    default:
      return '#9ca3af'
  }
}

function getQualityLabel(quality: ConnectionQuality): string {
  switch (quality) {
    case 'excellent':
      return 'Отлично'
    case 'good':
      return 'Хорошо'
    case 'fair':
      return 'Средне'
    case 'poor':
      return 'Плохо'
    default:
      return 'Неизвестно'
  }
}

// ============================================================================
// Types
// ============================================================================

export interface ConnectionStatusProps {
  /** Show latency value */
  showLatency?: boolean
  /** Show quality label */
  showQualityLabel?: boolean
  /** Show reconnection attempts */
  showReconnectAttempts?: boolean
  /** Compact mode (icon only) */
  compact?: boolean
  /** Additional class names */
  className?: string
}

// ============================================================================
// Status Configuration
// ============================================================================

interface StatusConfig {
  label: string
  color: string
  bgColor: string
  icon: string
}

const STATUS_CONFIG: Record<ConnectionStatusType, StatusConfig> = {
  connected: {
    label: 'Connected',
    color: 'text-green-600',
    bgColor: 'bg-green-100',
    icon: '\u2713', // checkmark
  },
  connecting: {
    label: 'Connecting...',
    color: 'text-yellow-600',
    bgColor: 'bg-yellow-100',
    icon: '\u25CF', // bullet
  },
  disconnected: {
    label: 'Disconnected',
    color: 'text-gray-500',
    bgColor: 'bg-gray-100',
    icon: '\u2717', // X mark
  },
  reconnecting: {
    label: 'Reconnecting...',
    color: 'text-orange-600',
    bgColor: 'bg-orange-100',
    icon: '\u21BB', // circular arrow
  },
  error: {
    label: 'Error',
    color: 'text-red-600',
    bgColor: 'bg-red-100',
    icon: '!',
  },
}

// ============================================================================
// Quality Indicator Component
// ============================================================================

interface QualityIndicatorProps {
  quality: ConnectionQuality
  showLabel?: boolean
  className?: string
}

const QualityIndicator: FC<QualityIndicatorProps> = ({ quality, showLabel = false, className }) => {
  const color = getQualityColor(quality)
  const label = getQualityLabel(quality)

  // Signal bars visualization
  const bars = useMemo(() => {
    const barCount = 4
    const activeBars =
      quality === 'excellent'
        ? 4
        : quality === 'good'
          ? 3
          : quality === 'fair'
            ? 2
            : quality === 'poor'
              ? 1
              : 0

    return Array.from({ length: barCount }, (_, i) => ({
      height: `${(i + 1) * 25}%`,
      active: i < activeBars,
    }))
  }, [quality])

  return (
    <div className={cn('flex items-center gap-1', className)}>
      {/* Signal bars */}
      <div className="flex items-end gap-0.5 h-4">
        {bars.map((bar, i) => (
          <div
            key={i}
            className={cn(
              'w-1 rounded-sm transition-colors',
              bar.active ? 'opacity-100' : 'opacity-30'
            )}
            style={{
              height: bar.height,
              backgroundColor: bar.active ? color : '#9CA3AF',
            }}
          />
        ))}
      </div>
      {showLabel && (
        <span className="text-xs font-medium" style={{ color }}>
          {label}
        </span>
      )}
    </div>
  )
}

// ============================================================================
// Latency Display Component
// ============================================================================

interface LatencyDisplayProps {
  latency: number
  className?: string
}

const LatencyDisplay: FC<LatencyDisplayProps> = ({ latency, className }) => {
  const color = useMemo(() => {
    if (latency <= 0) return '#9CA3AF'
    if (latency < 50) return '#22c55e'
    if (latency < 100) return '#84cc16'
    if (latency < 200) return '#eab308'
    return '#ef4444'
  }, [latency])

  if (latency <= 0) {
    return <span className={cn('text-xs text-gray-400', className)}>--ms</span>
  }

  return (
    <span className={cn('text-xs font-mono', className)} style={{ color }}>
      {latency}ms
    </span>
  )
}

// ============================================================================
// Main Component
// ============================================================================

export const ConnectionStatus: FC<ConnectionStatusProps> = ({
  showLatency = true,
  showQualityLabel = false,
  showReconnectAttempts = true,
  compact = false,
  className,
}) => {
  const status = useAtomValue(connectionStatusAtom)
  const quality = useAtomValue(connectionQualityAtom)
  const latency = useAtomValue(connectionLatencyAtom)
  const isReconnecting = useAtomValue(isReconnectingAtom)
  const reconnectAttempts = useAtomValue(reconnectAttemptsAtom)
  const maxAttempts = useAtomValue(maxReconnectAttemptsAtom)

  const config = STATUS_CONFIG[status] || STATUS_CONFIG.disconnected

  // Compact mode: just show quality indicator
  if (compact) {
    return (
      <div className={cn('flex items-center gap-1', className)}>
        <QualityIndicator quality={quality} />
        {showLatency && latency > 0 && <LatencyDisplay latency={latency} />}
      </div>
    )
  }

  return (
    <div className={cn('flex items-center gap-2', className)}>
      {/* Status badge */}
      <div
        className={cn(
          'flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium',
          config.bgColor,
          config.color
        )}
      >
        <span className="font-bold">{config.icon}</span>
        <span>{config.label}</span>
      </div>

      {/* Quality indicator (only when connected) */}
      {status === 'connected' && (
        <QualityIndicator quality={quality} showLabel={showQualityLabel} />
      )}

      {/* Latency (only when connected) */}
      {status === 'connected' && showLatency && <LatencyDisplay latency={latency} />}

      {/* Reconnection attempts */}
      {isReconnecting && showReconnectAttempts && (
        <span className="text-xs text-orange-600">
          ({reconnectAttempts}/{maxAttempts})
        </span>
      )}
    </div>
  )
}

// ============================================================================
// Exports
// ============================================================================

export { QualityIndicator, LatencyDisplay }
export default ConnectionStatus
