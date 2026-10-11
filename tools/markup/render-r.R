#!/usr/bin/env Rscript
# Render the R half of the markup catalog contract in
# docs/markup-catalog.md. Run from the repository root:
#
#   Rscript tools/markup/render-r.R --key
#   Rscript tools/markup/render-r.R --out .cache/markup/r.json
#
# --key prints a cache key and exits 0, rendering nothing: pkg-js's vitest
# global setup calls this on every test run and only re-renders when the
# key differs from the cached file's own key. --out <path> renders the
# full catalog to that path and exits 0, or exits non-zero with a message
# on stderr if rendering fails.
#
# This script is deliberately self-contained rather than a thin wrapper
# around an exported pkg-r function: pkg-r ships only page_deps(),
# host_input(), and bslib_react_dep(), so that an app installing it gets
# no browser-automation or third-party-widget dependencies it does not
# need at runtime. Everything a *contributor* needs to render the full
# catalog -- the "extra" kind samples (DT, reactable, htmlwidgets,
# shinycssloaders) and the served-page app runner (callr, httpuv, curl,
# xml2) -- lives only here. Install those packages once to run this
# script; an app that merely depends on bslibreact never needs them.
#
# Reaches into pkg-r's unexported internals (bslibreact:::.catalog_samples,
# bslibreact:::.sample, bslibreact:::catalog_eval) rather than duplicating
# the "tag" and "page" sample list, so this script and the package can
# never drift on what those samples are.

args <- commandArgs(trailingOnly = TRUE)

# Always the checkout's pkg-r, never an installed bslibreact: a sample just
# added to pkg-r/R/catalog-samples.R must show up in the next render, and
# an older installed copy would silently hide it.
if (!requireNamespace("pkgload", quietly = TRUE)) {
  cat(
    "this script needs the 'pkgload' package installed.\n",
    file = stderr()
  )
  quit(status = 1)
}
# This script lives at tools/markup/render-r.R, two levels below the
# repository root; pkg-r sits alongside tools/ at that same root.
script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
)
# commandArgs() has no --file= when the script is sourced, so fall back to
# a path relative to the working directory, the repository root.
pkg_dir <- if (length(script_file) == 1) {
  normalizePath(
    file.path(dirname(script_file), "..", "..", "pkg-r"),
    winslash = "/"
  )
} else {
  "pkg-r"
}
pkgload::load_all(pkg_dir, quiet = TRUE)

for (pkg in c("cli", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(
      sprintf("this script needs the '%s' package installed.\n", pkg),
      file = stderr()
    )
    quit(status = 1)
  }
}

.pkg_available <- function(pkg) requireNamespace(pkg, quietly = TRUE)

# ---- the "extra" kind samples: dev-only, never shipped in pkg-r ------------
#
# Same shape as pkg-r's own (unexported) catalog entries
# (bslibreact:::.sample()), so downstream code treats every sample the
# same regardless of where it came from. Kept out of pkg-r/R/catalog-samples.R
# because DT, reactable, htmlwidgets, and shinycssloaders are dependencies
# only this renderer needs, never an installed app.
.extra_samples <- list(
  bslibreact:::.sample(
    "plotOutput_with_spinner",
    "extra",
    "output",
    "shinycssloaders",
    quote(shinycssloaders::withSpinner(shiny::plotOutput("x")))
  ),
  bslibreact:::.sample(
    "DTOutput",
    "extra",
    "output",
    "DT",
    quote(DT::DTOutput("x", fill = TRUE))
  ),
  bslibreact:::.sample(
    "DTOutput_no_fill",
    "extra",
    "output",
    "DT",
    quote(DT::DTOutput("x", fill = FALSE))
  ),
  bslibreact:::.sample(
    "htmlwidget_output",
    "extra",
    "output",
    "htmlwidgets",
    quote(htmlwidgets::shinyWidgetOutput("x", "foo", "100%", "400px"))
  ),
  bslibreact:::.sample(
    "reactableOutput",
    "extra",
    "output",
    "reactable",
    quote(reactable::reactableOutput("x"))
  )
)

.full_catalog <- c(bslibreact:::.catalog_samples, .extra_samples)

# ---- cache key --------------------------------------------------------------

.catalog_hash <- function(catalog) {
  parts <- vapply(
    catalog,
    function(s) paste(s$name, s$kind, deparse1(s$call), sep = ""),
    character(1)
  )
  rlang::hash(paste(parts, collapse = ""))
}

.markup_catalog_key <- function(catalog) {
  sprintf(
    "r;bslib=%s;shiny=%s;htmltools=%s;catalog=%s;renderer=1",
    utils::packageVersion("bslib"),
    utils::packageVersion("shiny"),
    utils::packageVersion("htmltools"),
    .catalog_hash(catalog)
  )
}

# ---- rendering ---------------------------------------------------------------

# Wrapping `deps` and `head_inline_css` in I() (base R's "AsIs") forces
# jsonlite to serialize them as a JSON array regardless of length: see
# docs/markup-catalog.md for why this matters for a length-1 or length-0
# vector specifically.
.render_result <- function(
  s,
  served,
  html = NULL,
  html_attrs = NULL,
  head_inline_css = character(),
  deps = character(),
  skipped = NULL
) {
  list(
    kind = s$kind,
    group = s$group,
    served = served,
    call = deparse1(s$call),
    html = html,
    html_attrs = html_attrs,
    head_inline_css = I(head_inline_css),
    deps = I(deps),
    skipped = skipped
  )
}

# kind = "tag" (and the fallback path for kind = "page" when serving is
# unavailable, and kind = "extra" once its package is confirmed present):
# a plain htmltools::renderTags() call, under the same Bootstrap-5-forcing
# wrap docs/markup-catalog.md requires. See pkg-r/R/catalog-samples.R's own
# header comment for exactly which bslib render hooks this wrap affects
# and why skipping it silently produces Bootstrap 3 markup.
.render_unserved_sample <- function(s, theme) {
  old_opt <- shiny::getShinyOption("bootstrapTheme")
  shiny::shinyOptions(bootstrapTheme = theme)
  on.exit(shiny::shinyOptions(bootstrapTheme = old_opt), add = TRUE)

  tag <- eval(s$call, envir = baseenv())
  r <- htmltools::renderTags(tag)
  deps <- sort(unique(vapply(
    r$dependencies,
    function(d) paste0(d$name, "@", d$version),
    character(1)
  )))
  .render_result(s, served = FALSE, html = as.character(r$html), deps = deps)
}

.port_http_get <- function(url, timeout = 5) {
  h <- curl::new_handle(timeout = timeout)
  tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
}

.port_tail <- function(path, n) {
  if (!file.exists(path)) {
    return(character())
  }
  lines <- readLines(path, warn = FALSE)
  utils::tail(lines, n)
}

# kind = "page", serving available: fetch the real served document from
# the background app started by .start_markup_server(), and separately
# evaluate the same call locally (never served) just to read off its
# htmlDependency objects (findDependencies() only ever needs a tag tree,
# not a served page). "html" below comes from the served fetch, never
# from this local evaluation.
.render_served_sample <- function(s, server) {
  fetch_url <- paste0(
    server$url,
    "?sample=",
    utils::URLencode(s$name, reserved = TRUE)
  )
  res <- .port_http_get(fetch_url, timeout = 20)
  if (is.null(res) || res$status_code != 200) {
    status <- if (is.null(res)) {
      "no response"
    } else {
      paste("status", res$status_code)
    }
    return(.render_result(
      s,
      served = FALSE,
      skipped = paste0("served render failed (", status, ")")
    ))
  }

  html_raw <- rawToChar(res$content)
  Encoding(html_raw) <- "UTF-8"
  doc <- xml2::read_html(html_raw)
  body_html <- as.character(xml2::xml_find_first(doc, "//body"))
  html_attrs <- as.list(xml2::xml_attrs(xml2::xml_find_first(doc, "//html")))
  head_css <- vapply(
    xml2::xml_find_all(doc, "//head//style"),
    xml2::xml_text,
    character(1)
  )

  tag <- eval(s$call, envir = baseenv())
  deps_list <- htmltools::findDependencies(tag)
  deps <- sort(unique(vapply(
    deps_list,
    function(d) paste0(d$name, "@", d$version),
    character(1)
  )))

  .render_result(
    s,
    served = TRUE,
    html = body_html,
    html_attrs = html_attrs,
    head_inline_css = unname(head_css),
    deps = deps
  )
}

# Starts one background Shiny app that answers every "page"-kind sample as
# a function of a query string (?sample=<name>). The background process
# loads the same checkout with pkgload::load_all().
.start_markup_server <- function(theme, pkg_dir, timeout = 60) {
  port <- httpuv::randomPort()
  log <- tempfile(fileext = ".log")

  proc <- callr::r_bg(
    function(port, pkg_dir, theme) {
      pkgload::load_all(pkg_dir, quiet = TRUE)
      shiny::shinyOptions(bootstrapTheme = theme)
      ui <- function(req) {
        qs <- shiny::parseQueryString(req$QUERY_STRING)
        nm <- qs$sample
        if (is.null(nm) || !nzchar(nm)) {
          return(shiny::tags$html(shiny::tags$body(
            "bslib-react markup catalog server: pass ?sample=<name>"
          )))
        }
        rendered <- bslibreact:::catalog_eval(nm)
        rendered[[1]]
      }
      server <- function(input, output, session) NULL
      shiny::runApp(
        shiny::shinyApp(ui = ui, server = server),
        port = port,
        launch.browser = FALSE
      )
    },
    args = list(port = port, pkg_dir = pkg_dir, theme = theme),
    stdout = log,
    stderr = "2>&1",
    user_profile = FALSE,
    system_profile = FALSE
  )

  url <- sprintf("http://127.0.0.1:%d/", port)
  started <- Sys.time()
  repeat {
    elapsed <- as.numeric(Sys.time() - started, units = "secs")
    if (!proc$is_alive()) {
      cat(.port_tail(log, 40), sep = "\n")
      cli::cli_abort(
        "the markup catalog server exited before it started. See the log above."
      )
    }
    res <- .port_http_get(url, timeout = 2)
    if (!is.null(res) && res$status_code == 200) {
      break
    }
    if (elapsed > timeout) {
      proc$kill()
      cat(.port_tail(log, 40), sep = "\n")
      cli::cli_abort(
        "the markup catalog server did not answer within {timeout}s."
      )
    }
    Sys.sleep(0.25)
  }
  list(process = proc, url = url, log = log)
}

.render_markup_catalog <- function(
  path,
  pkg_dir,
  components = NULL,
  served = c("auto", "never", "always"),
  theme = bslib::bs_theme(version = 5),
  cache = TRUE,
  quiet = FALSE
) {
  served <- match.arg(served)
  key <- .markup_catalog_key(.full_catalog)

  if (isTRUE(cache) && file.exists(path)) {
    existing <- tryCatch(jsonlite::read_json(path), error = function(e) NULL)
    if (!is.null(existing) && identical(existing$key, key)) {
      if (!quiet) {
        cli::cli_alert_info(
          "{.path {path}} is already fresh for key {.val {key}}."
        )
      }
      return(invisible(existing))
    }
  }

  catalog <- .full_catalog
  if (!is.null(components)) {
    catalog <- Filter(function(s) s$name %in% components, catalog)
  }

  serve_pkgs <- c("callr", "httpuv", "curl", "xml2")
  serve_have <- vapply(serve_pkgs, .pkg_available, logical(1))
  serve_available <- all(serve_have)
  has_page_samples <- any(vapply(
    catalog,
    function(s) identical(s$kind, "page"),
    logical(1)
  ))

  if (identical(served, "always") && !serve_available) {
    cli::cli_abort(
      "{.arg served} = \"always\" needs {.pkg {serve_pkgs[!serve_have]}} installed."
    )
  }
  do_serve <- has_page_samples && served != "never" && serve_available

  server <- NULL
  if (do_serve) {
    n_page <- sum(vapply(
      catalog,
      function(s) identical(s$kind, "page"),
      logical(1)
    ))
    if (!quiet) {
      cli::cli_alert_info(
        "starting a background app to serve {n_page} page sample{?s}"
      )
    }
    server <- .start_markup_server(theme, pkg_dir)
    on.exit(
      if (
        !is.null(server) &&
          !is.null(server$process) &&
          server$process$is_alive()
      ) {
        server$process$kill()
      },
      add = TRUE
    )
  }

  samples <- stats::setNames(
    vector("list", length(catalog)),
    vapply(catalog, function(s) s$name, character(1))
  )
  for (s in catalog) {
    samples[[s$name]] <- if (
      identical(s$kind, "extra") && !.pkg_available(s$pkg)
    ) {
      .render_result(
        s,
        served = FALSE,
        skipped = paste0("package ", s$pkg, " is not installed")
      )
    } else if (identical(s$kind, "page") && do_serve) {
      .render_served_sample(s, server)
    } else {
      .render_unserved_sample(s, theme)
    }
  }

  record <- list(
    schema = 1L,
    language = "r",
    key = key,
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    generator = list(
      package = "bslibreact",
      version = as.character(utils::packageVersion("bslibreact"))
    ),
    versions = list(
      bslib = as.character(utils::packageVersion("bslib")),
      shiny = as.character(utils::packageVersion("shiny")),
      htmltools = as.character(utils::packageVersion("htmltools")),
      runtime = paste("R", getRversion())
    ),
    samples = samples
  )

  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(
    record,
    path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )
  if (!quiet) {
    cli::cli_alert_success(
      "wrote {length(samples)} sample{?s} to {.path {path}}"
    )
  }
  invisible(record)
}

# ---- CLI ---------------------------------------------------------------------

if ("--key" %in% args) {
  cat(.markup_catalog_key(.full_catalog), "\n", sep = "")
  quit(status = 0)
}

out_flag <- which(args == "--out")
if (length(out_flag) == 1 && out_flag < length(args)) {
  out_path <- args[out_flag + 1]
  result <- tryCatch(
    {
      .render_markup_catalog(path = out_path, pkg_dir = pkg_dir)
      TRUE
    },
    error = function(e) {
      cat(
        "render_markup_catalog() failed: ",
        conditionMessage(e),
        "\n",
        sep = "",
        file = stderr()
      )
      FALSE
    }
  )
  quit(status = if (isTRUE(result)) 0 else 1)
}

cat(
  "usage: Rscript tools/markup/render-r.R --key\n",
  "       Rscript tools/markup/render-r.R --out <path>\n",
  file = stderr()
)
quit(status = 1)
