import * as React from 'react';
import { cn } from '../../lib/cn';

// The board's white surface — `bg-card rounded-2xl`, the wrapper nearly every
// board section sits on (widgets/*: emotion-picker, game-rules, selected-emojis).
// Shared so the radius/fill/foreground stay identical across the board components.
export function BoardCard({
  className,
  children,
  ...rest
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('rounded-2xl bg-card p-4 text-card-foreground', className)}
      {...rest}
    >
      {children}
    </div>
  );
}
