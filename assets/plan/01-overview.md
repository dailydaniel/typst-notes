# typst-notes: Архитектура проекта

## Naming Convention

| Компонента | Директория | Описание |
|---|---|---|
| Typst-фреймворк | `notes-framework/` | Пакет `@local/notes` |
| Rust-библиотека | `notes-core/` | Ядро логики (AST, индекс, компиляция) |
| CLI | `notes-cli/` | Бинарник, обёртка над notes-core |
| Tauri-приложение | `notes-app/` | GUI, обёртка над notes-core |

## Идея

Note-taker на базе Typst вместо Markdown. Вместо сложной обработки `.md` файлов (парсеры, YAML frontmatter, Dataview DSL, кастомные рендереры) — вся логика заметок живёт в самом Typst (функции, типы, query, metadata), а приложение — тонкая обёртка.

**Вдохновение:** [basalt-lib](https://github.com/GabrielDTB/basalt-lib) — минималистичный Typst-фреймворк для zettelkasten.

## Три компоненты

```
┌─────────────────────────────────────────────────────────┐
│                  notes-app (Tauri)                │
│              GUI: редактор, превью, поиск               │
│            Зависит от notes-core как Rust lib           │
└───────────────────────┬─────────────────────────────────┘
                        │ вызывает
┌───────────────────────┴─────────────────────────────────┐
│              notes-core (Rust lib) + notes-cli          │
│     AST-парсинг, индексация, компиляция, управление     │
│         typst-syntax + typst + typst-kit crates         │
└───────────────────────┬─────────────────────────────────┘
                        │ генерирует notes-index.json
                        │ компилирует через typst crate
┌───────────────────────┴─────────────────────────────────┐
│              @local/notes (Typst framework)             │
│   Типы заметок, форматтеры, xlink, backlinks, граф      │
│         Читает notes-index.json для данных              │
└─────────────────────────────────────────────────────────┘
```

### 1. `@local/notes` — Typst-пакет (фреймворк)

Устанавливается как локальный Typst-пакет. Предоставляет:
- Типизированные конструкторы заметок (`note`, `task`, `card`, `tag` + пользовательские)
- Кросс-ссылки между заметками (`xlink`)
- Рендеринг backlinks и графа связей
- Vault-wide форматирование

**Не парсит AST** — получает данные из `notes-index.json`, подготовленного Rust-слоем.

### 2. `notes-core` + `notes-cli` — Rust-обёртка

`notes-core` — библиотечный crate с логикой:
- AST-парсинг `.typ` файлов через `typst-syntax`
- Построение индекса (`notes-index.json`)
- Программная компиляция через `typst` crate
- Управление vault (создание, заметки, CSV)

`notes-cli` — тонкий бинарник поверх `notes-core`:
```
notes init / new / index / compile / search / backlinks / list / graph
```

### 3. `notes-app` — Tauri-приложение

GUI поверх `notes-core` (подключается как Rust-зависимость):
- Подключается к любому vault (указать папку с `vault.typ`)
- Редактор + превью + поиск + backlinks
- Синхронизация через git на уровне файлов
- Tauri v2 — десктоп + iOS

## Структура монорепо

```
typst-notes/
├── Cargo.toml                    # Workspace: notes-core, notes-cli, notes-app
├── notes-framework/              # @local/notes Typst-пакет
│   ├── typst.toml
│   └── src/
│       ├── lib.typ               # Точка входа, реэкспорт
│       ├── vault.typ             # new-vault()
│       ├── note-type.typ         # new-note-type(), конструкторы
│       ├── xlink.typ             # xlink(), format-xlinks()
│       ├── backlinks.typ         # render-backlinks()
│       ├── graph.typ             # build-graph()
│       └── index.typ             # read-index(), query-index()
├── notes-core/                   # Rust библиотека
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── types.rs              # NoteMetadata, NoteLink, NotesIndex
│       ├── vault.rs              # Vault::init(), open(), discover()
│       ├── note.rs               # new_note(), generate templates
│       ├── ast.rs                # AST extraction (typst-syntax)
│       ├── index.rs              # build_index(), write JSON
│       ├── compiler.rs           # compile to HTML/PDF
│       ├── world.rs              # World trait implementation
│       ├── query.rs              # search, list, filter
│       ├── csv_registry.rs       # note-paths.csv read/write
│       └── error.rs              # NotesError
├── notes-cli/                    # CLI бинарник
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs               # Clap dispatch
│       └── commands/             # init, new, index, compile, ...
├── notes-app/              # Tauri приложение
│   ├── src-tauri/                # Rust backend
│   └── src/                      # Svelte frontend
└── examples/                     # Тестовый vault
    ├── vault.typ
    ├── note-paths.csv
    ├── notes-index.json
    └── notes/
```

## Структура vault пользователя

Создаётся через `notes init`:

```
my-vault/
├── vault.typ                     # Конфиг: типы, форматтеры, граф
├── note-paths.csv                # Реестр заметок (пути)
├── notes-index.json              # Индекс (генерируется notes index)
├── notes/
│   ├── welcome.typ               # Авто-созданная первая заметка
│   └── ...
└── assets/                       # Вложения (картинки и т.д.)
```

## Data Flow

```
1. Пользователь создаёт заметку:
   notes new "Title" --type task
   → создаёт notes/title.typ + обновляет note-paths.csv

2. Пользователь индексирует:
   notes index
   → парсит все .typ через typst-syntax AST
   → извлекает metadata + xlink вызовы
   → пишет notes-index.json

3. Пользователь компилирует:
   notes compile notes/title.typ --format html
   → Typst-фреймворк читает notes-index.json
   → разрешает xlink, рендерит backlinks
   → выдаёт HTML

4. Пользователь смотрит граф:
   notes graph
   → компилирует vault.typ → diagraph рисует граф из index данных
```

## Принципы

1. **Vault как центр** — все заметки зависят от `vault.typ`, он — от `@local/notes`
2. **Данные как файлы** — CSV, JSON, .typ — всё текстовое, git-friendly
3. **Фреймворк не парсит** — AST-парсинг только в Rust, фреймворк потребляет готовый индекс
4. **CLI-first** — всё работает из терминала, GUI опционален
5. **Подключаемый vault** — приложение открывает любую папку с `vault.typ`
6. **Синхронизация через git** — никакой app-level синхронизации, просто файлы
