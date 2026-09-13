#' Render the markup catalog to JSON
#'
#' Renders every sample in [markup_catalog()] (or a subset, via
#' `components`) using whichever bslib, shiny, and htmltools are actually
#' installed, and writes the result as JSON. This is the R half of the
#' contract documented in `docs/markup-catalog.md`; the matching JavaScript
#' package's test suite reads the file this function writes and compares
#' its own rendered React output against it.
#'
#' @param path Where to write the JSON file. The containing directory is
#'   created if needed.
#' @param components Character vector of catalog sample names to render,
#'   or `NULL` (the default) for the whole catalog.
#' @param served Controls whether `"page"`-kind samples (full bslib page
#'   shells) are rendered by starting a background Shiny app and fetching
#'   the real served document, or by falling back to a plain
#'   [htmltools::renderTags()] call on the bare tag (recorded as
#'   `served: false`):
#'   * `"auto"` (the default): serve when `callr`, `httpuv`, `curl`, and
#'     `xml2` are all installed and there is at least one `"page"` sample
#'     to render; fall back silently otherwise.
#'   * `"never"`: always use the fallback, even when serving is available.
#'   * `"always"`: require serving; errors if the needed packages are not
#'     installed, rather than silently falling back.
#'
#'   Serving matters for page shells specifically because bslib decides
#'   several components' markup, most importantly the navbar and its tabs,
#'   by asking `shiny::getCurrentThemeVersion()` at render time, which
#'   reads the Shiny option `"bootstrapTheme"` set while a real app serves
#'   a page. See the long comment above the `page_navbar` sample in
#'   `R/catalog-samples.R`, and
#'   `docs/decisions/0001-no-fixtures-live-ground-truth.md`, for the bug
#'   this once caused.
#' @param theme The [bslib::bs_theme()] every sample is rendered under.
#'   Defaults to a plain Bootstrap 5 theme, which is what makes nav markup
#'   (and everything else that branches on the active Bootstrap version)
#'   come out as a real app would render it, rather than bslib's Bootstrap
#'   3 fallback.
#' @param cache If `TRUE` (the default) and `path` already exists with a
#'   `key` matching [markup_catalog_key()], this function does nothing and
#'   returns the existing file's parsed content instead of re-rendering.
#' @param quiet If `FALSE` (the default), prints a short status message
#'   (whether the cache was already fresh, or how many samples were
#'   written) with [cli].
#'
#' @return Invisibly, the record that was written (or, when the cache was
#'   already fresh, the record read back from `path`), as a plain list.
#'
#' @export
#' @examples
#' \dontrun{
#' render_markup_catalog(path = ".cache/markup/r.json")
#' }
render_markup_catalog <- function(
  path = ".cache/markup/r.json",
  components = NULL,
  served = c("auto", "never", "always"),
  theme = bslib::bs_theme(version = 5),
  cache = TRUE,
  quiet = FALSE
) {
  served <- match.arg(served)
  key <- markup_catalog_key()

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

  catalog <- markup_catalog()
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
    server <- .start_markup_server(theme)
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
  # null = "null": jsonlite's default ("list") turns an R NULL nested in a
  # list into `{}` on write, not the JSON `null` the contract in
  # docs/markup-catalog.md requires for "html", "html_attrs", and
  # "skipped" when a sample has nothing to say there. Confirmed empirically
  # before relying on it; see the note above .render_result().
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

#' The markup catalog's cache key
#'
#' A single string that changes whenever the rendered catalog would
#' change: when bslib, shiny, or htmltools move to a different version,
#' when a sample's name, kind, or call changes (via `catalog_hash()`, an
#' internal function), or when this function's own format changes (the
#' trailing `renderer=` number). `pkg-js`'s test setup calls the matching
#' `--key` CLI mode
#' (`Rscript tools/markup/render-r.R --key`) on every test run and only
#' re-renders the cached JSON when the key differs, so this needs to be
#' cheap: it does not render anything.
#'
#' @param catalog The catalog to hash. Defaults to the whole catalog; pass
#'   a filtered [markup_catalog()] result to compute a key for a subset.
#'
#' @return A single string,
#'   `"r;bslib=<ver>;shiny=<ver>;htmltools=<ver>;catalog=<hash>;renderer=1"`.
#'
#' @export
#' @examples
#' markup_catalog_key()
markup_catalog_key <- function(catalog = markup_catalog()) {
  sprintf(
    "r;bslib=%s;shiny=%s;htmltools=%s;catalog=%s;renderer=1",
    utils::packageVersion("bslib"),
    utils::packageVersion("shiny"),
    utils::packageVersion("htmltools"),
    catalog_hash(catalog)
  )
}

# ---- internal rendering helpers --------------------------------------------

# One sample's JSON record. Wrapping `deps` and `head_inline_css` in I()
# (base R's "AsIs") forces jsonlite to serialize them as a JSON array
# regardless of length: a plain character vector of length 1 would
# otherwise come out as a bare string once auto_unbox = TRUE sees it
# (`"x"` instead of `["x"]`), and a plain `character(0)` alone would come
# out right ("[]") but only by accident, since an empty *list* serializes
# as "{}" instead (confirmed empirically: `jsonlite::toJSON(list())` is
# "{}", not "[]", because an R list has no way to say "empty array" versus
# "empty object" on its own). I() is documented jsonlite behavior for
# exactly this, and is applied consistently here rather than relying on
# length to happen to avoid the ambiguous cases.
#
# `html_attrs`, by contrast, wants OBJECT semantics (a named list of
# attribute name to value), including when there happen to be zero
# attributes, so it is left as a plain named list: jsonlite's "empty list
# is {}" behavior is exactly what that field needs when there is nothing
# to report.
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
# wrap docs/markup-catalog.md requires. See R/catalog-samples.R's own
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

# kind = "page", serving available: fetch the real served document from
# the background app started by .start_markup_server(), and separately
# evaluate the same call locally (never served) just to read off its
# htmlDependency objects. That second, unserved evaluation is legitimate
# for dependency collection specifically because findDependencies() only
# ever needs a tag tree, not a served page; see page-deps.R's own note on
# the same point. It is NOT legitimate for the rendered *markup* those
# dependencies come with, which is exactly why "html" below comes from the
# served fetch and not from this local evaluation.
.render_served_sample <- function(s, server) {
  fetch_url <- paste0(
    server$url,
    "?sample=",
    utils::URLencode(s$name, reserved = TRUE)
  )
  res <- port_http_get(fetch_url, timeout = 20)
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

# Start one background Shiny app that answers every "page"-kind sample as
# a function of a query string (?sample=<name>), the way
# docs/markup-catalog.md's render rules describe. Reuses
# port_http_get()/port_tail() from port-app.R (not the higher-level
# port_start_app(), which expects a directory containing an app.R: this
# app exists only as an R closure passed to callr::r_bg(), never written
# to disk, since its whole "ui" is just catalog_eval() dispatch).
#
# The background process loads this package with library() when it is
# actually installed, and falls back to pkgload::load_all() against the
# same source directory this session itself was loaded from otherwise
# (system.file(package = "bslibreact") resolves correctly in both cases:
# installed, or loaded via devtools::load_all(), since pkgload arranges
# for system.file() to keep working during development). This is what
# lets the served catalog renderer work equally from a plain
# `devtools::test()` run, before the package has ever been installed, and
# from an installed copy. pkgload is declared in Suggests for exactly
# this fallback branch; an installed package's own user never needs it,
# since requireNamespace("bslibreact") is TRUE for them and library()
# handles it instead.
.start_markup_server <- function(theme, timeout = 60) {
  port <- httpuv::randomPort()
  log <- tempfile(fileext = ".log")
  pkg_dir <- system.file(package = "bslibreact")

  proc <- callr::r_bg(
    function(port, pkg_dir, theme) {
      if (requireNamespace("bslibreact", quietly = TRUE)) {
        library(bslibreact)
      } else {
        pkgload::load_all(pkg_dir, quiet = TRUE)
      }
      shiny::shinyOptions(bootstrapTheme = theme)
      ui <- function(req) {
        qs <- shiny::parseQueryString(req$QUERY_STRING)
        nm <- qs$sample
        if (is.null(nm) || !nzchar(nm)) {
          return(shiny::tags$html(shiny::tags$body(
            "bslibreact markup catalog server: pass ?sample=<name>"
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
      cat(port_tail(log, 40), sep = "\n")
      cli::cli_abort(
        "the markup catalog server exited before it started. See the log above."
      )
    }
    res <- port_http_get(url, timeout = 2)
    if (!is.null(res) && res$status_code == 200) {
      break
    }
    if (elapsed > timeout) {
      proc$kill()
      cat(port_tail(log, 40), sep = "\n")
      cli::cli_abort(
        "the markup catalog server did not answer within {timeout}s."
      )
    }
    Sys.sleep(0.25)
  }
  list(process = proc, url = url, log = log)
}
