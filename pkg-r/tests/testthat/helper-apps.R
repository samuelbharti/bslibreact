# A minimal, valid Shiny app written to a fresh temp directory, cleaned up
# automatically when the calling test finishes (via withr::local_tempdir(),
# scoped to `.local_envir`, the caller's frame by default: the same
# pattern testthat's own local_edition() family uses). Used by
# test-port-app.R and the port_triage()/port_deps_diff()/port_peek() tests
# that need a real, tiny, running app rather than a fixture on disk.
#
# Pass `app_r` (a character vector of source lines) to write something
# other than the default app, for example a syntactically broken file.
local_temp_app <- function(app_r = NULL, .local_envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = .local_envir)
  if (is.null(app_r)) {
    app_r <- c(
      "library(shiny)",
      "",
      "ui <- fluidPage(",
      "  titlePanel(\"test app\"),",
      "  sliderInput(\"n\", \"N\", 1, 10, 5),",
      "  textOutput(\"out\")",
      ")",
      "",
      "server <- function(input, output, session) {",
      "  output$out <- renderText(paste(\"n is\", input$n))",
      "}",
      "",
      "shinyApp(ui, server)"
    )
  }
  writeLines(app_r, file.path(dir, "app.R"))
  dir
}
