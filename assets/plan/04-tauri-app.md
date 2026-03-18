# Tauri-приложение: notes-app

## Обзор

Тонкая GUI-обёртка над `notes-core`. Подключается к **любому vault** (директория с `vault.typ`). Синхронизация — через git на уровне файлов, без app-level sync.

**Стек:** Tauri v2 + Svelte + Vite + CodeMirror

## Ключевые принципы

1. **Подключаемый vault** — приложение не создаёт свой формат, а открывает существующий vault
2. **Портативность** — vault = папка с файлами, можно перекинуть на другое устройство или синхронизировать через GitHub
3. **notes-core как зависимость** — backend вызывает те же функции, что и CLI
4. **iOS в перспективе** — Tauri v2 поддерживает iOS, Rust crates работают на iOS

## Структура

```
notes-app/
├── Cargo.toml                    # Зависимость: notes-core
├── tauri.conf.json
├── capabilities/                 # Tauri v2 permission system
│   └── default.json
├── src-tauri/
│   └── src/
│       ├── main.rs               # Tauri entry point
│       ├── commands.rs           # Tauri command handlers
│       └── state.rs              # App state
└── src/                          # Frontend (Svelte)
    ├── App.svelte
    ├── main.ts
    ├── lib/
    │   ├── FileTree.svelte       # Панель файлов
    │   ├── Editor.svelte         # CodeMirror + Typst syntax
    │   ├── Preview.svelte        # HTML превью
    │   ├── SearchModal.svelte    # Cmd+K поиск
    │   ├── Backlinks.svelte      # Панель backlinks
    │   └── NewNote.svelte        # Создание заметки
    └── stores/
        ├── vault.ts              # Состояние vault
        └── editor.ts             # Состояние редактора
```

## Backend: Tauri Commands

Все команды — обёртки над `notes-core::Vault`:

```rust
#[tauri::command]
fn open_vault(path: String) -> Result<VaultInfo, String>;
// → Vault::open(&path)

#[tauri::command]
fn list_notes(r#type: Option<String>) -> Result<Vec<NoteMetadata>, String>;
// → vault.list_notes(type)

#[tauri::command]
fn read_note(path: String) -> Result<String, String>;
// → fs::read_to_string(vault_root / path)

#[tauri::command]
fn save_note(path: String, content: String) -> Result<(), String>;
// → fs::write(vault_root / path, content)
// → vault.update_index_for_file(path)  // авто-переиндексация

#[tauri::command]
fn create_note(title: String, note_type: String) -> Result<NoteMetadata, String>;
// → vault.new_note(title, type, ...)

#[tauri::command]
fn compile_note(path: String) -> Result<String, String>;
// → vault.compile_note(path, format: Html) → возвращает HTML строку

#[tauri::command]
fn search_notes(query: String) -> Result<Vec<NoteMetadata>, String>;
// → vault.search(query)

#[tauri::command]
fn get_backlinks(id: String) -> Result<Vec<NoteMetadata>, String>;
// → vault.backlinks(id)

#[tauri::command]
fn delete_note(id: String) -> Result<(), String>;
// → vault.delete_note(id)

#[tauri::command]
fn sync_vault() -> Result<SyncResult, String>;
// → vault.sync() — синхронизировать CSV с файлами + reindex
// Полезно после git pull или sync через iCloud

#[tauri::command]
fn reindex() -> Result<usize, String>;
// → vault.build_index() — полный reindex без sync
```

## Frontend: Компоненты

### Layout

```
┌──────────────────────────────────────────────────┐
│ Toolbar: [Open Vault] [New Note] [Export]         │
├──────────┬───────────────────┬───────────────────┤
│ FileTree │ Editor            │ Preview           │
│          │ (CodeMirror)      │ (HTML iframe)     │
│ notes/   │                   │                   │
│  ├ note1 │ #import "vault..  │ ┌───────────────┐ │
│  ├ note2 │ #show: task.with( │ │ Rendered HTML │ │
│  └ note3 │   id: "task-001", │ │               │ │
│          │   title: "...",   │ └───────────────┘ │
│          │ )                 │                   │
│          │                   │ ─── Backlinks ─── │
│          │ = My Note         │ • Note 2          │
│          │ Content here...   │ • Note 5          │
├──────────┴───────────────────┴───────────────────┤
│ Status: vault: /path/to/vault | 42 notes         │
└──────────────────────────────────────────────────┘
```

### FileTree
- Отображает содержимое vault: `vault.typ`, `notes/*.typ`
- Клик → открывает заметку в редакторе
- Контекстное меню: удалить, переименовать

### Editor
- **CodeMirror 6** с Typst language mode
- **tinymist LSP** (этап 3) для автодополнения
- При сохранении (Cmd+S) → `save_note()` + `compile_note()` → обновить Preview

### Preview
- HTML iframe с результатом `compile_note()`
- Обновляется при сохранении
- Кнопка PDF экспорта

### SearchModal (Cmd+K)
- Overlay с fuzzy-поиском по заметкам
- По выбору → открывает заметку в редакторе

### LinkInserter (Cmd+Shift+K)
- Тот же поиск, но вместо открытия → вставляет `#xlink(id: "selected-id")` в редактор

### Backlinks
- Панель под Preview
- Показывает заметки, ссылающиеся на текущую
- Клик → открывает заметку

### NewNote
- Диалог: title, type (dropdown), parent, tags
- При создании → `create_note()` → открывает в редакторе

## Подключение к стороннему vault

```
1. File → Open Vault → выбрать папку
2. Приложение ищет vault.typ в папке
3. Если найден → загружает vault (list_notes, load index)
4. Если не найден → предложить: "Create vault here?" или "Not a vault"
```

**Сценарии:**
- Перекинуть папку vault на другой компьютер → открыть в приложении
- `git clone` vault → открыть в приложении
- iCloud/Dropbox синхронизация папки → работает прозрачно

## Синхронизация

**Нет app-level синхронизации.** Vault — это папка с файлами:
- Git: `git add . && git commit && git push`
- iCloud/Dropbox: автоматическая синхронизация папки
- USB: скопировать папку

Приложение не знает о синхронизации. Оно просто работает с файлами на диске.

## iOS (Tauri v2)

**Статус:** Tauri v2 поддерживает iOS (стабильно с 2025).

**Ограничения:**
- File system — sandbox, доступ через `tauri-plugin-fs`
- Требуется Apple Developer Program ($99/год)
- Xcode для сборки (только macOS)

**Подход для iOS:**
- Vault хранится в App Documents directory
- Синхронизация через iCloud Drive (нативно) или git
- Упрощённый UI (без split-view, одна панель)
- Те же `notes-core` функции через Tauri IPC

**Реализация — этап 6+**, после стабилизации десктопа.

## Зависимости

### Rust (src-tauri/Cargo.toml)
```toml
[dependencies]
notes-core = { path = "../../notes-core" }
tauri = { version = "2", features = ["shell-open"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

### Frontend (package.json)
```json
{
  "dependencies": {
    "@tauri-apps/api": "^2",
    "codemirror": "^6",
    "@codemirror/lang-markdown": "^6"
  },
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "^4",
    "vite": "^6"
  }
}
```
