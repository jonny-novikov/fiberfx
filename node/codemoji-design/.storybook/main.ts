import type { StorybookConfig } from '@storybook/react-vite';
import tailwindcss from '@tailwindcss/vite';

const config: StorybookConfig = {
  framework: '@storybook/react-vite',
  stories: ['../stories/**/*.stories.@(ts|tsx|mdx)'],
  // Serve the gameplay reference PNGs as static assets so the screen catalog
  // can load them at /gameplay/<asset> in the built Storybook.
  staticDirs: [{ from: '../gameplay/assets', to: '/gameplay' }],
  // Compile Tailwind v4 utilities (the @import 'tailwindcss' + generated tokens
  // in stories/preview.css) by adding the @tailwindcss/vite plugin to SB's Vite.
  viteFinal: async (cfg) => {
    cfg.plugins = cfg.plugins || [];
    cfg.plugins.push(tailwindcss());
    return cfg;
  },
};

export default config;
