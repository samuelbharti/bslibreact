# The markup catalog's sample list: one entry for every bslib or shiny call
# whose rendered HTML the JavaScript package's tests are pinned against. See
# docs/markup-catalog.md for the contract this list has to satisfy (the
# exact JSON shape, the render rules per `kind`, and the frozen name list
# that `test-catalog.R` copies verbatim so a rename here is a deliberate,
# visible change, not an accident).
#
# Every sample here is an unevaluated call, not a fixture
# (docs/decisions/0001-no-fixtures-live-ground-truth.md): the repository's
# markup catalog renderer (tools/markup/render-r.R, a dev-only script, not
# part of this package) evaluates each one live, against whichever bslib
# and shiny are actually installed, every time the catalog is rendered.
# Nothing below is HTML; it is R source that produces HTML when run.
#
# Every call is written fully qualified (`bslib::`, `shiny::`, `htmltools::`
# and so on) and wrapped in `quote()`, so `deparse1(call)` gives back
# exactly the source text that appears in the JSON's "call" field: readable
# R code a person can paste into a console, not a dump of an evaluated
# object. Do not `library()` anything here and do not shorten a call to its
# unqualified name; the fully qualified form is part of the contract.
#
# A "kind: page" sample is a page shell (a `bslib::page_*()` call). Its
# rendered html is the page's own `<body>` tag, so a page component's body
# classes and inline style are checked against it too.
#
# This package ships only "kind: tag" and "kind: page" samples: the
# markup bslib-react's own components need to match. A "kind: extra"
# sample depends on a package this package itself does not need (DT,
# reactable, shinycssloaders, htmlwidgets); those samples live only in the
# markup catalog renderer's own dev-time list, so that this package's
# tests and installed dependencies never need any of the four. Everything
# below is "kind: tag" or "kind: page": a plain `htmltools::renderTags()`
# call under the Bootstrap-5-forcing option the renderer sets (see the page
# shells section below).

# A thin constructor, mostly so a typo in `kind` or `group` fails loudly
# here instead of silently reaching the JSON with a value nothing expects.
.sample <- function(name, kind, group, pkg, call) {
  stopifnot(
    is.character(name),
    length(name) == 1,
    kind %in% c("tag", "page", "extra"),
    group %in%
      c("page", "nav", "layout", "card", "tooltip", "output", "input", "misc"),
    is.character(pkg),
    length(pkg) == 1,
    is.call(call) || is.name(call)
  )
  list(name = name, kind = kind, group = group, pkg = pkg, call = call)
}

# Every call below stands alone: it is written the way an app author would
# actually write it, so the catalog renders what a real app actually
# ships, not a synthetic simplification.
.catalog_samples <- list(
  # ---- inputs -----------------------------------------------------------
  .sample(
    "selectInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::selectInput("x", "Quick pick", choices = c("10", "20", "30")))
  ),
  .sample(
    "selectizeInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::selectizeInput(
      "x",
      "Genes",
      choices = c("A", "B", "C"),
      selected = "A",
      multiple = TRUE
    ))
  ),
  .sample(
    "radioButtons",
    "tag",
    "input",
    "shiny",
    quote(shiny::radioButtons(
      "x",
      "Values",
      choices = c("Row z-score" = "row", "Expression" = "none")
    ))
  ),
  .sample(
    "checkboxInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::checkboxInput("x", "Cluster genes", value = TRUE))
  ),
  .sample(
    "sliderInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::sliderInput("x", "Bins", min = 1, max = 50, value = 30))
  ),
  .sample(
    "actionButton",
    "tag",
    "input",
    "shiny",
    quote(shiny::actionButton("x", "Go"))
  ),
  # A selectize input with no starting choices, populated later from the
  # server. The placeholder option is
  # part of the rendered markup, not just a runtime behavior.
  .sample(
    "selectizeInput_server_placeholder",
    "tag",
    "input",
    "shiny",
    quote(shiny::selectizeInput(
      "x",
      "Pick genes",
      choices = NULL,
      multiple = TRUE,
      options = list(placeholder = "type to search...")
    ))
  ),
  .sample(
    "textAreaInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::textAreaInput(
      "x",
      label = NULL,
      rows = 3,
      placeholder = "GENE1, GENE2, GENE3..."
    ))
  ),
  .sample(
    "actionButton_class_override",
    "tag",
    "input",
    "shiny",
    quote(shiny::actionButton("x", "Apply", class = "btn-sm"))
  ),
  .sample(
    "fileInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::fileInput("x", "de_results.csv", accept = ".csv"))
  ),
  .sample(
    "textInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::textInput(
      "q",
      NULL,
      placeholder = "Search accession, title or abstract",
      width = "100%"
    ))
  ),
  .sample(
    "actionLink",
    "tag",
    "input",
    "shiny",
    quote(shiny::actionLink("clear", "Clear all filters", class = "small"))
  ),
  .sample(
    "downloadButton",
    "tag",
    "input",
    "shiny",
    quote(shiny::downloadButton("qc_pdf", "PDF", class = "btn-sm ms-auto"))
  ),
  .sample(
    "sliderInput_no_ticks",
    "tag",
    "input",
    "shiny",
    quote(shiny::sliderInput(
      "font_size",
      "Font size",
      min = 10,
      max = 26,
      value = 21,
      step = 1,
      ticks = FALSE
    ))
  ),
  .sample(
    "selectizeInput_remove_button",
    "tag",
    "input",
    "shiny",
    quote(shiny::selectizeInput(
      "columns",
      "Columns",
      choices = NULL,
      selected = NULL,
      multiple = TRUE,
      width = "100%",
      options = list(plugins = list("remove_button"))
    ))
  ),
  # A server-populated selectize with a maxOptions cap and no remove_button
  # plugin; the plugin changes the markup inside the selectize wrapper, so
  # this differs from selectizeInput_remove_button above.
  .sample(
    "selectizeInput_max_options",
    "tag",
    "input",
    "shiny",
    quote(shiny::selectizeInput(
      "gene",
      "Search for a gene",
      choices = NULL,
      options = list(placeholder = "Symbol or Ensembl id", maxOptions = 50)
    ))
  ),
  .sample(
    "radioButtons_inline",
    "tag",
    "input",
    "shiny",
    quote(shiny::radioButtons(
      "geom",
      "Plot",
      choices = c("Boxplot" = "box", "Violin" = "violin"),
      inline = TRUE
    ))
  ),
  .sample(
    "numericInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::numericInput(
      "loading_pc",
      "Loadings for PC",
      value = 1,
      min = 1,
      max = 10,
      step = 1
    ))
  ),
  .sample(
    "passwordInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::passwordInput(
      "api_key",
      "API key",
      placeholder = "Paste your key"
    ))
  ),
  # Added for coverage docs/markup-catalog.md calls for; shiny inputs the
  # earlier kit never happened to need a fixture for.
  .sample(
    "checkboxGroupInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::checkboxGroupInput(
      "opts",
      "Choose",
      choices = c("One" = "one", "Two" = "two")
    ))
  ),
  .sample(
    "dateInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::dateInput("date1", "Date"))
  ),
  .sample(
    "dateRangeInput",
    "tag",
    "input",
    "shiny",
    quote(shiny::dateRangeInput("dates", "Date range"))
  ),
  .sample(
    "input_dark_mode",
    "tag",
    "input",
    "bslib",
    quote(bslib::input_dark_mode(id = "dark_mode"))
  ),
  .sample(
    "input_switch",
    "tag",
    "input",
    "bslib",
    quote(bslib::input_switch("switch1", "Enable feature", value = FALSE))
  ),
  .sample(
    "input_task_button",
    "tag",
    "input",
    "bslib",
    quote(bslib::input_task_button("task_btn", "Run analysis"))
  ),

  # ---- outputs ------------------------------------------------------------
  .sample(
    "plotOutput",
    "tag",
    "output",
    "shiny",
    quote(shiny::plotOutput("x"))
  ),
  .sample(
    "textOutput",
    "tag",
    "output",
    "shiny",
    quote(shiny::textOutput("x"))
  ),
  .sample(
    "verbatimTextOutput",
    "tag",
    "output",
    "shiny",
    quote(shiny::verbatimTextOutput("x"))
  ),
  # plotOutput with a click handler.
  # click= adds a data-* attribute the plain plotOutput sample does not
  # have, which is why this is its own sample rather than a variant note.
  .sample(
    "plotOutput_click",
    "tag",
    "output",
    "shiny",
    quote(shiny::plotOutput("x", height = "560px", click = "x_click"))
  ),
  .sample("uiOutput", "tag", "output", "shiny", quote(shiny::uiOutput("x"))),
  .sample(
    "uiOutput_fill",
    "tag",
    "output",
    "shiny",
    quote(shiny::uiOutput("x", fill = TRUE))
  ),
  # Added for coverage: uiOutput(inline = TRUE), used by page_navbar's own
  # nav_item(uiOutput(..., inline = TRUE)) sample below, and worth pinning
  # on its own since inline changes the wrapper element from <div> to
  # <span>.
  .sample(
    "uiOutput_inline",
    "tag",
    "output",
    "shiny",
    quote(shiny::uiOutput("chip", inline = TRUE))
  ),

  # ---- cards --------------------------------------------------------------
  .sample(
    "card_full_screen",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      full_screen = TRUE,
      bslib::card_header("Title"),
      bslib::card_body("Body")
    ))
  ),
  .sample(
    "card_bare_children",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      bslib::card_header("Current selection"),
      shiny::textOutput("count"),
      shiny::verbatimTextOutput("selected")
    ))
  ),
  # card_footer(), pinned alongside a header
  # and body so the footer's own spacing rules (border-top, padding) show
  # up next to the two shapes already covered.
  .sample(
    "card_footer",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      bslib::card_header("Title"),
      bslib::card_body("Body"),
      bslib::card_footer("Footer text")
    ))
  ),
  # Added for coverage: card(id=), which makes the card itself addressable
  # (for example by insert_accordion_panel()-style updates elsewhere in
  # bslib) without changing its full_screen behavior.
  .sample(
    "card_id",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      id = "summary_card",
      bslib::card_header("Summary"),
      bslib::card_body("Body")
    ))
  ),
  .sample(
    "card_height",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      height = "400px",
      bslib::card_header("Fixed height"),
      bslib::card_body("Body")
    ))
  ),
  .sample(
    "card_no_fill",
    "tag",
    "card",
    "bslib",
    quote(bslib::card(
      fill = FALSE,
      bslib::card_header("No fill"),
      bslib::card_body("Body")
    ))
  ),
  # value_box is grouped with cards (not layout): bslib's own reference
  # groups it alongside card() and it shares card's fill and theme classes.
  # This is the same standalone shape used inside layout_columns_value_box
  # below, pinned once on its own so a change in value_box() itself is not
  # only ever seen through a layout_columns() wrapper.
  .sample(
    "value_box",
    "tag",
    "card",
    "bslib",
    quote(bslib::value_box(
      title = "Genes used",
      value = shiny::textOutput("ngenes_alone"),
      theme = "primary"
    ))
  ),

  # ---- layout ---------------------------------------------------------------
  .sample(
    "sidebar_layout",
    "page",
    "page",
    "bslib",
    quote(bslib::page_sidebar(
      title = "Demo",
      sidebar = bslib::sidebar(
        width = 290,
        shiny::selectInput("x", "Pick", choices = "A")
      ),
      bslib::card(bslib::card_header("Main"), bslib::card_body("Content"))
    ))
  ),
  # A titled sidebar, and a right-positioned, initially closed one with an
  # id, which makes it a Shiny input toggle_sidebar() can drive. Neither is
  # a page shell, so both are kind = "tag".
  .sample(
    "sidebar_layout_titled",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_sidebar(
      sidebar = bslib::sidebar(title = "Filters", width = 260),
      htmltools::div("main")
    ))
  ),
  .sample(
    "sidebar_layout_right_closed",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        title = "Selected study",
        position = "right",
        width = 360,
        open = "closed",
        id = "details_pane"
      ),
      htmltools::div("main")
    ))
  ),
  # sidebar(class = ...) puts the class on the <aside> itself, next to
  # "sidebar" (and "bslib-sidebar-input" once the sidebar has an id).
  .sample(
    "sidebar_custom_class",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 420,
        class = "my-sidebar",
        htmltools::div("a")
      ),
      htmltools::div("main")
    ))
  ),
  # Added for coverage: layout_sidebar(gap=, padding=) sets CSS custom
  # properties on the wrapping div that plain layout_sidebar() leaves at
  # their stylesheet defaults.
  .sample(
    "sidebar_layout_gap_padding",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_sidebar(
      sidebar = bslib::sidebar(width = 280, "Filters"),
      gap = "1rem",
      padding = "1rem",
      htmltools::div("main")
    ))
  ),
  .sample(
    "accordion_checkbox_groups",
    "tag",
    "layout",
    "bslib",
    quote(bslib::accordion(
      id = "filters",
      multiple = TRUE,
      open = c("organism", "source"),
      bslib::accordion_panel(
        "Organism",
        value = "organism",
        icon = shiny::icon("dna"),
        shiny::checkboxGroupInput("organisms", NULL, choices = character(0))
      ),
      bslib::accordion_panel(
        "Data source",
        value = "source",
        icon = shiny::icon("database"),
        shiny::checkboxGroupInput("sources", NULL, choices = character(0))
      )
    ))
  ),
  # Added for coverage: a bare accordion with no icons or inputs, the
  # shape most apps reach for first.
  .sample(
    "accordion",
    "tag",
    "layout",
    "bslib",
    quote(bslib::accordion(
      bslib::accordion_panel("Section A", "Content A"),
      bslib::accordion_panel("Section B", "Content B")
    ))
  ),
  .sample(
    "layout_columns_value_box",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_columns(
      fill = FALSE,
      col_widths = c(4, 4, 4),
      bslib::value_box(
        "PC1 variance",
        shiny::textOutput("pc1"),
        theme = "primary"
      ),
      bslib::value_box(
        "PC2 variance",
        shiny::textOutput("pc2"),
        theme = "warning"
      ),
      bslib::value_box(
        "Genes used",
        shiny::textOutput("ngenes"),
        theme = "secondary"
      )
    ))
  ),
  # layout_columns()'s default fill = TRUE shape. It differs from
  # layout_columns_value_box above (fill = FALSE) only by html-fill-item on
  # the outer tag, which is why both are pinned.
  .sample(
    "layout_columns_fill",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_columns(
      col_widths = c(7, 5),
      bslib::card(bslib::card_header("Left"), bslib::card_body("Left body")),
      bslib::card(bslib::card_header("Right"), bslib::card_body("Right body"))
    ))
  ),
  # Added for coverage: layout_columns() with a single child, the edge
  # case for col_widths recycling.
  .sample(
    "layout_columns_single_child",
    "tag",
    "layout",
    "bslib",
    quote(bslib::layout_columns(
      bslib::card(bslib::card_header("Only"), bslib::card_body("One card"))
    ))
  ),

  # ---- tooltip and popover --------------------------------------------------
  .sample(
    "tooltip",
    "tag",
    "tooltip",
    "bslib",
    quote(bslib::tooltip(shiny::icon("circle-info"), "Extra detail on hover"))
  ),
  .sample(
    "popover",
    "tag",
    "tooltip",
    "bslib",
    quote(bslib::popover(
      shiny::actionButton("pop_btn", "Options"),
      "Popover content here"
    ))
  ),

  # ---- nav strips (not a full page) -----------------------------------------
  .sample(
    "navset_card_tab",
    "tag",
    "nav",
    "bslib",
    quote(bslib::navset_card_tab(
      bslib::nav_panel("Tab A", "a"),
      bslib::nav_panel("Tab B", "b")
    ))
  ),
  .sample(
    "navset_pill",
    "tag",
    "nav",
    "bslib",
    quote(bslib::navset_pill(
      bslib::nav_panel("Tab A", "a"),
      bslib::nav_panel("Tab B", "b")
    ))
  ),

  # ---- misc -----------------------------------------------------------------
  .sample(
    "details_summary",
    "tag",
    "misc",
    "htmltools",
    quote(htmltools::tags$details(
      htmltools::tags$summary("Paste a list"),
      shiny::textAreaInput("x", label = NULL, rows = 3)
    ))
  ),
  .sample(
    "helpText_hr",
    "tag",
    "misc",
    "htmltools",
    quote(htmltools::tagList(
      htmltools::hr(),
      shiny::helpText("Some help text here.")
    ))
  ),
  .sample("icon", "tag", "misc", "shiny", quote(shiny::icon("chart-column"))),

  # ---- page shells --------------------------------------------------------
  #
  # bslib's nav builders pick their markup at render time from
  # shiny::getCurrentThemeVersion(), which reads the Shiny option
  # "bootstrapTheme", not bslib::bs_global_set() and not a page's own
  # theme= argument. Outside a running app that option is unset, and every
  # nav sample would render Bootstrap 3 markup (`<li class="active"><a>`,
  # not `<li class="nav-item"><a class="nav-link active">`), the bug
  # docs/decisions/0001-no-fixtures-live-ground-truth.md describes.
  # tools/markup/render-r.R sets the option around every render, which gives
  # the same markup a running app serves.
  .sample(
    "page_fillable",
    "page",
    "page",
    "bslib",
    quote(bslib::page_fillable(
      padding = 8,
      gap = 4,
      htmltools::tags$h2("Title")
    ))
  ),
  .sample(
    "page_navbar",
    "page",
    "page",
    "bslib",
    quote(bslib::page_navbar(
      title = "Demo",
      id = "nav",
      theme = bslib::bs_theme(version = 5),
      navbar_options = bslib::navbar_options(bg = "#447099", theme = "dark"),
      fillable = "Browse",
      bslib::nav_panel("Browse", "x"),
      bslib::nav_panel("Overview", "y"),
      bslib::nav_spacer(),
      bslib::nav_item(shiny::uiOutput("chip", inline = TRUE)),
      bslib::nav_item(bslib::input_dark_mode(id = "dark_mode")),
      footer = htmltools::div("foot")
    ))
  ),
  # nav_panel(icon = icon(...)) puts the icon inside the tab link, before
  # the label, with bslib's own fa-fw (fixed width) class added on top of
  # whatever icon() itself produced.
  .sample(
    "page_navbar_icon",
    "page",
    "page",
    "bslib",
    quote(bslib::page_navbar(
      title = "Demo",
      id = "nav",
      theme = bslib::bs_theme(version = 5),
      bslib::nav_panel("Explorer", "x", icon = shiny::icon("chart-column")),
      bslib::nav_panel("About", "y", icon = shiny::icon("circle-info"))
    ))
  ),
  # page_navbar(sidebar = ...): an app-wide sidebar beside every tab,
  # distinct from a per-panel layout_sidebar(). No navbar_options() at all
  # here either, matching a bare page_navbar() call with no bg and no
  # explicit navbar theme: data-bs-theme comes out "auto".
  .sample(
    "page_navbar_sidebar",
    "page",
    "page",
    "bslib",
    quote(bslib::page_navbar(
      title = "Demo",
      id = "nav",
      theme = bslib::bs_theme(version = 5),
      sidebar = bslib::sidebar(
        id = "dock",
        position = "left",
        open = "closed",
        width = 600,
        htmltools::div("chat")
      ),
      bslib::nav_panel("Build", htmltools::div("build content")),
      bslib::nav_panel("About", htmltools::div("about content")),
      footer = htmltools::tags$footer("foot")
    ))
  ),
  # Replaces an earlier fixture that was hand corrected because a plain
  # as.character() dump could not represent a nav_menu() dropdown
  # faithfully (see docs/markup-catalog.md, "Sample names"). Rendered under
  # the bootstrapTheme option, it needs no such correction.
  .sample(
    "page_navbar_dropdown",
    "page",
    "page",
    "bslib",
    quote(bslib::page_navbar(
      title = "Demo",
      id = "nav",
      theme = bslib::bs_theme(version = 5),
      bslib::nav_panel("Home", "x"),
      bslib::nav_menu(
        "Docs",
        bslib::nav_panel("Guide", "g"),
        bslib::nav_panel("FAQ", "f")
      )
    ))
  ),
  # Added for coverage: fillable = FALSE, the opposite end of page_navbar's
  # own fillable = "Browse" (one panel fillable, the other not) above. Every
  # tab-pane here carries no fill classes and no inline style at all.
  .sample(
    "page_navbar_not_fillable",
    "page",
    "page",
    "bslib",
    quote(bslib::page_navbar(
      title = "Demo",
      id = "nav",
      theme = bslib::bs_theme(version = 5),
      fillable = FALSE,
      bslib::nav_panel("Overview", "x"),
      bslib::nav_panel("Details", "y")
    ))
  )
)
