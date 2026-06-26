// Demo Button — a SELF-CONTAINED re-expression of the app's button pattern
// (CVA + the local `cn`), NOT imported from codemoji-app. It exists to
// demonstrate the themeable tokens:
//   - the `buy` variant rides bg-accent (the single themeable --accent channel),
//     so the Buy/CTA highlight recolors orange/blue/green with the toolbar.
//   - the `golden` variant rides --gradient-gold (bg-gradient-gold), the
//     token form of the app's raster gild (bg-[url("/images/rooms/gold.png")]).
import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { cn } from '../lib/cn';

export const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-base font-bold transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        // Buy/CTA — the demo of the themeable accent. bg-accent resolves to
        // var(--color-accent) -> var(--accent), which [data-theme] overrides.
        buy: 'bg-accent text-white shadow hover:opacity-80 active:scale-95',
        default: 'bg-primary text-primary-foreground shadow hover:opacity-80 active:scale-95',
        outline: 'border-2 border-primary text-primary hover:opacity-80 active:scale-95',
        // Golden — the tokenized gild. bg-gradient-gold = var(--gradient-gold).
        golden:
          'bg-gradient-gold text-gold-foreground font-bold shadow hover:opacity-90 active:scale-95',
      },
      size: {
        default: 'h-12 px-4 py-2',
        sm: 'h-8 rounded-md px-3 text-xs',
        lg: 'h-10 rounded-md px-8',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => (
    <button ref={ref} className={cn(buttonVariants({ variant, size, className }))} {...props} />
  )
);
Button.displayName = 'Button';
