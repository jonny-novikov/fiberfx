import type { UserConfig } from 'i18next-parser'

const config: UserConfig = {
  // Языки для извлечения
  locales: ['ru', 'en'],

  // Путь вывода переводов
  // {{lng}} - язык, {{ns}} - namespace
  output: 'public/lang/$LOCALE/$NAMESPACE.json',

  // Пути для сканирования
  input: ['src/**/*.{ts,tsx}'],

  // Namespace по умолчанию
  defaultNamespace: 'translation',

  // Доступные namespaces
  namespaceSeparator: ':',
  keySeparator: '.',

  // Сохранять ключи, которые уже есть в файле, но не найдены в коде
  keepRemoved: false,

  // Сортировать ключи
  sort: true,

  // Создавать файлы если не существуют
  createOldCatalogs: false,

  // Не добавлять пустые значения
  failOnUpdate: false,

  // Значение по умолчанию для новых ключей
  // $LOCALE - заменится на код языка
  defaultValue: (locale?: string, _namespace?: string, key?: string) => {
    // Для русского языка возвращаем ключ как значение-заглушку
    if (locale === 'ru') {
      return `[RU] ${key}`
    }
    // Для английского тоже заглушка
    return `[EN] ${key}`
  },

  // Функции для извлечения (react-i18next)
  lexers: {
    ts: ['JavascriptLexer'],
    tsx: [
      {
        lexer: 'JsxLexer',
        // Атрибуты для извлечения из Trans компонента
        attr: 'i18nKey',
        // Функции для извлечения
        functions: ['t', 'i18next.t'],
      },
    ],
  },

  // Контекст и множественное число
  contextSeparator: '_',
  pluralSeparator: '_',

  // Verbose вывод
  verbose: true,
}

export default config
