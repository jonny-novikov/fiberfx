// Mirror of the app's `cn` helper (codemoji-app/src/shared/libs/utils/classnames.ts):
// twMerge(clsx(inputs)). Re-expressed here so the demo primitives are
// self-contained — NOT imported from the app.
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
