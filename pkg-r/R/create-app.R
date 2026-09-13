#' Scaffold a new shinyreact app
#'
#' Copies this package's `app-r` template (an `app.R` that uses
#' [page_deps()] and [host_input()], a minimal `src/ui.tsx` and
#' `src/App.tsx`, and the npm and TypeScript config a client bundle needs)
#' into a new directory, substituting the app's name, title, and this
#' package's own version into the copied files.
#'
#' @param path Directory to create the app in. Must not already exist as a
#'   non-empty directory (this function does not offer a `force` argument
#'   to overwrite one: 0.1.0's scope is a plain new scaffold, and silently
#'   overwriting files in an existing project directory is a worse default
#'   than asking the caller to pick an empty or new path).
#' @param name A short, file-system-safe name for the app. Defaults to
#'   `basename(path)`. Used for the `package.json` `name` field.
#' @param title A human-readable title. Defaults to `name`. Used in
#'   `app.R`'s `page_react(title = ...)` call and in `README.md`.
#' @param brand If `TRUE`, `app.R`'s theme is built with
#'   `bslib::bs_theme(version = 5, brand = TRUE)`, reading a `_brand.yml`
#'   you add next to `app.R` yourself. If `FALSE` (the default), the theme
#'   has no brand argument.
#' @param open If `TRUE` (the default in an interactive session), opens
#'   the new `app.R` for editing with [utils::file.edit()] once scaffolding
#'   finishes.
#'
#' @return The new app's path, invisibly.
#'
#' @export
#' @examples
#' \dontrun{
#' create_app("path/to/new-app", title = "Gene Explorer")
#' }
create_app <- function(
  path,
  name = basename(path),
  title = name,
  brand = FALSE,
  open = rlang::is_interactive()
) {
  if (
    dir.exists(path) &&
      length(list.files(path, all.files = TRUE, no.. = TRUE)) > 0
  ) {
    cli::cli_abort(c(
      "{.path {path}} already exists and is not empty.",
      "i" = "{.fn create_app} only scaffolds into a new or empty directory."
    ))
  }

  template_dir <- system.file("templates", "app-r", package = "bslibreact")
  if (!nzchar(template_dir)) {
    cli::cli_abort(
      "bslibreact's {.file templates/app-r} directory is missing. Reinstall the package."
    )
  }

  files <- list.files(
    template_dir,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  version <- as.character(utils::packageVersion("bslibreact"))

  for (f in files) {
    src <- file.path(template_dir, f)
    dest <- file.path(path, f)
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)

    content <- readLines(src, warn = FALSE)
    content <- gsub("APP_TITLE", title, content, fixed = TRUE)
    content <- gsub("APP_NAME", name, content, fixed = TRUE)
    content <- gsub("BSLIB_REACT_VERSION", version, content, fixed = TRUE)
    if (isTRUE(brand)) {
      content <- gsub(
        "bs_theme(version = 5)",
        "bs_theme(version = 5, brand = TRUE)",
        content,
        fixed = TRUE
      )
    }
    writeLines(content, dest)
  }

  cli::cli_alert_success("Created {.val {name}} at {.path {path}}.")

  if (isTRUE(open)) {
    app_file <- file.path(path, "app.R")
    if (file.exists(app_file)) {
      utils::file.edit(app_file)
    }
  }

  invisible(path)
}
