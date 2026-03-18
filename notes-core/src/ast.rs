use crate::error::NotesError;
use crate::types::{NoteMetadata, NoteLink};

/// Result of parsing a single .typ file
#[derive(Debug)]
pub struct AstExtraction {
    pub metadata: Option<NoteMetadata>,
    pub links: Vec<String>,
}

/// Parse a .typ file and extract metadata + links from its AST.
pub fn extract_from_file(source: &str, file_path: &str) -> Result<AstExtraction, NotesError> {
    todo!("Implement AST extraction")
}
