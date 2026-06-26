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

// Defaults render the Figma master copy (the "Тысяча." pitch + "Это что такое?").
export const Default: Story = {};
