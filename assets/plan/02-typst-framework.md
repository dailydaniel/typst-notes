# Typst-фреймворк: `@local/notes`

## Обзор

Локальный Typst-пакет, который предоставляет систему типизированных заметок с кросс-ссылками, backlinks и визуализацией графа. Не занимается парсингом — получает данные из `notes-index.json`.

## Установка

Устанавливается как `@local/notes:0.1.0` в:
- macOS: `~/Library/Application Support/typst/packages/local/notes/0.1.0/`
- Linux: `~/.local/share/typst/packages/local/notes/0.1.0/`
- Windows: `%APPDATA%/typst/packages/local/notes/0.1.0/`

CLI команда `notes init` автоматически копирует пакет при создании vault.

## Структура пакета

```
notes-framework/
├── typst.toml                    # name = "notes", version = "0.1.0"
└── src/
    ├── lib.typ                   # Точка входа, реэкспорт public API
    ├── vault.typ                 # new-vault() — инициализация vault
    ├── note-type.typ             # new-note-type() — генерация конструкторов
    ├── xlink.typ                 # xlink() — кросс-ссылки
    ├── backlinks.typ             # render-backlinks() — рендер обратных ссылок
    ├── graph.typ                 # build-graph() — визуализация графа
    └── index.typ                 # read-index(), query-index() — доступ к индексу
```

## typst.toml

```toml
[package]
name = "notes"
version = "0.1.0"
entrypoint = "src/lib.typ"
authors = ["typst-notes"]
license = "MIT"
description = "Note-taking framework for Typst"
```

---

## API

### lib.typ — Точка входа

```typst
#import "vault.typ": new-vault
#import "xlink.typ": xlink
#import "note.typ": as-branch
```

Экспортирует только три функции. Остальные модули — внутренние, используются через vault object.

---

### vault.typ — new-vault()

```typst
#let new-vault(
  note-paths: (),          // array<str> — пути из CSV
  index-path: "notes-index.json",  // str — путь к индексу
  formatters: (),          // array<function> — кастомные форматтеры
) -> dictionary
```

**Возвращает словарь (vault object):**

| Поле | Тип | Описание |
|------|-----|----------|
| `new-note-type` | function | Создаёт тип заметки |
| `format` | function | Show rule для форматирования |
| `build-graph` | function | Рендерит граф связей |
| `query` | function | Запросы по индексу |
| `index` | dictionary | Загруженные данные индекса |

**Что делает:**
1. Читает `notes-index.json` через `json(index-path)`
2. Создаёт внутренний `state("notes-current-id")` для отслеживания текущей заметки
3. Возвращает объект с методами, привязанными к данным индекса

**Реализация (скетч):**

```typst
#import "note-type.typ": make-note-type-constructor
#import "index.typ": read-index, query-index
#import "backlinks.typ": render-backlinks
#import "graph.typ": build-graph-from-index

#let new-vault(
  note-paths: (),
  index-path: "notes-index.json",
  formatters: (),
) = {
  let index = read-index(index-path)
  let _current-note-id = state("notes-current-id", none)

  let format(apply-backlinks: true, body) = {
    // Применить пользовательские форматтеры
    for f in formatters {
      show: f
    }
    body
    // Backlinks в конце
    if apply-backlinks {
      context {
        let current-id = _current-note-id.final()
        if current-id != none {
          render-backlinks(id: current-id, index: index)
        }
      }
    }
  }

  (
    new-note-type: make-note-type-constructor.with(
      _current-note-id: _current-note-id,
      index: index,
    ),
    format: format,
    build-graph: () => build-graph-from-index(index: index),
    query: (type: none, where: none, sort-by: none) => {
      query-index(index: index, type: type, where: where, sort-by: sort-by)
    },
    index: index,
  )
}
```

---

### note-type.typ — new-note-type()

```typst
vault.new-note-type(
  type: str,               // "task", "note", "card", "tag"
  fields: dictionary,      // Дополнительные поля: (due_date: none, color: none)
) -> function
```

**Возвращает функцию-конструктор** для использования с `#show:`:

```typst
#show: task.with(
  id: "task-001",
  title: "Build MVP",
  due_date: datetime(year: 2026, month: 4, day: 1),
  tags: ("tag-dev",),
)
```

**Базовые поля (для ВСЕХ типов):**

| Поле | Тип | Обязательное | Default | Описание |
|------|-----|-------------|---------|----------|
| `id` | str | да | — | Уникальный идентификатор |
| `title` | str | да | — | Название заметки |
| `parent` | str \| none | нет | none | ID родительской заметки |
| `tags` | array | нет | () | Массив ID тегов |
| `created` | datetime | нет | datetime.today() | Дата создания |

**Дополнительные поля по типам:**

| Тип | Доп. поля |
|-----|-----------|
| `note` | — |
| `task` | `due_date: none` |
| `card` | `front: none, back: none` |
| `tag` | `color: none` |

**Что делает конструктор при вызове:**
1. Обновляет `state("notes-current-id")` с id заметки
2. Вставляет `metadata((...))` с типом и всеми полями
3. Добавляет `<note:{id}>` label для внутренних ссылок
4. Передаёт body для рендеринга

**Реализация (скетч):**

```typst
#let make-note-type-constructor(
  _current-note-id: none,
  index: (:),
  type: "",
  fields: (:),
) = {
  let constructor(
    id: "",
    title: "",
    parent: none,
    tags: (),
    created: datetime.today(),
    ..extra-args,
    body,
  ) = {
    assert(id != "", message: "Note id is required")
    assert(title != "", message: "Note title is required")

    _current-note-id.update(id)

    let meta = (
      type: type, id: id, title: title,
      parent: parent, tags: tags, created: created,
      ..extra-args.named(),
    )

    [#metadata(meta) <note-meta>]

    body
  }

  constructor
}
```

---

### xlink.typ — Кросс-ссылки

```typst
#xlink(
  id: str,                 // ID целевой заметки (обязательно)
  body: content | auto,    // Текст ссылки (auto = подставится title из индекса)
) -> content
```

**Примеры:**
```typst
Смотри #xlink(id: "task-001")                    // → "Build MVP" (из индекса)
Смотри #xlink(id: "task-001")[мою задачу]         // → "мою задачу"
```

**Как работает:**
1. Вставляет `metadata((target: id, kind: "xlink"))` для отслеживания (AST-парсер Rust тоже ищет эти вызовы)
2. При рендеринге — ищет целевую заметку в индексе
3. Генерирует `link()` на HTML/PDF файл заметки
4. Если заметка не найдена — красный текст `[id] (not found)`

**Реализация (скетч):**

```typst
#let xlink(id: "", body: auto) = {
  // Вставить metadata для трекинга
  [#metadata((target: id, kind: "xlink")) <xlink>]

  // Найти заметку в индексе через context
  context {
    let index = query(<vault-index>)  // или получить через state
    let target = index.notes.find(n => n.id == id)
    if target != none {
      let display = if body == auto { target.title } else { body }
      link(target.path.replace(".typ", ".html"), display)
    } else {
      text(fill: red)[#id (not found)]
    }
  }
}
```

> **Примечание:** Точная реализация доступа к индексу из xlink зависит от того, как vault передаёт данные. Варианты: через `state`, через `metadata` с label, или через замыкание при создании vault.

---

### backlinks.typ — Обратные ссылки

```typst
render-backlinks(
  id: str,                 // ID текущей заметки
  index: dictionary,       // Данные индекса
) -> content
```

**Рендерит блок в конце заметки:**

```
─────────────────────────
Backlinks
- Build MVP (task)
- Project Overview (note)
```

**Реализация:**

```typst
#let render-backlinks(id: "", index: (:)) = {
  let incoming = index.links.filter(l => l.target == id)
  if incoming.len() > 0 {
    v(1em)
    line(length: 100%, stroke: 0.5pt + gray)
    text(size: 0.9em, fill: gray)[*Backlinks*]
    for bl in incoming {
      let source = index.notes.find(n => n.id == bl.source)
      if source != none {
        [- #link(source.path.replace(".typ", ".html"))[#source.title] _(#source.type)_]
      }
    }
  }
}
```

---

### graph.typ — Визуализация графа

```typst
build-graph-from-index(
  index: dictionary,       // Данные индекса
) -> content
```

**Использует `diagraph` (Graphviz) для рендеринга:**

```typst
#import "@preview/diagraph:0.3.0": raw-render

#let build-graph-from-index(index: (:)) = {
  let nodes = index.notes.map(n => {
    "  \"" + n.id + "\" [label=\"" + n.title + "\""
    + if n.type == "tag" { ", shape=diamond, fillcolor=\"lightyellow\", style=filled" }
    else if n.type == "task" { ", shape=box, style=\"rounded,filled\", fillcolor=\"lightblue\"" }
    else { ", shape=ellipse" }
    + "]"
  }).join("\n")

  let edges = index.links.map(l => {
    "  \"" + l.source + "\" -> \"" + l.target + "\""
  }).join("\n")

  raw-render(
    "digraph G {\n  rankdir=LR;\n  node [fontsize=10];\n"
    + nodes + "\n" + edges + "\n}"
  )
}
```

**Альтернатива:** `CeTZ` для кастомного рендеринга с force-directed layout.

---

### index.typ — Доступ к индексу

```typst
// Чтение индекса
read-index(path: str) -> dictionary

// Запросы по индексу
query-index(
  index: dictionary,
  type: str | none,        // Фильтр по типу
  where: function | none,  // Предикат: (note) => bool
  sort-by: str | none,     // Поле для сортировки
) -> array
```

**Реализация:**

```typst
#let read-index(path) = {
  let data = json(path)
  if "notes" not in data { data.insert("notes", ()) }
  if "links" not in data { data.insert("links", ()) }
  data
}

#let query-index(index: (:), type: none, where: none, sort-by: none) = {
  let results = index.notes
  if type != none { results = results.filter(n => n.type == type) }
  if where != none { results = results.filter(where) }
  if sort-by != none {
    results = results.sorted(by: (a, b) => a.at(sort-by) < b.at(sort-by))
  }
  results
}
```

---

## Root vs Branch

**Root** — заметка компилируется самостоятельно (`typst compile notes/task.typ`):
- Применяются page settings, нумерация
- В конце рендерятся backlinks
- Полное форматирование

**Branch** — заметка включена в другой документ:
- Без page breaks
- Без backlinks
- Минимальное форматирование

**Механизм (как в basalt-lib):**

```typst
// Включение заметки как branch:
#as-branch(include "notes/sub-note.typ")

// as-branch оборачивает include и сигнализирует root=false
#let as-branch(body) = {
  // Форматтеры получат root=false
  context {
    metadata((root: false))
  }
  body
}
```

**Форматтеры** получают `root` параметр и могут условно применять стили:

```typst
formatters: (
  (body, root: true, ..rest) => {
    if root {
      set page("a4", margin: 2cm)
    }
    body
  },
)
```

---

## Формат `notes-index.json`

```json
{
  "version": 1,
  "generated_at": "2026-03-18T15:30:00Z",
  "notes": [
    {
      "id": "welcome",
      "title": "Welcome",
      "type": "note",
      "parent": null,
      "tags": [],
      "created": "2026-03-18",
      "path": "notes/welcome.typ"
    },
    {
      "id": "task-001",
      "title": "Build MVP",
      "type": "task",
      "parent": null,
      "tags": ["tag-dev"],
      "created": "2026-03-18",
      "path": "notes/task-001.typ",
      "due_date": "2026-04-01"
    }
  ],
  "links": [
    {
      "source": "task-001",
      "target": "tag-dev",
      "source_path": "notes/task-001.typ"
    }
  ]
}
```

---

## Шаблон vault.typ (генерируется `notes init`)

```typst
#import "@local/notes:0.1.0" as base

#let note-paths = csv("note-paths.csv").flatten()

#let vault = base.new-vault(
  note-paths: note-paths,
  index-path: "notes-index.json",
)

// === Типы заметок ===

#let note = vault.new-note-type(type: "note", fields: (:))
#let task = vault.new-note-type(type: "task", fields: (due_date: none))
#let card = vault.new-note-type(type: "card", fields: (front: none, back: none))
#let tag = vault.new-note-type(type: "tag", fields: (color: none))

// === Форматирование ===
#show: vault.format.with(apply-backlinks: true)

// === Обзор (при компиляции vault.typ) ===
#pagebreak()
= Knowledge Graph
#vault.build-graph()
```

## Шаблон заметки (генерируется `notes new`)

```typst
#import "vault.typ": *

#show: task.with(
  id: "task-001",
  title: "Build the MVP",
  due_date: datetime(year: 2026, month: 4, day: 1),
  tags: ("tag-dev",),
)

= Build the MVP

Начни писать здесь...

// Ссылка на другую заметку:
// #xlink(id: "other-note")
```
