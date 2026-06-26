import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { ShareKeys } from './ShareKeys';

// ShareKeys already wraps itself in a BoardCard, so no card decorator here —
// just constrain the width to the board column. One story for the single state.
const meta: Meta<typeof ShareKeys> = {
  title: 'Board/Share Keys',
  component: ShareKeys,
  decorators: [
    (Story) => (
      <div className="max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof ShareKeys>;

export const Default: Story = {};
