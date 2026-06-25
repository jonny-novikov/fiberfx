import { useSetAtom } from 'jotai'
import { useState } from 'react'

import { TelegramUtils } from '@/shared/libs/utils/telegram'
import { Button } from '@/shared/ui'
import { showGameOverDialogAtom } from '@/widgets/game-over-dialog'
import { showShareRewardDialogAtom } from '@/widgets/share-reward-dialog/model/share-reward-dialog.store'
import { victoryDialogOpenAtom } from '@/widgets/victory-dialog'

interface AdminPanelProps {
  className?: string
}

export const AdminPanel = ({ className }: AdminPanelProps) => {
  const setVictoryDialogOpen = useSetAtom(victoryDialogOpenAtom)
  const showGameOverDialog = useSetAtom(showGameOverDialogAtom)
  const showShareRewardDialog = useSetAtom(showShareRewardDialogAtom)
  const [storyLog, setStoryLog] = useState<string>('')

  const handleOpenVictoryDialog = () => {
    setVictoryDialogOpen(true)
  }

  const handleOpenGameOverDialog = () => {
    showGameOverDialog({ gameId: '123' })
  }

  const handleOpenShareRewardDialog = () => {
    showShareRewardDialog({ rewardedAt: new Date().toISOString() })
  }

  /** Тест shareToStory напрямую — без API, чисто Telegram SDK */
  const handleTestShareToStory = () => {
    const available = TelegramUtils.isStoryAvailable()
    const availability = TelegramUtils.getStoryAvailability()
    setStoryLog(
      `available: ${available}, version: ${availability.version}, reason: ${availability.reason}`
    )

    if (!available) return

    try {
      TelegramUtils.shareToStory({
        mediaUrl: '/images/tg-stories/story-ru-1.webp',
        text: 'Test story from admin panel',
      })
      setStoryLog((prev) => prev + '\n✓ shareToStory called OK')
    } catch (err) {
      setStoryLog((prev) => prev + `\n✗ Error: ${err instanceof Error ? err.message : String(err)}`)
    }
  }

  if (!import.meta.env.DEV) {
    return null
  }

  return (
    <div className={className}>
      <h1>Admin Panel</h1>
      <p>Only for developers</p>
      <div className="flex flex-col gap-2">
        <Button className="w-full" onClick={handleOpenVictoryDialog}>
          Open victory modal
        </Button>
        <Button className="w-full" onClick={handleOpenGameOverDialog}>
          Open game over modal
        </Button>
        <Button className="w-full" onClick={handleOpenShareRewardDialog}>
          Open share reward modal
        </Button>
        <Button className="w-full" onClick={handleTestShareToStory}>
          Test shareToStory (no API)
        </Button>
        {storyLog && (
          <pre className="text-xs bg-black/10 rounded-lg p-2 whitespace-pre-wrap break-all">
            {storyLog}
          </pre>
        )}
      </div>
    </div>
  )
}
