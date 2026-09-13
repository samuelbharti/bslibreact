test_that("host_input() renders the widget under output[[id + suffix]]", {
  server <- function(input, output, session) {
    host_input(output, "bins", shiny::sliderInput("bins", "Bins", 1, 50, 30))
  }
  shiny::testServer(server, {
    html <- output$bins_ui$html
    expect_true(grepl('id="bins"', html, fixed = TRUE))
  })
})

test_that("host_input() returns the output name invisibly", {
  server <- function(input, output, session) {
    name <- host_input(
      output,
      "bins",
      shiny::sliderInput("bins", "Bins", 1, 50, 30)
    )
    session$userData$name <- name
  }
  shiny::testServer(server, {
    expect_identical(session$userData$name, "bins_ui")
  })
})

test_that("a custom suffix changes the output name", {
  server <- function(input, output, session) {
    name <- host_input(
      output,
      "bins",
      shiny::sliderInput("bins", "Bins", 1, 50, 30),
      suffix = "_widget"
    )
    session$userData$name <- name
  }
  shiny::testServer(server, {
    expect_identical(session$userData$name, "bins_widget")
    expect_true(grepl('id="bins"', output$bins_widget$html, fixed = TRUE))
  })
})

test_that("a widget whose own id equals the output name triggers the collision error", {
  # id = "lfc", suffix defaults to "_ui", so the output is named "lfc_ui".
  # Giving the widget itself the input id "lfc_ui" (instead of "lfc")
  # reuses the output wrapper's own id, which is exactly the mistake
  # check_no_id_collision() exists to catch.
  server <- function(input, output, session) {
    host_input(output, "lfc", shiny::sliderInput("lfc_ui", "LFC", 0, 1, 0.5))
  }
  shiny::testServer(server, {
    expect_error(output$lfc_ui, "lfc_ui")
  })
})

test_that("a widget that reads a reactive re-renders when the reactive changes", {
  server <- function(input, output, session) {
    top <- shiny::reactiveVal(50)
    host_input(output, "bins", shiny::sliderInput("bins", "Bins", 1, top(), 5))
  }
  shiny::testServer(server, {
    html_before <- output$bins_ui$html
    expect_true(grepl('max="50"', html_before, fixed = TRUE))

    top(90)
    session$flushReact()
    html_after <- output$bins_ui$html
    expect_true(grepl('max="90"', html_after, fixed = TRUE))
    expect_false(identical(html_before, html_after))
  })
})
