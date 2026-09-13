#' Collect the page dependencies a client bundle needs
#'
#' Renders a representative sample of bslib and shiny markup under `theme`
#' and returns the [htmltools::htmlDependency()] objects that markup
#' attaches, minus the `"bootstrap"` dependency itself. Attach the result
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
#' # `bs_global_set()`, not `bs_global_theme()`
#'
#' `theme`, when supplied, is set with [bslib::bs_global_set()] for the
#' duration of this call and restored (to whatever was globally set before,
#' or cleared if nothing was) on exit. This matters because several bslib
#' widgets, `sliderInput()`'s ionRangeSlider skin among them, resolve their
#' real CSS through [bslib::bs_dependency_defer()], a lazy
#' [htmltools::tagFunction()] that only resolves against the theme that is
#' globally active *at render time*, not any theme value merely passed as
#' an argument somewhere in the call tree. Outside a running Shiny session,
#' which is exactly the situation here since this function typically runs
#' once while an app's `ui` object is being built, bslib falls back to its
#' own stock theme unless something has set the global theme first.
#'
#' [bslib::bs_global_theme()] looks like the right function for this and is
#' not: its first argument is named `version` and takes a Bootstrap version
#' number (`3`, `4`, or `5`), not a theme object. Calling
#' `bslib::bs_global_theme(theme)` silently builds and sets a brand new,
#' *different* theme (bslib's own stock theme at whatever Bootstrap version
#' `theme` happens to coerce to) instead of setting `theme` itself. This has
#' shipped as a real bug: a theme built from `_brand.yml` kept its brand
#' colors under the buggy call (they come from Sass variables that also
#' happen to survive), but silently lost every typography customization
#' (`heading_font`, `base_font`, `code_font`), because those are separate
#' named arguments the buggy rebuild never passes through. `test-page-deps.R`
#' reproduces this exact failure as a regression test: the same tag,
#' rendered once under each call, resolves to two different compiled CSS
#' files, and only the correct one contains the custom heading font. Use
#' `page_deps()` (or `bslib::bs_global_set()` directly) and this class of
#' bug cannot recur here.
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
#'   an unused dependency costs a page nothing since the browser only
#'   fetches CSS or JS that a component on the page actually references,
#'   while a missing one is a widget that renders unstyled. Pass
#'   `character()` to include no catalog samples at all, relying only on
#'   `...`.
#'
#' @return A list of [htmltools::htmlDependency()] objects, with no
#'   dependency named `"bootstrap"`.
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

  # catalog_eval() only evaluates each sample's R call to produce a tag
  # object; it never starts a server. That holds for "page"-kind samples
  # too, since a page_*() call is, at the R level, still just a function
  # that returns a tag tree. findDependencies() walks any tag tree,
  # served or not: whether the resulting HTML is byte-identical to what a
  # real running app would serve (which does matter for the CATALOG
  # RENDERER's own output, in catalog-render.R) is irrelevant here, since
  # this function only reads the `htmlDependency` objects attached to the
  # tree, not its rendered HTML.
  components <- components %||% catalog_names(kind = c("tag", "page"))
  sampler <- htmltools::tagList(catalog_eval(components), ...)
  deps <- htmltools::findDependencies(sampler)
  deps[vapply(deps, function(d) !identical(d$name, "bootstrap"), logical(1))]
}
