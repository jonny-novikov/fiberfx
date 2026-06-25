import * as AvatarPrimitive from '@radix-ui/react-avatar'
import { useCallback } from 'react'

import { cn } from '@/shared/libs'

interface AvatarProps {
  src?: string
  fallback?: string
  className?: string
  isLoading?: boolean
  defaultImage?: string
  onError?: () => void
  onLoad?: () => void
}

export const Avatar = ({ src, fallback, className, isLoading = false }: AvatarProps) => {
  const getShortName = useCallback((name?: string) => {
    const safeName = (name ?? '').trim()
    if (safeName.length === 0) return 'U'

    const parts = safeName.split(/\s+/).filter(Boolean)
    const first = parts[0] ?? ''
    const second = parts[1] ?? ''

    if (first && second) {
      return `${first[0]}${second[0]}`.toUpperCase()
    }

    if (first.length >= 2) {
      return `${first[0]}${first[1]}`.toUpperCase()
    }

    return `${first[0]}`.toUpperCase()
  }, [])

  if (isLoading) {
    return (
      <div
        className={cn(
          'inline-flex size-[45px] animate-pulse items-center justify-center overflow-hidden rounded-full bg-gray-200',
          className
        )}
      >
        <div className="size-full bg-gradient-to-br from-gray-200 to-gray-300" />
      </div>
    )
  }

  return (
    <AvatarPrimitive.Root
      className={cn(
        'inline-flex size-[36px] select-none items-center justify-center overflow-hidden align-middle rounded-lg',
        className
      )}
    >
      <AvatarPrimitive.Image
        className="size-full rounded-[inherit] object-cover"
        src={src}
        alt={fallback}
      />
      <AvatarPrimitive.Fallback
        className="leading-1 flex size-full items-center justify-center bg-gradient-to-br from-blue-400 to-purple-500 text-white text-[15px] font-medium uppercase shadow-inner"
        delayMs={0}
      >
        {getShortName(fallback)}
      </AvatarPrimitive.Fallback>
    </AvatarPrimitive.Root>
  )
}
