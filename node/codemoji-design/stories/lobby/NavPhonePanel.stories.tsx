import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { NavPhonePanel } from './NavPhonePanel';

// Lobby story — the phone chrome. Shown on the app screen-fill gradient so the
// default transparent background reads the way it does on a real screen.
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

export const Transparent: Story = {};
export const Solid: Story = { args: { solid: true } };
