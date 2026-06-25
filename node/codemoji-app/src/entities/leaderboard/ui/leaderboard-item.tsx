import { MAX_SCORE } from '@codemoji/types'
import { useTranslation } from 'react-i18next'

import type { LeaderboardItemDto } from '../model/types/leaderboard.types'

import { cn } from '@/shared/libs'
import { Avatar, ProgressBar } from '@/shared/ui'

export interface LeaderboardItemProps {
  item: LeaderboardItemDto
  className?: string
}

// interface RankBadgeProps {
//   rank: number
// }

// const RankBadge = ({ rank }: RankBadgeProps) => {
//   // Top 3 get special medals
//   if (rank === 1) {
//     return (
//       <div className="w-8 h-8 rounded-full bg-linear-to-br from-yellow-300 to-amber-500 flex items-center justify-center text-white font-bold text-sm shadow-md">
//         🥇
//       </div>
//     )
//   }
//   if (rank === 2) {
//     return (
//       <div className="w-8 h-8 rounded-full bg-linear-to-br from-gray-300 to-slate-400 flex items-center justify-center text-white font-bold text-sm shadow-md">
//         🥈
//       </div>
//     )
//   }
//   if (rank === 3) {
//     return (
//       <div className="w-8 h-8 rounded-full bg-linear-to-br from-amber-600 to-orange-700 flex items-center justify-center text-white font-bold text-sm shadow-md">
//         🥉
//       </div>
//     )
//   }

//   // Others get numbered badge
//   return (
//     <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-600 font-medium text-sm">
//       {rank}
//     </div>
//   )
// }

// ============================================================================
// Main Component
// ============================================================================

export const LeaderboardItem = ({ item, className }: LeaderboardItemProps) => {
  const { t } = useTranslation()
  return (
    <div
      className={cn(
        'flex items-center gap-3 px-3 py-2 rounded-xl transition-colors',
        item.isCurrentPlayer && 'bg-blue-50 border border-blue-200',
        !item.isCurrentPlayer && 'hover:bg-gray-50',
        className
      )}
    >
      {/* Rank badge */}
      {/* <RankBadge rank={item.rank} /> */}
      {/* <div className="relative pl-1">

        {item.rank === 1 ? (
          <div className="w-12">
            <img
              src="/images/common/flame.png"
              alt="top 1"
              draggable="false"
              className="absolute bottom-0 -left-0.5 w-12"
            />
            <Avatar
              src={item.avatar ?? ''}
              fallback={item.displayName}
              className="absolute inset-0"
            />
          </div>
        ) : (
          <Avatar src={item.avatar ?? ''} fallback={item.displayName} className="w-10 h-10" />
        )}
      </div> */}

      <Avatar src={item.avatar ?? ''} fallback={item.displayName} className="w-10 h-10" />

      {/* Player info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <p
            className={cn(
              'text-sm font-medium truncate',
              item.isCurrentPlayer ? 'text-blue-700' : 'text-gray-900'
            )}
          >
            {item.displayName}
          </p>
          {item.isCurrentPlayer && (
            <span className="text-[10px] text-blue-500 font-medium">({t('leaderboard.you')})</span>
          )}
        </div>
        <div className="flex items-center gap-2 mt-0.5">
          {/* Attempts count */}
          {/* {player.attempts !== undefined && (
            <span className="text-xs text-gray-400">
              {attempts} {attempts === 1 ? 'попытка' : attempts < 5 ? 'попытки' : 'попыток'}
            </span>
          )} */}
        </div>
      </div>

      {/* Score section */}
      <div className="flex items-center gap-3 w-[100px]">
        {/* Total points */}
        {/* <div className="text-right min-w-[60px]">
          <p className="text-lg font-bold text-gray-900">{player.points}</p>
          <div className="h-1 bg-gray-200 rounded-full w-full mt-1 overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-blue-400 to-blue-600 rounded-full transition-all duration-300"
              style={{ width: `${player.percentage}%` }}
            />
          </div>
        </div> */}

        <div className="flex-1 max-w-[100px] text-right flex flex-col gap-1 justify-center">
          <div className="flex justify-between items-center">
            <p className="text-[11px] text-[#54C0EC] font-medium leading-none">
              {Math.round((item.finalPoints / MAX_SCORE) * 10000) / 100}%
            </p>
            <p className="text-sm text-dark-muted font-medium leading-none">{item.finalPoints}</p>
          </div>

          <ProgressBar
            progress={(item.finalPoints / MAX_SCORE) * 100}
            className="h-[7px]"
            colorClassName="bg-[#54C0EC]"
          />
        </div>

      </div>
    </div>
  )
}
