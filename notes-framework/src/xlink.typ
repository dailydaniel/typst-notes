// Cross-reference links between notes

/// Normalize props to always be an array.
/// Handles: (), ("a",), "a", ("a", "b")
#let _normalize-props(p) = {
  if type(p) == array { p }
  else if type(p) == str { (p,) }
  else { () }
}

/// Create an xlink function bound to a specific index and scope state.
///
/// Supports:
///   - `xlink("id")` — basic link (unchanged)
///   - `xlink("id", also: "other")` — cross-links current↔id, current↔other, id↔other
///   - `xlink("id", props: ("status",))` — shows properties inline
///   - Inside `xlink-scope`: inherits `also` and `props` from scope
#let make-xlink(index, scope-state) = {
  (id, also: none, props: (), body: none) => {
    context {
      let scope = scope-state.get()
      let eff-also = if also != none { also } else if scope != none { scope.at("also", default: none) } else { none }
      let raw-props = if _normalize-props(props).len() > 0 { props } else if scope != none { scope.at("props", default: ()) } else { () }
      let eff-props = _normalize-props(raw-props)

      let notes = index.at("notes", default: ())
      let target = notes.find(n => n.at("id", default: "") == id)

      // Render main link
      if target != none {
        let display = if body == none { id } else { body }
        link(target.at("path", default: ""), display)
      } else {
        text(fill: red)[#id (not found)]
      }

      // Render properties after link, before arrow
      if eff-props.len() > 0 and target != none {
        let items = ()
        for prop in eff-props {
          let val = target.at(prop, default: none)
          if val != none {
            items.push([#prop: #val])
          }
        }
        if items.len() > 0 {
          [ ]
          text(size: 0.85em, fill: luma(120))[(#items.join([ · ]))]
        }
      }

      // Render also link
      if eff-also != none {
        let also-note = notes.find(n => n.at("id", default: "") == eff-also)
        [ → ]
        if also-note != none {
          link(also-note.at("path", default: ""), eff-also)
        } else {
          text(fill: red)[#eff-also (not found)]
        }
      }
    }
  }
}

// Placeholder xlink — replaced by vault-specific version in user's vault.typ
#let xlink(id, also: none, props: (), body: none) = {
  text(fill: red)[\##id (no vault loaded)]
}
