// Note type constructor generation

#import "backlinks.typ": render-backlinks

/// Render a property value. Strings starting with "@" are rendered as
/// clickable links to other notes (resolved from index). Arrays are
/// processed element by element.
#let render-prop-value(val, index) = {
  if type(val) == str {
    if val.starts-with("@") {
      let id = val.slice(1)
      let notes = index.at("notes", default: ())
      let target = notes.find(n => n.at("id", default: "") == id)
      if target != none {
        link(target.at("path", default: ""), id)
      } else {
        text(fill: red)[#id (not found)]
      }
    } else {
      val
    }
  } else if type(val) == array {
    val.map(v => render-prop-value(v, index)).join(", ")
  } else {
    [#val]
  }
}

/// Create a note type constructor function.
/// Returns a function usable with #show: type.with(title: "...", ...)
///
/// - show-meta: bool — if false, only the title heading is rendered (no metadata block)
///
/// Parameters like id and parent are no longer passed in the show rule —
/// they are derived from the filename by the Rust indexer and looked up
/// in the index at render time.
#let make-note-type(note-state, type-name, index, show-meta: true) = {
  (title: "", created: none, ..extra, body) => {
    // Look up this note in the index by title and type
    let notes = index.at("notes", default: ())
    let found = notes.find(n => {
      n.at("title", default: "") == title and n.at("type", default: "") == type-name
    })

    let note-id = if found != none { found.at("id", default: none) } else { none }
    let parent = if found != none { found.at("parent", default: none) } else { none }

    // Track current note id via state
    if note-id != none {
      note-state.update(note-id)
    }

    // Auto-render title as heading
    heading(title)

    // Render metadata block (all properties)
    if show-meta {
      let items = ()
      items.push([*title:* #title])
      items.push([*type:* #type-name])
      if note-id != none {
        items.push([*id:* #note-id])
      }
      if parent != none {
        items.push([*parent:* #parent])
      }
      if created != none {
        items.push([*created:* #created])
      }
      let named = extra.named()
      for (key, val) in named {
        items.push([*#key\:* #render-prop-value(val, index)])
      }

      block(
        fill: luma(245),
        inset: 8pt,
        radius: 2pt,
        width: 100%,
        text(size: 0.85em, items.join(linebreak()))
      )
    }

    body

    // Render backlinks at the end
    if note-id != none {
      render-backlinks(note-id, index)
    }
  }
}
