import { useAtomValue } from 'jotai'
import { Suspense, useEffect, useState } from 'react'
import Confetti from 'react-confetti'
import { Outlet, useLocation } from 'react-router-dom'

import { KeysPurchaseDrawer } from '@/features/keys-purchase'
import { confettiConfigAtom, confettiVisibleAtom } from '@/shared/libs/stores'
import { getWebApp } from '@/shared/libs/utils/telegram-mock'
import { GameOverDialog } from '@/widgets/game-over-dialog'
import { Header } from '@/widgets/header'
import { Onboarding, isOnboardingCompleted, onboardingOpenAtom } from '@/widgets/onboarding'
import { PageLoader } from '@/widgets/page-loader'
// TODO: temporarily disabled – share/status hidden, not deleted
// import { ShareRewardDialog, ShareRewardProvider } from '@/widgets/share-reward-dialog'
import { VictoryDialog } from '@/widgets/victory-dialog'

export const BaseLayout = () => {
  const pathname = useLocation()
  const onboardingOpen = useAtomValue(onboardingOpenAtom)

  // Confetti state
  const confettiVisible = useAtomValue(confettiVisibleAtom)
  const confettiConfig = useAtomValue(confettiConfigAtom)
  const [windowSize, setWindowSize] = useState({
    width: typeof window !== 'undefined' ? window.innerWidth : 0,
    height: typeof window !== 'undefined' ? window.innerHeight : 0,
  })

  // Состояние для отслеживания первого запуска (обновляется после завершения онбординга)
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(() =>
    isOnboardingCompleted()
  )

  // Показываем онбординг при первом запуске (без возможности пропустить)
  // или когда он открыт через кнопку (с возможностью закрыть)
  const isFirstLaunch = !hasCompletedOnboarding
  const shouldShowOnboarding = isFirstLaunch || onboardingOpen

  const handleOnboardingComplete = () => {
    setHasCompletedOnboarding(true)
  }

  // Обновление размеров окна для конфетти
  useEffect(() => {
    const handleResize = () => {
      setWindowSize({ width: window.innerWidth, height: window.innerHeight })
    }
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  useEffect(() => {
    // Прокрутка страницы наверх при изменении роута
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' })

    // Use getWebApp() to get either real or mock WebApp
    const wa = getWebApp() as any

    if (pathname.pathname === '/rooms') {
      wa.setHeaderColor?.('#000')
      wa.setBackgroundColor?.('#D8E4EB')
    } else {
      wa.setHeaderColor?.('#E8F3F7')
      wa.setBackgroundColor?.('#E8F3F7')
    }
  }, [pathname])

  return (
    <div>
      {/* Глобальное конфетти - управляется через useConfetti() */}
      {confettiVisible && (
        <Confetti
          width={windowSize.width}
          height={windowSize.height}
          colors={confettiConfig.colors}
          numberOfPieces={confettiConfig.numberOfPieces}
          gravity={confettiConfig.gravity}
          recycle={confettiConfig.recycle}
          style={{ position: 'fixed', top: 0, left: 0, zIndex: 9999 }}
        />
      )}

      <Header />
      <Suspense fallback={<PageLoader />}>
        <Outlet />
      </Suspense>

      <KeysPurchaseDrawer />
      <VictoryDialog />
      <GameOverDialog />
      {/* <ShareRewardProvider /> */}
      {/* <ShareRewardDialog /> */}
      <Onboarding
        open={shouldShowOnboarding}
        dismissable={!isFirstLaunch}
        onComplete={handleOnboardingComplete}
      />
    </div>
  )
}

// h-[var(--tg-viewport-stable-height)]
