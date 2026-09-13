#' Host a server-rendered widget for a shinyreact client
#'
#' Registers `widget` as a [shiny::renderUI()] output named
#' `paste0(id, suffix)`, the way [shinyreact::page_react()] apps host a
#' bslib or shiny widget the client displays with `<ShinyOutput
#' id="<id><suffix>" />` (or the matching kit component, `HostedInput`,
#' from the `bslib-react` npm package) instead of rebuilding the widget's
#' markup in React. See `docs/decisions/0003-hosted-widgets.md` in the
#' repository for the reasoning behind hosting widgets this way instead of
#' driving them from React state.
#'
#' # Why the suffix matters
#'
#' A hosted widget contributes two elements to the page, not one: the
#' output wrapper Shiny creates for `output[[paste0(id, suffix)]]` (a
#' `<div id="foo_ui" class="shiny-html-output">`, in the default case), and
#' the widget's own element, with the widget's own input id, nested inside
#' it (a `<div id="foo" class="form-group shiny-input-container">`, for a
#' `shiny::sliderInput("foo", ...)`). These are two different ids on
#' purpose: the wrapper is what the client's `HostedInput` component
#' addresses to swap in new markup, and the widget's own id is what Shiny's
#' input binding addresses to read `input$foo`. Give both the same id (by
#' calling `host_input(output, "foo", sliderInput("foo", ...))`, omitting
#' the suffix's effect by reusing the id) and the page holds two elements
#' under the id `"foo"`; `document.getElementById()`, Shiny's own
#' `$("#foo")` lookups, and every downstream consumer of that id become
#' ambiguous, silently addressing whichever one the browser happens to
#' return first. `check_no_id_collision()` (an internal helper) catches
#' this at render time with a message naming the id involved, rather than
#' leaving it to surface later as an input or output that mysteriously
#' never updates.
#'
#' @param output The `output` object from a Shiny server function.
#' @param id A short, stable identifier for this hosted widget. This is
#'   not itself a DOM id: it is combined with `suffix` to make the output
#'   name, so `id` only has to be distinct from any other `host_input()`
#'   call's `id` in the same app, and independent of whatever input id the
#'   widget itself declares.
#' @param widget An expression that builds the widget, evaluated lazily
#'   inside [shiny::renderUI()] each time it is invalidated (so it can read
#'   reactive values, the same as any `renderUI()` block). Typically a
#'   single unevaluated widget call, for example
#'   `shiny::sliderInput("bins", "Bins", 1, 50, 30)`.
#' @param suffix Appended to `id` to make the output name. The default,
#'   `"_ui"`, matches the naming `bslib-react`'s `HostedInput` React
#'   component expects when it is given `id="bins"`: it looks for an
#'   output named `"bins_ui"`.
#'
#' @return The output name (`paste0(id, suffix)`), invisibly.
#'
#' @export
#' @examples
#' \dontrun{
#' server <- function(input, output, session) {
#'   host_input(output, "bins", shiny::sliderInput("bins", "Bins", 1, 50, 30))
#'   # The client displays this with <ShinyOutput id="bins_ui" />, and reads
#'   # the slider's own value the usual way, from input$bins.
#' }
#' }
host_input <- function(output, id, widget, suffix = "_ui") {
  expr <- rlang::enquo(widget)
  name <- paste0(id, suffix)
  output[[name]] <- shiny::renderUI({
    tag <- rlang::eval_tidy(expr)
    check_no_id_collision(tag, name)
    tag
  })
  invisible(name)
}
