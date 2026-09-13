# Two minimal apps used to prove port_deps_diff() catches a real missing
# dependency, without needing bslibreact itself to be installed in the
# background R processes these apps run in (they use nothing but shiny).

local_slider_app <- function(.local_envir = parent.frame()) {
  local_temp_app(
    app_r = c(
      "library(shiny)",
      "ui <- fluidPage(shiny::sliderInput('x', 'X', 1, 10, 5))",
      "server <- function(input, output, session) {}",
      "shinyApp(ui, server)"
    ),
    .local_envir = .local_envir
  )
}

local_no_widget_app <- function(.local_envir = parent.frame()) {
  local_temp_app(
    app_r = c(
      "library(shiny)",
      "ui <- fluidPage(shiny::tags$div('looks like a slider but is not one'))",
      "server <- function(input, output, session) {}",
      "shinyApp(ui, server)"
    ),
    .local_envir = .local_envir
  )
}

test_that("an app compared against itself is clean", {
  skip_if_not_installed(c("callr", "httpuv", "curl", "xml2"))
  skip_on_cran()

  dir <- local_slider_app()
  result <- port_deps_diff(dir, dir, quiet = TRUE)

  expect_s3_class(result, "port_deps_diff")
  expect_equal(result$n, 0)
})

test_that("a port missing a widget's dependency is flagged", {
  skip_if_not_installed(c("callr", "httpuv", "curl", "xml2"))
  skip_on_cran()

  parent_dir <- local_slider_app()
  port_dir <- local_no_widget_app()
  result <- port_deps_diff(parent_dir, port_dir, quiet = TRUE)

  expect_true(result$n > 0)
  # The ionRangeSlider files the parent loads and the port does not.
  css_lines <- Find(
    function(s) identical(s$title, "Stylesheets"),
    result$sections
  )$lines
  js_lines <- Find(
    function(s) identical(s$title, "Scripts"),
    result$sections
  )$lines
  expect_true(any(grepl("ion", c(css_lines, js_lines), ignore.case = TRUE)))
})
