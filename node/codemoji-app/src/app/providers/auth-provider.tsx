import { useEffect, ReactNode } from 'react'

import { useAuth } from '@/features/auth'
import { AppLoader } from '@/widgets/app-loader'

interface AuthProviderProps {
  children: ReactNode
  showErrorScreen?: boolean
  errorComponent?: ReactNode
}

function AuthErrorScreen({ error, onRetry }: { error: string; onRetry: () => void }) {
  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-b from-blue-50 to-blue-100">
      <div className="text-center space-y-4 p-6">
        <div className="text-6xl mb-4">😕</div>
        <h1 className="text-xl font-semibold text-gray-800">Authentication Failed</h1>
        <p className="text-gray-600 max-w-xs mx-auto">
          {error || 'Unable to authenticate. Please try again.'}
        </p>
        <button
          onClick={onRetry}
          className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>
  )
}

/**
 * AuthProvider component
 * Handles automatic authentication on app mount
 */
export function AuthProvider({
  children,
  showErrorScreen = true,
  errorComponent,
}: AuthProviderProps) {
  const { login, isAuthenticated, isPending, errorMessage } = useAuth()

  useEffect(() => {
    if (!isAuthenticated && !isPending && !errorMessage) {
      login()
    }
  }, [login, isAuthenticated, isPending, errorMessage])

  if (isPending || !isAuthenticated) {
    return <AppLoader />
  }

  if (errorMessage && showErrorScreen) {
    if (errorComponent) {
      return <>{errorComponent}</>
    }
    return <AuthErrorScreen error={errorMessage} onRetry={login} />
  }

  return <>{children}</>
}

export default AuthProvider
