# The gallery shell: a sidebar listing every example, grouped by category.
# Selecting one shows it large on the right, classic bslib + Shiny or
# bslib-react + shinyreact, with a code panel comparing both. Every example
# is a real, separate Shiny app under apps/<slug>/{classic,react}; this
# shell starts each one lazily, in the background, the first time it is
# selected, and reuses the same running process after that (see
# get_app_url() below). Real R throughout, no shinylive/webR: this
# replaces the earlier static, shinylive-based version of this gallery,
# which was slow to cold start and could not run the react half live at
# all (see docs/decisions/ once written, and git history for why).
library(shiny)
library(bslib)

source("examples.R")

BY_SLUG <- stats::setNames(
  EXAMPLES,
  vapply(EXAMPLES, function(e) e$slug, character(1))
)

# ---- lazy per-(slug, mode) app process, cached for the life of this R session ----

.procs <- new.env(parent = emptyenv())

get_app_url <- function(slug, mode) {
  key <- paste(slug, mode, sep = "/")
  cached <- .procs[[key]]
  if (!is.null(cached) && cached$proc$is_alive()) {
    return(cached$url)
  }

  dir <- normalizePath(file.path("apps", slug, mode))
  port <- httpuv::randomPort()
  log <- tempfile(fileext = ".log")
  proc <- callr::r_bg(
    function(dir, port) shiny::runApp(dir, port = port, launch.browser = FALSE),
    args = list(dir = dir, port = port),
    stdout = log,
    stderr = "2>&1",
    user_profile = FALSE,
    system_profile = FALSE
  )

  url <- sprintf("http://127.0.0.1:%d/", port)
  started <- Sys.time()
  repeat {
    if (!proc$is_alive()) {
      stop(sprintf(
        "%s (%s) exited before it started:\n%s",
        slug,
        mode,
        paste(tail(readLines(log, warn = FALSE), 20), collapse = "\n")
      ))
    }
    ok <- tryCatch(
      {
        res <- curl::curl_fetch_memory(
          url,
          handle = curl::new_handle(timeout = 2)
        )
        res$status_code == 200
      },
      error = function(e) FALSE
    )
    if (ok) {
      break
    }
    if (as.numeric(Sys.time() - started, units = "secs") > 30) {
      proc$kill()
      stop(sprintf("%s (%s) did not answer within 30s", slug, mode))
    }
    Sys.sleep(0.2)
  }

  .procs[[key]] <- list(proc = proc, url = url)
  url
}

# Stop every background app when the gallery itself stops, so a restart
# during development never leaves orphaned R processes behind.
onStop(function() {
  for (key in ls(.procs)) {
    p <- .procs[[key]]$proc
    if (!is.null(p) && p$is_alive()) p$kill()
  }
})

# ---- code panel: read straight from the real files, never copied ----

read_code <- function(path) {
  if (!file.exists(path)) {
    return("")
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

example_code <- function(slug) {
  list(
    classic = read_code(file.path("apps", slug, "classic", "app.R")),
    react_r = read_code(file.path("apps", slug, "react", "app.R")),
    react_tsx = read_code(file.path("apps", slug, "react", "src", "App.tsx"))
  )
}

# ---- sidebar: one link per example, grouped by category ----

nav_list <- function() {
  tagList(lapply(CATEGORIES, function(cat) {
    items <- Filter(function(e) e$category == cat$key, EXAMPLES)
    tagList(
      tags$div(class = "gallery-nav-heading", cat$label),
      tags$ul(
        class = "gallery-nav-list",
        lapply(items, function(e) {
          tags$li(actionLink(
            inputId = paste0("nav_", gsub("-", "_", e$slug)),
            label = e$title,
            class = "gallery-nav-link",
            `data-slug` = e$slug
          ))
        })
      )
    )
  }))
}

ui <- page_sidebar(
  title = "bslib-react component gallery",
  theme = bs_theme(version = 5),
  sidebar = sidebar(
    width = 280,
    tags$style(HTML(
      "
      .gallery-nav-heading { font-weight: 600; margin-top: 14px; font-size: 0.8rem; text-transform: uppercase; color: var(--bs-secondary-color); }
      .gallery-nav-heading:first-child { margin-top: 0; }
      .gallery-nav-list { list-style: none; padding-left: 0; margin: 4px 0 0; }
      .gallery-nav-link { display: block; padding: 4px 6px; border-radius: 6px; text-decoration: none; }
      .gallery-nav-link.active { background: var(--bs-primary); color: white; }
      .gallery-demo-frame { width: 100%; height: 78vh; border: 1px solid var(--bs-border-color); border-radius: 8px; }
      .gallery-code-panel pre { background: #0d1117; color: #e6edf3; padding: 10px; border-radius: 6px; overflow-x: auto; font-size: 0.8rem; }
    "
    )),
    nav_list()
  ),
  uiOutput("header"),
  navset_pill(
    id = "mode",
    nav_panel(
      "bslib + Shiny",
      value = "classic",
      tags$iframe(
        class = "gallery-demo-frame",
        src = "about:blank",
        id = "classic_frame"
      )
    ),
    nav_panel(
      "bslib-react + shinyreact",
      value = "react",
      tags$iframe(
        class = "gallery-demo-frame",
        src = "about:blank",
        id = "react_frame"
      )
    )
  ),
  checkboxInput("show_code", "Show code", value = FALSE),
  conditionalPanel(
    "input.show_code",
    layout_columns(
      col_widths = c(6, 6),
      div(
        class = "gallery-code-panel",
        h5("bslib + Shiny"),
        tags$pre(tags$code(textOutput("code_classic", inline = TRUE)))
      ),
      div(
        class = "gallery-code-panel",
        h5("bslib-react + shinyreact"),
        tags$pre(tags$code(textOutput("code_react_r", inline = TRUE))),
        tags$pre(tags$code(textOutput("code_react_tsx", inline = TRUE)))
      )
    )
  )
)

server <- function(input, output, session) {
  selected <- reactiveVal(EXAMPLES[[1]]$slug)

  lapply(EXAMPLES, function(e) {
    input_id <- paste0("nav_", gsub("-", "_", e$slug))
    observeEvent(input[[input_id]], selected(e$slug), ignoreInit = TRUE)
  })

  current <- reactive(BY_SLUG[[selected()]])

  output$header <- renderUI({
    e <- current()
    tagList(h3(e$title), p(class = "text-muted", e$note))
  })

  # Only the currently active pill's backend is started. Switching pills
  # (or examples) blocks this session for a couple of seconds the first
  # time a given (slug, mode) is viewed, while that background process
  # boots; every later view of the same one reuses it instantly.
  observe({
    slug <- current()$slug
    mode <- if (is.null(input$mode)) "classic" else input$mode
    url <- get_app_url(slug, mode)
    session$sendCustomMessage("gallery-set-frame", list(mode = mode, url = url))
  })

  code <- reactive(example_code(selected()))
  output$code_classic <- renderText(code()$classic)
  output$code_react_r <- renderText(code()$react_r)
  output$code_react_tsx <- renderText(code()$react_tsx)
  # The code panel starts hidden behind a conditionalPanel; without this,
  # Shiny suspends these three outputs until it is first shown, and they
  # never render their initial value in time for the click that reveals
  # them (see docs/build.md, "Hosting a widget", the same suspend rule).
  outputOptions(output, "code_classic", suspendWhenHidden = FALSE)
  outputOptions(output, "code_react_r", suspendWhenHidden = FALSE)
  outputOptions(output, "code_react_tsx", suspendWhenHidden = FALSE)
}

# A tiny bit of custom JS: set only the currently active pill's iframe
# src, and only when it actually changes, so switching examples or pills
# never reloads a frame that already has the right thing loaded.
ui <- tagList(
  ui,
  tags$script(HTML(
    "
    Shiny.addCustomMessageHandler('gallery-set-frame', function(msg) {
      var frame = document.getElementById(msg.mode + '_frame');
      if (frame && frame.src !== msg.url) frame.src = msg.url;
    });
  "
  ))
)

shinyApp(ui, server)
