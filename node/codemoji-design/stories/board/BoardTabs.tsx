import * as React from 'react';
import { cn } from '../lib/cn';

// The History / Leaderboard tab strip above the player list (94:2974).
// Re-expresses shared/ui/tabs built PLAIN — no Radix: a full-width row of
// border-b-2 buttons where only the underline COLOUR changes between states
// (active = the fixed Main Blue #54C0EC, matching the app/Figma; inactive = a
// faint border), so there is no layout shift.
// Controlled when `active`+`onChange` are passed, otherwise self-managed.
export interface BoardTab {
  id: string;
  label: string;
}

export interface BoardTabsProps {
  tabs?: BoardTab[];
  /** controlled active tab id; omit to let the strip manage its own */
  active?: string;
  onChange?: (id: string) => void;
  /** optional content area rendered under the strip */
  children?: React.ReactNode;
  className?: string;
}

const DEFAULT_TABS: BoardTab[] = [
  { id: 'history', label: '📋 История' },
  { id: 'leaderboard', label: '🏆 Лидерборд' },
];

export function BoardTabs({
  tabs = DEFAULT_TABS,
  active,
  onChange,
  children,
  className,
}: BoardTabsProps) {
  // Uncontrolled fallback: default to the last tab (leaderboard) like the board.
  const [internal, setInternal] = React.useState(
    () => active ?? tabs[tabs.length - 1]?.id
  );
  const current = active ?? internal;

  const select = (id: string) => {
    if (active === undefined) setInternal(id);
    onChange?.(id);
  };

  return (
    <div className={cn('font-sans', className)}>
      <div className="flex w-full items-center gap-8 px-4">
        {tabs.map((tab) => {
          const isActive = tab.id === current;
          return (
            <button
              key={tab.id}
              type="button"
              role="tab"
              aria-selected={isActive}
              onClick={() => select(tab.id)}
              className={cn(
                'flex-1 whitespace-nowrap border-b-2 px-2 py-3 text-sm font-medium transition-colors',
                isActive
                  ? 'border-main-blue text-main-blue'
                  : 'border-border/30 text-dark-muted'
              )}
            >
              {tab.label}
            </button>
          );
        })}
      </div>
      {children != null && <div className="pt-3">{children}</div>}
    </div>
  );
}
