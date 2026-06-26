import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// .mjs data module — typed via allowJs (inferred from the manifest); cast to Screen below.
import { roomsLobbyScreens, roomsLobbyCanonical } from './screens.data.mjs';
import { ScreenView, PhoneFrame, ThemeNote, type Screen } from './ScreenView';
import { Button } from '../components/Button';

// Rooms (Lobby) — the room list a player enters from the main hub. Its own
// dedicated screen (vs the combined Screens/Catalog grid): the canonical lobby up
// close, plus the design-variant explorations. The lobby's primary CTA renders
// live so the accent recolors with the Theme toolbar.

function LobbyView() {
  return (
    <ScreenView screen={roomsLobbyCanonical as Screen}>
      <p style={{ fontSize: 13, opacity: 0.85, marginBottom: 14 }}>
        Lists open rooms (entity <code>ROM</code>). Golden Rooms surface here too — see{' '}
        <strong>Screens/Golden&nbsp;Game</strong> for the boosted variant.
      </p>
      <Button variant="buy">Enter room</Button>
      <ThemeNote>Live — recolors with the ▸ Theme toolbar (orange · blue · green).</ThemeNote>
    </ScreenView>
  );
}

function LobbyVariants() {
  const set = roomsLobbyScreens as Screen[];
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 4, fontSize: 20 }}>Rooms lobby — design set ({set.length})</h2>
      <p style={{ marginBottom: 20, opacity: 0.7, fontSize: 13 }}>
        The canonical master component and its design explorations.
      </p>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 24 }}>
        {set.map((s) => (
          <div key={s.figma_id}>
            <PhoneFrame screen={s} width={210} />
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

const meta: Meta = { title: 'Screens/Rooms (Lobby)' };
export default meta;

type Story = StoryObj;
export const Lobby: Story = { render: () => <LobbyView /> };
export const DesignVariants: Story = { render: () => <LobbyVariants /> };
