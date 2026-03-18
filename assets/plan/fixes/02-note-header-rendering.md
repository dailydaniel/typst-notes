# Fix: Note header rendering

## Problem

Currently the note type constructor only renders the body. Metadata (type, tags, parent, custom fields) is invisible in the compiled output. Title is duplicated — user writes both `title: "closures"` in the show rule and `= closures` as a heading.

## Solution

### Auto-render title as heading

The constructor renders `title` as a heading automatically. No need to write `= Title` manually in the `.typ` file.

### Metadata block with all properties

Render a frontmatter-style block below the title showing **all** properties: title, type, id, parent, created, and any custom fields (tags, difficulty, link, etc.).

### `show-meta` flag

The note type constructor accepts a `show-meta` parameter (default: `true`). When `false`, only the title heading is rendered — the metadata block is hidden.

Usage in vault.typ:
```typst
#let note = (vault.note-type)("note")              // metadata shown
#let note-clean = (vault.note-type)("note", show-meta: false)  // title only
```

Or per-note:
```typst
#show: card.with(
  title: "closures",
  show-meta: false,
)
```

### `@id` references in properties

Properties can contain references to other notes using the `@id` string convention:

```typst
#show: card.with(
  title: "closures",
  tags: ("rust", "fp", "@programming/python"),
  related: "@programming/rust/traits",
)
```

Two systems handle `@id`:

1. **Framework (note-type.typ)**: When rendering a property value, strings starting with `@` are rendered as clickable links (title resolved from index). Other strings render as plain text.

2. **Rust parser (ast.rs)**: When extracting property values, strings starting with `@` are added to the `links` list in the index (with `@` stripped). This way `notes index` captures cross-references from properties.

This keeps properties as pure strings (no content/function calls), works with regular `typst compile`, and links are indexed by `notes index`.

For inline links in body text, use `#xlink("id")` as before.

### Rendered output

Default (`show-meta: true`):
```
= closures                         ← auto from title

┌──────────────────────────────────┐
│ title: closures                  │
│ type: card                       │
│ id: programming/rust/closures    │
│ parent: programming/rust         │
│ tags: rust, fp, python →         │  ← @id rendered as link
│ difficulty: hard                 │
│ created: 2026-03-18              │
└──────────────────────────────────┘

Body content here...

--- Backlinks ---
```

With `show-meta: false`:
```
= closures                         ← auto from title

Body content here...

--- Backlinks ---
```

### Note file format (after fix)

```typst
#import "../vault.typ": *

#show: card.with(
  title: "closures",
  tags: ("rust", "fp", "@programming/python"),
  difficulty: "hard",
)

Body content here — no need to write `= closures`.
```

## Implementation

### Framework: `notes-framework/src/note-type.typ`

```typst
#let make-note-type(note-state, type-name, index, show-meta: true) = {
  (title: "", created: none, ..extra, body) => {
    heading(title)

    if show-meta {
      // Render metadata block
      // For each value: if string starts with "@", look up in index
      // and render as link. Otherwise render as plain text.
      // Arrays: process each element individually.
    }

    body
    // Backlinks...
  }
}
```

### Rust parser: `notes-core/src/ast.rs`

In `extract_note_constructor()`, when processing extra fields:
- Call `expr_to_json_value()` as before
- Additionally scan string values for `@` prefix
- If found, strip `@` and add to links list
- Also scan arrays of strings for `@` prefixed values

## Phase

Framework + Rust parser improvement. No `notes compile` needed.
