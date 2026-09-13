# Tests the server's reactive logic directly, with shiny::testServer(),
# rather than driving a real browser: the client's own markup is bslib-react's
# responsibility (see pkg-js/tests/markup.test.tsx), and the bind mechanics
# are pkg-js/tests/bind.test.tsx's job. This file only has to prove app.R's
# own reactive code is correct.

app_dir <- normalizePath(file.path(testthat::test_path(), "..", ".."))

# Evaluate only the library() calls and the `server <- function(...)`
# assignment from app.R, so `server` exists in this environment with no
# need to also build `ui` (page_react() needs a built www/ directory on
# disk to resolve against, which is beside the point of a server-only
# test and would tie this test to the working directory runTests()
# happens to use).
load_server <- function() {
  env <- new.env()
  exprs <- parse(file.path(app_dir, "app.R"))
  for (e in exprs) {
    is_library_call <- is.call(e) && identical(e[[1]], as.name("library"))
    is_server_def <- is.call(e) &&
      identical(e[[1]], as.name("<-")) &&
      identical(e[[2]], as.name("server"))
    if (is_library_call || is_server_def) eval(e, envir = env)
  }
  env$server
}

test_that("the plot and the count wait for the hosted slider's value", {
  shiny::testServer(load_server(), {
    # Before the hosted slider has connected, input$bins does not exist yet
    # (see app.R's own comment on this). req()'s condition is FALSE, which
    # raises a "shiny.silent.error" - invisible in a live browser (the
    # output just stays blank), but testServer() surfaces it as a real
    # condition on direct access, so the right assertion is that the
    # error IS that specific silent class, not some other bug (a genuine
    # NULL-argument error from hist(), for example, would not match this).
    expect_error(output$plot, class = "shiny.silent.error")
    expect_error(output$bins_count, class = "shiny.silent.error")
  })
})

test_that("the count reflects the slider once it is set", {
  shiny::testServer(load_server(), {
    session$setInputs(bins = 25)
    expect_equal(output$bins_count, "25")
  })
})
