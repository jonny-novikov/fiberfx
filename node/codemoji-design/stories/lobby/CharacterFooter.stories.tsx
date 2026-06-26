import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { CharacterFooter } from './CharacterFooter';

// A decorative footer (the lobby's mascot), so the width decorator mirrors the
// other lobby stories. The raster mascot is replaced by a large Unicode glyph.
const meta: Meta<typeof CharacterFooter> = {
  title: 'Lobby/Character Footer',
  component: CharacterFooter,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof CharacterFooter>;

export const Default: Story = { args: { caption: 'See you in the next round' } };
