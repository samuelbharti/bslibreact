test_that("a minimal app starts, answers, and stops cleanly", {
  skip_if_not_installed(c("callr", "httpuv", "curl"))
  skip_on_cran()

  dir <- local_temp_app()
  app <- port_start_app(dir)
  withr::defer(port_stop_app(app))

  res <- port_http_get(app$url)
  expect_false(is.null(res))
  expect_identical(res$status_code, 200L)
  expect_identical(port_app_log_errors(app), character())

  port_stop_app(app)
  Sys.sleep(0.2)
  expect_false(app$process$is_alive())
})

test_that("a directory with no app.R/ui.R/app.py errors clearly", {
  dir <- withr::local_tempdir()
  expect_error(port_app_dir(dir), "no app\\.R")
})

test_that("a non-existent directory errors clearly", {
  expect_error(
    port_app_dir(file.path(withr::local_tempdir(), "nope")),
    "not found"
  )
})

test_that("a broken app.R errors with the log tail included in the message", {
  skip_if_not_installed(c("callr", "httpuv", "curl"))
  skip_on_cran()

  dir <- local_temp_app(
    app_r = c(
      "library(shiny)",
      "this is not valid R {{{"
    )
  )
  err <- tryCatch(port_start_app(dir, timeout = 15), error = function(e) e)
  expect_s3_class(err, "error")
  # The R parser's own diagnostic for the broken file ends up in the log,
  # and .port_abort_with_log() folds the log tail into the condition's own
  # message rather than only printing it to the console.
  expect_match(conditionMessage(err), "log tail", ignore.case = TRUE)
})
