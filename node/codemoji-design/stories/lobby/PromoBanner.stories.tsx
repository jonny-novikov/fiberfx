import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { PromoBanner } from './PromoBanner';

// Lobby story — mirrors the RoomCard exemplar: title 'Lobby/<Name>', a plain
// max-w-sm width decorator (PromoBanner is itself a BoardCard, so no extra
// surface wrapper), one story per meaningful state.
const meta: Meta<typeof PromoBanner> = {
  title: 'Lobby/Promo Banner',
  component: PromoBanner,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof PromoBanner>;

export const Default: Story = { args: { totalEarned: 25693 } };
