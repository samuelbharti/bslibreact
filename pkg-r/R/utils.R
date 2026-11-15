# Internal helpers shared across the package. Nothing here is exported.

# host_input() renders a widget into an output wrapper named
# "<id><suffix>" (see host-input.R and docs/decisions/0003-hosted-widgets.md
# for the full reasoning). The wrapper itself becomes a DOM element with
# that name as its id, because that is how Shiny's own output binding
# works: output$foo_ui becomes <div id="foo_ui" class="shiny-html-output">.
# If the widget passed to host_input() ALSO happens to carry that same id
# on one of its own elements (most often because a caller copy-pasted an
# existing widget id instead of giving the hosted widget its own), the
# rendered page ends up with two elements sharing one DOM id: the output
# wrapper itself, and the widget's own input element inside it. Browsers
# tolerate a duplicate id, but every id-based lookup after that point
# (getElementById, a CSS id selector, Shiny's own input/output registries)
# becomes ambiguous, and only one of the two elements is ever addressed.
# This check catches the mistake at render time, with a message that says
# exactly which id collided, instead of leaving it to show up later as a
# widget that silently never updates.
#
# The walk is over the plain list structure of an htmltools tag: a
# "shiny.tag" has an $attribs named list (which may or may not contain
# "id") and a $children list of further tags, character strings, or
# nested lists (tagList() and plain list() are both just lists here).
# Character strings, NULL, numbers and other leaf values are not tags and
# cannot carry an id, so the recursion bottoms out on them.
check_no_id_collision <- function(tag, name) {
  if (.tag_tree_has_id(tag, name)) {
    cli::cli_abort(c(
      "The widget passed to {.fn host_input} has its own element with id {.val {name}}.",
      "x" = "That id is already used by the output wrapper this widget is hosted in.",
      "i" = "Give the widget's own input a different id than {.val {name}}, or pass a different {.arg suffix} to {.fn host_input}.",
      "i" = "The `_ui` suffix exists for this reason: the widget's own call puts its input id on its own markup, and the output wrapper puts the output id on its own element, so reusing one string for both stacks two elements under one DOM id."
    ))
  }
  invisible(NULL)
}

.tag_tree_has_id <- function(x, name) {
  if (is.null(x)) {
    return(FALSE)
  }
  if (inherits(x, "shiny.tag")) {
    if (identical(x$attribs$id, name)) {
      return(TRUE)
    }
    return(.tag_tree_has_id(x$children, name))
  }
  if (is.list(x)) {
    for (child in x) {
      if (.tag_tree_has_id(child, name)) {
        return(TRUE)
      }
    }
    return(FALSE)
  }
  # A character string, a number, an htmltools "html" literal, or anything
  # else that is not a tag or a list: it cannot carry an id.
  FALSE
}
