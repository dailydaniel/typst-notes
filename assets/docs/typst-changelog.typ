// Typst Changelog: 0.13.0 — 0.14.x
// Последние изменения, важные для проекта typst-notes
// Источники:
//   https://typst.app/docs/changelog/0.13.0/
//   https://typst.app/docs/changelog/0.14.0/

// ============================================================
// TYPST 0.14.0 (24 октября 2025)
// ============================================================

// --- ACCESSIBILITY (главная фича) ---
// - PDF теперь по умолчанию генерирует accessibility tags
// - Поддержка PDF/UA-1 для соответствия стандартам доступности
// - Новые функции: pdf.header-cell(), pdf.data-cell(), pdf.table-summary()
// - pdf.artifact() — пометка контента как не-семантического
// - Флаг CLI: --no-pdf-tags для отключения тегов

// --- PDF EXPORT ---
// - Полностью переписан экспорт PDF (библиотека krilla)
// - Поддержка PDF версий: 1.4, 1.5, 1.6, 1.7, 2.0
// - Все стандарты PDF/A: PDF/A-1 через PDF/A-4 со всеми уровнями
// - PDF как формат изображений (можно вставлять PDF как image)
// - Закладки заголовков теперь включают нумерацию

// --- HTML EXPORT ---
// - Значительно расширен (но всё ещё экспериментальный)
// - Добавлена поддержка: images, footnotes, outlines, bibliography,
//   smartquotes, sub/super, underline, overline, strike, highlight,
//   smallcaps, case functions
// - Типизированные HTML функции: html.div(), html.span() и др.
// - Подсветка синтаксиса для блоков кода
// - CLI: typst compile file.typ file.html --features html

// --- ТИПОГРАФИКА ---
// - Character-level justification: par.justification-limits
//   (важно для книжной вёрстки)
// - Улучшенный CJK-Latin spacing

// --- МАТЕМАТИКА ---
// - frac.style: "skewed" и "inline" стили дробей
// - Несколько шрифтов в одной формуле
// - Новая функция scr() для roundhand script
// - Параметр dotless для accents
// - Лучшая поддержка complex Unicode

// --- ТАБЛИЦЫ ---
// - Множественные заголовки и подзаголовки
// - Новый элемент title для отображения заголовка документа

// --- МАССИВЫ И СТРОКИ ---
// - array.first(default: val), array.last(default: val)
// - str.first(default: val), str.last(default: val)
// - array.join(default: val)
// - array.sorted(by: (a, b) => ...)  — кастомная сортировка
// - str.normalize() — Unicode нормализация

// --- CLI ---
// - typst info — информация о сборке
// - typst completions — авто-дополнение для shell
// - TYPST_IGNORE_SYSTEM_FONTS, TYPST_IGNORE_EMBEDDED_FONTS — env vars
// - --target для typst query
// - --deps / --deps-format (замена --make-deps)

// --- BREAKING CHANGES (0.14) ---
// - Убраны сравнения type/str (int == "integer" больше не работает)
// - Пустые font lists в text.font запрещены
// - Labels не могут быть пустыми
// - link("") теперь ошибка
// - enum.item использует auto вместо none
// - Стили библиографии переименованы:
//   "chicago-fullnotes" → "chicago-notes"
//   "modern-humanities-research-association" → "...-notes"

// --- ПРОИЗВОДИТЕЛЬНОСТЬ ---
// - Layout engine стал многопоточным (ускорение 2-3x)

// --- ИЗОБРАЖЕНИЯ ---
// - WebP формат поддержан
// - PDF как формат изображений

// ============================================================
// TYPST 0.13.0 (19 февраля 2025)
// ============================================================

// --- ПАРАГРАФЫ ---
// - Typst теперь различает параграфы и inline-контент
// - Лучшая поддержка first-line-indent
// - Влияет на show rules — изменение поведения

// --- OUTLINE (Оглавление) ---
// - Полностью переработан
// - Лучший внешний вид по умолчанию
// - Автоматическое выравнивание нумерации
// - Удалены поля body и page

// --- КРИВЫЕ БЕЗЬЕ ---
// - Новая функция curve() (замена path())
// - curve.move(), curve.line(), curve.cubic(), curve.close()
// - Более простой и гибкий интерфейс

// --- ИЗОБРАЖЕНИЯ ---
// - Поддержка raw pixel raster форматов через image()
// - Генерация изображений прямо из кода Typst

// --- BYTES ---
// - Функции, принимающие пути файлов, теперь принимают и bytes
// - Больше гибкости для image(), data loading, plugins

// --- PLUGINS (WebAssembly) ---
// - Plugin type заменён на plugin function, возвращающую modules
// - Автоматическая многопоточность
// - BREAKING: plugin("file.wasm") теперь возвращает module

// --- HTML EXPORT ---
// - Начата разработка (за feature flag)
// - Команда: typst compile file.typ --features html

// --- CLI ---
// - --features аргумент для экспериментальных фич
// - Live-reloading HTTP сервер для HTML
// - typst watch file.typ file.html --features html

// --- BREAKING CHANGES (0.13) ---
// - Различие paragraphs/inline — влияет на show rules
// - Outline: удалены body и page, полностью новый API
// - Plugin: тип заменён на функцию
// - Удалены: style(), state.display(), locate() compatibility
// - Символы: ohm.inv → Omega.inv
// - Удалены: degree.c, degree.f, kelvin

// ============================================================
// ПОЛЕЗНЫЕ ССЫЛКИ
// ============================================================
// Документация: https://typst.app/docs/
// Changelog: https://typst.app/docs/changelog/
// Roadmap: https://typst.app/docs/roadmap/
// GitHub: https://github.com/typst/typst
// Пакеты: https://typst.app/universe/
// Блог: https://typst.app/blog/
