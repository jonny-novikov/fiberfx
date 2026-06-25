import React, { useEffect, useState, useMemo, useCallback } from 'react';

import { ALL_EMOJIS } from '../../../shared/libs/consts';
import { cn } from '../../../shared/libs/utils/classnames';

import { AppleEmoji } from '@/shared/ui';

export interface ScrollingEmojiLineProps {
  /** Количество эмодзи в строке */
  count?: number;
  /** Скорость анимации в секундах */
  duration?: number;
  /** Размер эмодзи */
  size?: 'sm' | 'md' | 'lg' | 'xl';
  /** Направление прокрутки */
  direction?: 'left' | 'right';
  /** Дополнительные классы */
  className?: string;
  /** Интервал обновления эмодзи (в миллисекундах) */
  updateInterval?: number;
  /** Прозрачность */
  opacity?: number;
  /** Плавная смена эмодзи во время анимации */
  smoothUpdate?: boolean;
}

export const ScrollingEmojiLine: React.FC<ScrollingEmojiLineProps> = ({
  count = 30, // Увеличено для лучшего покрытия мобильных экранов
  duration = 20,
  size = 'md',
  direction = 'left',
  className,
  updateInterval = 3000,
  opacity = 0.6,
  smoothUpdate = true,
}) => {
  // Генерируем действительно рандомную последовательность эмодзи с перемешиванием
  const generateRandomEmojis = useCallback(() => {
    // Создаем копию массива и перемешиваем его (Fisher-Yates shuffle)
    const shuffledEmojis = [...ALL_EMOJIS];
    for (let i = shuffledEmojis.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffledEmojis[i], shuffledEmojis[j]] = [
        shuffledEmojis[j],
        shuffledEmojis[i],
      ];
    }

    // Берем первые count элементов из перемешанного массива
    return shuffledEmojis.slice(0, count);
  }, [count]);

  // Генерируем дополнительный набор для второй части бегущей строки
  const generateSecondaryEmojis = useCallback(() => {
    return Array.from({ length: count }, () => {
      let randomEmoji;
      // Убеждаемся, что эмодзи не повторяется слишком часто подряд
      do {
        randomEmoji = ALL_EMOJIS[Math.floor(Math.random() * ALL_EMOJIS.length)];
      } while (Math.random() < 0.1); // 10% шанс повторения
      return randomEmoji;
    });
  }, [count]);

  const [emojis, setEmojis] = useState<string[]>(() => generateRandomEmojis());
  const [secondaryEmojis, setSecondaryEmojis] = useState<string[]>(() =>
    generateSecondaryEmojis()
  );
  const [isTransitioning, setIsTransitioning] = useState(false);

  // Обновляем эмодзи через заданные интервалы
  useEffect(() => {
    const interval = setInterval(() => {
      if (smoothUpdate) {
        // Плавная смена эмодзи
        setIsTransitioning(true);

        setTimeout(() => {
          setEmojis(generateRandomEmojis());
          setSecondaryEmojis(generateSecondaryEmojis());
          setIsTransitioning(false);
        }, 300); // Короткая задержка для плавности
      } else {
        // Мгновенная смена
        setEmojis(generateRandomEmojis());
        setSecondaryEmojis(generateSecondaryEmojis());
      }
    }, updateInterval);

    return () => clearInterval(interval);
  }, [
    count,
    updateInterval,
    smoothUpdate,
    generateRandomEmojis,
    generateSecondaryEmojis,
  ]);

  // Мемоизируем размеры эмодзи в пикселях для AppleEmoji
  const emojiSize = useMemo(() => {
    const sizeMap = {
      sm: 16,
      md: 24,
      lg: 32,
      xl: 48,
    };
    return sizeMap[size];
  }, [size]);

  // Мемоизируем стили размеров с адаптивностью для мобильных (до 700px)
  const sizeClasses = useMemo(() => {
    const sizeMap = {
      sm: 'text-sm sm:text-base md:text-lg',
      md: 'text-base sm:text-xl md:text-2xl',
      lg: 'text-xl sm:text-2xl md:text-4xl',
      xl: 'text-2xl sm:text-4xl md:text-6xl',
    };
    return sizeMap[size];
  }, [size]);

  // Стили анимации
  const animationStyle = {
    animationDuration: `${duration}s`,
    opacity: opacity,
  };

  // Создаем общий массив эмодзи для рендеринга с оптимизацией для мобильных
  // Uses AppleEmoji for consistent rendering across all platforms
  const renderEmojis = useCallback(
    (emojiArray: string[], keyPrefix: string) => {
      return emojiArray.map((emoji, index) => (
        <span
          key={`${keyPrefix}-${index}`}
          className={cn(
            'inline-flex items-center justify-center transition-all duration-700 ease-in-out',
            'hover:scale-125 hover:rotate-12 cursor-pointer select-none',
            'mx-0.5', // Базовые стили для мобильных
            'sm:mx-1',
            'md:mx-2',
            {
              'animate-float': Math.random() > 0.88,
              'animate-wiggle': Math.random() > 0.93,
            }
          )}
          style={{
            transform: `rotate(${(Math.random() - 0.5) * 8}deg)`,
          }}
        >
          <AppleEmoji id={emoji} size={emojiSize} />
        </span>
      ));
    },
    [emojiSize]
  );

  return (
    <div
      className={cn(
        'relative overflow-hidden whitespace-nowrap',
        'bg-transparent w-full',
        className
      )}
    >
      {/* Контейнер с бесконечной анимацией */}
      <div
        className={cn(
          'inline-flex',
          direction === 'right' ? 'animate-scroll-rtl' : 'animate-scroll',
          sizeClasses,
          'will-change-transform',
          {
            'opacity-60 scale-98': isTransitioning && smoothUpdate,
          }
        )}
        style={animationStyle}
      >
        {/* Первый блок эмодзи */}
        <div className="flex flex-shrink-0 items-center">
          {renderEmojis(emojis, 'first-emojis')}
        </div>

        {/* Разделитель между блоками (меньше на мобильных) */}
        <div className="flex-shrink-0 w-2 sm:w-4 md:w-8" />

        {/* Второй блок эмодзи (для бесшовности) */}
        <div className="flex flex-shrink-0 items-center">
          {renderEmojis(secondaryEmojis, 'second-emojis')}
        </div>

        {/* Разделитель */}
        <div className="flex-shrink-0 w-2 sm:w-4 md:w-8" />

        {/* Дубликат первого блока для идеально непрерывной прокрутки */}
        <div className="flex flex-shrink-0 items-center">
          {renderEmojis(emojis, 'first-duplicate')}
        </div>

        {/* Разделитель */}
        <div className="flex-shrink-0 w-2 sm:w-4 md:w-8" />

        {/* Дубликат второго блока */}
        <div className="flex flex-shrink-0 items-center">
          {renderEmojis(secondaryEmojis, 'second-duplicate')}
        </div>
      </div>
    </div>
  );
};
