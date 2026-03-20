#import "@local/notes:0.1.0": new-vault, as-branch

#let vault = new-vault(
  index: json("notes-index.json"),
)

// Note types
#let tag = (vault.note-type)("tag")
#let note = (vault.note-type)("note", fields: (tags: (), links: ()))
#let task = (vault.note-type)("task", fields: (tags: (), priority: "", status: ""))
#let report = (vault.note-type)("report", fields: (tags: ()))
#let journal = (vault.note-type)("journal", fields: (date: "", previous: ""))

// Cross-references
#let xlink = vault.xlink
#let xlink-scope = vault.xlink-scope

#let current-work = xlink-scope.with(also: "work/main job", props: ("priority",))