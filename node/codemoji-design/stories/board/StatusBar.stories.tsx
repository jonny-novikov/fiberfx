import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { StatusBar } from './StatusBar';

// The thin resources strip — its own rounded surface, so no BoardCard decorator;
// font-sans is applied directly to match the board's type.
const meta: Meta<typeof StatusBar> = {
  title: 'Board/Status Bar',
  component: StatusBar,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof StatusBar>;

export const Default: Story = {
  args: { username: '@player', diamonds: 52352, clips: 1240, keys: 147 },
};
