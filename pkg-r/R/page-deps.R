# One entry per dependency name, keeping the highest version, in the order
# the names were first seen. numeric_version() is strict about what it will
# parse and these versions come from whatever upstream set them, so an
# unparsable one falls back to first-seen rather than erroring.
dedupe_by_name <- function(deps) {
  if (length(deps) < 2) {
    return(deps)
  }
  nms <- vapply(deps, function(d) d$name, character(1))
  keep <- vapply(
    split(seq_along(deps), factor(nms, levels = unique(nms))),
    function(idx) {
      v <- suppressWarnings(
        numeric_version(
          vapply(deps[idx], function(d) as.character(d$version), character(1)),
          strict = FALSE
        )
      )
      # max()/== rather than which.max(), which cannot coerce a
      # numeric_version on R older than 4.6. Same for any(is.na())
      # instead of anyNA(), which does not dispatch on one.
      if (any(is.na(v))) idx[[1]] else idx[[which(v == max(v))[[1]]]]
    },
    integer(1)
  )
  deps[unname(keep)]
}

# The baseline every shiny page attaches on its own. Kept in step by hand
# with _ALWAYS_EXCLUDED in the Python sibling's _deps.py; the two lists
# diverged once already, with R returning jquery that Python dropped.
ALWAYS_EXCLUDED <- c("bootstrap", "jquery")

#' Collect the page dependencies a client bundle needs
#'
#' Renders a representative sample of bslib and shiny markup under `theme`
#' and returns the [htmltools::htmlDependency()] objects that markup
#' attaches, deduplicated, minus the `"bootstrap"` and `"jquery"`
#' dependencies every shiny page already carries. Attach the result
#' to a shinyreact page alongside [bslib_react_dep()], for example
#' `shinyreact::page_react(page_deps(app_theme), bslib_react_dep(), theme = app_theme)`,
#' so the client gets exactly the CSS and JavaScript a matching bslib page
#' would have attached on its own: `sliderInput()`'s ionRangeSlider skin,
#' `selectizeInput()`'s selectize assets, `bslib::accordion()`'s and
#' `bslib::tooltip()`'s Bootstrap bundles, and so on.
#'
#' `"bootstrap"` itself is dropped from the result because a shinyreact page
#' already attaches its own theme through the page function's own `theme=`
#' argument (or gets no theme at all); attaching it twice serves the
#' compiled Bootstrap CSS from two dependency entries pointed at two
#' separately compiled copies, which is wasted bytes at best and, if the
#' two copies were compiled from different themes, a page that looks
#' different depending on which `<link>` happens to load last.
#'
#' @details
#' # The theme
#'
#' `theme`, when supplied, is set with [bslib::bs_global_set()] for the
#' duration of this call and restored on exit. Several bslib widgets,
#' `sliderInput()`'s ionRangeSlider skin among them, resolve their CSS
#' through [bslib::bs_dependency_defer()], which reads the globally active
#' theme at render time. Outside a running Shiny session, which is where
#' this function usually runs, that would be bslib's stock theme.
#'
#' Set a global theme with `bs_global_set()`, not
#' [bslib::bs_global_theme()]: its first argument is a Bootstrap version
#' number, so passing it a theme object builds a different, stock theme
#' and drops custom fonts.
#'
#' @param theme A [bslib::bs_theme()] object, or `NULL` for a themeless app
#'   (a plain `page_fillable()`/`page_sidebar()` with no `theme=` argument,
#'   for example). When not `NULL`, it is validated with
#'   [bslib::is_bs_theme()].
#' @param ... Additional tags to include in the dependency sample, unnamed
#'   (checked with [rlang::check_dots_unnamed()]). Use this for anything the
#'   default `components` sampler does not cover: a hosted third party
#'   widget (`DT::DTOutput()`, `reactable::reactableOutput()`), an icon
#'   pack, or a page-level element specific to one app.
#' @param components Character vector of catalog sample names to render for
#'   their dependencies, or `NULL` (the default) to
#'   use every `"tag"` and `"page"` sample, which is deliberately generous:
#'   an unused dependency costs the page one extra download, while a
#'   missing one is a widget that renders unstyled. Pass
#'   `character()` to include no catalog samples at all, relying only on
#'   `...`.
#'
#' @return A list of [htmltools::htmlDependency()] objects, one per
#'   dependency name, keeping the highest version of each, and with no
#'   dependency named `"bootstrap"` or `"jquery"`.
#'
#' @export
#' @examples
#' deps <- page_deps(bslib::bs_theme(version = 5))
#' length(deps)
#'
#' # A themeless app still gets the widget dependencies it needs (the
#' # ionRangeSlider skin, selectize assets, and so on), just with no
#' # bslib/Bootstrap theme compiled in.
#' length(page_deps(theme = NULL)) > 0
#'
#' \dontrun{
#' # A real app: attach page_deps() to a shinyreact page alongside
#' # bslib_react_dep(), after shinyreact's own dependency (both scripts
#' # are `defer`, so relative document order is what determines that
#' # shinyreact's globals exist before bslib-react's IIFE reads them).
#' app_theme <- bslib::bs_theme(version = 5)
#' ui <- shinyreact::page_react(
#'   title = "Demo",
#'   theme = app_theme,
#'   page_deps(app_theme),
#'   bslib_react_dep()
#' )
#' }

page_deps <- function(theme = NULL, ..., components = NULL) {
  rlang::check_dots_unnamed()

  if (!is.null(theme)) {
    if (!bslib::is_bs_theme(theme)) {
      cli::cli_abort(
        "{.arg theme} must be a {.fn bslib::bs_theme} object or NULL, not {.obj_type_friendly {theme}}."
      )
    }
    old <- bslib::bs_global_get()
    bslib::bs_global_set(theme)
    on.exit(
      if (is.null(old)) bslib::bs_global_clear() else bslib::bs_global_set(old),
      add = TRUE
    )
  }

  # catalog_eval() only evaluates each sample's call to get a tag tree, page
  # samples included; findDependencies() then reads the htmlDependency
  # objects attached to it. Nothing is rendered or served.
  components <- components %||% catalog_names(kind = c("tag", "page"))
  sampler <- htmltools::tagList(catalog_eval(components), ...)
  deps <- htmltools::findDependencies(sampler)

  # Every sample carries its own copy of the shared dependencies, so the
  # raw walk returns the same handful of names hundreds of times over.
  # Deliberately not htmltools::resolveDependencies(), which also rewrites
  # each dependency's `src` to an absolute path on this machine and drops
  # its `package` field: that would bake local paths into the result and
  # change the shape of the objects a caller gets back.
  deps <- dedupe_by_name(deps)

  # bootstrap and jquery are the baseline any shiny page already attaches,
  # so a caller reading this output should see only the extra things
  # bslib-react needs on top. Matches the Python sibling's _ALWAYS_EXCLUDED.
  deps[vapply(deps, function(d) !d$name %in% ALWAYS_EXCLUDED, logical(1))]
}
