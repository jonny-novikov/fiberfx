import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { GoldenInProgressScreen, GoldenFinishedScreen } from './GoldenScreen';

// CAPSTONE — the two Golden Room screens assembled from the design system. The
// compositions live in GoldenScreen.tsx so they are shared with the
// Screens/Golden Game drift view; these stories render them on their own.

const meta: Meta = { title: 'Golden Game/Overview' };
export default meta;

type Story = StoryObj;
export const InProgress: Story = { name: 'In progress', render: () => <GoldenInProgressScreen /> };
export const Finished: Story = { render: () => <GoldenFinishedScreen /> };
