use crate::error::NotesError;
use crate::types::{NotesIndex, VaultConfig};
use std::path::{Path, PathBuf};

/// Represents an open vault
pub struct Vault {
    pub config: VaultConfig,
    pub index: Option<NotesIndex>,
}

impl Vault {
    /// Create a new vault at the given path.
    pub fn init(path: &Path) -> Result<Vault, NotesError> {
        todo!()
    }

    /// Open an existing vault.
    pub fn open(path: &Path) -> Result<Vault, NotesError> {
        todo!()
    }

    /// Find vault root by walking up directories.
    pub fn discover(path: &Path) -> Result<PathBuf, NotesError> {
        todo!()
    }

    /// Load index from notes-index.json.
    pub fn load_index(&mut self) -> Result<&NotesIndex, NotesError> {
        todo!()
    }

    /// Get note paths from CSV.
    pub fn note_paths(&self) -> Result<Vec<String>, NotesError> {
        todo!()
    }
}
