# Tauri Frontend: Svelte + Vite

## Stack

- Svelte 5 (runes)
- Vite
- CodeMirror 6 (editor)
- @tauri-apps/api v2 (IPC)

## Layout

```
┌──────────────────────────────────────────────────┐
│ Toolbar                                           │
├──────────┬───────────────────┬───────────────────┤
│ Sidebar  │ Editor            │ Preview           │
│          │                   │                   │
│ Tree     │ CodeMirror        │ Compiled HTML     │
│          │                   │                   │
│          │                   ├───────────────────┤
│          │                   │ Backlinks         │
├──────────┴───────────────────┴───────────────────┤
│ Statusbar                                         │
└──────────────────────────────────────────────────┘
```

Three resizable panels. Preview + backlinks stacked vertically on the right.

## Components

### App.svelte
- Root layout, three-panel split
- Manages current vault state
- Handles keyboard shortcuts (Cmd+S, Cmd+K, Cmd+N)

### Sidebar (FileTree.svelte)
- Tree view of notes grouped by hierarchy (parent/child)
- Built from `list_notes()` response, grouped by parent field
- Click → open note in editor
- Right-click → context menu (delete, rename)
- "New Note" button at top

### Editor (Editor.svelte)
- CodeMirror 6 instance
- Typst syntax highlighting (codemirror-lang-typst or basic markdown mode)
- On Cmd+S: `save_note()` → `compile_note()` → update preview
- Tracks dirty state (unsaved changes indicator)

### Preview (Preview.svelte)
- Displays compiled HTML from `compile_note()`
- Uses srcdoc on iframe or direct innerHTML
- "Export PDF" button → `compile_note_pdf()` with save dialog

### Backlinks (Backlinks.svelte)
- List of notes linking to the current note
- Calls `get_backlinks(current_id)` when note changes
- Click → navigate to that note

### SearchModal (SearchModal.svelte)
- Cmd+K overlay
- Input field, calls `search_notes()` on keystroke (debounced)
- Results list with keyboard navigation
- Enter → open selected note

### NewNoteDialog (NewNoteDialog.svelte)
- Modal: title input, type dropdown (from `get_vault_types()`)
- Supports path syntax: "parent/child"
- Submit → `create_note()` → open in editor

### Toolbar (Toolbar.svelte)
- Open Vault button (folder picker via Tauri dialog)
- New Note button
- Sync button
- Reindex button

### Statusbar (Statusbar.svelte)
- Vault path
- Note count
- Current note id
- Save status (saved/unsaved)

## Stores (state management)

### vault.ts
- `currentVault`: vault path, note count
- `notes`: NoteMetadata[] from list_notes
- `types`: VaultType[] from get_vault_types
- `refreshNotes()`: re-fetch list after CRUD

### editor.ts
- `currentNote`: id, path, content
- `isDirty`: unsaved changes flag
- `openNote(id)`: read_note → set content
- `saveNote()`: save_note → compile → update preview

### preview.ts
- `previewHtml`: compiled HTML string
- `backlinks`: NoteMetadata[] for current note

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+S | Save + compile |
| Cmd+K | Search modal |
| Cmd+N | New note dialog |
| Cmd+Shift+K | Insert xlink (search + insert) |

## MVP scope

Phase 1 (MVP):
- Open vault
- Tree sidebar
- Editor + preview
- Save + compile
- Search
- Create/delete notes

Phase 2:
- Rename via UI
- Backlinks panel
- PDF export
- Graph view (d3-force)

Phase 3:
- Typst LSP (tinymist) integration for autocomplete
- Tabs for multiple notes
- Drag & drop in tree (move/reparent)
- Settings/preferences
