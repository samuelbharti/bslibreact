#!/usr/bin/env Rscript
# Render the R half of the markup catalog in docs/markup-catalog.md. Run
# from the repository root:
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
# need at runtime. The "extra" kind samples (DT, reactable, htmlwidgets,
# shinycssloaders) live only here; install those packages to render them.
# An app that depends on bslibreact never needs them.
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
    "r;bslib=%s;shiny=%s;htmltools=%s;catalog=%s;renderer=2",
    utils::packageVersion("bslib"),
    utils::packageVersion("shiny"),
    utils::packageVersion("htmltools"),
    .catalog_hash(catalog)
  )
}

# ---- rendering ---------------------------------------------------------------

# Every sample, page samples included, is a plain htmltools::renderTags()
# call under the Bootstrap-5-forcing option docs/markup-catalog.md
# requires: several bslib render hooks (the nav item builders above all)
# read shiny::getCurrentThemeVersion(), which reads that option, and
# rendering without it silently produces Bootstrap 3 markup. A page
# sample's html is its <body> tag, classes and inline style included, and
# its <head> <style> blocks go in head_inline_css.
.render_sample <- function(s, theme) {
  old_opt <- shiny::getShinyOption("bootstrapTheme")
  shiny::shinyOptions(bootstrapTheme = theme)
  on.exit(shiny::shinyOptions(bootstrapTheme = old_opt), add = TRUE)

  r <- htmltools::renderTags(eval(s$call, envir = baseenv()))
  head_css <- regmatches(
    as.character(r$head),
    gregexpr(
      "(?s)(?<=<style>).*?(?=</style>)",
      as.character(r$head),
      perl = TRUE
    )
  )[[1]]
  deps <- sort(unique(vapply(
    r$dependencies,
    function(d) paste0(d$name, "@", d$version),
    character(1)
  )))
  .result(
    s,
    html = as.character(r$html),
    head_css = trimws(head_css),
    deps = deps
  )
}

# I() ("AsIs") makes jsonlite write head_inline_css and deps as JSON arrays
# even when they hold zero or one element.
.result <- function(
  s,
  html = NULL,
  head_css = character(),
  deps = character(),
  skipped = NULL
) {
  list(
    kind = s$kind,
    group = s$group,
    call = deparse1(s$call),
    html = html,
    head_inline_css = I(head_css),
    deps = I(deps),
    skipped = skipped
  )
}

.render_markup_catalog <- function(path, theme = bslib::bs_theme(version = 5)) {
  samples <- lapply(.full_catalog, function(s) {
    if (identical(s$kind, "extra") && !.pkg_available(s$pkg)) {
      .result(s, skipped = paste0("package ", s$pkg, " is not installed"))
    } else {
      .render_sample(s, theme)
    }
  })
  names(samples) <- vapply(.full_catalog, function(s) s$name, character(1))

  record <- list(
    schema = 2L,
    language = "r",
    key = .markup_catalog_key(.full_catalog),
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
  cli::cli_alert_success("wrote {length(samples)} sample{?s} to {.path {path}}")
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
      .render_markup_catalog(path = out_path)
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
