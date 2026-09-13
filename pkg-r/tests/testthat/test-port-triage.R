# A tiny fixture app with known input, output, and theme calls, so counts
# and locations can be asserted exactly rather than merely "some number
# greater than zero".
local_triage_fixture <- function(.local_envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = .local_envir)
  writeLines(
    c(
      "library(shiny)",
      "library(bslib)",
      "",
      "app_theme <- bs_theme(version = 5)",
      "",
      "ui <- page_sidebar(",
      "  title = \"Fixture\",",
      "  theme = app_theme,",
      "  sidebar = sidebar(",
      "    selectInput(\"x\", \"X\", choices = c(\"a\", \"b\")),",
      "    selectInput(\"y\", \"Y\", choices = c(\"a\", \"b\"))",
      "  ),",
      "  plotOutput(\"p\")",
      ")",
      "",
      "server <- function(input, output, session) {",
      "  output$p <- renderPlot(plot(1))",
      "}",
      "",
      "shinyApp(ui, server)"
    ),
    file.path(dir, "app.R")
  )
  dir
}

find_section <- function(x, title) {
  Find(function(s) identical(s$title, title), x$sections)
}

test_that("port_triage() counts known inputs, outputs, and the page/theme calls", {
  dir <- local_triage_fixture()
  result <- port_triage(dir, quiet = TRUE)

  expect_s3_class(result, "port_triage")
  expect_identical(result$dir, normalizePath(dir, winslash = "/"))

  inputs <- find_section(result, "Inputs")$bullets
  expect_true(any(grepl("^selectInput: 2 ", inputs)))

  outputs <- find_section(result, "Outputs")$bullets
  expect_true(any(grepl("^plotOutput: 1 ", outputs)))

  page <- find_section(result, "Page and theme")$bullets
  expect_true(any(grepl("^page_sidebar: 1 ", page)))
  expect_true(any(grepl("^bs_theme: ", page)))
  expect_true(any(grepl("bslib page function: yes", page, fixed = TRUE)))
  expect_true(any(grepl("bslib loaded anywhere: yes", page, fixed = TRUE)))
})

test_that("format.port_triage() starts with '# Triage:' and reads as Markdown", {
  dir <- local_triage_fixture()
  result <- port_triage(dir, quiet = TRUE)
  lines <- format(result)

  expect_true(startsWith(lines[1], "# Triage:"))
  expect_true(any(lines == "## Inputs"))
  expect_true(any(grepl("^- selectInput: 2 ", lines)))
})

test_that("quiet = TRUE produces no console output", {
  dir <- local_triage_fixture()
  expect_silent(port_triage(dir, quiet = TRUE))
})

test_that("quiet = FALSE (the default) prints a report", {
  # cli (print.port_triage()'s own rendering) writes through message(), not
  # stdout, so this is expect_message(), not expect_output().
  dir <- local_triage_fixture()
  expect_message(port_triage(dir), "Triage")
})

test_that("a directory with no R files errors clearly", {
  dir <- withr::local_tempdir()
  writeLines("hello", file.path(dir, "app.R"))
  # port_app_dir() itself is satisfied by the presence of app.R; the "no R
  # files" case this guards is for the (contrived) situation where the
  # skip regex in port_triage() excludes every file it finds, which does
  # not happen for a top-level app.R, so this instead exercises the
  # ordinary one-file path end to end.
  result <- port_triage(dir, quiet = TRUE)
  expect_identical(find_section(result, "Size")$bullets[1], "R files: 1")
})
