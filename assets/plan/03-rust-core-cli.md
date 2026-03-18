# Rust: notes-core + notes-cli

## Обзор

- `notes-core` — библиотечный crate, ядро логики
- `notes-cli` — тонкий бинарник, CLI-обёртка над notes-core
- Tauri-приложение также использует notes-core как зависимость

## Зависимости notes-core

```toml
[dependencies]
typst-syntax = "0.14"     # AST-парсинг .typ файлов
typst = "0.14"             # Программная компиляция
typst-kit = "0.14"         # Шрифты, пакеты
serde = { version = "1", features = ["derive"] }
serde_json = "1"
csv = "1"
thiserror = "2"
chrono = { version = "0.4", features = ["serde"] }
slug = "0.1"               # Генерация id из title
```

## Зависимости notes-cli

```toml
[dependencies]
notes-core = { path = "../notes-core" }
clap = { version = "4", features = ["derive"] }
colored = "2"
serde_json = "1"
```

---

## Структура notes-core

```
notes-core/src/
├── lib.rs                # Реэкспорт public API
├── types.rs              # Все типы данных
├── error.rs              # NotesError
├── vault.rs              # Vault struct: init(), open(), discover()
├── note.rs               # Создание заметок, генерация шаблонов
├── ast.rs                # AST-парсинг через typst-syntax
├── index.rs              # Построение и запись notes-index.json
├── compiler.rs           # Компиляция через typst crate
├── world.rs              # NotesWorld: impl World trait
├── query.rs              # Поиск и фильтрация по индексу
├── csv_registry.rs       # Чтение/запись note-paths.csv
└── graph.rs              # Генерация данных графа
```

---

## types.rs — Типы данных

```rust
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Метаданные одной заметки (извлекаются из AST)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteMetadata {
    pub id: String,
    pub title: String,
    #[serde(rename = "type")]
    pub note_type: String,              // "note", "task", "card", "tag"
    pub parent: Option<String>,
    pub tags: Vec<String>,
    pub created: Option<String>,        // ISO 8601
    pub path: String,                   // относительный путь от vault root
    #[serde(flatten)]
    pub extra: serde_json::Map<String, serde_json::Value>,
}

/// Ссылка между заметками (извлечена из xlink вызова)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteLink {
    pub source: String,                 // id заметки-источника
    pub target: String,                 // id целевой заметки
    pub source_path: String,
}

/// Полный индекс vault
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NotesIndex {
    pub version: u32,                   // 1
    pub generated_at: String,           // ISO 8601
    pub notes: Vec<NoteMetadata>,
    pub links: Vec<NoteLink>,
}

/// Конфигурация vault (пути)
#[derive(Debug, Clone)]
pub struct VaultConfig {
    pub root: PathBuf,
    pub note_paths_file: PathBuf,       // vault_root/note-paths.csv
    pub index_file: PathBuf,            // vault_root/notes-index.json
    pub notes_dir: PathBuf,             // vault_root/notes/
    pub assets_dir: PathBuf,            // vault_root/assets/
}

/// Определение типа заметки
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteType {
    pub name: String,
    pub fields: Vec<NoteTypeField>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteTypeField {
    pub name: String,
    pub field_type: String,             // "str", "datetime", "content", "array"
    pub required: bool,
}
```

---

## error.rs — Ошибки

```rust
use thiserror::Error;
use std::path::PathBuf;

#[derive(Error, Debug)]
pub enum NotesError {
    #[error("Vault not found: no vault.typ in {0} or parent directories")]
    VaultNotFound(PathBuf),

    #[error("Vault already exists at {0}")]
    VaultAlreadyExists(PathBuf),

    #[error("Note not found: {0}")]
    NoteNotFound(String),

    #[error("Duplicate note id: {0}")]
    DuplicateId(String),

    #[error("Invalid note type: {0}")]
    InvalidNoteType(String),

    #[error("AST parsing error in {file}: {message}")]
    AstError { file: String, message: String },

    #[error("Compilation error: {0}")]
    CompileError(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}
```

---

## vault.rs — Управление vault

```rust
pub struct Vault {
    pub config: VaultConfig,
    pub index: Option<NotesIndex>,
}

impl Vault {
    /// Создать новый vault в указанной директории.
    /// Создаёт: vault.typ, note-paths.csv, notes/, assets/, welcome.typ
    /// Устанавливает @local/notes пакет если не установлен.
    pub fn init(path: &Path) -> Result<Vault, NotesError>;

    /// Открыть существующий vault (найти vault.typ в директории).
    pub fn open(path: &Path) -> Result<Vault, NotesError>;

    /// Найти vault root, поднимаясь по директориям от path.
    pub fn discover(path: &Path) -> Result<PathBuf, NotesError>;

    /// Загрузить индекс из notes-index.json.
    pub fn load_index(&mut self) -> Result<&NotesIndex, NotesError>;

    /// Получить пути заметок из CSV.
    pub fn note_paths(&self) -> Result<Vec<String>, NotesError>;
}
```

**`Vault::init(path)` генерирует:**

1. `vault.typ` — шаблон с import, типами, форматтерами, графом
2. `note-paths.csv` — с одной записью `notes/welcome.typ`
3. `notes/welcome.typ` — приветственная заметка типа "note"
4. `notes/` и `assets/` директории
5. Копирует `@local/notes` в системную директорию пакетов Typst

**`Vault::discover(path)`:**
- Ищет `vault.typ` начиная с `path`, поднимаясь вверх
- Аналог `git rev-parse --show-toplevel`

---

## note.rs — Создание заметок

```rust
impl Vault {
    /// Создать новую заметку.
    pub fn new_note(
        &self,
        title: &str,
        note_type: &str,         // "note", "task", "card", "tag"
        id: Option<&str>,        // если None — генерируется из title
        parent: Option<&str>,
        tags: &[&str],
        extra_fields: &[(&str, &str)],
    ) -> Result<NoteMetadata, NotesError>;

    /// Сгенерировать Typst-код для заметки.
    fn generate_note_content(
        &self,
        id: &str,
        title: &str,
        note_type: &str,
        parent: Option<&str>,
        tags: &[&str],
        extra_fields: &[(&str, &str)],
    ) -> String;

    /// Сгенерировать уникальный ID из title.
    fn generate_id(&self, title: &str) -> Result<String, NotesError>;

    /// Удалить заметку: файл + CSV.
    pub fn delete_note(&self, id: &str) -> Result<(), NotesError>;
}
```

**Генерация ID:**
1. Slugify: `"My Task Title"` → `"my-task-title"`
2. Проверка уникальности в индексе/CSV
3. При коллизии: `my-task-title-2`, `my-task-title-3`, ...

**Шаблон генерируемой заметки:**

```typst
#import "vault.typ": *

#show: {type}.with(
  id: "{id}",
  title: "{title}",
  {extra_fields}
)

= {title}

```

---

## ast.rs — AST-парсинг (ключевой модуль)

Парсит `.typ` файлы через `typst-syntax` и извлекает метаданные + ссылки без компиляции.

```rust
use typst_syntax::{self, ast, SyntaxNode};

/// Результат парсинга одного .typ файла
#[derive(Debug)]
pub struct AstExtraction {
    pub metadata: Option<NoteMetadata>,
    pub links: Vec<String>,             // target ids из xlink вызовов
}

/// Парсить файл и извлечь metadata + links.
pub fn extract_from_file(
    source: &str,
    file_path: &str,
) -> Result<AstExtraction, NotesError>;
```

### Алгоритм AST-парсинга

1. `typst_syntax::parse(source)` → `SyntaxNode` (корень дерева)
2. Рекурсивный обход всех children
3. Ищем два паттерна:

**Паттерн 1: `#show: type.with(id: "...", title: "...", ...)`**

```
ShowRule
  └── FuncCall (callee: FieldAccess)
        ├── target: Ident ("task")
        ├── field: "with"
        └── Args
              ├── Named("id", Str("task-001"))
              ├── Named("title", Str("Build MVP"))
              └── Named("tags", Array(Str("tag-dev")))
```

Извлекаем:
- `type` из Ident перед `.with`
- Все named args как поля NoteMetadata

**Паттерн 2: `#xlink(id: "...")`**

```
FuncCall (callee: Ident("xlink"))
  └── Args
        └── Named("id", Str("other-note"))
```

Извлекаем: `target = "other-note"`

### Реализация (скетч)

```rust
pub fn extract_from_file(source: &str, file_path: &str) -> Result<AstExtraction, NotesError> {
    let root = typst_syntax::parse(source);
    let mut metadata = None;
    let mut links = Vec::new();
    walk_node(&root, &mut metadata, &mut links, file_path);
    Ok(AstExtraction { metadata, links })
}

fn walk_node(node: &SyntaxNode, metadata: &mut Option<NoteMetadata>,
             links: &mut Vec<String>, file_path: &str) {
    // Проверяем ShowRule: #show: task.with(...)
    if let Some(show_rule) = node.cast::<ast::ShowRule>() {
        if let Some(ast::Expr::FuncCall(call)) = show_rule.transform() {
            if let Some(meta) = extract_note_constructor(call, file_path) {
                *metadata = Some(meta);
            }
        }
    }

    // Проверяем FuncCall: #xlink(id: "...")
    if let Some(func_call) = node.cast::<ast::FuncCall>() {
        if let Some(target_id) = extract_xlink(func_call) {
            links.push(target_id);
        }
    }

    // Рекурсия
    for child in node.children() {
        walk_node(child, metadata, links, file_path);
    }
}

fn extract_note_constructor(call: ast::FuncCall, file_path: &str) -> Option<NoteMetadata> {
    // Ищем паттерн: something.with(...)
    if let ast::Expr::FieldAccess(fa) = call.callee() {
        if fa.field().get() != "with" { return None; }

        let type_name = match fa.target() {
            ast::Expr::Ident(id) => id.get().to_string(),
            _ => return None,
        };

        let mut id = None;
        let mut title = None;
        let mut parent = None;
        let mut tags = Vec::new();
        let mut extra = serde_json::Map::new();

        for arg in call.args().items() {
            if let ast::Arg::Named(named) = arg {
                match named.name().get() {
                    "id" => id = expr_to_string(named.expr()),
                    "title" => title = expr_to_string(named.expr()),
                    "parent" => parent = expr_to_string(named.expr()),
                    "tags" => tags = expr_to_string_array(named.expr()),
                    "created" => { /* parse datetime */ },
                    key => {
                        if let Some(val) = expr_to_string(named.expr()) {
                            extra.insert(key.into(), val.into());
                        }
                    }
                }
            }
        }

        return Some(NoteMetadata {
            id: id?,
            title: title?,
            note_type: type_name,
            parent, tags,
            created: None,
            path: file_path.to_string(),
            extra,
        });
    }
    None
}

fn extract_xlink(call: ast::FuncCall) -> Option<String> {
    if let ast::Expr::Ident(id) = call.callee() {
        if id.get() == "xlink" {
            for arg in call.args().items() {
                if let ast::Arg::Named(named) = arg {
                    if named.name().get() == "id" {
                        return expr_to_string(named.expr());
                    }
                }
            }
        }
    }
    None
}

/// Извлечь строку из AST-выражения (только литералы!)
fn expr_to_string(expr: ast::Expr) -> Option<String> {
    match expr {
        ast::Expr::Str(s) => Some(s.get().to_string()),
        _ => None,  // Переменные и выражения не поддерживаются
    }
}

/// Извлечь массив строк из AST-выражения
fn expr_to_string_array(expr: ast::Expr) -> Vec<String> {
    if let ast::Expr::Array(arr) = expr {
        arr.items()
            .filter_map(|item| {
                if let ast::ArrayItem::Pos(expr) = item {
                    expr_to_string(expr)
                } else { None }
            })
            .collect()
    } else {
        Vec::new()
    }
}
```

### Ограничения AST-парсинга

**Работает только с литералами.** Если пользователь пишет:
```typst
#let my-id = "task-001"
#show: task.with(id: my-id)  // AST видит Ident("my-id"), не "task-001"
```
...то id не будет извлечён. Документация должна требовать литеральные значения в `#show: type.with(...)`.

**Будущая альтернатива:** Использовать `typst::compile()` + `typst query "<note-meta>"` для полной эвалюации. Это медленнее, но работает с любыми выражениями.

---

## index.rs — Построение индекса

```rust
impl Vault {
    /// Перестроить индекс: парсить все заметки из CSV, записать JSON.
    pub fn build_index(&mut self) -> Result<usize, NotesError>;

    /// Инкрементально обновить индекс для одного файла.
    pub fn update_index_for_file(&mut self, path: &Path) -> Result<(), NotesError>;

    /// Записать индекс на диск.
    fn write_index(&self) -> Result<(), NotesError>;
}
```

**`build_index()` алгоритм:**
1. Прочитать `note-paths.csv` → массив путей
2. Для каждого пути: `read_to_string` → `ast::extract_from_file()`
3. Собрать `Vec<NoteMetadata>` и `Vec<NoteLink>`
4. Записать `NotesIndex` в `notes-index.json`
5. Вернуть количество проиндексированных заметок

**Инкрементальное обновление:**
- Удалить старые записи для данного файла
- Перепарсить файл
- Вставить новые записи
- Записать на диск

---

## compiler.rs — Компиляция

```rust
#[derive(Debug, Clone, Copy)]
pub enum OutputFormat {
    Pdf,
    Html,
}

impl Vault {
    /// Скомпилировать заметку в указанный формат.
    pub fn compile_note(
        &self,
        note_path: &Path,
        output_path: &Path,
        format: OutputFormat,
    ) -> Result<(), NotesError>;

    /// Скомпилировать vault.typ (граф, обзор).
    pub fn compile_vault(
        &self,
        output_path: &Path,
        format: OutputFormat,
    ) -> Result<(), NotesError>;
}
```

**Алгоритм:**
1. Создать `NotesWorld` с root = vault directory, main = target file
2. Вызвать `typst::compile(&world)` → `Document`
3. Экспортировать в нужный формат (PDF через `typst_pdf`, HTML — экспериментально)

---

## world.rs — Реализация World trait

```rust
pub struct NotesWorld {
    root: PathBuf,
    main: FileId,
    library: LazyHash<Library>,
    book: LazyHash<FontBook>,
    fonts: Vec<FontSlot>,
    sources: HashMap<FileId, Source>,
    files: HashMap<FileId, Bytes>,
    packages: PackageStorage,
}

impl World for NotesWorld {
    fn library(&self) -> &LazyHash<Library>;
    fn book(&self) -> &LazyHash<FontBook>;
    fn main(&self) -> FileId;
    fn source(&self, id: FileId) -> Result<Source, FileError>;
    fn file(&self, id: FileId) -> Result<Bytes, FileError>;
    fn font(&self, index: usize) -> Option<Font>;
    fn today(&self, offset: Option<i64>) -> Option<Datetime>;
}
```

**Использует `typst-kit` для:**
- `FontSearcher` — поиск системных шрифтов
- `PackageStorage` — разрешение `@local/notes` и `@preview/*` пакетов

**Рекомендация:** Взять за основу реализацию из `typst-cli/src/world.rs`.

---

## sync.rs — Синхронизация CSV с файловой системой

```rust
impl Vault {
    /// Сканирует notes/*.typ, сравнивает с CSV, синхронизирует.
    /// Добавляет новые файлы, удаляет отсутствующие.
    /// После синхронизации CSV — пересобирает индекс.
    /// Возвращает (added, removed) counts.
    pub fn sync(&mut self) -> Result<(usize, usize), NotesError>;
}
```

**Алгоритм:**
1. Прочитать `note-paths.csv` → Set A
2. Сканировать `notes/*.typ` → Set B
3. Новые файлы: B - A → добавить в CSV
4. Удалённые файлы: A - B → убрать из CSV
5. Если были изменения → `build_index()`
6. Вернуть `(added.len(), removed.len())`

**Когда нужен:**
- `git pull` добавил/удалил файлы заметок
- Файлы синхронизированы через iCloud/Dropbox
- Пользователь вручную добавил/удалил `.typ` в `notes/`

---

## query.rs — Поиск

```rust
impl Vault {
    /// Полнотекстовый поиск по titles и содержимому файлов.
    pub fn search(&self, query: &str) -> Result<Vec<NoteMetadata>, NotesError>;

    /// Список заметок с опциональным фильтром по типу.
    pub fn list_notes(&self, note_type: Option<&str>) -> Result<Vec<NoteMetadata>, NotesError>;

    /// Обратные ссылки: заметки, ссылающиеся на данный id.
    pub fn backlinks(&self, id: &str) -> Result<Vec<NoteMetadata>, NotesError>;
}
```

---

## csv_registry.rs — Управление CSV

```rust
/// Прочитать пути из CSV (один столбец, без заголовка).
pub fn read_note_paths(csv_path: &Path) -> Result<Vec<String>, NotesError>;

/// Добавить путь (append).
pub fn add_note_path(csv_path: &Path, note_path: &str) -> Result<(), NotesError>;

/// Удалить путь.
pub fn remove_note_path(csv_path: &Path, note_path: &str) -> Result<(), NotesError>;
```

**Формат `note-paths.csv`:**

```
notes/welcome.typ
notes/task-001.typ
notes/tag-rust.typ
```

Один столбец, без заголовка. Typst читает: `csv("note-paths.csv").flatten()`.

---

## Структура notes-cli

```
notes-cli/src/
├── main.rs               # Clap dispatch
└── commands/
    ├── mod.rs
    ├── init.rs
    ├── new.rs
    ├── index.rs
    ├── sync.rs
    ├── compile.rs
    ├── search.rs
    ├── backlinks.rs
    ├── list.rs
    └── graph.rs
```

## CLI команды

```
notes init [path]
    Создать vault. Default: текущая директория.
    → Vault::init()

notes new <title> [--type task] [--id my-id] [--parent parent-id] [--tags tag1,tag2]
    Создать заметку.
    → Vault::new_note()

notes index
    Пересобрать индекс (парсить все .typ, записать JSON).
    → Vault::build_index()

notes sync
    Синхронизировать CSV с файловой системой + переиндексировать.
    Сканирует notes/*.typ, добавляет новые, убирает удалённые.
    Полезно после git pull или ручного добавления файлов.
    → Vault::sync()

notes compile <file> [--format html|pdf] [-o output]
    Скомпилировать заметку.
    → Vault::compile_note()

notes search <query> [--type task]
    Поиск по заметкам.
    → Vault::search()

notes backlinks <id>
    Показать обратные ссылки.
    → Vault::backlinks()

notes list [--type task] [--format table|json]
    Список заметок.
    → Vault::list_notes()

notes graph [--format html|pdf] [-o output]
    Скомпилировать vault.typ с графом.
    → Vault::compile_vault()
```

### Clap определения

```rust
#[derive(Parser)]
#[command(name = "notes", about = "Typst-based note-taking CLI")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Init { #[arg(default_value = ".")] path: String },
    New {
        title: String,
        #[arg(long, default_value = "note")] r#type: String,
        #[arg(long)] id: Option<String>,
        #[arg(long)] parent: Option<String>,
        #[arg(long, value_delimiter = ',')] tags: Vec<String>,
    },
    Index,
    /// Синхронизировать CSV с файловой системой + reindex
    Sync,
    Compile {
        file: String,
        #[arg(long, default_value = "html")] format: String,
        #[arg(short, long)] output: Option<String>,
    },
    Search {
        query: String,
        #[arg(long)] r#type: Option<String>,
    },
    Backlinks { id: String },
    List {
        #[arg(long)] r#type: Option<String>,
        #[arg(long, default_value = "table")] format: String,
    },
    Graph {
        #[arg(long, default_value = "html")] format: String,
        #[arg(short, long)] output: Option<String>,
    },
}
```

### Примеры использования

```bash
# Создать vault
notes init my-vault
cd my-vault

# Создать заметки
notes new "Build MVP" --type task --tags dev,mvp
notes new "Rust" --type tag
notes new "Closures in Rust" --type card --parent rust

# Собрать индекс
notes sync
# → Synced: +0 added, -0 removed

notes index
# → Indexed 4 notes, 3 links

# Посмотреть заметки
notes list
# ID            TITLE              TYPE   TAGS
# welcome       Welcome            note
# build-mvp     Build MVP          task   dev, mvp
# rust          Rust               tag
# closures...   Closures in Rust   card

# Поиск
notes search "rust"
# → rust, closures-in-rust

# Backlinks
notes backlinks rust
# → closures-in-rust

# Компиляция
notes compile notes/build-mvp.typ --format html

# Граф
notes graph --format html -o graph.html
```
