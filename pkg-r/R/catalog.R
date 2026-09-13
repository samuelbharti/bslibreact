# Read access to the sample list in catalog-samples.R. See
# docs/markup-catalog.md for the contract these feed into: the repository's
# markup catalog renderer (tools/markup/render-r.R), a dev-only script
# outside this package, is the writer.

# Every sample of the requested kind(s), in catalog order. Internal:
# nothing outside this package needs the full catalog, only page_deps()'s
# and catalog_names()'s narrower slices of it. kind is one or more of
# "tag", "page", "extra", though this package's own catalog-samples.R
# defines no "extra" entries; that kind exists for the dev-only renderer's
# own additional third-party-widget samples.
markup_catalog <- function(kind = c("tag", "page", "extra")) {
  valid <- c("tag", "page", "extra")
  if (!is.character(kind) || length(kind) == 0 || !all(kind %in% valid)) {
    cli::cli_abort("{.arg kind} must be one or more of {.val {valid}}.")
  }
  Filter(function(s) s$kind %in% kind, .catalog_samples)
}

# The names in a filtered slice of the catalog, in catalog order. Used by
# page_deps() to pick its default sampler (every "tag" and "page" sample).
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
# An unknown name is a programming error, so it aborts rather than
# silently returning NULL: page_deps(components=) relies on this to name
# the bad component in its own error.
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
  lapply(names, function(nm) eval(by_name[[nm]]$call, envir = env))
}
