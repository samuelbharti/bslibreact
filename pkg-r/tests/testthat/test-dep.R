test_that("bslib_react_dep() has the right name, script, and defer attribute", {
  dep <- bslib_react_dep()
  expect_identical(dep$name, "bslib-react")
  expect_identical(dep$script$src, "bslib-react.js")
  expect_identical(dep$script$defer, "")
})

description_version <- function() {
  unname(read.dcf(
    system.file("DESCRIPTION", package = "bslibreact"),
    fields = "Version"
  )[1, 1])
}

test_that("version is the package version when not a dev checkout", {
  local_mocked_bindings(.dev_checkout = function() FALSE)
  dep <- bslib_react_dep()
  expect_identical(dep$version, description_version())
})

test_that("version gets an mtime suffix in a dev checkout", {
  dir <- withr::local_tempdir()
  js_path <- file.path(dir, "bslib-react.js")
  writeLines("/* fake bundle */", js_path)
  known_mtime <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
  Sys.setFileTime(js_path, known_mtime)

  local_mocked_bindings(.dev_checkout = function() TRUE, .www_dir = function() {
    dir
  })

  dep <- bslib_react_dep()
  expect_identical(
    dep$version,
    paste0(description_version(), ".", sprintf("%.0f", as.numeric(known_mtime)))
  )
})

test_that("bslib_react_dep() does not error when the bundle file does not exist yet", {
  # bslib-react.js may not have been vendored in yet (pkg-js not built),
  # and htmltools::htmlDependency() itself never checks file existence at
  # construction time, only once something actually serves the files.
  dir <- withr::local_tempdir()
  local_mocked_bindings(
    .dev_checkout = function() FALSE,
    .www_dir = function() dir
  )
  expect_no_error(dep <- bslib_react_dep())
  expect_identical(dep$version, description_version())
})

test_that("stylesheet is present iff the .css file exists", {
  dir <- withr::local_tempdir()
  writeLines("/* fake */", file.path(dir, "bslib-react.js"))
  local_mocked_bindings(.www_dir = function() dir)

  dep_without_css <- bslib_react_dep()
  expect_null(dep_without_css$stylesheet)

  writeLines("/* fake css */", file.path(dir, "bslib-react.css"))
  dep_with_css <- bslib_react_dep()
  expect_identical(dep_with_css$stylesheet, "bslib-react.css")
})
