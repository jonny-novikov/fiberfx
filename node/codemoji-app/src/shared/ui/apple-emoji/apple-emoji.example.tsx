/**
 * Примеры использования компонента AppleEmoji
 */

import { AppleEmoji } from './apple-emoji';

import {
  APPLE_EMOJI_ANIMALS,
  getRandomAppleAnimal,
  getRandomAppleAnimals,
  findAppleEmojiByUnicode,
} from '@/shared/libs/consts/apple-emoji.consts';

/**
 * Пример 1: Базовое использование с ID
 */
export function Example1_BasicUsageWithId() {
  return (
    <div className="flex gap-4 p-4">
      <AppleEmoji id="dog" size={32} />
      <AppleEmoji id="cat" size={32} />
      <AppleEmoji id="rabbit" size={32} />
    </div>
  );
}

/**
 * Пример 2: Базовое использование с Unicode символами
 */
export function Example2_BasicUsageWithUnicode() {
  return (
    <div className="flex gap-4 p-4">
      <AppleEmoji id="🐶" size={32} />
      <AppleEmoji id="🐱" size={32} />
      <AppleEmoji id="🐰" size={32} />
    </div>
  );
}

/**
 * Пример 3: Разные размеры
 */
export function Example3_DifferentSizes() {
  return (
    <div className="flex items-center gap-4 p-4">
      <AppleEmoji id="🐶" size={16} />
      <AppleEmoji id="🐶" size={24} />
      <AppleEmoji id="🐶" size={32} />
      <AppleEmoji id="🐶" size={48} />
      <AppleEmoji id="🐶" size={64} />
    </div>
  );
}

/**
 * Пример 4: Использование констант APPLE_EMOJI_ANIMALS
 */
export function Example4_UsingConstants() {
  return (
    <div className="grid grid-cols-10 gap-2 p-4">
      {APPLE_EMOJI_ANIMALS.slice(0, 20).map((animal, index) => (
        <div
          key={`${animal.unicode}-${index}`}
          className="flex flex-col items-center"
        >
          {animal.render(40)}
          <span className="text-xs mt-1">{animal.id}</span>
        </div>
      ))}
    </div>
  );
}

/**
 * Пример 5: Случайные эмодзи
 */
export function Example5_RandomEmojis() {
  const randomAnimal = getRandomAppleAnimal();
  const randomAnimals = getRandomAppleAnimals(5);

  return (
    <div className="p-4 space-y-4">
      <div>
        <h3 className="text-lg font-bold mb-2">Одно случайное животное:</h3>
        {randomAnimal.render(64)}
      </div>

      <div>
        <h3 className="text-lg font-bold mb-2">Пять случайных животных:</h3>
        <div className="flex gap-3">
          {randomAnimals.map((animal, i) => (
            <div key={i}>{animal.render(48)}</div>
          ))}
        </div>
      </div>
    </div>
  );
}

/**
 * Пример 6: Поиск и отображение конкретного эмодзи
 */
export function Example6_SearchAndDisplay() {
  const dogEmoji = findAppleEmojiByUnicode('🐶');
  const catEmoji = findAppleEmojiByUnicode('🐱');
  const bearEmoji = findAppleEmojiByUnicode('🐻');

  return (
    <div className="p-4 space-y-4">
      {dogEmoji && (
        <div className="flex items-center gap-3">
          {dogEmoji.render(48)}
          <div>
            <p className="font-bold">ID: {dogEmoji.id}</p>
            <p>Unicode: {dogEmoji.unicode}</p>
          </div>
        </div>
      )}

      {catEmoji && (
        <div className="flex items-center gap-3">
          {catEmoji.render(48)}
          <div>
            <p className="font-bold">ID: {catEmoji.id}</p>
            <p>Unicode: {catEmoji.unicode}</p>
          </div>
        </div>
      )}

      {bearEmoji && (
        <div className="flex items-center gap-3">
          {bearEmoji.render(48)}
          <div>
            <p className="font-bold">ID: {bearEmoji.id}</p>
            <p>Unicode: {bearEmoji.unicode}</p>
          </div>
        </div>
      )}
    </div>
  );
}

/**
 * Пример 7: Сетка всех животных
 */
export function Example7_AllAnimalsGrid() {
  return (
    <div className="p-4">
      <h2 className="text-2xl font-bold mb-4">
        Все животные ({APPLE_EMOJI_ANIMALS.length} эмодзи)
      </h2>
      <div className="grid grid-cols-8 md:grid-cols-12 lg:grid-cols-16 gap-3">
        {APPLE_EMOJI_ANIMALS.map((animal, index) => (
          <div
            key={`${animal.unicode}-${index}`}
            className="flex flex-col items-center p-2 hover:bg-gray-100 rounded-lg transition-colors"
            title={animal.id}
          >
            {animal.render(32)}
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * Пример 8: С пользовательскими классами
 */
export function Example8_CustomClasses() {
  return (
    <div className="p-4 space-y-4">
      <AppleEmoji id="🐶" size={48} className="drop-shadow-lg" />
      <AppleEmoji id="🐱" size={48} className="opacity-50 hover:opacity-100" />
      <AppleEmoji
        id="🐰"
        size={48}
        className="transform hover:scale-125 transition-transform"
      />
    </div>
  );
}
