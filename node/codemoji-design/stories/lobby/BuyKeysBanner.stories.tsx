import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BuyKeysBanner } from './BuyKeysBanner';

// BuyKeysBanner is itself a card, so — like the RoomCard exemplar — the decorator
// is a plain max-w-sm width box (NOT a BoardCard wrapper). The card's buy CTA
// rides bg-accent, so switching the toolbar theme recolors the button here.
const meta: Meta<typeof BuyKeysBanner> = {
  title: 'Lobby/Buy Keys Banner',
  component: BuyKeysBanner,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof BuyKeysBanner>;

export const Default: Story = { args: { players: 25693 } };
