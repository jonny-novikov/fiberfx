import { useTranslation } from 'react-i18next'

import { usePlayerGuessHistory } from '@/entities/history/api/history.queries'
import { TelegramUtils, cn } from '@/shared/libs'
import { GOLDEN_ROOM_RULES_URL } from '@/shared/libs/consts'
import {
  Avatar,
  Button,
  SpriteEmoji,
  Tabs,
  TabsTrigger,
  TabsList,
  TabsContent,
  AppleEmoji,
} from '@/shared/ui'

// ---------------------------------------------------------------------------
// Types (local until backend endpoints are available)
// ---------------------------------------------------------------------------

interface GoldenGuessEntry {
  rank: number
  guessCode: string[]
  keyCost: number
  isCurrentPlayer: boolean
}

interface GoldenLeaderboardEntry {
  rank: number
  displayName: string
  avatar: string | null
  guessCode: string[]
  prize: string
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

// TODO: Replace with real API endpoint when backend adds /game/:gameId/all-guesses
const MOCK_ALL_CODES: GoldenGuessEntry[] = [
  { rank: 15, guessCode: ['0102', '0203', '0304', '0405', '0506', '0607'], keyCost: 5, isCurrentPlayer: true },
  { rank: 14, guessCode: ['0100', '0201', '0302', '0403', '0504', '0605'], keyCost: 5, isCurrentPlayer: false },
  { rank: 13, guessCode: ['0001', '0102', '0203', '0304', '0405', '0506'], keyCost: 5, isCurrentPlayer: false },
  { rank: 12, guessCode: ['0200', '0301', '0402', '0503', '0604', '0705'], keyCost: 5, isCurrentPlayer: true },
  { rank: 11, guessCode: ['0300', '0401', '0502', '0603', '0704', '0805'], keyCost: 5, isCurrentPlayer: false },
  { rank: 10, guessCode: ['0400', '0501', '0602', '0703', '0804', '0905'], keyCost: 5, isCurrentPlayer: false },
]

// TODO: Replace with real golden leaderboard API when backend adds guessCode to leaderboard
const MOCK_GOLDEN_LEADERBOARD: GoldenLeaderboardEntry[] = [
  { rank: 1, displayName: 'vi..ed', avatar: null, guessCode: ['0102', '0203', '0304', '0405', '0506', '0607'], prize: '$23.43' },
  { rank: 2, displayName: 'al..ce', avatar: null, guessCode: ['0100', '0201', '0302', '0403', '0504', '0605'], prize: '$15.20' },
  { rank: 3, displayName: 'bo..ry', avatar: null, guessCode: ['0001', '0102', '0203', '0304', '0405', '0506'], prize: '🔑 100' },
  { rank: 4, displayName: 'ch..ie', avatar: null, guessCode: ['0200', '0301', '0402', '0503', '0604', '0705'], prize: '🔑 75' },
  { rank: 5, displayName: 'da..id', avatar: null, guessCode: ['0300', '0401', '0502', '0603', '0704', '0805'], prize: '🔑 50' },
]

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

const GoldenPlayersList = ({ gameId }: { gameId: string }) => {
  const { t } = useTranslation()
  const { data: historyData, isLoading } = usePlayerGuessHistory(gameId)

  return (
    <div className="px-1 pt-3 pb-4 space-y-5">
      {/* Ваши варианты */}
      <section>
        <h3 className="text-xs font-bold text-muted uppercase tracking-wide px-2 mb-2">
          {t('game.goldenTabs.yourVariants', { defaultValue: 'Ваши варианты' })}
        </h3>

        {isLoading ? (
          <div className="animate-pulse space-y-2 px-2">
            <div className="h-8 bg-gray-100 rounded-lg" />
            <div className="h-8 bg-gray-100 rounded-lg" />
          </div>
        ) : !historyData || historyData.length === 0 ? (
          <p className="text-xs text-gray-400 px-2">
            {t('history.empty', { defaultValue: 'Нет попыток' })}
          </p>
        ) : (
          <div className="space-y-1">
            {historyData.map((item, index) => (
              <div
                key={item.guessId}
                className="flex items-center justify-between gap-2 px-2 py-1.5 rounded-xl bg-blue-50"
              >
                <span className="text-xs text-dark-muted font-medium w-5 text-center">
                  {historyData.length - index}
                </span>

                <div className="flex gap-0.5 items-center flex-1 justify-center">
                  {(item.guessCode ?? []).map((code, i) => (
                    <SpriteEmoji key={i} code={code} size={20} />
                  ))}
                </div>

                <span className="text-xs text-dark-muted font-medium whitespace-nowrap">
                  {item.scoring.exactMatches ?? 0} 🔑
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Все коды игроков */}
      <section>
        <h3 className="text-xs font-bold text-muted uppercase tracking-wide px-2 mb-2">
          {t('game.goldenTabs.allCodes', { defaultValue: 'Все коды игроков' })}
        </h3>

        <div className="space-y-1">
          {MOCK_ALL_CODES.map((entry) => (
            <div
              key={entry.rank}
              className={cn(
                'flex items-center justify-between gap-2 px-2 py-1.5 rounded-xl',
                entry.isCurrentPlayer ? 'bg-blue-50' : 'bg-gray-50',
              )}
            >
              <span className="text-xs text-dark-muted font-medium w-5 text-center">
                {entry.rank}
              </span>

              <div className="flex gap-0.5 items-center flex-1 justify-center">
                {entry.guessCode.map((code, i) => (
                  <SpriteEmoji key={i} code={code} size={20} />
                ))}
              </div>

              <span className="text-xs text-dark-muted font-medium whitespace-nowrap">
                {entry.keyCost} 🔑
              </span>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

const GoldenLeaderboardList = () => {
  return (
    <div className="px-1 pt-3 pb-4 space-y-1">
      {MOCK_GOLDEN_LEADERBOARD.map((entry) => (
        <div
          key={entry.rank}
          className="flex items-center gap-2 px-2 py-2 rounded-xl hover:bg-gray-50 transition-colors"
        >
          <span className="text-sm font-bold text-dark-muted w-5 text-center shrink-0">
            {entry.rank}
          </span>

          <Avatar
            src={entry.avatar ?? ''}
            fallback={entry.displayName}
            className="w-8 h-8 shrink-0"
          />

          <span className="text-sm font-medium text-gray-900 truncate min-w-0 shrink">
            {entry.displayName}
          </span>

          <div className="flex gap-0.5 items-center flex-1 justify-center">
            {entry.guessCode.map((code, i) => (
              <SpriteEmoji key={i} code={code} size={18} />
            ))}
          </div>

          <span className="text-sm font-bold text-dark-muted whitespace-nowrap shrink-0">
            {entry.prize}
          </span>
        </div>
      ))}
    </div>
  )
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

interface GoldenGameTabsProps {
  className?: string
  gameId: string
}

export const GoldenGameTabs = ({ className, gameId }: GoldenGameTabsProps) => {
  const { t } = useTranslation()

  return (
    <div className={cn('bg-white rounded-3xl flex flex-col h-[50dvh]', className)}>
      <Tabs defaultValue="players" className="flex-1 flex flex-col min-h-0">
        <TabsList className="relative shrink-0">
          <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-card" />
          <TabsTrigger value="players" className="flex items-center gap-1">
            <AppleEmoji id="busts_in_silhouette" size={16} />
            <span>{t('game.goldenTabs.players', { defaultValue: 'Игроки' })}</span>
          </TabsTrigger>
          <TabsTrigger value="leaderboard" className="flex items-center gap-1">
            <AppleEmoji id="trophy" size={16} />
            <span>{t('game.goldenTabs.leaderboard', { defaultValue: 'Лидерборд' })}</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="players" className="flex-1 min-h-0">
          <div className="h-full overflow-y-auto scrollbar-custom">
            <GoldenPlayersList gameId={gameId} />
          </div>
        </TabsContent>

        <TabsContent value="leaderboard" className="flex-1 min-h-0">
          <div className="h-full overflow-y-auto scrollbar-custom">
            <GoldenLeaderboardList />
          </div>
        </TabsContent>
      </Tabs>

      {/* Sticky rules button */}
      <div className="shrink-0 px-3 pb-3">
        <Button
          id="golden-rules-btn"
          variant="golden"
          className="w-full"
          onClick={() =>
            TelegramUtils.openExternal(GOLDEN_ROOM_RULES_URL, { tryInstantView: true })
          }
        >
          {t('lobbyInfo.readRules', { defaultValue: 'Читать правила' })}
        </Button>
      </div>
    </div>
  )
}
