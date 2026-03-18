use crate::error::NotesError;
use crate::vault::Vault;

impl Vault {
    /// Sync CSV with filesystem: scan notes/*.typ, add new, remove missing.
    /// Then rebuild index. Returns (added, removed) counts.
    pub fn sync(&mut self) -> Result<(usize, usize), NotesError> {
        todo!()
    }
}
