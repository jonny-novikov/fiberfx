import type { Decorator, Preview } from '@storybook/react-vite';
import React from 'react';
import '../stories/preview.css';

// Global `theme` toolbar — recolors the single themeable --accent channel by
// setting data-theme on the story container (orange | blue | green).
export const globalTypes = {
  theme: {
    description: 'Accent theme (recolors --accent)',
    defaultValue: 'orange',
    toolbar: {
      title: 'Theme',
      icon: 'paintbrush',
      items: [
        { value: 'orange', title: 'Orange (default)', right: '#FF8400' },
        { value: 'blue', title: 'Blue (link)', right: '#0050FF' },
        { value: 'green', title: 'Green (success)', right: '#00D95F' },
      ],
      dynamicTitle: true,
    },
  },
};

// Decorator: apply the chosen [data-theme] + the app background gradient
// (from-bg-from to-bg-to) to the preview surface, in Noto Sans Mono.
const withTheme: Decorator = (Story, context) => {
  const theme = context.globals.theme || 'orange';
  return (
    <div
      data-theme={theme}
      className="font-sans bg-gradient-to-b from-bg-from to-bg-to text-muted"
      style={{ minHeight: '100vh', padding: '1.5rem' }}
    >
      <Story />
    </div>
  );
};

const preview: Preview = {
  decorators: [withTheme],
  parameters: {
    controls: { matchers: { color: /(background|color)$/i, date: /Date$/i } },
    layout: 'fullscreen',
  },
};

export default preview;
