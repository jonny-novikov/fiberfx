/**
 * Sentry Instrumentation for React Frontend
 *
 * This file MUST be imported first in main.tsx before any other imports.
 * Sentry needs to instrument modules as they're loaded.
 *
 * @see https://docs.sentry.io/platforms/javascript/guides/react/
 */
import * as Sentry from '@sentry/react';

const dsn = import.meta.env.VITE_SENTRY_DSN;
const environment = import.meta.env.MODE || 'development';
const release = import.meta.env.VITE_SENTRY_RELEASE || `codemoji-frontend@${import.meta.env.VITE_APP_VERSION || 'unknown'}`;

/** Whether Sentry is initialized and active */
export const isSentryEnabled = Boolean(dsn);

// Only initialize if DSN is provided
if (dsn) {
  Sentry.init({
    dsn,
    environment,
    release,

    // Send default PII data (IP addresses, etc.)
    sendDefaultPii: true,

    // Performance monitoring
    tracesSampleRate: environment === 'production' ? 0.1 : 1.0,

    // Session Replay for debugging user flows
    replaysSessionSampleRate: environment === 'production' ? 0.1 : 1.0,
    replaysOnErrorSampleRate: 1.0,

    // Integrations
    integrations: [
      // Browser tracing for performance
      Sentry.browserTracingIntegration(),
      // Session Replay
      Sentry.replayIntegration({
        // Mask all text for privacy
        maskAllText: false,
        // Block all media for privacy
        blockAllMedia: false,
      }),
      // React Router integration
      Sentry.reactRouterV6BrowserTracingIntegration({
        useEffect: undefined, // Will be set up with router
        useLocation: undefined,
        useNavigationType: undefined,
        createRoutesFromChildren: undefined,
        matchRoutes: undefined,
      }),
    ],

    // Filter out common noise
    beforeSend(event) {
      // Skip ResizeObserver loop errors (common false positive)
      if (event.message?.includes('ResizeObserver loop')) {
        return null;
      }
      return event;
    },
  });

  console.log(`[Sentry] Initialized for ${environment}`);
} else if (environment === 'production') {
  console.warn('[Sentry] VITE_SENTRY_DSN not set - error tracking disabled');
}

export { Sentry };
