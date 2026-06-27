import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { RoomCard } from './RoomCard';

// EXEMPLAR lobby story — the template the other lobby components mirror:
// title 'Lobby/<Name>', a plain max-w-sm width decorator (RoomCard is itself a
// card), one story per meaningful state. RoomCard reuses the board's BoardCard +
// the gold Button variant, so the design system composes across screens.
const meta: Meta<typeof RoomCard> = {
  title: 'Lobby/Room Card',
  component: RoomCard,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof RoomCard>;

// Args track the Figma master rooms (Бокс для разминки / Золотая комната / Стальной ящик).
export const Free: Story = {
  args: { name: 'Бокс для разминки', prize: 52, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть 🔑 бесплатно' },
};
export const Golden: Story = {
  name: 'Golden room',
  args: { name: 'Золотая комната', prize: 10, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть сейф 🔑 1', golden: true },
};
export const Progress: Story = {
  args: { name: 'Стальной ящик', prize: 1352, stars: 2, emojiCount: 140, cells: 6, bestPercent: 24.32, ctaLabel: 'Открыть 🔑 сейф' },
};
