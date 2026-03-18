use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Metadata extracted from a note's AST
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteMetadata {
    pub id: String,
    pub title: String,
    #[serde(rename = "type")]
    pub note_type: String,
    pub parent: Option<String>,
    pub tags: Vec<String>,
    pub created: Option<String>,
    pub path: String,
    #[serde(flatten)]
    pub extra: serde_json::Map<String, serde_json::Value>,
}

/// A link between notes (from xlink call)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NoteLink {
    pub source: String,
    pub target: String,
    pub source_path: String,
}

/// Complete vault index
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NotesIndex {
    pub version: u32,
    pub generated_at: String,
    pub notes: Vec<NoteMetadata>,
    pub links: Vec<NoteLink>,
}

/// Vault configuration (paths)
#[derive(Debug, Clone)]
pub struct VaultConfig {
    pub root: PathBuf,
    pub note_paths_file: PathBuf,
    pub index_file: PathBuf,
    pub notes_dir: PathBuf,
    pub assets_dir: PathBuf,
}
