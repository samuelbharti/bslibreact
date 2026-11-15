# The vendored bslibreact.js bundle. This mirrors the pattern in
# shinyreact's own pkg-r/R/dep.R (.dev_checkout()'s mtime cache-bust, in
# particular), renamed for this package: shinyreact vendors its own
# JavaScript client under inst/lib/shiny/; this package vendors the
# bslibreact IIFE bundle under inst/lib/bslibreact/, built by pkg-js and
# copied in by `make update-dist` (see the Makefile's r-update-dist
# target). Nothing in this file reads pkg-js's source; it only ever reads
# the already-built inst/lib/bslibreact/bslibreact.js.

.www_dir <- function() system.file("lib", "bslibreact", package = "bslibreact")

# The vendored bundle always ships with the release it was built for, so
# its version is the package's own (docs/decisions/0002).
.package_version <- function() {
  as.character(utils::packageVersion("bslibreact"))
}

# TRUE only in a repo checkout (devtools::load_all()), where the repo's
# pkg-js/package.json sits four levels above inst/lib/bslibreact/. Never
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

# The package version, suffixed with the bundle file's own mtime in a dev
# checkout. Installed, a page loads "<version>"; in the repo, where the same
# file can change between one `make update-dist` and the next without a
# version bump, it loads "<version>.<mtime>", so the browser's cache is
# still busted on a rebuild. Mirrors shinyreact's .bundle_version().
.bundle_version <- function() {
  if (.dev_checkout()) {
    mtime <- suppressWarnings(file.mtime(file.path(
      .www_dir(),
      "bslibreact.js"
    )))
    if (length(mtime) == 1L && !is.na(mtime)) {
      return(paste0(
        .package_version(),
        ".",
        sprintf("%.0f", as.numeric(mtime))
      ))
    }
  }
  .package_version()
}

#' The vendored bslibreact.js dependency
#'
#' Returns the [htmltools::htmlDependency()] for the vendored
#' `bslibreact.js` bundle (and its stylesheet, when one is built), which
#' sets `window.bslibreact`. Attach it only for a client with no build step
#' that reads the kit from that global, for example
#' `page_react(page_deps(app_theme), bslibreact_dep(), theme = app_theme)`.
#' A client built with Vite bundles the kit itself and does not need it.
#'
#' # Load order
#'
#' The bundle reads `window.shinyreact` as it evaluates, so it must run after
#' shinyreact's own bundle. `shinyreact::page_react()` attaches that first,
#' and both scripts use `defer`, which keeps document order. The app's own
#' `ui.js` also runs before this bundle, so a client script reads
#' `window.bslibreact` inside a `window` `load` listener.
#'
#' # Before `pkg-js` has built anything
#'
#' This function never errors for a missing bundle file: an
#' [htmltools::htmlDependency()] does not check that its files exist when
#' it is constructed, only once something actually tries to serve them, so
#' this returns a structurally valid dependency even when
#' `inst/lib/bslibreact/bslibreact.js` has not been vendored in yet. This
#' matters during this repository's
#' own development, where `pkg-js`'s build and `pkg-r`'s own checks can run
#' before `make update-dist` has ever populated `inst/lib/bslibreact/`.
#'
#' @return An [htmltools::htmlDependency()].
#' @export
#' @examples
#' dep <- bslibreact_dep()
#' dep$name
#' dep$script
bslibreact_dep <- function() {
  css <- file.path(.www_dir(), "bslibreact.css")
  htmltools::htmlDependency(
    name = "bslibreact",
    version = .bundle_version(),
    src = c(file = .www_dir()),
    script = list(src = "bslibreact.js", defer = ""),
    stylesheet = if (file.exists(css)) "bslibreact.css"
  )
}
