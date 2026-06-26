import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { SubscriptionBanner } from './SubscriptionBanner';

// Lobby story — mirrors the RoomCard exemplar: title 'Lobby/<Name>', a plain
// max-w-sm width decorator (the banner is itself a surface, so no BoardCard
// wrapper — that would double the fill), one story per meaningful state.
const meta: Meta<typeof SubscriptionBanner> = {
  title: 'Lobby/Subscription Banner',
  component: SubscriptionBanner,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof SubscriptionBanner>;

export const Default: Story = {
  args: {
    teaser: 'Unlock daily rewards',
    description: 'Subscribe to claim free keys every day and skip the wait.',
  },
};
