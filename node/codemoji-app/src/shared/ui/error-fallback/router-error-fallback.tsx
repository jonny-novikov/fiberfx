import { isRouteErrorResponse, useRouteError } from 'react-router-dom';

import { ErrorFallback } from './error-fallback';

export const RouterErrorFallback = () => {
  const routeError = useRouteError();

  let error: Error;

  if (isRouteErrorResponse(routeError)) {
    error = new Error(`${routeError.status} ${routeError.statusText}`);
  } else if (routeError instanceof Error) {
    error = routeError;
  } else if (typeof routeError === 'string') {
    error = new Error(routeError);
  } else {
    error = new Error('Unknown error');
  }

  return <ErrorFallback error={error} resetErrorBoundary={() => {}} />;
};
