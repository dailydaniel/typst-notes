- архитектура
	- фреймворк @local/notes
		- функция для создания vault заметки
		- функция для создания типов заметок
		- функция для создания заметки (туда передается созданный в vault.typ тип, по этому типу определяются properties, в конце заметки есть блок с backlinks)
			- базовые properties для каждого типа заметок:
				- name (название, должно создавать `name.typ`)
				- id (любой айди для дальнейшего поиска)
				- parent (вместо папок будет ссылка на родителя)
				- tags (может быть пустым, список ссылок на другие заметки)
		- функция для создания ссылки на заметку
		- функции для ast парсинга других .typ заметок
		- функции для backlinks
		- функция для создания графа на основе парсинга заметок
	- основной файл vault.typ
		- импортирует фреймворк
		- считывает `notes-path.csv` с названиями заметок
		- парсит через ast метаданные всех заметок
		- выводит в конце граф связей этих заметок
		- объявляет некоторые типы заметок (хардкод дефолтных)
		- задает стиль заметок и тд
	- все остальные заметки
		- хранятся в папке `notes/`, вложения в папке `assets/`
		- импортируют `vault.typ`, а не фреймворк, создают заметку (тип заметки с properties) внутри файла - без этого заметка не будет в регистре заметок
		- в конце каждой заметки рендерится также блок backlinks автоматически
	- приложение tauri
		- при создании vault, автоматически генерируется код `vault.typ`, в котором сразу есть импорт фреймворка, основные типы и граф, остальное можно редактировать
		- создается также папка `notes/` и `assets/` с тестовой заметкой с базовым типом
		- приложение реализует ide с [tinymist](https://myriad-dreamin.github.io/tinymist/) (LSP для typst) как obsidian для markdown - слева как в ide/obsidian навигация по vault (`vault.typ`, `notes-path.csv`, `notes/*.typ`, `assets/*`)
			- CodeMirror/Monaco с подсветкой Typst и интеграцией с LSP (tinymist)
			- автодополнение функций фреймворка (`task(…)` ,  `note(…)` ,  `xlink(…)`, ...)
		- при создании заметки обновляется `notes-path.csv`
		- приложение само ставит все (тк оно на rust, то может ставить / управлять typst через rust)
		- в один момент можно открывать одну заметку, при открытии новой старая закрывается
		- когда открывается заметка, то в основной панели можно редактировать код в левой половине и в правой будет превью отрендереной заметки, рендерится все только в html, не в pdf (`typst watch file.typ file.html --features html`)
		- если открывается ссылка на заметку, которая не создана, то создается пустая с дефолтным типом note
		- сочетание cmd+k делает полнотекстовый поиск по заметкам и при нажатии происходит переход в страницу с заметкой (она открывается)
		- сочетание cmd+shift+k делает тоже самое, но вместо перехода копирует в буфер обмена код typst с созданием ссылки на выбранную заметку
- примеры
	- vault
		-
		  ```typst
		  #import "@local/notes:1.0.0" as base
		  
		  #let note-paths = csv("note-paths.csv").flatten()
		  
		  #let vault = base.new-vault(
		    note-paths: note-paths,
		  )
		  
		  // Дефолтные типы
		  #let tag = vault.new-note-type(
		    type: "tag",
		    fields: ()
		  )
		  
		  #let task = vault.new-note-type(
		    type: "task",
		    fields: (due_date: datetime)
		  )
		  
		  #let note = vault.new-note-type(
		    type: "note",
		    fields: ()
		  )
		  
		  // Пользовательские типы (ручное редактирование)
		  #let card = vault.new-note-type(
		    type: "card",
		    fields: (front: str, back: str)
		  )
		  
		  // Форматтеры: общий стиль + авто-backlinks для root
		  #show: vault.format.with(
		    apply-backlinks: true,
		  )
		  
		  // В конце vault — граф
		  #pagebreak()
		  = Graph
		  
		  #vault.build-graph()
		  ```
	- note
		-
		  ```typst
		  #import "vault.typ": *
		  
		  #show: task.with(
		    id: "task-001",
		    title: "Разработать MVP",
		    due_date: datetime.today(),
		    tags: ("notes", "mvp"),
		  )
		  
		  = Разработка MVP
		  
		  Описание задачи...
		  
		  Ссылка на другую заметку: #xlink(id: "note-123")
		  
		  ```
- план разработки mvp (proof of concept)
	- Этап 1 - Typst-фреймворк (базовый)
		- 1. Базовый пакет  @local/notes:
			- парсинг  .typ  (обёртка над AST)
			- extract-metadata  и  extract-links
			- базовый  new-vault(note-paths, …) с кешированием индекса
			- new-note-type  → генерация конструкторов
			- query API по индексу
			- рендер backlinks и заготовка под граф.
		- 2. Простейший  `vault.typ`:
			- чтение  note-paths.csv
			- дефолтные типы:  task,  note,  card,  tag
			- базовые форматтеры + рендер графа
	- Этап 2 - Tauri MVP
		- 1. Backend:
			- команды: создать заметку, обновить note-paths.csv
			- команда компиляции заметки в HTML (через CLI/библиотеку)
			- простое чтение метаданных для списка заметок
			- команды с cmd+k, cmd+shift+k
			- кнопка с экспортом заметки в html/pdf
		- 2. Frontend:
			- простой редактор (CodeMirror) с подсветкой Typst
			- панель со списком заметок
			- превью HTML
	- Этап 3 - улучшения
		- Интеграция tinymist LSP → автодополнение, подсветка ошибок
- полезные ссылки:
	- [tinymist](https://myriad-dreamin.github.io/tinymist/) - LSP для typst
	- [typst github](https://github.com/typst/typst) - github проекта
	- [typst-syntax](https://crates.io/crates/typst-syntax/0.14.0/dependencies), [typst-cli](https://crates.io/crates/typst-cli) - rust crates for typst
	- [basalt-lib](https://github.com/GabrielDTB/basalt-lib) - simple typst framework for creating vault, notes & links as example and proof of concept
