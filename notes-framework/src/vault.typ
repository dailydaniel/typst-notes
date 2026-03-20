// Vault initialization and management

#import "index.typ": read-index, query-index
#import "note-type.typ": make-note-type
#import "xlink.typ": make-xlink
#import "backlinks.typ": render-backlinks
#import "graph.typ": build-graph-from-index

/// Create a new vault object.
///
/// - index: dictionary — pre-loaded index data (from json("notes-index.json"))
/// - formatters: array — optional show-rule functions
///
/// Returns a dictionary with methods:
///   - note-type(name) — create a note type constructor
///   - xlink — cross-reference function
///   - xlink-scope — scope wrapper for bulk xlink enrichment
///   - get-prop — read any property of any note
///   - build-graph() — render the knowledge graph
///   - query(type, where, sort-by) — query notes from index
///   - backlinks(id) — render backlinks for a note
///   - index — raw index data
#let new-vault(
  index: (:),
  formatters: (),
) = {
  let idx = read-index(index)
  let note-state = state("notes-current-id", none)
  let scope-state = state("notes-xlink-scope", none)

  let _note-type(name, show-meta: true, ..rest) = {
    // `rest` absorbs CLI-only params like `fields` — ignored by framework
    make-note-type(note-state, name, idx, show-meta: show-meta, inputs: sys.inputs)
  }

  let _xlink = make-xlink(idx, scope-state)

  let _xlink-scope(also: none, props: (), body) = {
    scope-state.update((also: also, props: props))
    body
    scope-state.update(none)
  }

  let _get-prop(note-id, prop) = {
    let notes = idx.at("notes", default: ())
    let found = notes.find(n => n.at("id", default: "") == note-id)
    if found != none {
      found.at(prop, default: none)
    }
  }

  let _format(apply-backlinks: true, body) = {
    body
    if apply-backlinks {
      context {
        let current-id = note-state.get()
        if current-id != none {
          render-backlinks(current-id, idx)
        }
      }
    }
  }

  (
    note-type: _note-type,
    xlink: _xlink,
    xlink-scope: _xlink-scope,
    get-prop: _get-prop,
    format: _format,
    build-graph: () => build-graph-from-index(idx),
    query: (type: none, where: none, sort-by: none) => {
      query-index(idx, type: type, where: where, sort-by: sort-by)
    },
    backlinks: (id) => render-backlinks(id, idx),
    index: idx,
  )
}
