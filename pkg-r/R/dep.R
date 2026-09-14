# The vendored bslib-react.js bundle. This mirrors the pattern in
# shinyreact's own pkg-r/R/dep.R (.dev_checkout()'s mtime cache-bust, in
# particular), renamed for this package: shinyreact vendors its own
# JavaScript client under inst/lib/shiny/; this package vendors the
# bslib-react IIFE bundle under inst/lib/bslib-react/, built by pkg-js and
# copied in by `make update-dist` (see the Makefile's r-update-dist
# target). Nothing in this file reads pkg-js's source; it only ever reads
# the already-built inst/lib/bslib-react/bslib-react.js.

.www_dir <- function() system.file("lib", "bslib-react", package = "bslibreact")

# The bslib-react.js bundle's own version, i.e. the release of pkg-js this
# copy was vendored from. Bump alongside pkg-js/package.json's version;
# test-version.R checks the two agree once pkg-js exists in this checkout.
# Mirrors shinyreact's .shinyreact_js_version and this package's own
# Python sibling's _BSLIB_REACT_JS_VERSION.
.bslib_react_js_version <- "0.0.1"

# TRUE only in a repo checkout (devtools::load_all()), where the repo's
# pkg-js/package.json sits four levels above inst/lib/bslib-react/. Never
# TRUE for an installed package, since an install ships inst/lib/ but not
# the sibling pkg-js/ source tree it was built from.
.dev_checkout <- function() {
  file.exists(file.path(
    .www_dir(),
    "..",
    "..",
    "..",
    "..",
    "pkg-js",
    "package.json"
  ))
}

# .bslib_react_js_version, suffixed with the bundle file's own mtime in a
# dev checkout. Installed, a page loads version "0.0.1"; in the repo, where
# the same file on disk can change between one `make update-dist` and the
# next without this constant being bumped, it loads "0.0.1.<mtime>"
# instead, so the browser's own dependency cache still gets busted on a
# rebuild while the version string still names the release. Mirrors
# shinyreact's .bundle_version().
.bundle_version <- function() {
  if (.dev_checkout()) {
    mtime <- suppressWarnings(file.mtime(file.path(
      .www_dir(),
      "bslib-react.js"
    )))
    if (length(mtime) == 1L && !is.na(mtime)) {
      return(paste0(.bslib_react_js_version, ".", as.integer(mtime)))
    }
  }
  .bslib_react_js_version
}

#' The vendored bslib-react.js dependency
#'
#' Returns the [htmltools::htmlDependency()] for the vendored
#' `bslib-react.js` bundle (and its stylesheet, when one is built). Attach
#' this to a shinyreact page alongside [page_deps()]'s result, for example
#' `shinyreact::page_react(..., page_deps(app_theme), bslib_react_dep())`.
#'
#' # Load order
#'
#' `bslib_react_dep()` must be attached to the page *after* shinyreact's
#' own bundle dependency (whatever attaches `shinyreact.js`, typically
#' something `shinyreact::page_react()` already does on its own). Both
#' scripts load with `defer`, so the browser is free to fetch them in
#' parallel; what `defer` does guarantee is that deferred scripts *execute*
#' in the relative order they appear in the document, after the DOM is
#' parsed. `bslib-react.js` is an IIFE that reads `window.shinyreact.React`
#' and `window.shinyreact.ReactDOM` at the moment it evaluates, expecting
#' shinyreact's own bundle to have already run and populated that global.
#' Get the order backwards and `bslib-react.js` throws while trying to read
#' a property of `undefined`, before it ever assigns `window.bslibReact`.
#'
#' # Before `pkg-js` has built anything
#'
#' This function never errors for a missing bundle file: an
#' [htmltools::htmlDependency()] does not check that its files exist when
#' it is constructed, only once something actually tries to serve them, so
#' this returns a structurally valid dependency even when
#' `inst/lib/bslib-react/bslib-react.js` has not been vendored in yet. This
#' matters during this repository's
#' own development, where `pkg-js`'s build and `pkg-r`'s own checks can run
#' before `make update-dist` has ever populated `inst/lib/bslib-react/`.
#'
#' @return An [htmltools::htmlDependency()].
#' @export
#' @examples
#' dep <- bslib_react_dep()
#' dep$name
#' dep$script
bslib_react_dep <- function() {
  css <- file.path(.www_dir(), "bslib-react.css")
  htmltools::htmlDependency(
    name = "bslib-react",
    version = .bundle_version(),
    src = c(file = .www_dir()),
    script = list(src = "bslib-react.js", defer = ""),
    stylesheet = if (file.exists(css)) "bslib-react.css"
  )
}
