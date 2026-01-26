import { defineConfig, presetUno, presetIcons } from 'unocss';

export default defineConfig({
  presets: [
    presetUno(),
    presetIcons({
      scale: 1.2,
      cdn: 'https://esm.sh/',
    }),
  ],
  theme: {
    colors: {
      // Codemoji brand colors
      primary: {
        DEFAULT: '#6366F1', // Indigo
        dark: '#4F46E5',
        light: '#818CF8',
      },
      ink: {
        heading: '#1F2937',
        body: '#374151',
        muted: '#6B7280',
        subtle: '#9CA3AF',
      },
      bg: {
        primary: '#FFFFFF',
        secondary: '#F9FAFB',
        tertiary: '#F3F4F6',
      },
      border: '#E5E7EB',
      danger: '#EF4444',
      success: '#10B981',
    },
    fontFamily: {
      primary: 'Inter, system-ui, -apple-system, sans-serif',
      mono: 'JetBrains Mono, Fira Code, monospace',
    },
    boxShadow: {
      card: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
      elevated: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
    },
  },
  shortcuts: {
    'flex-center': 'flex items-center justify-center',
    'flex-between': 'flex items-center justify-between',
    'card': 'bg-white rounded-xl shadow-card p-6 border border-border',
    'btn': 'px-4 py-2 rounded-lg font-medium transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed',
    'btn-primary': 'btn bg-primary text-white hover:bg-primary-dark focus:ring-2 focus:ring-primary/50',
    'btn-secondary': 'btn bg-bg-secondary text-ink-body border border-border hover:bg-bg-tertiary',
    'input': 'w-full px-4 py-3 border border-border rounded-lg bg-white text-ink-body placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-colors',
    'input-error': 'border-danger focus:ring-danger/30 focus:border-danger',
    'label': 'block text-sm font-medium text-ink-muted mb-1.5',
  },
});
