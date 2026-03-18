// Typst API Reference — Функции по категориям
// Актуально для Typst 0.14.x
// Источник: https://typst.app/docs/reference/

// ============================================================
// FOUNDATIONS (Основы)
// ============================================================

// --- Типы ---
// int, float, decimal, bool, str, content, array, dictionary,
// bytes, label, selector, regex, function, module, type,
// auto, none, arguments, version, symbol, duration, datetime

// --- Утилиты ---
// assert(condition, message: "...")  — проверка условия
// panic("message")                  — остановка с ошибкой
// repr(value)                       — строковое представление
// eval("code")                      — вычислить строку как код
// type(value)                       — получить тип значения

// --- Система ---
// sys.version                       — версия Typst
// target()                          — целевой формат (pdf/html)

// ============================================================
// MODEL (Модель документа)
// ============================================================

// --- Документ ---
// #set document(title: [...], author: ("...",), date: datetime.today())

// --- Текстовые элементы ---
// heading(level: 1, numbering: "1.", body)
// par(justify: true, leading: 0.65em, first-line-indent: 0pt)
// emph[italic]           // или _italic_
// strong[bold]           // или *bold*
// quote(block: true, attribution: [Author])[text]

// --- Списки ---
// list(marker: [-], body: ...)        // маркированный
// enum(numbering: "1.", body: ...)    // нумерованный
// terms((term, desc), ...)            // терминов

// --- Ссылки ---
// link(dest, body)                    // гиперссылка
// ref(target)                         // ссылка на метку (@label)
// cite(key)                           // цитирование

// --- Фигуры ---
// figure(body, caption: [...], supplement: [...], numbering: "1")
// figure.caption(separator: [ — ], position: top)

// --- Сноски ---
// footnote[text]

// --- Библиография ---
// bibliography(path, style: "ieee", title: auto)

// --- Оглавление (обновлено в 0.13) ---
// outline(title: auto, depth: none, indent: auto, fill: repeat[.])

// --- Таблицы ---
// table(
//   columns: (auto,) * 3,       // или (1fr, 2fr, auto)
//   rows: auto,
//   gutter: auto,
//   column-gutter: auto,
//   row-gutter: auto,
//   fill: none,                  // или function(x, y)
//   align: auto,                 // или function(x, y)
//   stroke: 1pt,
//   inset: 5pt,
//   ..children,
// )
// table.header(..cells)           // заголовок
// table.footer(..cells)           // подвал
// table.cell(
//   colspan: 1, rowspan: 1,
//   fill: none, align: auto,
//   x: auto, y: auto,
//   body,
// )

// ============================================================
// TEXT (Текст)
// ============================================================

// text(
//   font: "...",
//   size: 11pt,
//   fill: black,
//   weight: "regular",     // "thin", "light", "regular", "medium", "bold", "black"
//   style: "normal",       // "normal", "italic", "oblique"
//   lang: "en",
//   region: none,
//   dir: auto,             // ltr / rtl
//   hyphenate: auto,
//   kerning: true,
//   ligatures: true,
//   body,
// )

// --- Декорации ---
// underline(body, offset: auto, stroke: auto)
// overline(body, offset: auto, stroke: auto)
// strike(body, offset: auto, stroke: auto)
// highlight(body, fill: auto)

// --- Трансформации ---
// upper(body)          // ВЕРХНИЙ РЕГИСТР
// lower(body)          // нижний регистр
// smallcaps(body)      // малые заглавные (all: false)
//   smallcaps(all: true, body)  // с 0.13: все буквы

// --- Элементы ---
// linebreak()          // \
// raw(text, lang: none, block: false)
// smartquote()
// lorem(n)             // генерация lorem ipsum текста
// sub[subscript]
// super[superscript]

// ============================================================
// MATH (Математика)
// ============================================================

// equation(body, block: false, numbering: none, supplement: auto)
// frac(num, denom)                    // дробь
//   frac.style: "display", "inline", "skewed"  // с 0.14
// vec(..items, delim: "(")            // вектор
// mat(..rows, delim: "(")             // матрица
// cases(..arms)                       // cases
// binom(n, k)                         // биномиальный коэффициент
// sqrt(body) / root(n, body)          // корни
// accent(body, accent)                // акцент (hat, tilde, ...)
// cancel(body)                        // зачеркивание
// attach(body, t: none, b: none)      // верхний/нижний индексы
// lr(body, size: auto)                // автоматические скобки
// primes(n)                           // штрихи

// Стили:
// upright(body), italic(body), bold(body)
// serif(body), sans(body), mono(body)
// cal(body), frak(body), bb(body)
// scr(body)                           // roundhand script (с 0.14)

// ============================================================
// LAYOUT (Раскладка)
// ============================================================

// --- Страница ---
// page(
//   paper: "a4",
//   width: auto, height: auto,
//   margin: auto,
//   header: none, footer: none,
//   numbering: none,
//   number-align: center + bottom,
//   columns: 1,
//   fill: none,
//   body,
// )
// pagebreak(weak: false)
// colbreak(weak: false)

// --- Контейнеры ---
// block(
//   width: auto, height: auto,
//   fill: none, stroke: none,
//   radius: 0pt, inset: 0pt,
//   outset: 0pt, spacing: 1.2em,
//   above: auto, below: auto,
//   clip: false, sticky: false,
//   body,
// )
// box(width: auto, height: auto, fill: none, ..., body)

// --- Выравнивание ---
// align(alignment, body)
// pad(body, left: 0pt, right: 0pt, top: 0pt, bottom: 0pt)
//   // сокращения: pad(x: 1em), pad(y: 1em), pad(rest: 1em)

// --- Сетка ---
// grid(
//   columns: (),
//   rows: (),
//   gutter: auto,
//   column-gutter: auto,
//   row-gutter: auto,
//   fill: none,
//   align: auto,
//   ..children,
// )

// --- Стек ---
// stack(dir: ttb, spacing: none, ..children)
//   // dir: ttb (top-to-bottom), ltr, rtl, btt

// --- Позиционирование ---
// place(alignment, body, float: false, scope: "column", clearance: 1.5em)
// move(body, dx: 0pt, dy: 0pt)

// --- Трансформации ---
// rotate(angle, body, origin: center + horizon)
// scale(factor, body, origin: center + horizon)
//   // или scale(x: 100%, y: 100%)
// skew(ax: 0deg, ay: 0deg, body)
// hide(body)                           // скрыть (но занимает место)

// --- Единицы ---
// 1pt, 1mm, 1cm, 1in, 1em            // длины
// 1fr                                  // доли (в grid/table)
// 50%                                  // проценты
// 45deg, 1rad                          // углы

// --- Измерение ---
// measure(body)                        // размеры элемента
// layout(func)                         // доступ к размерам контейнера

// ============================================================
// VISUALIZE (Визуализация)
// ============================================================

// --- Фигуры ---
// rect(width: auto, height: auto, fill: none, stroke: 1pt, radius: 0pt)
// square(size: auto, fill: none, stroke: 1pt, radius: 0pt)
// circle(radius: auto, fill: none, stroke: 1pt)
// ellipse(width: auto, height: auto, fill: none, stroke: 1pt)
// line(start: (0pt, 0pt), end: none, length: 0pt, angle: 0deg, stroke: 1pt)
// polygon(..vertices, fill: none, stroke: 1pt)
// path(..vertices, fill: none, stroke: 1pt, closed: false)

// Кривые Безье (с 0.13):
// curve(
//   fill: none, stroke: 1pt, closed: false,
//   ..components,
// )
// curve.move(point)
// curve.line(point)
// curve.quad(control, end)             // квадратичная
// curve.cubic(control1, control2, end) // кубическая
// curve.close(mode: "smooth")

// --- Изображения ---
// image(path, width: auto, height: auto, fit: "cover")
//   // fit: "cover", "contain", "stretch"
//   // Форматы: PNG, JPEG, GIF, SVG, PDF, WebP
//   // С 0.13: поддержка raw pixel data
//   // С 0.14: PDF как формат изображений, WebP

// --- Цвета ---
// Предопределённые: black, white, gray, silver,
//   red, maroon, green, olive, blue, navy,
//   yellow, orange, purple, fuchsia, aqua, teal
//
// Конструкторы:
// rgb(r, g, b)  или  rgb("#rrggbb")  или  rgb(r, g, b, a)
// luma(lightness)                      // оттенки серого
// cmyk(c, m, y, k)
// oklab(l, a, b)
// oklch(l, c, h)
// color.hsl(h, s, l)
// color.hsv(h, s, v)
//
// Методы цветов:
// color.lighten(30%)
// color.darken(20%)
// color.saturate(50%)
// color.desaturate(50%)
// color.negate()
// color.transparentize(50%)
// color.opacify(50%)
// color.mix(other, space: rgb)

// --- Градиенты ---
// gradient.linear(..stops, dir: auto, angle: auto)
// gradient.radial(..stops, center: (50%, 50%), radius: 50%)
// gradient.conic(..stops, center: (50%, 50%), angle: 0deg)
// color.map.rainbow, color.map.turbo, color.map.viridis, ...

// --- Штрихи (Stroke) ---
// stroke(
//   paint: black,
//   thickness: 1pt,
//   cap: "butt",        // "butt", "round", "square"
//   join: "miter",       // "miter", "round", "bevel"
//   dash: none,          // "solid", "dotted", "dashed", "dash-dotted"
//   miter-limit: 4.0,
// )

// --- Тайлинг (паттерны) ---
// tiling(body, size: auto, spacing: (0pt, 0pt), relative: "parent")

// ============================================================
// INTROSPECTION (Интроспекция)
// ============================================================

// counter(key)                         // счётчик
//   counter(heading)                   // счётчик заголовков
//   counter(page)                      // счётчик страниц
//   counter(figure)                    // счётчик фигур
//   .step()                            // увеличить
//   .update(value)                     // установить
//   .display(pattern)                  // отобразить (в context)
//   .get()                             // получить (в context)
//   .at(location)                      // значение в месте
//   .final()                           // финальное значение

// state(key, default)                  // состояние
//   .update(value)                     // обновить
//   .update(old => new)                // обновить функцией
//   .get()                             // получить (в context)
//   .at(location)
//   .final()

// query(selector)                      // найти элементы (в context)
//   query(heading)
//   query(heading.where(level: 1))
//   query(<my-label>)

// here()                               // текущая позиция (в context)
//   here().page()
//   here().position()

// locate(func)                         // DEPRECATED в 0.13+

// metadata(value)                      // вставить метаданные
//   // можно потом найти через query

// ============================================================
// DATA LOADING (Загрузка данных)
// ============================================================

// csv(path, delimiter: ",")            // CSV файл → array
// json(path)                           // JSON → dictionary/array
// toml(path)                           // TOML → dictionary
// yaml(path)                           // YAML → dictionary
// xml(path)                            // XML → dictionary
// cbor(path)                           // CBOR → value
// read(path)                           // текстовый файл → str
//
// С 0.13: все функции также принимают bytes вместо path

// ============================================================
// PDF EXPORT (с 0.14)
// ============================================================

// pdf.artifact(body)                   // не-семантический контент
// pdf.attach(path, name: auto, ...)    // вложенный файл
//   // pdf.embed() переименован в pdf.attach()
// pdf.header-cell(body)                // заголовочная ячейка таблицы
// pdf.data-cell(body)                  // ячейка данных таблицы
// pdf.table-summary(body)              // описание таблицы

// ============================================================
// HTML EXPORT (экспериментально, с 0.13+)
// ============================================================

// html.elem(tag, attrs: (:), body)     // HTML элемент
// html.frame(body)                     // фрейм
//
// Типизированные (с 0.14):
// html.div(body), html.span(body), html.p(body), ...
//
// CLI: typst compile file.typ output.html --features html

// ============================================================
// DATETIME
// ============================================================

// datetime.today()
// datetime(year: 2025, month: 1, day: 1)
// datetime(hour: 12, minute: 30, second: 0)
// dt.display("[year]-[month]-[day]")
// dt.year(), dt.month(), dt.day()
// dt.hour(), dt.minute(), dt.second()

// ============================================================
// REGEX
// ============================================================

// regex("[a-z]+")
// regex("\\d{3}-\\d{4}")
// str.match(regex)                     // первое совпадение
// str.matches(regex)                   // все совпадения
// str.replace(regex, replacement)
// str.split(regex)
