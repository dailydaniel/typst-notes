use std::path::PathBuf;
use thiserror::Error;

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
