import { RouterProvider } from 'react-router-dom'

import { router } from '../router'
import { useTelegramWebApp, TelegramBackButtonProvider } from '../shared/libs'

import { AuthProvider, QueryProvider } from './providers'

import { AppLoader } from '@/widgets/app-loader'

export function App() {
  const { isReady, isTelegram } = useTelegramWebApp()

  if (!isReady) {
    return <AppLoader />
  }

  if (!isTelegram) {
    return <div>This app is only available in Telegram</div>
  }

  return (
    <QueryProvider>
      <TelegramBackButtonProvider>
        <AuthProvider>
          <RouterProvider
            router={router}
            future={{
              v7_startTransition: true,
            }}
          />
        </AuthProvider>
      </TelegramBackButtonProvider>
    </QueryProvider>
  )
}
