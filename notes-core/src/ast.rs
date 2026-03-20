use crate::error::NotesError;
use crate::types::{self, NoteMetadata, VaultType};
use std::collections::HashMap;
use typst_syntax::{ast, SyntaxNode};

/// Result of parsing a single .typ file
#[derive(Debug)]
pub struct AstExtraction {
    pub metadata: Option<NoteMetadata>,
    pub links: Vec<String>,
    /// Cross-links between two notes (neither is necessarily the current file).
    /// Created by `xlink("a", also: "b")` or xlink-scope contexts.
    pub cross_links: Vec<(String, String)>,
}

/// Data extracted from a single xlink call
struct XlinkData {
    target: String,
    also: Option<String>,
}

/// State accumulated while walking the AST
struct WalkState {
    show_data: Option<ShowData>,
    links: Vec<String>,
    cross_links: Vec<(String, String)>,
    /// Aliases: `let name = xlink-scope.with(also: "...")` → name → also_target
    scope_aliases: HashMap<String, String>,
}

/// Parse a .typ file and extract metadata + links from its AST.
/// The `id` and `parent` are derived from `file_path`, not from the show rule.
/// `external_aliases` are scope aliases defined in vault.typ (imported into notes).
pub fn extract_from_file(
    source: &str,
    file_path: &str,
    external_aliases: &HashMap<String, String>,
) -> Result<AstExtraction, NotesError> {
    let root = typst_syntax::parse(source);
    let mut state = WalkState {
        show_data: None,
        links: Vec::new(),
        cross_links: Vec::new(),
        scope_aliases: external_aliases.clone(),
    };
    walk_node(&root, &mut state, None);

    let metadata = state
        .show_data
        .map(|(note_type, title, created, extra, property_links)| {
            let id = types::path_to_id(file_path);
            let parent = types::id_to_parent(&id);
            state.links.extend(property_links);
            NoteMetadata {
                id,
                title,
                note_type,
                parent,
                created,
                path: file_path.to_string(),
                extra,
            }
        });

    Ok(AstExtraction {
        metadata,
        links: state.links,
        cross_links: state.cross_links,
    })
}

type ShowData = (
    String,                                     // note_type
    String,                                     // title
    Option<String>,                             // created
    serde_json::Map<String, serde_json::Value>, // extra
    Vec<String>,                                // @id links from properties
);

fn walk_node(node: &SyntaxNode, state: &mut WalkState, scope_also: Option<&str>) {
    // Collect let-bindings for scope aliases
    if let Some(let_binding) = node.cast::<ast::LetBinding>() {
        if let Some((name, also)) = extract_scope_alias(let_binding) {
            state.scope_aliases.insert(name, also);
        }
    }

    // Extract show-rule metadata
    if let Some(show_rule) = node.cast::<ast::ShowRule>() {
        if show_rule.selector().is_none() {
            let transform = show_rule.transform();
            if let ast::Expr::FuncCall(call) = transform {
                if let Some(data) = extract_note_constructor(call) {
                    state.show_data = Some(data);
                }
            }
        }
    }

    // Handle function calls
    if let Some(func_call) = node.cast::<ast::FuncCall>() {
        // Check if it's an xlink
        if let Some(xlink_data) = extract_xlink(func_call) {
            state.links.push(xlink_data.target.clone());

            let effective_also = xlink_data.also.as_deref().or(scope_also);
            if let Some(also) = effective_also {
                state.links.push(also.to_string());
                // Bidirectional cross-link between target and also
                state
                    .cross_links
                    .push((xlink_data.target.clone(), also.to_string()));
                state
                    .cross_links
                    .push((also.to_string(), xlink_data.target));
            }
            return;
        }

        // Check if it's xlink-scope or a scope alias
        if let Some(also_target) = extract_xlink_scope_call(func_call, &state.scope_aliases) {
            // Walk children with the scope's also context
            for child in node.children() {
                walk_node(child, state, Some(&also_target));
            }
            return;
        }
    }

    for child in node.children() {
        walk_node(child, state, scope_also);
    }
}

/// Extract type name, title, and extra fields from `type.with(title: "...", ...)`.
fn extract_note_constructor(call: ast::FuncCall) -> Option<ShowData> {
    let ast::Expr::FieldAccess(fa) = call.callee() else {
        return None;
    };
    if fa.field().as_str() != "with" {
        return None;
    }
    let ast::Expr::Ident(type_ident) = fa.target() else {
        return None;
    };
    let type_name = type_ident.as_str().to_string();

    let mut title = None;
    let mut created = None;
    let mut extra = serde_json::Map::new();
    let mut property_links = Vec::new();

    for arg in call.args().items() {
        let ast::Arg::Named(named) = arg else {
            continue;
        };
        let key = named.name().as_str();
        match key {
            "title" => title = expr_to_string(named.expr()),
            "created" => created = expr_to_string(named.expr()),
            // Skip legacy fields — id, parent are derived from filename now
            "id" | "parent" => {}
            _ => {
                if let Some(val) = expr_to_json_value(named.expr()) {
                    collect_at_links(&val, &mut property_links);
                    extra.insert(key.to_string(), val);
                }
            }
        }
    }

    Some((
        type_name,
        title.unwrap_or_default(),
        created,
        extra,
        property_links,
    ))
}

/// Extract target id and optional `also` from xlink("id", also: "other").
fn extract_xlink(call: ast::FuncCall) -> Option<XlinkData> {
    let ast::Expr::Ident(ident) = call.callee() else {
        return None;
    };
    if ident.as_str() != "xlink" {
        return None;
    }

    let mut target = None;
    let mut also = None;

    for arg in call.args().items() {
        match arg {
            ast::Arg::Pos(expr) => {
                if target.is_none() {
                    target = expr_to_string(expr);
                }
            }
            ast::Arg::Named(named) => match named.name().as_str() {
                "id" => {
                    if target.is_none() {
                        target = expr_to_string(named.expr());
                    }
                }
                "also" => {
                    also = expr_to_string(named.expr());
                }
                _ => {}
            },
            _ => {}
        }
    }

    Some(XlinkData {
        target: target?,
        also,
    })
}

/// Detect `xlink-scope(also: "...")` calls or calls to known scope aliases.
/// Returns the `also` target if this is a scope call.
fn extract_xlink_scope_call(
    call: ast::FuncCall,
    aliases: &HashMap<String, String>,
) -> Option<String> {
    let callee_name = match call.callee() {
        ast::Expr::Ident(ident) => ident.as_str().to_string(),
        _ => return None,
    };

    // Direct xlink-scope call
    if callee_name == "xlink-scope" {
        for arg in call.args().items() {
            if let ast::Arg::Named(named) = arg {
                if named.name().as_str() == "also" {
                    return expr_to_string(named.expr());
                }
            }
        }
        return None;
    }

    // Aliased call
    aliases.get(&callee_name).cloned()
}

/// Detect `let name = xlink-scope.with(also: "...")` and return (name, also_target).
fn extract_scope_alias(binding: ast::LetBinding) -> Option<(String, String)> {
    let init = binding.init()?;

    // Get the binding name
    let name = match binding.kind() {
        ast::LetBindingKind::Normal(pattern) => {
            let bindings = pattern.bindings();
            let first = bindings.first()?;
            first.as_str().to_string()
        }
        ast::LetBindingKind::Closure(ident) => ident.as_str().to_string(),
    };

    // Pattern: xlink-scope.with(also: "...")
    let ast::Expr::FuncCall(call) = init else {
        return None;
    };
    let ast::Expr::FieldAccess(fa) = call.callee() else {
        return None;
    };
    if fa.field().as_str() != "with" {
        return None;
    }
    let ast::Expr::Ident(ident) = fa.target() else {
        return None;
    };
    if ident.as_str() != "xlink-scope" {
        return None;
    }

    for arg in call.args().items() {
        if let ast::Arg::Named(named) = arg {
            if named.name().as_str() == "also" {
                return Some((name, expr_to_string(named.expr())?));
            }
        }
    }
    None
}

/// Scan a JSON value for strings starting with "@" and collect the ids (without @).
fn collect_at_links(value: &serde_json::Value, links: &mut Vec<String>) {
    match value {
        serde_json::Value::String(s) => {
            if let Some(id) = s.strip_prefix('@') {
                links.push(id.to_string());
            }
        }
        serde_json::Value::Array(arr) => {
            for item in arr {
                collect_at_links(item, links);
            }
        }
        _ => {}
    }
}

fn expr_to_string(expr: ast::Expr) -> Option<String> {
    match expr {
        ast::Expr::Str(s) => Some(s.get().to_string()),
        _ => None,
    }
}

fn expr_to_json_value(expr: ast::Expr) -> Option<serde_json::Value> {
    match expr {
        ast::Expr::Str(s) => Some(serde_json::Value::String(s.get().to_string())),
        ast::Expr::Int(i) => Some(serde_json::Value::Number(i.get().into())),
        ast::Expr::Bool(b) => Some(serde_json::Value::Bool(b.get())),
        ast::Expr::Array(arr) => {
            let items: Vec<serde_json::Value> = arr
                .items()
                .filter_map(|item| match item {
                    ast::ArrayItem::Pos(e) => expr_to_json_value(e),
                    _ => None,
                })
                .collect();
            Some(serde_json::Value::Array(items))
        }
        _ => None,
    }
}

/// Parse vault.typ source and extract xlink-scope aliases.
/// Finds `#let name = xlink-scope.with(also: "...")` patterns.
pub fn extract_scope_aliases(source: &str) -> HashMap<String, String> {
    let root = typst_syntax::parse(source);
    let mut aliases = HashMap::new();
    walk_for_scope_aliases(&root, &mut aliases);
    aliases
}

fn walk_for_scope_aliases(node: &SyntaxNode, aliases: &mut HashMap<String, String>) {
    if let Some(let_binding) = node.cast::<ast::LetBinding>() {
        if let Some((name, also)) = extract_scope_alias(let_binding) {
            aliases.insert(name, also);
        }
    }
    for child in node.children() {
        walk_for_scope_aliases(child, aliases);
    }
}

/// Parse vault.typ source and extract all note type definitions.
/// Finds `#let name = (vault.note-type)("type-name", fields: (...))` patterns.
pub fn extract_vault_types(source: &str) -> Vec<VaultType> {
    let root = typst_syntax::parse(source);
    let mut types = Vec::new();
    walk_for_types(&root, &mut types);
    types
}

fn walk_for_types(node: &SyntaxNode, types: &mut Vec<VaultType>) {
    if let Some(let_binding) = node.cast::<ast::LetBinding>() {
        if let Some(vtype) = extract_type_from_let(let_binding) {
            types.push(vtype);
        }
    }
    for child in node.children() {
        walk_for_types(child, types);
    }
}

fn extract_type_from_let(binding: ast::LetBinding) -> Option<VaultType> {
    let init = binding.init()?;

    // Value should be FuncCall: (vault.note-type)("name", ...)
    let ast::Expr::FuncCall(call) = init else {
        return None;
    };

    // Callee should be Parenthesized(FieldAccess(_, "note-type"))
    let ast::Expr::Parenthesized(paren) = call.callee() else {
        return None;
    };

    let ast::Expr::FieldAccess(fa) = paren.expr() else {
        return None;
    };

    if fa.field().as_str() != "note-type" {
        return None;
    }

    // Extract type name from first positional arg and fields from named arg
    let mut name = None;
    let mut fields = Vec::new();

    for arg in call.args().items() {
        match arg {
            ast::Arg::Pos(expr) => {
                if name.is_none() {
                    name = expr_to_string(expr);
                }
            }
            ast::Arg::Named(named) => {
                if named.name().as_str() == "fields" {
                    fields = extract_dict_fields(named.expr());
                }
            }
            _ => {}
        }
    }

    Some(VaultType {
        name: name?,
        fields,
    })
}

fn extract_dict_fields(expr: ast::Expr) -> Vec<(String, String)> {
    let ast::Expr::Dict(dict) = expr else {
        return Vec::new();
    };

    let mut fields = Vec::new();
    for item in dict.items() {
        if let ast::DictItem::Named(named) = item {
            let key = named.name().as_str().to_string();
            let value = expr_to_raw_typst(named.expr());
            fields.push((key, value));
        }
    }
    fields
}

/// Convert an AST expression to its raw Typst source representation.
fn expr_to_raw_typst(expr: ast::Expr) -> String {
    match expr {
        ast::Expr::Str(s) => format!("\"{}\"", s.get()),
        ast::Expr::Int(i) => i.get().to_string(),
        ast::Expr::Bool(b) => if b.get() { "true" } else { "false" }.to_string(),
        ast::Expr::Array(arr) => {
            let items: Vec<String> = arr
                .items()
                .filter_map(|item| match item {
                    ast::ArrayItem::Pos(e) => Some(expr_to_raw_typst(e)),
                    _ => None,
                })
                .collect();
            if items.is_empty() {
                "()".to_string()
            } else {
                format!("({})", items.join(", "))
            }
        }
        _ => "\"\"".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_id_derived_from_filename() {
        let source = r#"
#show: task.with(
  title: "Build MVP",
)
"#;
        let result = extract_from_file(source, "notes/build-mvp.typ", &HashMap::new()).unwrap();
        let meta = result.metadata.unwrap();
        assert_eq!(meta.id, "build-mvp");
        assert_eq!(meta.title, "Build MVP");
        assert_eq!(meta.note_type, "task");
        assert!(meta.parent.is_none());
    }

    #[test]
    fn test_hierarchy_from_filename() {
        let source = r#"
#show: card.with(
  title: "Closures",
)
"#;
        let result =
            extract_from_file(source, "notes/programming--rust--closures.typ", &HashMap::new()).unwrap();
        let meta = result.metadata.unwrap();
        assert_eq!(meta.id, "programming/rust/closures");
        assert_eq!(meta.parent, Some("programming/rust".to_string()));
        assert_eq!(meta.title, "Closures");
    }

    #[test]
    fn test_legacy_id_ignored() {
        let source = r#"
#show: note.with(
  id: "old-id",
  title: "My Note",
)
"#;
        let result = extract_from_file(source, "notes/my-note.typ", &HashMap::new()).unwrap();
        let meta = result.metadata.unwrap();
        // id comes from filename, not from show rule
        assert_eq!(meta.id, "my-note");
    }

    #[test]
    fn test_extract_xlinks() {
        let source = r#"
#show: note.with(title: "Note A")

See #xlink("note-b") and #xlink("note-c").
"#;
        let result = extract_from_file(source, "notes/a.typ", &HashMap::new()).unwrap();
        assert_eq!(result.links, vec!["note-b", "note-c"]);
        assert!(result.cross_links.is_empty());
    }

    #[test]
    fn test_xlink_with_also() {
        let source = r#"
#show: note.with(title: "Journal")

Working on #xlink("task1", also: "work/job1").
"#;
        let result = extract_from_file(source, "notes/journal.typ", &HashMap::new()).unwrap();
        // Links from current file: task1 and work/job1
        assert!(result.links.contains(&"task1".to_string()));
        assert!(result.links.contains(&"work/job1".to_string()));
        // Cross-links: task1 ↔ work/job1
        assert!(result.cross_links.contains(&("task1".to_string(), "work/job1".to_string())));
        assert!(result.cross_links.contains(&("work/job1".to_string(), "task1".to_string())));
    }

    #[test]
    fn test_xlink_scope_direct() {
        let source = r#"
#show: note.with(title: "Journal")

#xlink-scope(also: "work/job1")[
  Task one: #xlink("task1")
  Task two: #xlink("task2")
]
"#;
        let result = extract_from_file(source, "notes/journal.typ", &HashMap::new()).unwrap();
        // Links from current file
        assert!(result.links.contains(&"task1".to_string()));
        assert!(result.links.contains(&"task2".to_string()));
        assert!(result.links.contains(&"work/job1".to_string()));
        // Cross-links: task1 ↔ job1, task2 ↔ job1
        assert!(result.cross_links.contains(&("task1".to_string(), "work/job1".to_string())));
        assert!(result.cross_links.contains(&("work/job1".to_string(), "task1".to_string())));
        assert!(result.cross_links.contains(&("task2".to_string(), "work/job1".to_string())));
        assert!(result.cross_links.contains(&("work/job1".to_string(), "task2".to_string())));
    }

    #[test]
    fn test_xlink_scope_alias() {
        let source = r#"
#let current-work = xlink-scope.with(also: "work/job1")

#show: note.with(title: "Journal")

#current-work[
  #xlink("task1")
]
"#;
        let result = extract_from_file(source, "notes/journal.typ", &HashMap::new()).unwrap();
        assert!(result.links.contains(&"task1".to_string()));
        assert!(result.links.contains(&"work/job1".to_string()));
        assert!(result.cross_links.contains(&("task1".to_string(), "work/job1".to_string())));
    }

    #[test]
    fn test_xlink_scope_external_alias() {
        // Alias defined in vault.typ, used in a note
        let vault_source = r#"
#let current-work = xlink-scope.with(also: "work/job1")
"#;
        let aliases = extract_scope_aliases(vault_source);
        assert_eq!(aliases.get("current-work"), Some(&"work/job1".to_string()));

        let note_source = r#"
#show: note.with(title: "Journal")

#current-work[
  #xlink("task1")
]
"#;
        let result = extract_from_file(note_source, "notes/journal.typ", &aliases).unwrap();
        assert!(result.links.contains(&"task1".to_string()));
        assert!(result.links.contains(&"work/job1".to_string()));
        assert!(result.cross_links.contains(&("task1".to_string(), "work/job1".to_string())));
    }

    #[test]
    fn test_no_show_rule() {
        let source = "= Just a heading\n\nSome content.\n";
        let result = extract_from_file(source, "notes/plain.typ", &HashMap::new()).unwrap();
        assert!(result.metadata.is_none());
    }

    #[test]
    fn test_extra_fields() {
        let source = r#"
#show: card.with(
  title: "Closures",
  difficulty: "hard",
)
"#;
        let result = extract_from_file(source, "notes/card-1.typ", &HashMap::new()).unwrap();
        let meta = result.metadata.unwrap();
        assert_eq!(
            meta.extra.get("difficulty").and_then(|v| v.as_str()),
            Some("hard")
        );
    }

    #[test]
    fn test_empty_file() {
        let result = extract_from_file("", "notes/empty.typ", &HashMap::new()).unwrap();
        assert!(result.metadata.is_none());
    }

    #[test]
    fn test_tags_extracted_as_extra() {
        let source = r#"
#show: card.with(
  title: "Closures",
  tags: ("rust", "fp"),
)
"#;
        let result = extract_from_file(source, "notes/closures.typ", &HashMap::new()).unwrap();
        let meta = result.metadata.unwrap();
        let tags = meta.extra.get("tags").unwrap().as_array().unwrap();
        assert_eq!(tags.len(), 2);
        assert_eq!(tags[0].as_str().unwrap(), "rust");
        assert_eq!(tags[1].as_str().unwrap(), "fp");
    }

    #[test]
    fn test_at_links_in_properties() {
        let source = r#"
#show: card.with(
  title: "Closures",
  tags: ("rust", "@programming/python"),
  related: "@programming/rust/traits",
)
"#;
        let result = extract_from_file(source, "notes/closures.typ", &HashMap::new()).unwrap();
        assert!(result.links.contains(&"programming/python".to_string()));
        assert!(result.links.contains(&"programming/rust/traits".to_string()));
    }

    #[test]
    fn test_extract_vault_types_basic() {
        let source = r#"
#let note = (vault.note-type)("note")
#let task = (vault.note-type)("task")
#let card = (vault.note-type)("card")
"#;
        let types = extract_vault_types(source);
        assert_eq!(types.len(), 3);
        assert_eq!(types[0].name, "note");
        assert_eq!(types[1].name, "task");
        assert_eq!(types[2].name, "card");
        assert!(types[0].fields.is_empty());
    }

    #[test]
    fn test_extract_vault_types_with_fields() {
        let source = r#"
#let note = (vault.note-type)("note", fields: (tags: "", links: ""))
#let task = (vault.note-type)("task", fields: (status: "", priority: ""))
#let card = (vault.note-type)("card")
"#;
        let types = extract_vault_types(source);
        assert_eq!(types.len(), 3);

        assert_eq!(types[0].name, "note");
        assert_eq!(types[0].fields, vec![
            ("tags".to_string(), "\"\"".to_string()),
            ("links".to_string(), "\"\"".to_string()),
        ]);

        assert_eq!(types[1].name, "task");
        assert_eq!(types[1].fields, vec![
            ("status".to_string(), "\"\"".to_string()),
            ("priority".to_string(), "\"\"".to_string()),
        ]);

        assert_eq!(types[2].name, "card");
        assert!(types[2].fields.is_empty());
    }

    #[test]
    fn test_extract_vault_types_full_vault() {
        let source = r#"
#import "@local/notes:0.1.0": new-vault, as-branch

#let vault = new-vault(
  index: json("notes-index.json"),
)

#let note = (vault.note-type)("note")
#let task = (vault.note-type)("task", fields: (priority: ""))
#let card = (vault.note-type)("card")
#let xlink = vault.xlink
"#;
        let types = extract_vault_types(source);
        assert_eq!(types.len(), 3);
        assert_eq!(types[0].name, "note");
        assert_eq!(types[1].name, "task");
        assert_eq!(types[2].name, "card");
    }

    #[test]
    fn test_extract_vault_types_array_fields() {
        let source = r#"
#let report = (vault.note-type)("report", fields: (tags: ()))
#let note = (vault.note-type)("note", fields: (tags: (), links: ()))
"#;
        let types = extract_vault_types(source);
        assert_eq!(types.len(), 2);
        assert_eq!(types[0].name, "report");
        eprintln!("report fields: {:?}", types[0].fields);
        assert_eq!(types[0].fields[0].0, "tags");
        assert_eq!(types[0].fields[0].1, "()");

        assert_eq!(types[1].fields[0].1, "()");
        assert_eq!(types[1].fields[1].1, "()");
    }

    #[test]
    fn test_at_links_combined_with_xlinks() {
        let source = r#"
#show: card.with(
  title: "Closures",
  related: "@programming/rust/traits",
)

See also #xlink("programming/python").
"#;
        let result = extract_from_file(source, "notes/closures.typ", &HashMap::new()).unwrap();
        assert_eq!(result.links.len(), 2);
        assert!(result.links.contains(&"programming/rust/traits".to_string()));
        assert!(result.links.contains(&"programming/python".to_string()));
    }
}
