import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';

// The History / Leaderboard tab strip + its switchable content (94:2974).
// Re-expresses shared/ui/tabs built PLAIN — no Radix: a full-width row of
// border-b-2 buttons where only the underline COLOUR changes between states
// (active = the fixed Main Blue #54C0EC, matching the app/Figma; inactive = a
// faint border), so there is no layout shift.
//
// SWITCHABLE: each tab carries its own `content`, and only the ACTIVE tab's panel
// renders — mirroring the app's <TabsContent value="…"> (one panel shown at a
// time). A tab with no `content` falls back to `children` (the single-panel use,
// e.g. the Golden standings). Controlled via `active`+`onChange`, else self-managed
// from `defaultActive` (which itself defaults to the FIRST tab — the app opens on
// History, `defaultValue="history"`).
//
// PADDING: the strip and the panel are flush to the host BoardCard's padding (no
// extra inset of their own), so the tab underline lines up over the row content —
// the rows carry their own px-2, shared by History + Leaderboard so the two tabs
// align column-for-column when switched.
export interface BoardTab {
  id: string;
  label: string;
  /** the panel shown when this tab is active; omit to use the shared `children` */
  content?: React.ReactNode;
}

export interface BoardTabsProps {
  tabs?: BoardTab[];
  /** content keyed by tab id — pairs with the default (localized) labels so the
   *  caller switches panels without re-specifying every label */
  panels?: Record<string, React.ReactNode>;
  /** controlled active tab id; omit to let the strip manage its own */
  active?: string;
  /** uncontrolled initial tab id (default: the first tab) */
  defaultActive?: string;
  onChange?: (id: string) => void;
  /** fallback panel when the active tab carries no `content`/`panels` entry */
  children?: React.ReactNode;
  className?: string;
}

export function BoardTabs({
  tabs,
  panels,
  active,
  defaultActive,
  onChange,
  children,
  className,
}: BoardTabsProps) {
  const { t } = useTranslation();
  // Default strip: History / Leaderboard, labels localized (the emoji prefix + the
  // app's game.tabs.* keys). A caller can still pass its own `tabs`.
  const resolvedTabs: BoardTab[] = tabs ?? [
    { id: 'history', label: `📋 ${t('game.tabs.history')}` },
    { id: 'leaderboard', label: `🏆 ${t('game.tabs.leaderboard')}` },
  ];
  // Uncontrolled fallback: open on `defaultActive`, else the first tab (History),
  // matching the app's `defaultValue="history"`.
  const [internal, setInternal] = React.useState(
    () => active ?? defaultActive ?? resolvedTabs[0]?.id
  );
  const current = active ?? internal;

  const select = (id: string) => {
    if (active === undefined) setInternal(id);
    onChange?.(id);
  };

  // The active panel: the `panels` map by id, else the tab's own `content`, else
  // the shared children (single-panel fallback, e.g. the Golden standings).
  const activeTab = resolvedTabs.find((tab) => tab.id === current);
  const panel = panels?.[current] ?? activeTab?.content ?? children;

  return (
    <div className={cn('font-sans', className)}>
      <div className="flex w-full items-center">
        {resolvedTabs.map((tab) => {
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
      {panel != null && <div className="pt-3">{panel}</div>}
    </div>
  );
}
