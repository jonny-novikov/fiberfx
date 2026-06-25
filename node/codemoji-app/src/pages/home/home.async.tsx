import { lazy } from 'react';

export const HomePage = lazy(() =>
  import('./home.page').then((m) => ({ default: m.HomePage }))
);
