# Фазы реализации

## Phase 0: Скаффолдинг

**Что:** Создать структуру монорепо, настроить зависимости.

- [ ] Инициализировать Cargo workspace (`Cargo.toml` с members)
- [ ] Создать `notes-core/` с `Cargo.toml` и зависимостями
- [ ] Создать `notes-cli/` с `Cargo.toml`
- [ ] Создать `notes-framework/` с `typst.toml` и пустыми `.typ` файлами
- [ ] Создать `examples/` с тестовым vault
- [ ] Настроить `.gitignore`
- [ ] Проверить: `cargo build` компилируется

---

## Phase 1: AST Extraction (notes-core)

**Что:** Самая технически критичная часть — парсинг `.typ` файлов.

- [ ] `types.rs` — все структуры данных
- [ ] `error.rs` — типы ошибок
- [ ] `ast.rs` — полная логика AST-парсинга:
  - [ ] `extract_from_file()` — парсинг одного файла
  - [ ] Извлечение `#show: type.with(...)` → NoteMetadata
  - [ ] Извлечение `#xlink(id: ...)` → NoteLink
  - [ ] `expr_to_string()`, `expr_to_string_array()` — хелперы
- [ ] `csv_registry.rs` — чтение/запись CSV
- [ ] Тесты:
  - [ ] Парсинг example note файлов
  - [ ] Корректное извлечение всех полей metadata
  - [ ] Корректное извлечение xlink targets
  - [ ] Edge cases: пустой файл, нет show rule, malformed

**Критерий готовности:** `extract_from_file()` корректно парсит все 4 типа заметок из примеров.

---

## Phase 2: Vault + Index (notes-core)

**Что:** Управление vault и построение индекса.

- [ ] `vault.rs`:
  - [ ] `Vault::init()` — генерация vault.typ, CSV, welcome note
  - [ ] `Vault::open()` — открытие существующего vault
  - [ ] `Vault::discover()` — поиск vault root вверх по дереву
- [ ] `note.rs`:
  - [ ] `new_note()` — создание файла + обновление CSV
  - [ ] `generate_id()` — slugify + uniqueness check
  - [ ] `generate_note_content()` — шаблоны для каждого типа
- [ ] `index.rs`:
  - [ ] `build_index()` — парсить все файлы, записать JSON
  - [ ] `update_index_for_file()` — инкрементальное обновление
- [ ] `query.rs` — search, list_notes, backlinks
- [ ] `graph.rs` — GraphData из индекса
- [ ] `sync.rs` — синхронизация CSV с файловой системой
- [ ] Тесты:
  - [ ] init → open → new_note → build_index → search

**Критерий готовности:** Полный цикл init → create notes → index → query работает программно.

---

## Phase 3: CLI (notes-cli)

**Что:** CLI-обёртка над notes-core.

- [ ] `main.rs` — Clap derive, dispatch
- [ ] Команды: init, new, index, sync, search, backlinks, list
- [ ] Форматированный вывод (таблицы, цвета)
- [ ] Тесты:
  - [ ] Полный workflow через CLI
  - [ ] `notes init my-vault && cd my-vault && notes new "Test" && notes index && notes list`

**Критерий готовности:** Все команды кроме compile и graph работают из терминала.

---

## Phase 4: Typst Framework

**Что:** Пакет `@local/notes`.

- [ ] `typst.toml` — манифест пакета
- [ ] `lib.typ` — реэкспорт
- [ ] `index.typ` — `read-index()`, `query-index()`
- [ ] `vault.typ` — `new-vault()`
- [ ] `note-type.typ` — `make-note-type-constructor()`, конструкторы
- [ ] `xlink.typ` — `xlink()`, разрешение ссылок
- [ ] `backlinks.typ` — `render-backlinks()`
- [ ] `graph.typ` — `build-graph-from-index()` через diagraph
- [ ] Установка как `@local/notes:0.1.0`
- [ ] Тесты:
  - [ ] Создать vault через CLI → написать заметки → `notes index` → `typst compile note.typ`
  - [ ] Проверить: backlinks рендерятся, xlink разрешается, граф строится

**Критерий готовности:** `typst compile notes/welcome.typ` выдаёт PDF/HTML с backlinks и рабочими ссылками.

---

## Phase 5: Компиляция (notes-core)

**Что:** Программная компиляция через `typst` crate.

- [ ] `world.rs` — `NotesWorld` реализация `World` trait:
  - [ ] Разрешение файлов (относительные пути, `@local/notes`)
  - [ ] Загрузка шрифтов через `typst-kit`
  - [ ] Разрешение пакетов через `typst-kit`
- [ ] `compiler.rs`:
  - [ ] `compile_note()` → HTML/PDF
  - [ ] `compile_vault()` → граф
- [ ] CLI команды: `notes compile`, `notes graph`
- [ ] Тесты:
  - [ ] Компиляция в PDF и HTML
  - [ ] Компиляция vault.typ с графом

**Критерий готовности:** `notes compile notes/task.typ --format html` выдаёт HTML файл.

---

## Phase 6: Tauri MVP

**Что:** Десктопное приложение.

- [ ] Инициализация Tauri v2 + Svelte + Vite
- [ ] Backend commands (обёртки над notes-core)
- [ ] FileTree — навигация по vault
- [ ] Editor — CodeMirror с подсветкой Typst
- [ ] Preview — HTML iframe
- [ ] Search — Cmd+K overlay
- [ ] Link inserter — Cmd+Shift+K
- [ ] NewNote — диалог создания
- [ ] Backlinks — панель под preview
- [ ] Open Vault — подключение к любому vault

**Критерий готовности:** Можно открыть vault, создать заметку, редактировать, видеть preview.

---

## Phase 7+ (будущее)

- tinymist LSP интеграция
- iOS приложение
- `notes watch` — auto-index при изменениях (notify crate)
- `notes-index.json` кеширование по mtime
- Параллельный парсинг (rayon)
- Экспорт в web (статический HTML сайт из vault)
- Flashcard mode для `card` типа
- Пользовательские типы через конфиг

---

## Риски и решения

### 1. AST парсит только литералы

**Риск:** `#show: task.with(id: my-var)` — переменная не будет извлечена.

**Решение:** Документировать, что metadata в `#show: type.with(...)` должна быть литеральной. В будущем — fallback на `typst query` для полной эвалюации.

### 2. Устаревший индекс

**Риск:** После редактирования заметки `notes-index.json` не актуален до `notes index`.

**Решение:**
- CLI: `notes compile` автоматически проверяет mtime и переиндексирует
- Tauri: переиндексирует при сохранении (debounced)
- Framework: graceful handling — `[unknown note]` вместо краша

### 3. World trait сложность

**Риск:** Реализация `World` — нетривиальная задача (разрешение путей, пакетов, шрифтов).

**Решение:** Использовать `typst-kit` helpers + взять за основу `typst-cli/src/world.rs`. Вынести в Phase 5 — не блокирует остальные фазы.

### 4. HTML export незрелый

**Риск:** Typst HTML export экспериментальный, не все фичи работают.

**Решение:** HTML для preview (достаточно для заметок), PDF для финального экспорта. Следить за обновлениями Typst.

### 5. Масштабируемость

**Риск:** 1000+ заметок — медленный `notes index`.

**Решение:**
- `typst_syntax::parse()` быстрый (только синтаксис, без eval)
- Инкрементальный `update_index_for_file()`
- Параллельный парсинг через `rayon` (Phase 7)
- Проверка mtime для пропуска неизменённых файлов

### 6. @local/notes установка

**Риск:** Пользователь должен установить пакет в системную директорию.

**Решение:** `notes init` автоматически копирует пакет. Tauri app делает это при первом запуске. Документировать ручную установку.

### 7. Кросс-платформенные пути

**Риск:** Пути в CSV и JSON могут ломаться между OS (/ vs \).

**Решение:** Всегда использовать `/` как разделитель в CSV и JSON. Конвертировать в нативные пути только при обращении к файловой системе.
