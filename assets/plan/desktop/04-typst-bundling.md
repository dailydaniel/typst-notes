# Plan: Bundling Typst into the App

## Problem
Сейчас для работы приложения нужно:
1. `typst` CLI установлен глобально и доступен в PATH
2. Framework `@local/notes:0.1.0` установлен в `~/Library/Application Support/typst/packages/local/notes/0.1.0/`

Это делает невозможной дистрибуцию приложения обычным пользователям.

## Вариант 1: Bundle typst binary + framework (Quick)

### Идея
Typst CLI кладётся как ресурс Tauri, framework копируется при первом запуске. Subprocess подход сохраняется.

### Шаги

1. **Добавить typst binary в Tauri resources**
   - Скачать typst binary для каждой платформы (macOS arm64/x64, Linux, Windows)
   - `tauri.conf.json` → `bundle.resources`: включить бинарник
   - При запуске: `app.path().resource_dir()` → путь к бинарнику
   - В `compiler.rs`: вместо `Command::new("typst")` → `Command::new(bundled_typst_path)`

2. **Встроить framework в ресурсы**
   - `bundle.resources`: включить `notes-framework/src/**`
   - При первом запуске или при каждом запуске:
     - Скопировать framework в `app_data_dir/packages/local/notes/0.1.0/`
     - Или использовать `--package-path` флаг typst CLI

3. **Использовать `--package-path` для резолва пакетов**
   ```
   typst compile --root {vault} --package-path {app_resources}/packages note.typ output.html
   ```
   - Структура в ресурсах: `packages/local/notes/0.1.0/src/...`
   - Typst резолвит `@local/notes:0.1.0` из этой директории

4. **Cross-platform binary**
   - macOS: `typst-aarch64-apple-darwin`, `typst-x86_64-apple-darwin`
   - Linux: `typst-x86_64-unknown-linux-gnu`
   - Windows: `typst-x86_64-pc-windows-msvc.exe`
   - В `tauri.conf.json` можно использовать sidecar с platform-specific бинарниками

### Tauri Sidecar (рекомендуемый подход)
Tauri имеет встроенную поддержку sidecar binaries:
```json
// tauri.conf.json
{
  "bundle": {
    "externalBin": ["binaries/typst"]
  }
}
```
- Бинарники именуются по платформе: `typst-aarch64-apple-darwin`, `typst-x86_64-apple-darwin` и т.д.
- Tauri автоматически выбирает нужный
- В Rust: `app.shell().sidecar("typst")` вместо `Command::new("typst")`

### Плюсы
- Минимальные изменения в коде (~50 строк)
- Subprocess изоляция — если typst крашится, приложение не падает
- Легко обновлять typst версию — просто заменить бинарник
- ~2-4 часа работы

### Минусы
- Увеличение размера бандла на ~30 MB (typst binary)
- Subprocess overhead (1-3 сек на компиляцию)
- Нужно поддерживать бинарники для каждой платформы

---

## Вариант 2: Typst as Rust crate (Proper)

### Идея
Заменить subprocess на прямой вызов typst через Rust crate. Framework встраивается в бинарник через `include_str!()`.

### Шаги

1. **Добавить typst crate в Cargo.toml**
   ```toml
   [dependencies]
   typst = "0.14"           # или текущая версия
   typst-pdf = "0.14"
   typst-html = "0.14"      # experimental
   typst-render = "0.14"    # для PNG если нужно
   comemo = "0.4"           # memoization, требуется typst
   ```

2. **Реализовать `typst::World` trait**
   ```rust
   struct NotesWorld {
       root: PathBuf,
       main_file: FileId,
       library: LazyHash<Library>,
       book: LazyHash<FontBook>,
       fonts: Vec<Font>,
       files: HashMap<FileId, FileSlot>,
       framework_files: HashMap<String, &'static str>, // embedded
   }

   impl World for NotesWorld {
       fn library(&self) -> &LazyHash<Library> { ... }
       fn book(&self) -> &LazyHash<FontBook> { ... }
       fn main(&self) -> FileId { ... }
       fn source(&self, id: FileId) -> FileResult<Source> { ... }
       fn file(&self, id: FileId) -> FileResult<Bytes> { ... }
       fn font(&self, index: usize) -> Option<Font> { ... }
       fn today(&self, offset: Option<i64>) -> Option<Datetime> { ... }
       fn packages(&self) -> &[(PackageSpec, Option<EcoString>)] { ... }
   }
   ```

3. **Встроить framework файлы**
   ```rust
   const FRAMEWORK_FILES: &[(&str, &str)] = &[
       ("src/lib.typ", include_str!("../../notes-framework/src/lib.typ")),
       ("src/vault.typ", include_str!("../../notes-framework/src/vault.typ")),
       ("src/xlink.typ", include_str!("../../notes-framework/src/xlink.typ")),
       ("src/backlinks.typ", include_str!("../../notes-framework/src/backlinks.typ")),
       ("src/note-type.typ", include_str!("../../notes-framework/src/note-type.typ")),
       ("src/index.typ", include_str!("../../notes-framework/src/index.typ")),
       ("src/graph.typ", include_str!("../../notes-framework/src/graph.typ")),
       ("typst.toml", include_str!("../../notes-framework/typst.toml")),
   ];
   ```

4. **Резолв `@local/notes:0.1.0`**
   - В `World::source()` и `World::file()`:
     - Если `FileId` указывает на `@local/notes`, вернуть embedded content
     - Иначе читать с диска

5. **Компиляция**
   ```rust
   fn compile_note(world: &NotesWorld) -> Result<String, Vec<SourceDiagnostic>> {
       let document = typst::compile(world)?;
       // HTML:
       let html = typst_html::html(&document)?;
       // PDF:
       let pdf = typst_pdf::pdf(&document, &PdfOptions::default())?;
   }
   ```

6. **Шрифты**
   - Загрузить системные шрифты при старте
   - Или встроить минимальный набор (New Computer Modern для typst default)
   - `typst_assets::fonts()` — встроенные шрифты typst

7. **Обновить `compiler.rs`**
   - Заменить `Command::new("typst").arg("compile")...` на `typst::compile(world)`
   - Убрать dependency на typst CLI в PATH

### Подводные камни

- **typst-html experimental** — API может меняться между минорными версиями. `typst_html::html()` может не поддерживать все фичи
- **World trait complexity** — правильная реализация file resolution, package resolution, caching (comemo) требует ~300-500 строк
- **Размер бинарника** — typst crate добавит ~20-30 MB к бинарнику (шрифты, парсер, layouter)
- **Compile time** — typst crate значительно увеличит время cargo build (~1-2 мин)
- **Version lock** — привязка к конкретной версии typst crate; обновление может сломать API

### Плюсы
- Нет внешних зависимостей вообще
- Быстрее компиляция (нет subprocess overhead, in-process)
- Возможность incremental compilation (comemo cache)
- Лучшие error messages (structured diagnostics вместо stderr parsing)
- Можно рендерить в памяти без temp файлов

### Минусы
- 2-3 дня работы (World trait + тестирование)
- typst-html нестабилен
- Значительно увеличивает compile time проекта
- Tight coupling с конкретной версией typst

---

## Рекомендация

**Сейчас**: Вариант 1 (sidecar binary). Быстро, надёжно, минимум рисков.

**Позже** (когда typst HTML export стабилизируется): Вариант 2. Даёт лучший UX (скорость, diagnostics, incremental compilation).

Варианты не взаимоисключающие — можно начать с 1 и мигрировать на 2.
