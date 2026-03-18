# Fix: Compile & Watch via `notes` CLI

## Problem

Currently `notes index` must be run manually before `typst compile`. This is easy to forget and leads to stale backlinks/xlinks. Also, compilation must go through our CLI — not raw `typst` — so we control the output path and auto-indexing.

## Solution

### `notes compile <path>`

```bash
notes compile notes/welcome.typ                # → assets/current.html (default)
notes compile notes/welcome.typ --format pdf    # → assets/current.pdf
notes compile notes/welcome.typ -o out.html     # → custom path
```

Default: always outputs to `assets/current.html`. This is the single preview file that Tauri renders.

Before compiling, checks file mtimes against `notes-index.json`. If any `.typ` is newer — auto-reindexes.

### `notes watch <path>`

```bash
notes watch notes/welcome.typ                  # → assets/current.html, live
```

Same as compile but runs in a loop:
1. Watch the vault directory for `.typ` file changes (via `notify` crate)
2. On change: reindex if stale → recompile target note → write `assets/current.html`
3. Tauri frontend watches `assets/current.html` and refreshes the preview iframe

This is the core integration point with Tauri: user opens a note in the editor, `watch` runs in the background, right panel shows `assets/current.html`.

## Implementation

### `notes-core/src/compiler.rs`

```rust
impl Vault {
    pub fn compile_note(&mut self, path: &Path, output: &Path, format: OutputFormat) -> Result<(), NotesError> {
        self.reindex_if_stale()?;
        // Compile via typst crate + World trait
        // ...
    }

    fn reindex_if_stale(&mut self) -> Result<(), NotesError> {
        let index_mtime = fs::metadata(&self.config.index_file)
            .and_then(|m| m.modified())
            .ok();

        let needs_reindex = self.note_paths()?.iter().any(|p| {
            let path = self.config.root.join(p);
            let file_mtime = fs::metadata(&path).and_then(|m| m.modified()).ok();
            match (file_mtime, index_mtime) {
                (Some(f), Some(i)) => f > i,
                _ => true,
            }
        });

        if needs_reindex {
            self.build_index()?;
        }
        Ok(())
    }
}
```

### `notes-core/src/watch.rs`

```rust
use notify::{Watcher, RecursiveMode, watcher};

impl Vault {
    pub fn watch_and_compile(&mut self, target: &Path, output: &Path, format: OutputFormat) -> Result<(), NotesError> {
        // Initial compile
        self.compile_note(target, output, format)?;

        // Watch loop
        let (tx, rx) = std::sync::mpsc::channel();
        let mut watcher = watcher(tx, Duration::from_millis(500))?;
        watcher.watch(&self.config.notes_dir, RecursiveMode::Recursive)?;

        for event in rx {
            if is_typ_change(&event) {
                self.compile_note(target, output, format)?;
            }
        }
    }
}
```

### CLI

```rust
Commands::Compile { file, format, output } => {
    // Default output: assets/current.html
    let default_output = vault.config.assets_dir.join(format!("current.{}", ext));
    let output = output.unwrap_or(default_output);
    vault.compile_note(&file, &output, format)?;
}

Commands::Watch { file } => {
    let output = vault.config.assets_dir.join("current.html");
    vault.watch_and_compile(&file, &output, OutputFormat::Html)?;
}
```

## Phase

Part of Phase 5 (compilation). `notify` crate dependency added in Phase 5.
Output to `assets/current.html` simplifies future Tauri integration — it just renders this file.

## Blocked by

- `world.rs` — World trait implementation
- `compiler.rs` — programmatic compilation via `typst` crate
