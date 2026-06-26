import * as React from 'react';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';

// The dark teaser banner near the top of the lobby (121:2056). Re-expresses
// widgets/subscription-banner: the app paints it with a .webp background image
// (`bg-[url(...)]`) and a `<CloseIcon />` SVG + the app's `variant="clear"` /
// `variant="secondary"` buttons — none of which exist in the design system. Here
// it is a flat `bg-primary` surface, a Unicode "✕" close, and the themeable
// `buy` Button (rides bg-accent, reads on dark). Self-contained: onClose / onCta
// are callbacks, no dialog or localStorage.
export interface SubscriptionBannerProps {
  teaser?: string;
  description?: string;
  onClose?: () => void;
  onCta?: () => void;
  className?: string;
}

export function SubscriptionBanner({
  teaser = 'Unlock daily rewards',
  description = 'Subscribe to claim free keys every day and skip the wait.',
  onClose,
  onCta,
  className,
}: SubscriptionBannerProps) {
  return (
    <div className={cn('relative rounded-2xl bg-primary p-6 text-white', className)}>
      <button
        type="button"
        aria-label="Dismiss"
        onClick={onClose}
        className="absolute right-3 top-3 text-white transition-opacity hover:opacity-70"
      >
        ✕
      </button>
      <p className="text-xs font-medium">
        {teaser}
        <br />
        {description}
      </p>
      <Button className="mt-4" variant="buy" onClick={onCta}>
        What's this?
      </Button>
    </div>
  );
}
