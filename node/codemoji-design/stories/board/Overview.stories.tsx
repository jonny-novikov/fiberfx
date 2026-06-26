import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardScreen } from './BoardScreen';

// CAPSTONE — the whole gameplay board (94:2974) assembled from the design system's
// board components. The composition lives in BoardScreen.tsx so it is shared with
// the Screens/Game (Free) drift view; this story renders it on its own.

const meta: Meta<typeof BoardScreen> = {
  title: 'Board/Overview',
  component: BoardScreen,
};
export default meta;

type Story = StoryObj<typeof BoardScreen>;
export const FullBoard: Story = { name: 'Full board' };
