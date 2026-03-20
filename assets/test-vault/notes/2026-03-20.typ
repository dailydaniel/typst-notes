#import "../vault.typ": *

#show: journal.with(
  title: "2026-03-20",
  date: "2026-03-20",
  previous: "@2026-03-19",
)

#let current-pet-project = xlink-scope.with(
  also: "work/petp1", 
  props: ("status",)
)

text

#grid(
  columns: (1fr, 1fr),
  align(center)[
    #current-work[
      #xlink("task1") in progress
    ]
  ],
  align(center)[
    #current-pet-project[
      #xlink("add-tauri-app") in progress
    ]
  ]
)

#current-work[
  #xlink("task1") in progress
]