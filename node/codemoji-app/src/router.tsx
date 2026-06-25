import { createBrowserRouter, Navigate } from 'react-router-dom'

import { GamePage } from './pages/game'
import { HomePage } from './pages/home/home.async'
import { RoomsPage } from './pages/rooms'
import { WithdrawPage } from './pages/withdraw'
import { BaseLayout } from './shared/layout/base-layout'
import { RouterErrorFallback } from './shared/ui/error-fallback/router-error-fallback'

export function createRouter(defaultRoute: string = '/rooms') {
  return createBrowserRouter(
    [
      {
        path: '/',
        element: <BaseLayout />,
        errorElement: <RouterErrorFallback />,
        children: [
          {
            index: true,
            element: <Navigate to={defaultRoute} replace />,
          },
          {
            path: '/home',
            element: <HomePage />,
          },
          {
            path: '/rooms',
            element: <RoomsPage />,
          },
          {
            path: '/game/:roomId/:gameId',
            element: <GamePage />,
          },
          {
            path: '/withdraw',
            element: <WithdrawPage />,
          },
        ],
      },
    ],
    {
      future: {
        v7_relativeSplatPath: true,
      },
    }
  )
}

export const router = createRouter()
