// Typst Syntax Reference
// Актуально для Typst 0.14.x (октябрь 2025)
// Источник: https://typst.app/docs/reference/

// ============================================================
// 1. РЕЖИМЫ КОНТЕНТА
// ============================================================
// Typst имеет три режима:
// - Markup mode (по умолчанию) — текст и разметка
// - Code mode — после # или внутри { }
// - Math mode — внутри $ ... $

// ============================================================
// 2. ЗАГОЛОВКИ
// ============================================================
// = Уровень 1
// == Уровень 2
// === Уровень 3
// ==== Уровень 4

// Нумерация заголовков:
// #set heading(numbering: "1.a")
// #set heading(numbering: "1.1")

// ============================================================
// 3. ФОРМАТИРОВАНИЕ ТЕКСТА
// ============================================================
// *жирный текст*
// _курсив_
// `моноширинный код`
// #underline[подчеркнутый]
// #strike[зачеркнутый]
// #highlight[выделенный]
// #smallcaps[малые заглавные]
// #super[верхний индекс]
// #sub[нижний индекс]
// #overline[надчеркнутый]

// ============================================================
// 4. СПИСКИ
// ============================================================
// Маркированный:
// - элемент 1
// - элемент 2
//   - вложенный

// Нумерованный:
// + элемент 1
// + элемент 2
//   + вложенный

// Список терминов:
// / Термин: Определение
// / Другой термин: Другое определение

// ============================================================
// 5. ССЫЛКИ И МЕТКИ
// ============================================================
// Метка: <my-label>
// Ссылка на метку: @my-label
// Гиперссылка: #link("https://example.com")[текст]
// Email: #link("mailto:user@example.com")

// ============================================================
// 6. ИЗОБРАЖЕНИЯ И ФИГУРЫ
// ============================================================
// #image("path.jpg")
// #image("path.png", width: 50%)
// #image("path.svg", height: 3cm)
//
// #figure(
//   image("photo.jpg", width: 80%),
//   caption: [Подпись к изображению],
// ) <fig-label>
//
// Ссылка на фигуру: @fig-label
// Поддерживаемые форматы: PNG, JPEG, GIF, SVG, PDF (с 0.14), WebP (с 0.14)

// ============================================================
// 7. МАТЕМАТИКА
// ============================================================
// Инлайн: $x^2 + y^2 = z^2$
// Блочная (отдельная строка):
// $ sum_(i=0)^n a_i x^i $
//
// Верхний индекс: $x^2$
// Нижний индекс: $x_i$
// Дробь: $a / b$  или  $frac(a, b)$
// Корень: $sqrt(x)$  или  $root(3, x)$
// Вектор: $vec(x, y, z)$
// Матрица: $mat(a, b; c, d)$
// Греческие буквы: $alpha$, $beta$, $gamma$, $rho$, $nabla$
// Стрелки: $arrow.r$, $arrow.l$, $arrow.squiggly$
// Текст в формуле: $"text here"$
// Скобки: $lr([ ... ])$
//
// Стили дробей (с 0.14): frac.style может быть skewed или inline

// ============================================================
// 8. БЛОКИ КОДА
// ============================================================
// Инлайн: `code`
// С языком: ```rust fn main() {}```
//
// Блок:
// ```rust
// fn main() {
//     println!("Hello!");
// }
// ```
//
// Программный: #raw("code", lang: "rust")

// ============================================================
// 9. ТАБЛИЦЫ
// ============================================================
// #table(
//   columns: (1fr, auto, auto),
//   inset: 10pt,
//   align: horizon,
//   table.header(
//     [*Col 1*], [*Col 2*], [*Col 3*],
//   ),
//   [data], [data], [data],
// )
//
// Стилизация:
// #set table(stroke: none, gutter: 0.2em)
// #set table(fill: (x, y) => if y == 0 { gray })
//
// Кастомные ячейки:
// #table.cell(fill: green)[content]
// #table.cell(colspan: 2)[spanning]
// #table.cell(rowspan: 3)[spanning]
//
// Show rule для ячеек:
// #show table.cell: it => { ... it.x, it.y, it.body ... }
//
// Множественные заголовки (с 0.14): поддержка subheaders

// ============================================================
// 10. НАСТРОЙКА СТРАНИЦЫ
// ============================================================
// #set page(
//   paper: "a4",           // "a4", "a5", "a6", "us-letter", ...
//   margin: (x: 2cm, y: 2.5cm),
//   // или margin: (top: 2cm, bottom: 2cm, left: 2cm, right: 2cm),
//   header: [Заголовок],
//   footer: [Подвал],
//   numbering: "1",        // нумерация страниц
//   columns: 2,            // многоколоночная верстка
// )

// ============================================================
// 11. НАСТРОЙКА ТЕКСТА
// ============================================================
// #set text(
//   font: "New Computer Modern",  // или "Libertinus Serif"
//   size: 11pt,
//   lang: "ru",
//   fill: blue,
//   style: "italic",
//   weight: "bold",
// )
//
// #set par(
//   justify: true,
//   leading: 0.65em,      // межстрочный интервал
//   first-line-indent: 1em,
// )

// ============================================================
// 12. SET И SHOW ПРАВИЛА
// ============================================================
// SET — устанавливает параметры по умолчанию:
// #set text(size: 12pt)
// #set page(margin: 2cm)
// #set heading(numbering: "1.")
//
// SHOW — трансформирует элементы:
// #show heading: smallcaps
// #show heading.where(level: 1): set text(size: 16pt)
// #show heading.where(level: 2): it => { emph(it.body) }
// #show "строка": [замена]
// #show: template   // применить к всему документу

// ============================================================
// 13. ПЕРЕМЕННЫЕ И ФУНКЦИИ
// ============================================================
// #let name = "value"
// #let x = 42
// #let flag = true
// #let items = (1, 2, 3)              // массив
// #let data = (key: "value")          // словарь
//
// Функции:
// #let greet(name) = [Hello, #name!]
// #let styled(text, color: blue) = {
//   set text(fill: color)
//   text
// }
//
// Вызов:
// #greet("World")
// #styled(color: red)[content]
//
// Частичное применение:
// #show: conf.with(title: "My Doc")

// ============================================================
// 14. УСЛОВИЯ И ЦИКЛЫ
// ============================================================
// #if condition [
//   true branch
// ] else [
//   false branch
// ]
//
// #for item in items [
//   Item: #item \
// ]
//
// #while x > 0 { x -= 1 }

// ============================================================
// 15. ИМПОРТ И МОДУЛИ
// ============================================================
// #import "file.typ": func1, func2
// #import "file.typ": *           // всё
// #import "@preview/pkg:1.0.0"    // из Universe
// #import "@local/pkg:1.0.0"     // локальный пакет
//
// #include "other.typ"            // вставить содержимое файла

// ============================================================
// 16. LAYOUT ЭЛЕМЕНТЫ
// ============================================================
// #align(center)[centered]
// #align(center + horizon)[centered vertically too]
//
// #block(width: 100%, fill: luma(230), inset: 8pt)[content]
// #box[inline content]
//
// #grid(
//   columns: (1fr, 1fr),
//   row-gutter: 12pt,
//   [col 1], [col 2],
// )
//
// #stack(dir: ltr, spacing: 1em, [a], [b], [c])
//
// #columns(2)[
//   Two column text...
//   #colbreak()
//   Second column.
// ]
//
// #pad(x: 1em)[padded content]
//
// #place(top + right)[absolute positioned]
// #place(top + center, float: true, scope: "parent")[floating]
//
// #move(dx: 5pt, dy: -3pt)[shifted]
// #rotate(45deg)[rotated]
// #scale(150%)[scaled]

// ============================================================
// 17. ФИГУРЫ И ГРАФИКА
// ============================================================
// #rect(width: 100%, height: 2cm, fill: blue)
// #circle(radius: 1cm, fill: red)
// #ellipse(width: 3cm, height: 2cm)
// #square(size: 1cm, fill: green)
// #line(length: 100%, stroke: 2pt + red)
// #polygon(fill: blue, (0pt, 0pt), (2cm, 0pt), (1cm, 2cm))
//
// Кривые Безье (с 0.13):
// #curve(
//   curve.move((0pt, 0pt)),
//   curve.line((1cm, 0pt)),
//   curve.cubic(none, (2cm, 1cm), (1cm, 1cm)),
//   curve.close(),
// )
//
// Цвета:
// red, blue, green, yellow, purple, orange, gray, black, white
// rgb("#ff0000"), rgb(255, 0, 0)
// luma(200)              // оттенки серого
// blue.lighten(80%)
// red.darken(20%)
//
// Градиенты:
// gradient.linear(red, blue)
// gradient.linear(..color.map.rainbow)
// gradient.radial(red, blue)
// gradient.conic(red, blue)
//
// Штрихи:
// stroke: 2pt + red
// stroke: (paint: blue, thickness: 4pt, cap: "round", dash: "dashed")

// ============================================================
// 18. ДАННЫЕ
// ============================================================
// #let data = csv("file.csv")
// #let data = json("file.json")
// #let data = toml("file.toml")
// #let data = yaml("file.yaml")
// #let data = xml("file.xml")
// #let data = read("file.txt")     // текстовый файл
// #let data = cbor("file.cbor")

// ============================================================
// 19. CONTEXT И INTROSPECTION
// ============================================================
// context — доступ к контекстным данным:
// #context document.title
// #context counter(heading).display()
// #context here().page()
//
// Counter:
// #let c = counter("my-counter")
// #c.step()
// #context c.display()
//
// State:
// #let s = state("my-state", 0)
// #s.update(x => x + 1)
// #context s.get()
//
// Query:
// #context query(heading)     // все заголовки
// #context query(<label>)     // элемент с меткой

// ============================================================
// 20. МЕТАДАННЫЕ ДОКУМЕНТА
// ============================================================
// #set document(
//   title: [My Document],
//   author: ("Author Name",),
//   date: datetime.today(),
// )

// ============================================================
// 21. БИБЛИОГРАФИЯ
// ============================================================
// #bibliography("refs.bib")
// #bibliography("refs.bib", style: "ieee")
// #bibliography("refs.bib", style: "apa")
// #cite(<key>)     или    @key
//
// Стили (обновлено в 0.14):
// "chicago-notes" (ранее "chicago-fullnotes")
// "modern-humanities-research-association-notes"

// ============================================================
// 22. OUTLINE (Оглавление)
// ============================================================
// #outline()                    // оглавление
// #outline(depth: 2)            // до уровня 2
// #outline(indent: auto)
// #outline(title: "Contents")

// ============================================================
// 23. FOOTNOTES
// ============================================================
// Текст#footnote[Сноска внизу страницы.]

// ============================================================
// 24. РАЗРЫВЫ
// ============================================================
// #pagebreak()         // новая страница
// #colbreak()          // новая колонка
// \                    // перенос строки (в тексте)
// #parbreak()          // новый абзац
// ...                  // многоточие / разрыв контента

// ============================================================
// 25. ШАБЛОНЫ (TEMPLATES)
// ============================================================
// Шаблон — это функция, принимающая doc:
//
// #let my-template(
//   title: "",
//   authors: (),
//   doc,
// ) = {
//   set page(paper: "a4")
//   set text(font: "Libertinus Serif", size: 11pt)
//   set par(justify: true)
//
//   // Титульная страница
//   align(center)[
//     #text(size: 20pt, weight: "bold")[#title]
//     #v(1em)
//     #for author in authors [
//       #author \
//     ]
//   ]
//   pagebreak()
//
//   doc
// }
//
// Использование:
// #import "template.typ": my-template
// #show: my-template.with(title: "Report", authors: ("Alice",))

// ============================================================
// 26. МАССИВЫ И СЛОВАРИ
// ============================================================
// Массив:
// #let arr = (1, 2, 3)
// arr.len()
// arr.at(0)
// arr.first()     // с default: arr.first(default: 0) (с 0.14)
// arr.last()
// arr.push(4)
// arr.map(x => x * 2)
// arr.filter(x => x > 1)
// arr.sorted()
// arr.sorted(by: (a, b) => a > b)    // с 0.14
// arr.join(", ")
// arr.flatten()
// arr.rev()
// arr.enumerate()
// arr.zip(other)
// arr.contains(2)
// arr.sum()
//
// Словарь:
// #let dict = (name: "Alice", age: 30)
// dict.at("name")
// dict.keys()
// dict.values()
// dict.pairs()
// dict.insert("key", "value")
// dict.remove("key")
// dict.len()

// ============================================================
// 27. СТРОКИ
// ============================================================
// #let s = "hello"
// s.len()
// s.contains("ell")
// s.starts-with("he")
// s.ends-with("lo")
// s.replace("l", "r")
// s.split(" ")
// s.trim()
// s.first()
// s.last()
// s.slice(1, 3)
// s.normalize()     // Unicode normalization (с 0.14)
// upper(s)
// lower(s)

// ============================================================
// 28. ТИПЫ ДАННЫХ
// ============================================================
// content    — разметка: [Hello]
// str        — строка: "Hello"
// int        — целое число: 42
// float      — дробное число: 3.14
// bool       — логический: true / false
// array      — массив: (1, 2, 3)
// dictionary — словарь: (key: "value")
// length     — длина: 1cm, 2pt, 3em, 4in, 5mm
// angle      — угол: 45deg, 1rad
// ratio      — процент: 50%
// alignment  — выравнивание: left, center, right, top, bottom, horizon
// color      — цвет: red, rgb("#ff0000")
// datetime   — дата/время: datetime.today()
// duration   — продолжительность
// regex      — регулярное выражение: regex("[a-z]+")
// label      — метка: <my-label>
// selector   — селектор: heading.where(level: 1)
// function   — функция
// auto       — автоматическое значение
// none       — отсутствие значения

// ============================================================
// 29. CALC (МАТЕМАТИЧЕСКИЕ ФУНКЦИИ)
// ============================================================
// calc.abs(-5)       // 5
// calc.min(1, 2)     // 1
// calc.max(1, 2)     // 2
// calc.pow(2, 3)     // 8
// calc.sqrt(9)       // 3.0
// calc.floor(3.7)    // 3
// calc.ceil(3.2)     // 4
// calc.round(3.5)    // 4
// calc.rem(7, 3)     // 1
// calc.log(100)      // 2.0
// calc.sin(90deg)    // 1.0
// calc.cos(0deg)     // 1.0

// ============================================================
// 30. CLI
// ============================================================
// typst compile input.typ                    // -> input.pdf
// typst compile input.typ output.pdf
// typst compile input.typ output.html --features html  // HTML (экспериментально)
// typst watch input.typ                      // авто-перекомпиляция
// typst init                                 // создать проект
// typst query input.typ "<label>"            // запрос
// typst fonts                                // список шрифтов
// typst info                                 // информация о сборке (с 0.14)
// typst completions                          // автодополнение для shell (с 0.14)
