import { useAtom } from 'jotai'
import { FC } from 'react'
import { useNavigate } from 'react-router-dom'

import { playerAtom, useMyResources } from '@/entities/player'
import { cn } from '@/shared/libs'
import { Skeleton } from '@/shared/ui'

interface StatusBarProps {
  className?: string
}

export const StatusBar: FC<StatusBarProps> = ({ className }) => {
  const { data: resources, isLoading } = useMyResources()
  const [player] = useAtom(playerAtom)
  // const streak = 0
  const diamonds = resources?.diamonds?.balance ?? 0
  const keys = resources?.keys?.balance ?? 0
  const clips = resources?.keys?.bonusKeys ?? 0

  const playerUsername = player?.username ? `@${player.username}` : '@username'
  const navigate = useNavigate()
  if (isLoading) {
    return (
      <div className={cn('', className)}>
        <Skeleton className="h-8 w-full rounded-2xl" />
      </div>
    )
  }

  return (
    <button
      type="button"
      className={cn('cursor-pointer', className)}
      onClick={() => {
        navigate('/withdraw')
      }}
    >
      <div className="bg-card rounded-2xl px-4 h-8 shadow-lg flex items-center justify-between text-card-foreground text-[0.625rem] leading-none">
        {/* Серия дней */}
        {/* <div className="flex items-center gap-1">
          <AppleEmoji id="fire" size={12} />
          <span className="text-sm">{streak} дней</span>
        </div> */}

        <p className="font-medium">{playerUsername}</p>

        <div className="flex gap-4">
          {/* Звезды */}
          <div className="flex items-center gap-1">
            {/* <AppleEmoji id="star" size={12} /> */}
            <img src="/images/common/diamond.png" alt="diamond" className="size-4" />
            <span>{diamonds.toLocaleString()}</span>
          </div>

          <div className="flex items-center gap-1">
            <img src="/images/keys/clip.png" alt="clip" className="size-4" />
            <span>{clips.toLocaleString()}</span>
          </div>

          {/* Ключи */}
          <div className="flex items-center gap-1">
            <img src="/images/keys/dark-key.png" alt="key" className="size-3.5" />
            <span>{keys.toLocaleString()}</span>
          </div>
        </div>
      </div>
    </button>
  )
}
