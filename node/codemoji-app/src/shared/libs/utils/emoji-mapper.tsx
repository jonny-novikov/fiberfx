import { AppleEmoji } from '@/shared/ui';

/**
 * Маппинг Unicode символов эмодзи на их ID в emoji-mart
 * Сгенерирован на основе данных emoji-mart для категории животных
 */
export const EMOJI_UNICODE_TO_ID: Record<string, string> = {
  // Домашние животные
  '🐶': 'dog',
  '🐕': 'dog2',
  '🦮': 'guide_dog',
  '🐕‍🦺': 'service_dog',
  '🐩': 'poodle',
  '🐱': 'cat',
  '🐈': 'cat2',
  '🐈‍⬛': 'black_cat',
  '🐭': 'mouse',
  '🐹': 'hamster',
  '🐰': 'rabbit',
  '🐇': 'rabbit2',

  // Дикие млекопитающие
  '🦊': 'fox_face',
  '🐻': 'bear',
  '🐻‍❄️': 'polar_bear',
  '🐼': 'panda_face',
  '🐨': 'koala',
  '🐯': 'tiger',
  '🦁': 'lion',
  '🐮': 'cow',
  '🐄': 'cow2',
  '🐷': 'pig',
  '🐖': 'pig2',
  '🐗': 'boar',
  '🐽': 'pig_nose',
  '🐵': 'monkey_face',
  '🐒': 'monkey',
  '🦍': 'gorilla',
  '🦧': 'orangutan',
  '🐺': 'wolf',
  '🦝': 'raccoon',
  '🐴': 'horse',
  '🐎': 'racehorse',
  '🦄': 'unicorn',
  '🦓': 'zebra',
  '🦌': 'deer',
  '🦬': 'bison',
  '🐂': 'ox',
  '🐃': 'water_buffalo',
  '🦏': 'rhinoceros',
  '🦛': 'hippopotamus',
  '🐘': 'elephant',
  '🦒': 'giraffe',
  '🦘': 'kangaroo',
  '🦥': 'sloth',
  '🦦': 'otter',
  '🦫': 'beaver',
  '🐪': 'dromedary_camel',
  '🐫': 'camel',
  '🦙': 'llama',
  '🦣': 'mammoth',

  // Птицы
  '🐔': 'chicken',
  '🐓': 'rooster',
  '🐣': 'hatching_chick',
  '🐤': 'baby_chick',
  '🐥': 'hatched_chick',
  '🐦': 'bird',
  '🐧': 'penguin',
  '🕊️': 'dove',
  '🦅': 'eagle',
  '🦆': 'duck',
  '🦢': 'swan',
  '🦉': 'owl',
  '🦤': 'dodo',
  '🪶': 'feather',
  '🦚': 'peacock',
  '🦜': 'parrot',
  '🦩': 'flamingo',
  '🦃': 'turkey',

  // Рептилии и амфибии
  '🐸': 'frog',
  '🐊': 'crocodile',
  '🐢': 'turtle',
  '🦎': 'lizard',
  '🐍': 'snake',
  '🐲': 'dragon_face',
  '🐉': 'dragon',
  '🦕': 'sauropod',
  '🦖': 't-rex',

  // Морские обитатели
  '🐳': 'whale',
  '🐋': 'whale2',
  '🐬': 'dolphin',
  '🦭': 'seal',
  '🐟': 'fish',
  '🐠': 'tropical_fish',
  '🐡': 'blowfish',
  '🦈': 'shark',
  '🐙': 'octopus',
  '🐚': 'shell',
  '🦀': 'crab',
  '🦞': 'lobster',
  '🦐': 'shrimp',
  '🦑': 'squid',
  '🪼': 'jellyfish',
  '🐌': 'snail',

  // Насекомые и беспозвоночные
  '🐝': 'bee',
  '🐛': 'bug',
  '🦋': 'butterfly',
  '🐞': 'lady_beetle',
  '🐜': 'ant',
  '🪰': 'fly',
  '🪱': 'worm',
  '🦗': 'cricket',
  '🕷️': 'spider',
  '🕸️': 'spider_web',
  '🦂': 'scorpion',
  '🦟': 'mosquito',
  '🪲': 'beetle',
  '🪳': 'cockroach',

  // Другие
  '🦇': 'bat',
  '🐾': 'feet',
};

/**
 * Конвертирует Unicode символ эмодзи в его ID для emoji-mart
 */
export function emojiToId(unicode: string): string {
  return EMOJI_UNICODE_TO_ID[unicode] || unicode;
}

/**
 * Рендерит эмодзи в стиле Apple
 * @param emoji - Unicode символ эмодзи
 * @param size - размер в пикселях
 * @param className - дополнительные CSS классы
 */
export function renderAppleEmoji(
  emoji: string,
  size: number = 24,
  className?: string
) {
  const id = emojiToId(emoji);
  return <AppleEmoji id={id} size={size} className={className} />;
}

/**
 * Получает Apple-styled эмодзи компонент для массива Unicode символов
 */
export function getAppleEmojiComponents(
  emojis: string[],
  size: number = 24,
  className?: string
) {
  return emojis.map((emoji, index) => ({
    key: `${emoji}-${index}`,
    component: renderAppleEmoji(emoji, size, className),
    unicode: emoji,
    id: emojiToId(emoji),
  }));
}
