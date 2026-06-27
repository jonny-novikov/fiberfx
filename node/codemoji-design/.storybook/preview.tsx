import type { Decorator, Preview } from '@storybook/react-vite';
import React from 'react';
import { I18nextProvider } from 'react-i18next';
import i18n, { SUPPORTED_LANGUAGES } from '../stories/i18n/i18n';
import '../stories/preview.css';

// Global toolbars.
//  - `theme` recolors the single themeable --accent channel via data-theme.
//  - `locale` switches the i18n language live (ru | en) — see withI18n below.
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
  locale: {
    description: 'Component language (i18n)',
    defaultValue: 'ru',
    toolbar: {
      title: 'Language',
      icon: 'globe',
      items: [
        { value: 'ru', title: 'Русский', right: 'RU' },
        { value: 'en', title: 'English', right: 'EN' },
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

// Decorator: drive the i18n language from the `locale` toolbar and provide the i18n
// instance to every story. changeLanguage runs in an effect (not during render);
// useTranslation's subscription re-renders each consumer when the language flips.
const withI18n: Decorator = (Story, context) => {
  const locale = (context.globals.locale as string) || SUPPORTED_LANGUAGES[0];
  React.useEffect(() => {
    if (i18n.language !== locale) i18n.changeLanguage(locale);
  }, [locale]);
  return (
    <I18nextProvider i18n={i18n}>
      <Story />
    </I18nextProvider>
  );
};

const preview: Preview = {
  decorators: [withTheme, withI18n],
  parameters: {
    controls: { matchers: { color: /(background|color)$/i, date: /Date$/i } },
    layout: 'fullscreen',
  },
};

export default preview;
