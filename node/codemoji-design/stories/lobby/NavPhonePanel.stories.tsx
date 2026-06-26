import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { NavPhonePanel } from './NavPhonePanel';

// Lobby story — the phone chrome, built from the exported status-bar assets. Shown on
// the app screen-fill gradient so the transparent panel reads as it does on a real
// screen. (Assets load from /assets/status-bar/* via the public/ staticDir.)
const meta: Meta<typeof NavPhonePanel> = {
  title: 'Lobby/Nav Phone Panel',
  component: NavPhonePanel,
  decorators: [
    (Story) => (
      <div
        className="font-sans max-w-sm p-3"
        style={{ background: 'linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))' }}
      >
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof NavPhonePanel>;

export const Default: Story = {};
