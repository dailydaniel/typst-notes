# Tauri Frontend: Phase 1

## Stack

- Svelte 5 (runes, $state/$derived/$effect)
- Vite 6
- CodeMirror 6 + codemirror-lang-typst (подсветка Typst синтаксиса)
- @tauri-apps/api v2 (IPC invoke)
- @tauri-apps/plugin-dialog (выбор папки)
- @tauri-apps/plugin-fs (чтение/запись vault.typ)

## Layout

```
[≡] [Open] [New] [🔍 Search]     {note-id ●}     [... actions]
├─────────┬──────────────────────┬──────────────────┤
│ All     │                      │                  │
│ Notes   │  Editor (CodeMirror) │  Preview (HTML)  │
│         │                      │                  │
│─────────│                      │                  │
│ Starred │                      │                  │
└─────────┴──────────────────────┴──────────────────┘
```

CSS Grid: `grid-template-columns: var(--sidebar-w, 250px) 1fr 1fr`.
Sidebar скрывается кнопкой ≡. Preview скрывается кнопкой и не показывается для vault.typ.

## Файловая структура

```
notes-app/src/
├── main.ts                     # точка входа (есть)
├── app.css                     # глобальные стили + CSS-переменные
├── App.svelte                  # корневой layout (переписать)
├── lib/
│   ├── types.ts                # TS-интерфейсы (VaultInfo, NoteMetadata, etc.)
│   ├── api.ts                  # типизированные обёртки invoke()
│   ├── state.svelte.ts         # AppState класс с $state/$derived
│   ├── Toolbar.svelte          # верхняя панель
│   ├── Sidebar.svelte          # левая панель: All Notes + Starred
│   ├── Editor.svelte           # CodeMirror 6 обёртка
│   ├── Preview.svelte          # iframe с HTML preview
│   ├── SearchModal.svelte      # Cmd+K поиск
│   ├── CreateNoteModal.svelte  # создание заметки
│   ├── RenameModal.svelte      # переименование
│   └── ActionsMenu.svelte      # "..." меню действий
```

## npm-зависимости (добавить)

```bash
npm install codemirror @codemirror/view @codemirror/state @codemirror/commands @codemirror/language codemirror-lang-typst
```

`codemirror-lang-typst` использует WASM (скомпилирован из typst-syntax). CSP в tauri.conf.json отключён (`"csp": null`), поэтому WASM должен загружаться. Если будут проблемы с загрузкой WASM — разберёмся (vite-plugin-wasm и т.д.), но НЕ откатываемся на markdown подсветку, т.к. синтаксис Typst принципиально отличается.

## Типы (`lib/types.ts`)

```typescript
interface VaultInfo {
  root: string;
  note_count: number;
  types: VaultTypeInfo[];
}

interface VaultTypeInfo {
  name: string;
  fields: [string, string][];  // [field_name, default_value]
}

interface NoteMetadata {
  id: string;
  title: string;
  type: string;       // Rust #[serde(rename = "type")] → JSON ключ "type"
  parent: string | null;
  created: string | null;
  path: string;
  [key: string]: unknown;  // #[serde(flatten)] extra fields
}
```

## API (`lib/api.ts`)

Типизированные обёртки для всех 16 invoke-команд. Имена параметров camelCase (Tauri v2 авто-конвертит в snake_case):

- `openVault(path)` → `VaultInfo`
- `initVault(path)` → `VaultInfo`
- `getVaultTypes()` → `VaultTypeInfo[]`
- `listNotes(noteType?)` → `NoteMetadata[]`
- `createNote(title, noteType)` → `NoteMetadata`
- `deleteNote(id)` → `void`
- `renameNote(oldId, newId)` → `string[]`
- `readNote(id)` → `string`
- `saveNote(id, content)` → `void`
- `compileNote(id)` → `string` (HTML)
- `compileNotePdf(id, output)` → `string`
- `searchNotes(query)` → `NoteMetadata[]`
- `getBacklinks(id)` → `NoteMetadata[]`
- `getGraph()` → `{ nodes, edges }`
- `reindex()` → `number`
- `syncVault()` → `[number, number]`

## State (`lib/state.svelte.ts`)

Класс `AppState` с Svelte 5 runes:

```
Vault:    vault, notes, vaultTypes
Editor:   currentNoteId, currentContent, originalContent, isVaultTyp (boolean)
Derived:  isDirty (content !== original), currentNote, isVaultOpen
UI:       sidebarOpen, previewOpen, searchModalOpen, createModalOpen, renameModalOpen
Preview:  previewHtml
Starred:  starredIds (localStorage), starredNotes (derived)
```

Методы: `toggleStar(id)`, `isStarred(id)`.

Starred хранятся в `localStorage["typst-notes-starred"]` — массив id. Не в vault, т.к. это UI-preference.

Последний открытый vault: `localStorage["typst-notes-last-vault"]` — путь. При старте пытаемся открыть автоматически.

## Компоненты

### App.svelte
- CSS Grid layout (toolbar сверху, три колонки)
- Handler-функции: `handleOpenVault`, `handleOpenNote`, `handleSave`, `handleDelete`, `handleExportPdf`
- `handleOpenNote(id)`: проверяет isDirty → confirm("Save changes?") → да: save+switch, нет: остаться
- `handleSave`: saveNote → compileNote → обновить preview + refreshNotes
- При открытии vault: vault.typ в редактор (без preview), build index
- `$effect` для keyboard shortcuts (Cmd+S, Cmd+K, Cmd+O)
- Условный рендер модалок (SearchModal, CreateNoteModal, RenameModal)

### vault.typ как частный случай
vault.typ — не note (нет id в note-paths.csv), но **редактируется как обычный файл** с полной подсветкой Typst в CodeMirror:
- Чтение: `readTextFile("{vault.root}/vault.typ")` через `@tauri-apps/plugin-fs`
- Сохранение: `writeTextFile(...)` через `@tauri-apps/plugin-fs`
- Preview: не показываем (vault.typ не компилируется в HTML)
- `isVaultTyp` флаг в state управляет скрытием preview

### Toolbar.svelte
Верхняя панель:
- `≡` — toggle sidebar (`appState.sidebarOpen`)
- Open Vault (Cmd+O) — dialog plugin, выбор папки
- New Note — открывает CreateNoteModal
- 🔍 Search (Cmd+K) — открывает SearchModal
- Центр: `{currentNote.id}` + красная точка `●` если dirty
- Справа: `...` → ActionsMenu

### ActionsMenu.svelte
Dropdown при клике на `...`:
- Save (Cmd+S)
- Star / Unstar
- Rename → RenameModal
- Delete → `confirm()` → deleteNote
- Export PDF → compileNotePdf → `~/Downloads/{id}.pdf`

### Sidebar.svelte
- Две вкладки: **All Notes** / **Starred**
- All Notes: плоский список по id, сортировка алфавитная
- Starred: фильтр по starredIds из localStorage
- Клик → `onOpenNote(id)`
- Подсветка текущей заметки

### Editor.svelte
CodeMirror 6 в Svelte 5:
- `onMount()` создаёт `EditorView` с extensions: `basicSetup`, `typst()`, `updateListener`
- Cleanup: `view.destroy()` в return от onMount
- Двусторонняя синхронизация:
  - User typing → `updateListener` → `onContentChange(text)` → `appState.currentContent`
  - Переключение заметки → `$effect` отслеживает `content` prop → `view.dispatch()` заменяет документ
  - Guard `skipNextExternal` предотвращает бесконечный цикл
- CSS: `.cm-editor` растягивается на контейнер (flex: 1, height: 100%)

### Preview.svelte
- `<iframe srcdoc={html}>` — изолированный рендер (sandbox, без конфликтов CSS)
- Показывается только при открытой заметке (не vault.typ) и если previewOpen = true
- Кнопка Hide/Show preview

### SearchModal.svelte
- Overlay модалка, Escape / клик по backdrop закрывает
- Input автофокус
- Результаты в двух секциях:
  1. **По title/id**: локальный фильтр `appState.notes` (мгновенный)
  2. **По содержимому**: `searchNotes(query)` с debounce 200ms (исключая дубли из первой секции)
- Keyboard navigation: стрелки + Enter
- Если нет результатов: "Create '{query}'" — вызывает CreateNoteModal

### CreateNoteModal.svelte
- Поле title + dropdown типов из `appState.vaultTypes`
- Submit → `createNote(title, type)` → refreshNotes → openNote

### RenameModal.svelte
- Поле newId, pre-filled текущим id
- Submit → `renameNote(old, new)` → refreshNotes → обновить currentNoteId

## Порядок реализации

1. **Фундамент**: `types.ts`, `api.ts`, `state.svelte.ts`, `app.css`
2. **Layout + Toolbar**: переписать `App.svelte`, создать `Toolbar.svelte`, Open Vault
3. **Sidebar**: `Sidebar.svelte` с All Notes / Starred, клик → open note
4. **Editor**: npm install CodeMirror, `Editor.svelte` с Typst подсветкой — убедиться что WASM работает
5. **Save + Preview**: Cmd+S → save → compile, `Preview.svelte` с iframe
6. **Search**: `SearchModal.svelte`, Cmd+K, dual search
7. **CRUD**: `CreateNoteModal.svelte`, `RenameModal.svelte`, `ActionsMenu.svelte`, delete с confirm
8. **Polish**: starred persistence, unsaved confirm, toggle sidebar/preview, export PDF, last vault, loading states

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+S | Save + compile preview |
| Cmd+K | Search modal |
| Cmd+O | Open vault |

## Риски

- **codemirror-lang-typst WASM** в Tauri webview — проверить при step 4. Если не грузится, попробовать vite-plugin-wasm. Не откатываться на markdown.
- **CodeMirror ↔ Svelte 5 loop** — guard flag `skipNextExternal`
- **compile_note latency** — subprocess `typst`, 1-3 сек. Показать loading в preview.
- **Tauri camelCase → snake_case** — проверить для noteType, oldId, newId.

## Будущие фазы

Phase 2:
- Graph view (d3-force / cytoscape)
- Backlinks как отдельная панель (если нужно помимо рендера в заметке)
- Tabs для нескольких открытых заметок

Phase 3:
- Tinymist LSP (autocomplete, go-to-definition, ошибки)
- Drag & drop, настройки, темы
