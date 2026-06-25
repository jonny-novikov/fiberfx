/**
 * Константы для работы с Apple-styled эмодзи
 * Использует emoji-mart для единообразного отображения на всех платформах
 */

import React from 'react';

import { emojiToId } from '../utils/emoji-mapper';

import { EMOJI_CATEGORIES } from './emoji.consts';

import { AppleEmoji } from '@/shared/ui';

/**
 * Интерфейс для Apple эмодзи элемента
 */
export interface AppleEmojiItem {
  /** Unicode символ */
  unicode: string;
  /** ID для emoji-mart */
  id: string;
  /** React компонент для рендеринга */
  render: (size?: number, className?: string) => React.ReactElement;
}

/**
 * Преобразует массив Unicode эмодзи в массив AppleEmojiItem
 */
function createAppleEmojiItems(emojis: string[]): AppleEmojiItem[] {
  return emojis.map((unicode) => ({
    unicode,
    id: emojiToId(unicode),
    render: (size = 24, className = '') => (
      <AppleEmoji id={emojiToId(unicode)} size={size} className={className} />
    ),
  }));
}

/**
 * Животные в формате AppleEmoji
 * Готовые к использованию компоненты с единообразным стилем
 */
export const APPLE_EMOJI_ANIMALS = createAppleEmojiItems(
  (EMOJI_CATEGORIES as any).animals.emojis
);

/**
 * Получить случайное Apple эмодзи животного
 */
export const getRandomAppleAnimal = (): AppleEmojiItem => {
  const randomIndex = Math.floor(Math.random() * APPLE_EMOJI_ANIMALS.length);
  return APPLE_EMOJI_ANIMALS[randomIndex];
};

/**
 * Получить несколько случайных уникальных Apple эмодзи животных
 */
export const getRandomAppleAnimals = (count: number): AppleEmojiItem[] => {
  const shuffled = [...APPLE_EMOJI_ANIMALS].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(count, APPLE_EMOJI_ANIMALS.length));
};

/**
 * Найти AppleEmojiItem по Unicode символу
 */
export const findAppleEmojiByUnicode = (
  unicode: string
): AppleEmojiItem | undefined => {
  return APPLE_EMOJI_ANIMALS.find((item) => item.unicode === unicode);
};

/**
 * Найти AppleEmojiItem по ID
 */
export const findAppleEmojiById = (id: string): AppleEmojiItem | undefined => {
  return APPLE_EMOJI_ANIMALS.find((item) => item.id === id);
};
