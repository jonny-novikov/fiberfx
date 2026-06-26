import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { GoldenAnswerReveal } from './GoldenAnswerReveal';

const meta: Meta<typeof GoldenAnswerReveal> = {
  title: 'Golden Game/Answer Reveal',
  component: GoldenAnswerReveal,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GoldenAnswerReveal>;

export const Default: Story = { args: { code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'] } };
