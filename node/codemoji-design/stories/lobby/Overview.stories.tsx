import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { LobbyScreen } from './LobbyScreen';

// CAPSTONE — the whole Rooms→Lobby screen (121:2056) assembled from the design
// system. The composition lives in LobbyScreen.tsx so it is shared with the
// Screens/Rooms (Lobby) drift view; this story renders it on its own.

const meta: Meta<typeof LobbyScreen> = {
  title: 'Lobby/Overview',
  component: LobbyScreen,
};
export default meta;

type Story = StoryObj<typeof LobbyScreen>;
export const FullLobby: Story = { name: 'Full lobby' };
