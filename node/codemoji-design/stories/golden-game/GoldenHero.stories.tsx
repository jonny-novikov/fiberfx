import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { GoldenHero } from './GoldenHero';

// EXEMPLAR golden-game story — title 'Golden Game/<Name>', a plain max-w-sm width
// decorator (the hero is its own surface), one story per meaningful state.
const meta: Meta<typeof GoldenHero> = {
  title: 'Golden Game/Golden Hero',
  component: GoldenHero,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GoldenHero>;

export const InProgress: Story = { args: { timeLeft: '48:00:00', prizePool: 2352, boost: 3 } };
export const EndingSoon: Story = {
  name: 'Ending soon',
  args: { timeLeft: '00:04:12', prizePool: 2352, boost: 3 },
};
