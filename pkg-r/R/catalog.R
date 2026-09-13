# Read access to the sample list in catalog-samples.R, plus the hashing
# used to detect when the catalog itself has changed. See
# docs/markup-catalog.md for the contract these feed into
# (render_markup_catalog(), in catalog-render.R, is the writer).

#' The markup catalog
#'
#' A catalog of bslib and shiny calls whose rendered markup this package
#' and the matching JavaScript package's tests are pinned against. Each
#' entry is a list with `name`, `kind` (`"tag"`, `"page"`, or `"extra"`),
#' `group` (one of `"page"`, `"nav"`, `"layout"`, `"card"`, `"tooltip"`,
#' `"output"`, `"input"`, `"misc"`), `pkg` (the package the call's root
#' function belongs to, checked with [requireNamespace()] for `"extra"`
#' entries before evaluating), and `call` (an unevaluated, fully qualified
#' R call; see `catalog_eval()`, an internal function).
#'
#' See `docs/markup-catalog.md` at the repository root for the full render
#' contract, including why `"page"` samples are served from a real running
#' app rather than rendered as a bare tag.
#'
#' @param kind One or more of `"tag"`, `"page"`, `"extra"`. Defaults to all
#'   three.
#'
#' @return A list of catalog entries, in a stable order (the order they are
#'   defined in `R/catalog-samples.R`), filtered to the requested kind(s).
#'
#' @export
#' @examples
#' length(markup_catalog())
#' markup_catalog(kind = "extra")[[1]]$name
markup_catalog <- function(kind = c("tag", "page", "extra")) {
  valid <- c("tag", "page", "extra")
  if (!is.character(kind) || length(kind) == 0 || !all(kind %in% valid)) {
    cli::cli_abort("{.arg kind} must be one or more of {.val {valid}}.")
  }
  Filter(function(s) s$kind %in% kind, .catalog_samples)
}

# The names in a filtered slice of the catalog, in catalog order. Used by
# page_deps() to pick its default sampler (every "tag" and "page" sample)
# and by render_markup_catalog() to know what it needs to produce a
# complete JSON file.
catalog_names <- function(kind = c("tag", "page", "extra")) {
  vapply(markup_catalog(kind), function(s) s$name, character(1))
}

# Evaluate one or more catalog samples by name, returning a list of tags in
# the same order as `names` (not catalog order). `env` is where each call
# is evaluated; the default, baseenv(), is enough because every call in
# catalog-samples.R is fully qualified and closes over no free variables of
# its own, and using the base environment rather than the caller's global
# environment keeps a sample's evaluation from accidentally picking up an
# unrelated object of the same name (an "x" left lying around in .GlobalEnv,
# say) that happens to be in scope.
#
# A "kind: extra" sample whose package is not installed evaluates to NULL
# instead of erroring, so a caller can Filter(Negate(is.null), ...) the
# result when that matters, and so a single missing optional package never
# takes down page_deps()'s default sampler (which never includes "extra"
# samples in the first place) or a caller who explicitly asked for one.
#
# An unknown name is a programming error, not a missing optional package,
# so it aborts rather than silently returning NULL: page_deps(components=)
# relies on this to name the bad component in its own error.
catalog_eval <- function(names, env = baseenv()) {
  all <- .catalog_samples
  by_name <- stats::setNames(all, vapply(all, function(s) s$name, character(1)))
  unknown <- setdiff(names, names(by_name))
  if (length(unknown) > 0) {
    cli::cli_abort(
      "Unknown catalog sample name{?s}: {.val {unknown}}.",
      class = "bslibreact_unknown_sample"
    )
  }
  lapply(names, function(nm) {
    s <- by_name[[nm]]
    if (identical(s$kind, "extra") && !.pkg_available(s$pkg)) {
      return(NULL)
    }
    eval(s$call, envir = env)
  })
}

# A stable hash of the catalog's shape: every sample's name, kind, and the
# deparsed source of its call, concatenated and hashed. render_markup_catalog()
# folds this into markup_catalog_key() so that editing catalog-samples.R
# (adding, removing, renaming a sample, or changing what a call does)
# changes the key even when bslib, shiny, and htmltools have not moved,
# which is what tells pkg-js's global-setup to re-render its cached copy
# instead of trusting a stale one.
#
# Hash choice: rlang::hash() (a thin wrapper over a fast, non-cryptographic
# hash, xxhash) has been part of rlang since well before the minimum
# version this package requires (rlang >= 1.1.0), so it is used directly.
# The fallback below only matters if this package is ever run against a
# rlang build stripped of that export, which is not expected to happen in
# practice; it uses tools::md5sum() on a temp file rather than adding a
# new dependency (digest:: or openssl::) for something this package would
# otherwise use exactly once. A concatenation of character counts or
# similar arithmetic "hash" is deliberately not used: it collides far too
# easily on the kind of small, similarly shaped text this function hashes
# (two calls that differ only by swapping two argument values, for
# example, can sum to the same total).
catalog_hash <- function(catalog = markup_catalog()) {
  parts <- vapply(
    catalog,
    function(s) {
      paste(s$name, s$kind, deparse1(s$call), sep = "")
    },
    character(1)
  )
  content <- paste(parts, collapse = "")

  if (exists("hash", where = asNamespace("rlang"), inherits = FALSE)) {
    return(rlang::hash(content))
  }

  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)
  writeLines(content, tmp, useBytes = TRUE)
  unname(tools::md5sum(tmp))
}
