# The gallery shell: a sidebar listing every example, grouped by category.
# Selecting one shows two columns side by side, classic bslib + Shiny and
# bslib-react + shinyreact, each with its live demo and the complete source
# below it. Every example is a real, separate Shiny app under
# apps/<slug>/{classic,react}, started on demand and kept warm afterwards.
# Only a handful stay alive at once (see MAX_LIVE): booting all 84 at
# startup pins the CPU loading heavy packages and nothing ever gets ready.
# Real R throughout, no shinylive/webR: see gallery/README.md for why.
library(shiny)
library(bslib)

source("examples.R")

BY_SLUG <- stats::setNames(
  EXAMPLES,
  vapply(EXAMPLES, function(e) e$slug, character(1))
)

# ---- background app processes: started on demand, kept warm, capped ----

MAX_LIVE <- 8

.procs <- new.env(parent = emptyenv())

proc_alive <- function(key) {
  entry <- .procs[[key]]
  !is.null(entry) && !is.null(entry$proc) && entry$proc$is_alive()
}

# Keeps the most recently used apps running and stops the rest. Without a
# cap, browsing the whole gallery would leave 84 R processes resident.
evict_stale <- function(keep) {
  live <- Filter(proc_alive, ls(.procs))
  if (length(live) <= MAX_LIVE) {
    return(invisible())
  }
  used <- vapply(live, function(k) as.numeric(.procs[[k]]$used), numeric(1))
  candidates <- setdiff(live[order(used)], keep)
  for (key in utils::head(candidates, length(live) - MAX_LIVE)) {
    .procs[[key]]$proc$kill()
    rm(list = key, envir = .procs)
  }
  invisible()
}

ensure_started <- function(slug, mode) {
  key <- paste(slug, mode, sep = "/")
  if (proc_alive(key)) {
    entry <- .procs[[key]]
    entry$used <- Sys.time()
    .procs[[key]] <- entry
    return(invisible(key))
  }

  dir <- normalizePath(file.path("apps", slug, mode))
  port <- httpuv::randomPort()
  proc <- callr::r_bg(
    function(dir, port) shiny::runApp(dir, port = port, launch.browser = FALSE),
    args = list(dir = dir, port = port),
    stdout = tempfile(fileext = ".log"),
    stderr = "2>&1",
    user_profile = FALSE,
    system_profile = FALSE
  )
  .procs[[key]] <- list(
    proc = proc,
    url = sprintf("http://127.0.0.1:%d/", port),
    ready = FALSE,
    used = Sys.time()
  )
  invisible(key)
}

# Checks (and caches) whether a started process is answering yet. A short
# timeout keeps a not-yet-ready check cheap: a refused connection returns
# almost instantly, so this never meaningfully blocks the polling loop.
app_is_ready <- function(slug, mode) {
  key <- paste(slug, mode, sep = "/")
  entry <- .procs[[key]]
  if (is.null(entry)) {
    return(FALSE)
  }
  if (isTRUE(entry$ready)) {
    return(TRUE)
  }
  ok <- tryCatch(
    {
      res <- curl::curl_fetch_memory(
        entry$url,
        handle = curl::new_handle(timeout_ms = 400, connecttimeout_ms = 400)
      )
      res$status_code == 200
    },
    error = function(e) FALSE
  )
  if (ok) {
    entry$ready <- TRUE
    .procs[[key]] <- entry
  }
  ok
}

app_url <- function(slug, mode) .procs[[paste(slug, mode, sep = "/")]]$url

onStop(function() {
  for (key in ls(.procs)) {
    p <- .procs[[key]]$proc
    if (!is.null(p) && p$is_alive()) p$kill()
  }
})

# ---- code panels: read straight from the real files, never copied ----

read_code <- function(...) {
  path <- file.path(...)
  if (!file.exists(path)) {
    return(NULL)
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

# Every file someone needs to reproduce one side of one example, in the
# order they would read them. Labels double as a directory listing. The
# react side is one app spanning R and TypeScript, not two alternatives:
# bslibreact is its server half, the bslib-react npm package its client
# half, and app.R is the same either way.
BUILD_NOTE <- paste(
  "# once, from gallery/",
  "npm install",
  "npm run build     # bundles each src/ui.tsx to its app's www/ui.js",
  "",
  "# then run this example on its own",
  sep = "\n"
)

route_files <- function(slug, side) {
  spec <- switch(
    side,
    classic = list(
      list(
        label = "app.R",
        path = c("apps", slug, "classic", "app.R"),
        lang = "r"
      )
    ),
    react = list(
      list(
        label = "app.R",
        path = c("apps", slug, "react", "app.R"),
        lang = "r"
      ),
      list(
        label = "src/App.tsx",
        path = c("apps", slug, "react", "src", "App.tsx"),
        lang = "typescript"
      ),
      list(
        label = "src/ui.tsx",
        path = c("apps", slug, "react", "src", "ui.tsx"),
        lang = "typescript"
      )
    )
  )
  out <- lapply(spec, function(f) {
    text <- do.call(read_code, as.list(f$path))
    if (is.null(text)) {
      NULL
    } else {
      list(label = f$label, text = text, lang = f$lang)
    }
  })
  out <- Filter(Negate(is.null), out)
  run <- sprintf("shiny::runApp(\"gallery/apps/%s/%s\")", slug, side)
  build <- if (identical(side, "react")) {
    paste0(BUILD_NOTE, "\nRscript -e '", run, "'")
  } else {
    paste0("Rscript -e '", run, "'")
  }
  c(out, list(list(label = "Run it", text = build, lang = "bash")))
}

code_panel_ui <- function(files) {
  if (length(files) == 0) {
    return(p(class = "text-muted", "No source for this example."))
  }
  tagList(lapply(files, function(f) {
    tagList(
      tags$div(class = "gallery-file", f$label),
      tags$pre(tags$code(class = paste0("language-", f$lang), f$text))
    )
  }))
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
            class = "gallery-nav-link"
          ))
        })
      )
    )
  }))
}

# One demo column: a heading, a frame that shows a spinner until its
# backend answers, and the source below it. Deliberately not a card, the
# demo inside the frame already draws its own.
demo_column <- function(id, title, subtitle, code_body) {
  tags$div(
    class = "gallery-col",
    tags$div(class = "gallery-col-head", title),
    tags$div(class = "gallery-col-sub", subtitle),
    tags$div(
      class = "gallery-frame-wrap",
      tags$div(
        class = "gallery-spinner",
        id = paste0(id, "_spinner"),
        tags$div(class = "spinner-border text-secondary", role = "status"),
        tags$span(class = "gallery-spinner-text", "Starting the app...")
      ),
      tags$iframe(class = "gallery-demo-frame", id = paste0(id, "_frame"))
    ),
    code_body
  )
}

GALLERY_CSS <- "
.gallery-nav-heading { font-weight: 600; margin-top: 16px; font-size: .75rem; letter-spacing: .04em; text-transform: uppercase; color: var(--bs-secondary-color); }
.gallery-nav-heading:first-child { margin-top: 0; }
.gallery-nav-list { list-style: none; padding-left: 0; margin: 6px 0 0; }
.gallery-nav-list li { margin: 1px 0; }
.gallery-nav-link { display: block; padding: 5px 8px; border-radius: 6px; text-decoration: none; font-size: .9rem; }
.gallery-nav-link:hover { background: var(--bs-tertiary-bg); }
.gallery-title { margin: 0 0 2px; font-size: 1.45rem; font-weight: 650; }
.gallery-note { color: var(--bs-secondary-color); margin-bottom: 20px; }
.gallery-col-head { font-size: 1rem; font-weight: 650; }
.gallery-col-sub { font-size: .85rem; color: var(--bs-secondary-color); margin-bottom: 8px; }
.gallery-frame-wrap { position: relative; height: 52vh; min-height: 400px; margin-bottom: 18px; }
.gallery-demo-frame { width: 100%; height: 100%; border: 1px solid var(--bs-border-color); border-radius: 10px; background: var(--bs-body-bg); }
.gallery-spinner { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; background: var(--bs-body-bg); border: 1px solid var(--bs-border-color); border-radius: 10px; }
.gallery-spinner-text { color: var(--bs-secondary-color); font-size: .9rem; }
.gallery-file { font-family: var(--bs-font-monospace); font-size: .8rem; font-weight: 600; color: var(--bs-secondary-color); padding: 6px 10px; border: 1px solid var(--bs-border-color); border-bottom: 0; border-radius: 8px 8px 0 0; background: var(--bs-tertiary-bg); }
.gallery-col pre { margin: 0 0 16px; border: 1px solid var(--bs-border-color); border-radius: 0 0 8px 8px; background: var(--bs-body-bg); }
.gallery-col pre code { display: block; padding: 12px 14px; font-size: .82rem; line-height: 1.5; white-space: pre-wrap; overflow-wrap: anywhere; background: transparent; }
.gallery-col .nav-pills { margin-bottom: 10px; gap: 6px; }
.gallery-col .nav-pills .nav-link { padding: 4px 12px; font-size: .85rem; }
"

ui <- page_sidebar(
  title = "bslib-react component gallery",
  theme = bs_theme(version = 5),
  sidebar = sidebar(width = 270, nav_list()),
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css"
    ),
    tags$script(
      src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"
    ),
    tags$style(HTML(GALLERY_CSS))
  ),
  uiOutput("header"),
  layout_columns(
    col_widths = c(6, 6),
    demo_column(
      "classic",
      "bslib + Shiny",
      "The usual R stack, for comparison.",
      uiOutput("code_classic")
    ),
    demo_column(
      "react",
      "bslib-react + shinyreact",
      "One app: bslibreact serves it, the bslib-react npm package draws it.",
      uiOutput("code_react")
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
    tagList(
      h1(class = "gallery-title", e$title),
      p(class = "gallery-note", e$note)
    )
  })

  # Both columns are always visible, so both are started and tracked on
  # every selection change. Polls without blocking: invalidateLater()
  # re-runs this observer instead of freezing the session while an app boots.
  observe({
    slug <- selected()
    keys <- c(
      paste(slug, "classic", sep = "/"),
      paste(slug, "react", sep = "/")
    )
    for (mode in c("classic", "react")) {
      ensure_started(slug, mode)
    }
    evict_stale(keep = keys)

    pending <- FALSE
    for (mode in c("classic", "react")) {
      ready <- app_is_ready(slug, mode)
      if (!ready) {
        pending <- TRUE
      }
      session$sendCustomMessage(
        "gallery-set-frame",
        list(
          mode = mode,
          ready = ready,
          url = if (ready) app_url(slug, mode) else NULL
        )
      )
    }
    if (pending) invalidateLater(250, session)
  })

  output$code_classic <- renderUI(code_panel_ui(route_files(
    selected(),
    "classic"
  )))
  output$code_react <- renderUI(code_panel_ui(route_files(selected(), "react")))
}

ui <- tagList(
  ui,
  tags$script(HTML(
    "
    function galleryHighlight() {
      if (!window.hljs) return;
      document.querySelectorAll('.gallery-col pre code:not(.hljs)').forEach(function (el) {
        window.hljs.highlightElement(el);
      });
    }
    $(document).on('shiny:value', function () { setTimeout(galleryHighlight, 0); });
    $(document).on('shiny:connected', function () { setTimeout(galleryHighlight, 0); });

    Shiny.addCustomMessageHandler('gallery-set-frame', function (msg) {
      var frame = document.getElementById(msg.mode + '_frame');
      var spinner = document.getElementById(msg.mode + '_spinner');
      if (!frame || !spinner) return;
      if (msg.ready) {
        if (frame.src !== msg.url) frame.src = msg.url;
        spinner.style.display = 'none';
        frame.style.visibility = 'visible';
      } else {
        spinner.style.display = 'flex';
        frame.style.visibility = 'hidden';
      }
    });
  "
  ))
)

shinyApp(ui, server)
