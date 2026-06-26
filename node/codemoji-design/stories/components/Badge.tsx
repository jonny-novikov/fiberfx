// Demo Badge — a small self-contained primitive (CVA + the local `cn`) showing
// the accent token on a chip surface and the gold token on a "boost" chip.
import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { cn } from '../lib/cn';

export const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-h5 font-bold',
  {
    variants: {
      variant: {
        accent: 'bg-accent text-white',
        muted: 'bg-muted text-white',
        success: 'bg-success text-white',
        gold: 'bg-gold-texture text-gold-foreground',
      },
    },
    defaultVariants: { variant: 'accent' },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant, className }))} {...props} />;
}
