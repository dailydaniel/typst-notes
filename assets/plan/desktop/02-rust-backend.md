# Tauri Backend: Rust Commands

## Overview

Thin wrappers over `notes-core::Vault`. The Tauri app holds a `Vault` in managed state. All commands access it via `tauri::State`.

## App State

```rust
use std::sync::Mutex;
use notes_core::vault::Vault;

pub struct AppState {
    pub vault: Mutex<Option<Vault>>,
}
```

`Mutex<Option<Vault>>` — None until a vault is opened. Commands return error if vault not opened.

## Commands

### Vault management

```rust
#[tauri::command]
fn open_vault(state: State<AppState>, path: String) -> Result<VaultInfo, String>
```
- Calls `Vault::open(&path)`, stores in state
- Calls `vault.load_index()` (or `build_index()` if index missing)
- Returns `VaultInfo { root, note_count, type_names }`

```rust
#[tauri::command]
fn init_vault(state: State<AppState>, path: String) -> Result<VaultInfo, String>
```
- Calls `Vault::init(&path)`, stores in state

```rust
#[tauri::command]
fn get_vault_types(state: State<AppState>) -> Result<Vec<VaultType>, String>
```
- Calls `vault.note_types()`
- Frontend needs this for "new note" type dropdown

### Notes CRUD

```rust
#[tauri::command]
fn list_notes(state: State<AppState>, note_type: Option<String>) -> Result<Vec<NoteMetadata>, String>
```
- Calls `vault.list_notes(note_type.as_deref())`

```rust
#[tauri::command]
fn create_note(state: State<AppState>, title: String, note_type: String) -> Result<NoteMetadata, String>
```
- Calls `vault.new_note(&title, &note_type, &[])`
- Auto-reindexes after creation

```rust
#[tauri::command]
fn delete_note(state: State<AppState>, id: String) -> Result<(), String>
```
- Calls `vault.delete_note(&id)`

```rust
#[tauri::command]
fn rename_note(state: State<AppState>, old_id: String, new_id: String) -> Result<Vec<String>, String>
```
- Calls `vault.rename_note(&old_id, &new_id)`
- Returns list of renamed ids (includes children)

### File read/write

```rust
#[tauri::command]
fn read_note(state: State<AppState>, id: String) -> Result<String, String>
```
- Resolves id → path via `types::id_to_path()`
- Returns file content as string

```rust
#[tauri::command]
fn save_note(state: State<AppState>, id: String, content: String) -> Result<(), String>
```
- Writes content to file
- Calls `vault.update_index_for_file()` for incremental reindex

### Compile

```rust
#[tauri::command]
fn compile_note(state: State<AppState>, id: String) -> Result<String, String>
```
- Calls `vault.reindex_if_stale()`
- Calls `vault.compile_note()` with format "html" to a temp file
- Reads the HTML output and returns as string
- Frontend displays in iframe/webview

```rust
#[tauri::command]
fn compile_note_pdf(state: State<AppState>, id: String, output: String) -> Result<String, String>
```
- Same but format "pdf", writes to user-chosen path
- Returns output path

### Search & navigation

```rust
#[tauri::command]
fn search_notes(state: State<AppState>, query: String) -> Result<Vec<NoteMetadata>, String>
```
- Calls `vault.search(&query)`

```rust
#[tauri::command]
fn get_backlinks(state: State<AppState>, id: String) -> Result<Vec<NoteMetadata>, String>
```
- Calls `vault.backlinks(&id)`

### Graph

```rust
#[tauri::command]
fn get_graph(state: State<AppState>) -> Result<GraphData, String>
```
- Calls `vault.graph_data()`
- Frontend renders with d3/cytoscape

### Index management

```rust
#[tauri::command]
fn reindex(state: State<AppState>) -> Result<usize, String>
```
- Calls `vault.build_index()`
- Returns note count

```rust
#[tauri::command]
fn sync_vault(state: State<AppState>) -> Result<(usize, usize), String>
```
- Calls `vault.sync()`
- Returns (added, removed)

## File structure

```
notes-app/src-tauri/src/
├── main.rs        # Tauri setup, register commands, manage state
├── commands.rs    # All #[tauri::command] functions
└── state.rs       # AppState struct
```

## Dependencies (Cargo.toml)

```toml
[dependencies]
notes-core = { path = "../notes-core" }
tauri = { version = "2", features = [] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

## Error handling

All commands return `Result<T, String>`. Map `NotesError` to `String`:

```rust
fn map_err(e: NotesError) -> String {
    e.to_string()
}
```

Tauri serializes `Err(String)` as a rejection to the frontend `invoke()` promise.

## Notes

- `compile_note` returns HTML as string — no need for file watcher in Tauri, frontend calls compile on save
- `save_note` + `compile_note` are called sequentially by frontend on Cmd+S
- `Mutex<Option<Vault>>` is safe because Tauri commands run on a thread pool, not the main thread
- For watch mode: not needed in Tauri. Frontend triggers compile on save. File watcher (notify) only needed if external editor modifies files — can add later via Tauri events
