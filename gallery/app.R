# The gallery shell: a sidebar listing every example, grouped by category.
# Selecting one shows three columns side by side, classic bslib + Shiny,
# bslib-react built from npm, and bslib-react from the R package's own
# vendored bundle, each with its live demo and complete source below it.
# Every one is a real, separate Shiny app under
# apps/<slug>/{classic,vite,rpkg}, started on demand and kept warm after.
# Only a handful stay alive at once (see MAX_LIVE): booting all of them at
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

# The three variants each example is shown in, left to right.
MODES <- c("classic", "vite", "rpkg")

# Three apps per example, so this keeps three examples warm.
MAX_LIVE <- 9

.procs <- new.env(parent = emptyenv())

# Not every example necessarily has all three variants built.
has_variant <- function(slug, mode) dir.exists(file.path("apps", slug, mode))

proc_alive <- function(key) {
  entry <- .procs[[key]]
  !is.null(entry) && !is.null(entry$proc) && entry$proc$is_alive()
}

# Keeps the most recently used apps running and stops the rest. Without a
# cap, browsing the whole gallery would leave over a hundred R processes resident.
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

# Every file someone needs to reproduce one variant of one example, in the
# order they would read them. Labels double as a directory listing.
#
# app.R is byte identical across vite and rpkg on purpose: bslibreact is
# the server half of both, and the only thing that changes is where the
# client comes from. vite builds it from TSX with Vite; rpkg hand-writes
# it against the bundle the R package already vendors, so it needs no npm
# and no build step at all.
BUILD_NOTE <- paste(
  "# once, from the repository root",
  "npm ci",
  "make bundles      # bundles each src/ui.tsx to its app's www/ui.js",
  "",
  "# then run this example on its own",
  sep = "\n"
)

NO_BUILD_NOTE <- "# no npm, no build step, just run it\n"

route_files <- function(slug, variant) {
  spec <- switch(
    variant,
    classic = list(
      list(
        label = "app.R",
        path = c("apps", slug, "classic", "app.R"),
        lang = "r"
      )
    ),
    vite = list(
      list(
        label = "app.R",
        path = c("apps", slug, "vite", "app.R"),
        lang = "r"
      ),
      list(
        label = "src/App.tsx",
        path = c("apps", slug, "vite", "src", "App.tsx"),
        lang = "typescript"
      ),
      list(
        label = "src/ui.tsx",
        path = c("apps", slug, "vite", "src", "ui.tsx"),
        lang = "typescript"
      )
    ),
    rpkg = list(
      list(
        label = "app.R",
        path = c("apps", slug, "rpkg", "app.R"),
        lang = "r"
      ),
      list(
        label = "www/ui.js",
        path = c("apps", slug, "rpkg", "www", "ui.js"),
        lang = "javascript"
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
  if (length(out) == 0) {
    return(list())
  }
  run <- sprintf(
    "Rscript -e 'shiny::runApp(\"gallery/apps/%s/%s\")'",
    slug,
    variant
  )
  run <- switch(
    variant,
    vite = paste0(BUILD_NOTE, "\n", run),
    rpkg = paste0(NO_BUILD_NOTE, run),
    run
  )
  c(out, list(list(label = "Run it", text = run, lang = "bash")))
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

REPO_URL <- "https://github.com/samuelbharti/bslib-react"

gallery_footer <- function() {
  tags$footer(
    class = "gallery-footer",
    tags$span(
      "Every component built three ways, running live. Source read straight",
      "from the files each demo runs."
    ),
    tags$span(
      class = "gallery-footer-spacer",
      "Built by ",
      tags$a(
        href = "https://github.com/samuelbharti",
        target = "_blank",
        rel = "noopener",
        "Samuel Bharti"
      )
    ),
    tags$a(
      href = REPO_URL,
      target = "_blank",
      rel = "noopener",
      "Source"
    ),
    tags$a(
      href = paste0(REPO_URL, "/issues"),
      target = "_blank",
      rel = "noopener",
      "Report an issue"
    ),
    tags$a(
      href = paste0(REPO_URL, "/blob/main/LICENSE"),
      target = "_blank",
      rel = "noopener",
      "MIT licensed"
    )
  )
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
.bslib-sidebar-layout > aside > .sidebar-content { padding: 10px 12px 14px !important; gap: 2px !important; }
.gallery-nav-heading { font-weight: 600; margin-top: 7px; font-size: .68rem; letter-spacing: .04em; text-transform: uppercase; color: var(--bs-secondary-color); }
.gallery-nav-heading:first-child { margin-top: 0; }
.gallery-nav-list { list-style: none; padding-left: 0; margin: 3px 0 0; }
.gallery-nav-list li { margin: 0; }
.gallery-nav-link { display: block; padding: 3px 7px; border-radius: 5px; text-decoration: none; font-size: .82rem; line-height: 1.4; min-height: 24px; }
.gallery-nav-link:hover { background: var(--bs-tertiary-bg); }
.gallery-title { margin: 0 0 1px; font-size: 1.25rem; font-weight: 650; }
.gallery-note { color: var(--bs-secondary-color); font-size: .85rem; margin-bottom: 10px; }
.gallery-col-head { font-size: .92rem; font-weight: 650; }
.gallery-col-sub { font-size: .78rem; color: var(--bs-secondary-color); margin-bottom: 6px; }
.gallery-frame-wrap { position: relative; height: 46vh; min-height: 330px; margin-bottom: 12px; }
.gallery-demo-frame { width: 100%; height: 100%; border: 1px solid var(--bs-border-color); border-radius: 10px; background: var(--bs-body-bg); }
.gallery-spinner { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; background: var(--bs-body-bg); border: 1px solid var(--bs-border-color); border-radius: 10px; }
.gallery-spinner-text { color: var(--bs-secondary-color); font-size: .9rem; }
.gallery-file { font-family: var(--bs-font-monospace); font-size: .8rem; font-weight: 600; color: var(--bs-secondary-color); padding: 4px 9px; border: 1px solid var(--bs-border-color); border-bottom: 0; border-radius: 8px 8px 0 0; background: var(--bs-tertiary-bg); }
.gallery-col pre { margin: 0 0 12px; border: 1px solid var(--bs-border-color); border-radius: 0 0 8px 8px; background: var(--bs-body-bg); }
.gallery-col pre code { display: block; padding: 10px 12px; font-size: .76rem; line-height: 1.45; white-space: pre-wrap; overflow-wrap: anywhere; background: transparent; }
.gallery-col .nav-pills { margin-bottom: 10px; gap: 6px; }
.gallery-col .nav-pills .nav-link { padding: 4px 12px; font-size: .85rem; }
.gallery-brand { display: flex; align-items: center; justify-content: space-between; width: 100%; gap: 12px; }
.gallery-brand-link { font-size: .85rem; font-weight: 500; text-decoration: none; padding: 3px 10px; border: 1px solid var(--bs-border-color); border-radius: 6px; }
.gallery-brand-link:hover { background: var(--bs-tertiary-bg); }
.gallery-footer { margin-top: 8px; padding: 14px 0 4px; border-top: 1px solid var(--bs-border-color); display: flex; flex-wrap: wrap; align-items: center; gap: 6px 14px; font-size: .8rem; color: var(--bs-secondary-color); }
.gallery-footer a { color: inherit; text-decoration: underline; text-underline-offset: 2px; }
.gallery-footer a:hover { color: var(--bs-link-color); }
.gallery-footer-spacer { margin-left: auto; }
"

ui <- page_sidebar(
  title = tags$div(
    class = "gallery-brand",
    tags$span("bslib-react component gallery"),
    tags$a(
      class = "gallery-brand-link",
      href = REPO_URL,
      target = "_blank",
      rel = "noopener",
      "GitHub"
    )
  ),
  theme = bs_theme(version = 5),
  # Not fillable: the code panels below each demo are as tall as the files
  # they show, so the main column flows and the page scrolls once, rather
  # than every panel getting its own nested scrollbar.
  fillable = FALSE,
  sidebar = sidebar(width = 210, nav_list()),
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
    col_widths = c(4, 4, 4),
    demo_column(
      "classic",
      "bslib + Shiny",
      "The usual R stack, for comparison.",
      uiOutput("code_classic")
    ),
    demo_column(
      "vite",
      "bslib-react from npm",
      "UI written in TSX, bundled by Vite. Needs Node.",
      uiOutput("code_vite")
    ),
    demo_column(
      "rpkg",
      "bslib-react from the R package",
      "Same UI from the vendored bundle. No npm, no build step.",
      uiOutput("code_rpkg")
    )
  ),
  gallery_footer()
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

  # All three columns are always visible, so all three are started and
  # tracked on every selection change. Polls without blocking:
  # invalidateLater() re-runs this observer instead of freezing the session
  # while an app boots.
  observe({
    slug <- selected()
    present <- Filter(function(m) has_variant(slug, m), MODES)
    keys <- paste(slug, present, sep = "/")
    for (mode in present) {
      ensure_started(slug, mode)
    }
    evict_stale(keep = keys)

    pending <- FALSE
    for (mode in MODES) {
      if (!has_variant(slug, mode)) {
        session$sendCustomMessage(
          "gallery-set-frame",
          list(mode = mode, ready = FALSE, missing = TRUE)
        )
        next
      }
      ready <- app_is_ready(slug, mode)
      if (!ready) {
        pending <- TRUE
      }
      session$sendCustomMessage(
        "gallery-set-frame",
        list(
          mode = mode,
          ready = ready,
          missing = FALSE,
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
  output$code_vite <- renderUI(code_panel_ui(route_files(selected(), "vite")))
  output$code_rpkg <- renderUI(code_panel_ui(route_files(selected(), "rpkg")))
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
      var label = spinner.querySelector('.gallery-spinner-text');
      var busy = spinner.querySelector('.spinner-border');
      if (msg.missing) {
        spinner.style.display = 'flex';
        frame.style.visibility = 'hidden';
        if (busy) busy.style.display = 'none';
        if (label) label.textContent = 'Not available for this component.';
        return;
      }
      if (busy) busy.style.display = '';
      if (label) label.textContent = 'Starting the app...';
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
