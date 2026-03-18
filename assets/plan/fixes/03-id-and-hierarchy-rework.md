# Fix: ID system and hierarchy rework

## Problems

1. `id` field in `#show: note.with(id: "...")` is redundant — it's just slug(title)
2. `--parent` and `--tags` CLI flags are confusing and disconnected from the graph
3. No hierarchical note structure
4. User shouldn't manage ids manually

## Solution

### ID = slug of full path through parents

The identifier is the full parent chain, not just the note name.

```
notes new "programming/rust/closures" --type card
```

Creates:
- `closures` with parent=`rust`, id=`programming/rust/closures`
- `rust` with parent=`programming`, id=`programming/rust` (auto-created if missing, type: note)
- `programming` with parent=none, id=`programming` (auto-created if missing, type: note)

### Filename = slug of full path with `--` separator

Files stay flat in `notes/`:
```
notes/programming.typ                    → id: "programming"
notes/programming--rust.typ              → id: "programming/rust"
notes/programming--rust--closures.typ    → id: "programming/rust/closures"
notes/math--topology--closures.typ       → id: "math/topology/closures"
```

`--` separator avoids conflicts with single `-` in slugified words (e.g., "rust-basics" stays "rust-basics", hierarchy uses "--").

### Remove `id` from show rule

The note no longer declares its id. The AST parser derives it from the filename.

Before:
```typst
#show: card.with(
  id: "closures",
  title: "Closures",
  parent: "rust-basics",
  tags: ("rust"),
)
```

After:
```typst
#show: card.with(
  title: "Closures",
)
```

- `id` — derived from filename by the Rust AST parser
- `parent` — derived from filename (everything before last `--` segment)
- No `tags` field (was confusing, use xlinks for connections)

### Remove `--parent` and `--tags` CLI flags

- `--parent` is replaced by path syntax: `notes new "parent/child"`
- `--tags` removed entirely — use xlinks for connections between notes

### Auto-creation of parent chain

```bash
notes new "programming/rust/closures" --type card
```

Algorithm:
1. Parse path segments: `["programming", "rust", "closures"]`
2. For each segment from root to leaf:
   - Check if note exists (by looking for the file)
   - If not, create it with type `note` (default)
3. Last segment gets the specified `--type`
4. Each note's parent is the previous segment

### xlink works by id (= path)

```typst
#xlink("programming/rust")           // links to rust note
#xlink("programming/rust/closures")  // links to closures note
```

Resolved via index lookup. Renders target's title.

### Custom note types with fields

Note types define a field template. When creating a note, empty fields are included:

```bash
notes new "repos/my-project" --type repo
```

Generates:
```typst
#show: repo.with(
  title: "my-project",
  link: "",
  description: "",
)
```

Type definitions in vault.typ:
```typst
#let repo = (vault.note-type)("repo", fields: (link: "", description: ""))
```

### Default fields for all note types

Every note has: `title` (required). That's it for the show rule.
`id` and `parent` are derived from the filename, not stored in the note.

## Impact on existing code

### AST parser (`ast.rs`)
- Remove `id` extraction from show rule
- Derive id from filename: `programming--rust--closures.typ` → `programming/rust/closures`
- Derive parent from id: `programming/rust/closures` → parent: `programming/rust`
- Keep extracting `title`, `type`, and custom fields

### CSV registry
- Paths now use `--` separator: `notes/programming--rust--closures.typ`

### Note creation (`note.rs`)
- Parse `/` in title as hierarchy separator
- Generate `--` filenames
- Auto-create parent notes
- Remove `--parent` and `--tags` params

### Index
- `id` field = derived from path, not from show rule
- `parent` field = derived from path
- Remove `tags` field (or keep as optional custom field)

### CLI
- Remove `--parent` and `--tags` from `notes new`
- `notes new "a/b/c" --type task` is the primary interface

## Migration

Existing notes with `id:` in show rule will still parse (id from show rule takes precedence as fallback), but new notes won't have it.
