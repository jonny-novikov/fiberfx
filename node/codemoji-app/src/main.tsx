// Sentry MUST be imported first before any other imports
import './instrument'
// i18n MUST be imported early to initialize translations
import './i18n/i18n'
import * as Sentry from '@sentry/react'
import { TonConnectUIProvider } from '@tonconnect/ui-react'
import { StrictMode } from 'react'
import * as ReactDOM from 'react-dom/client'

import { App } from './app/app'
import { TonConnectProvider } from './app/providers'
import { MaintenanceScreen } from './widgets/maintenance-screen'

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement)

if (import.meta.env.DEV) {
  import('eruda').then((eruda) => eruda.default.init())
}

let manifestFile: string
const domain = window.location.hostname

if (import.meta.env.DEV) {
  manifestFile = 'tonconnect-manifest-dev.json'
} else {
  const isStaging = domain.includes('staging')
  manifestFile = isStaging
    ? 'tonconnect-manifest-staging.json'
    : 'tonconnect-manifest-production.json'
}

const manifestUrl = `${window.location.origin}/${manifestFile}`

const isMaintenanceMode = import.meta.env.VITE_MAINTENANCE_MODE === 'true'

root.render(
  <StrictMode>
    {isMaintenanceMode ? (
      <MaintenanceScreen />
    ) : (
      <Sentry.ErrorBoundary fallback={<p>An error occurred. Please refresh the page.</p>}>
        <TonConnectUIProvider manifestUrl={manifestUrl}>
          <TonConnectProvider>
            <App />
          </TonConnectProvider>
        </TonConnectUIProvider>
      </Sentry.ErrorBoundary>
    )}
  </StrictMode>
)
