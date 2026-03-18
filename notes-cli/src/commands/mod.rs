use notes_core::error::NotesError;

pub fn init(path: &str) -> Result<(), NotesError> {
    println!("TODO: init vault at {path}");
    Ok(())
}

pub fn new_note(
    title: &str,
    note_type: &str,
    id: Option<&str>,
    parent: Option<&str>,
    tags: &[String],
) -> Result<(), NotesError> {
    println!("TODO: create {note_type} \"{title}\"");
    Ok(())
}

pub fn index() -> Result<(), NotesError> {
    println!("TODO: rebuild index");
    Ok(())
}

pub fn sync() -> Result<(), NotesError> {
    println!("TODO: sync CSV + reindex");
    Ok(())
}

pub fn compile(file: &str, format: &str, output: Option<&str>) -> Result<(), NotesError> {
    println!("TODO: compile {file} to {format}");
    Ok(())
}

pub fn search(query: &str, note_type: Option<&str>) -> Result<(), NotesError> {
    println!("TODO: search \"{query}\"");
    Ok(())
}

pub fn backlinks(id: &str) -> Result<(), NotesError> {
    println!("TODO: backlinks for {id}");
    Ok(())
}

pub fn list(note_type: Option<&str>, format: &str) -> Result<(), NotesError> {
    println!("TODO: list notes");
    Ok(())
}

pub fn graph(format: &str, output: Option<&str>) -> Result<(), NotesError> {
    println!("TODO: compile graph");
    Ok(())
}
