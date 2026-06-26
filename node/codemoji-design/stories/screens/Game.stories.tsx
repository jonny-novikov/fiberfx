import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// .mjs data module — typed via allowJs (inferred from the manifest); cast to Screen below.
import { boardScreens, boardCanonical } from './screens.data.mjs';
import { ScreenView, PhoneFrame, ThemeNote, type Screen } from './ScreenView';
import { Button } from '../components/Button';

// Game (Free) — the standard, non-boosted gameplay board: compose + submit a
// 6-emoji guess. "Free" distinguishes it from the boosted Golden Game (see
// Screens/Golden Game). Its in-game purchase CTA (Buy keys) renders live — the
// canonical demo of the themeable accent in its real screen context.

function BoardView() {
  return (
    <ScreenView screen={boardCanonical as Screen}>
      <p style={{ fontSize: 13, opacity: 0.85, marginBottom: 14 }}>
        The free game. <code>mode: both</code> — the same board serves free and Golden play; the
        boost lives on the room, not the board (see <strong>Screens/Golden&nbsp;Game</strong>).
      </p>
      <Button variant="buy">Buy keys</Button>
      <ThemeNote>Live — recolors with the ▸ Theme toolbar (orange · blue · green).</ThemeNote>
    </ScreenView>
  );
}

function BoardExplorations() {
  const set = boardScreens as Screen[];
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 4, fontSize: 20 }}>Game board — design set ({set.length})</h2>
      <p style={{ marginBottom: 20, opacity: 0.7, fontSize: 13 }}>
        The canonical master component and its design explorations.
      </p>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 24 }}>
        {set.map((s) => (
          <div key={s.figma_id}>
            <PhoneFrame screen={s} width={180} />
            <div style={{ fontSize: 11, marginTop: 8, opacity: 0.7 }}>
              <code>{s.figma_id}</code> · {s.figma_type}
              {/canonical/i.test(s.role) && (
                <span style={{ marginLeft: 6, fontWeight: 700, color: 'var(--color-accent)' }}>
                  canonical
                </span>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

const meta: Meta = { title: 'Screens/Game (Free)' };
export default meta;

type Story = StoryObj;
export const Board: Story = { render: () => <BoardView /> };
export const DesignExplorations: Story = { render: () => <BoardExplorations /> };
