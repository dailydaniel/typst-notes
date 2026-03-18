use crate::error::NotesError;
use crate::vault::Vault;
use std::path::Path;

impl Vault {
    /// Rebuild the entire index from all registered notes.
    pub fn build_index(&mut self) -> Result<usize, NotesError> {
        todo!()
    }

    /// Incrementally update index for a single file.
    pub fn update_index_for_file(&mut self, path: &Path) -> Result<(), NotesError> {
        todo!()
    }
}
