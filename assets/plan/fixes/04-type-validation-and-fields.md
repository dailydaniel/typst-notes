# Fix: CLI type validation and field generation from vault.typ

## Problem

1. `notes new "x" --type banana` doesn't validate — creates a note with unknown type
2. Note types can have required fields (e.g., `repo` needs `link`, `description`), but CLI doesn't know about them
3. No extra config files — vault.typ is the single source of truth for types

## Solution

### Type definitions in vault.typ

Users define types with optional `fields` parameter:

```typst
#let note = (vault.note-type)("note")
#let task = (vault.note-type)("task", fields: (status: "", priority: ""))
#let repo = (vault.note-type)("repo", fields: (link: "", description: ""))
#let card = (vault.note-type)("card")
```

`fields` is a dictionary of field names with default values. These are the fields that CLI will generate as empty/default when creating a note of this type.

### CLI parses vault.typ

When running `notes new`, CLI:

1. Reads `vault.typ` from the vault root
2. Parses it with `typst-syntax` AST
3. Extracts all type definitions: finds `let` bindings where the value is a `(vault.note-type)("name", ...)` call
4. Validates `--type` against known types → error if unknown
5. Extracts `fields` for the type → generates them as empty values in the new note

### AST extraction

In vault.typ, a type definition looks like:

```typst
#let repo = (vault.note-type)("repo", fields: (link: "", description: ""))
```

AST structure:
- `LetBinding` with name = `repo`
- Value = `FuncCall`
  - Callee = `Parenthesized(FieldAccess(Ident("vault"), "note-type"))`
  - Positional arg = `Str("repo")` — type name
  - Named arg `fields` = `Dict((link: "", description: ""))` — field definitions

New function: `extract_vault_types(source: &str) -> Vec<VaultType>`

```rust
pub struct VaultType {
    pub name: String,
    pub fields: Vec<(String, String)>, // (field_name, default_value)
}
```

### Generated note

```bash
notes new "my-project" --type repo
```

Generates:
```typst
#import "../vault.typ": *

#show: repo.with(
  title: "my-project",
  link: "",
  description: "",
)
```

### Error on unknown type

```bash
notes new "x" --type banana
# Error: unknown note type "banana". Available types: note, task, repo, card
```

## Implementation

### `notes-core/src/ast.rs`

Add `extract_vault_types()`:
- Walk AST for `LetBinding` nodes
- Match callee pattern: `Parenthesized(FieldAccess(_, "note-type"))`
- Extract type name from first positional arg
- Extract fields from `fields` named arg (Dict expression)

### `notes-core/src/vault.rs`

Add `Vault::note_types() -> Vec<VaultType>`:
- Reads vault.typ
- Calls `extract_vault_types()`

### `notes-core/src/note.rs`

Update `new_note()`:
- Accept fields from vault type definition
- Merge with any extra fields passed via CLI
- Generate note content with all fields

Update auto-parent creation:
- When `notes new "a/b/c"` auto-creates parents `a` and `a/b`, look up type `"note"` in vault types
- If `note` type has `fields` defined (e.g., `fields: (tags: "", links: "")`), generate them in the auto-created parent
- Currently parent type `"note"` is hardcoded — keep that, but now also include its fields from vault.typ

### `notes-cli`

Update `new_note` command:
- Call `vault.note_types()` to get available types
- Validate `--type` against them
- Pass type's fields to `new_note()`

### Framework: `notes-framework/src/note-type.typ`

`make-note-type` already accepts `..extra` in the constructor, so user-defined fields work without changes. The `fields` parameter in `(vault.note-type)("repo", fields: (...))` is consumed by CLI only — the framework ignores it (it goes into the function's arguments but doesn't affect rendering).

## Phase

Pre-Tauri improvement. No new config files — vault.typ is the single source of truth.
