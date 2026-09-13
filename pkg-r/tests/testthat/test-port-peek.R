test_that("peeking a running app reports connected, a screenshot, and a computed box", {
  skip_if_not_installed(c("callr", "httpuv", "curl", "chromote"))
  skip_if_no_chrome()
  skip_on_cran()

  dir <- local_temp_app()
  out <- withr::local_tempdir()
  result <- port_peek(dir, select = "body", out = out, wait = 20, quiet = TRUE)

  expect_s3_class(result, "port_peek")
  expect_true(result$connected)
  expect_true(file.exists(result$screenshot))
  expect_false(is.null(result$picked[["body"]]))
  expect_length(result$picked[["body"]]$box, 4)
})

test_that("a missing selector is reported as missing, not an error", {
  skip_if_not_installed(c("callr", "httpuv", "curl", "chromote"))
  skip_if_no_chrome()
  skip_on_cran()

  dir <- local_temp_app()
  out <- withr::local_tempdir()
  result <- port_peek(
    dir,
    select = "#not-a-real-id",
    out = out,
    wait = 20,
    quiet = TRUE
  )

  expect_true(isTRUE(result$picked[["#not-a-real-id"]]$missing))
})

test_that("screenshots default under tempdir(), never the working directory", {
  skip_if_not_installed(c("callr", "httpuv", "curl", "chromote"))
  skip_if_no_chrome()
  skip_on_cran()

  dir <- local_temp_app()
  wd_before <- list.files(getwd())
  result <- port_peek(dir, wait = 20, quiet = TRUE)

  # Compare normalized paths rather than raw strings: tempdir() and a
  # path built with file.path() are not always separator-for-separator
  # identical text on Windows, even when they name the same directory.
  screenshot_dir <- normalizePath(dirname(result$screenshot), winslash = "/")
  expected_dir <- normalizePath(
    file.path(tempdir(), "bslibreact-peek"),
    winslash = "/"
  )
  expect_identical(screenshot_dir, expected_dir)
  expect_identical(list.files(getwd()), wd_before)
})
