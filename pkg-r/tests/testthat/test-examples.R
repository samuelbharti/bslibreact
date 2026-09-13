# Guards inst/examples-shiny/volcano-plot/ (copied from the repository
# root's examples/volcano-plot/ by `make update-examples`) against drift,
# the same way shinyreact's own test suite checks its vendored examples.
# Both the source and the copy are later additions to this repository
# (examples/volcano-plot/ does not exist yet at the time this package was
# scaffolded); this activates automatically once they do.
test_that("inst/examples-shiny/volcano-plot matches examples/volcano-plot's R side", {
  source_dir <- testthat::test_path(
    "..",
    "..",
    "..",
    "examples",
    "volcano-plot"
  )
  copy_dir <- system.file(
    "examples-shiny",
    "volcano-plot",
    package = "bslibreact"
  )
  skip_if_not(
    file.exists(file.path(source_dir, "app.R")),
    "examples/volcano-plot does not exist yet"
  )
  skip_if_not(
    nzchar(copy_dir),
    "inst/examples-shiny/volcano-plot has not been vendored yet"
  )

  expect_identical(
    readLines(file.path(source_dir, "app.R"), warn = FALSE),
    readLines(file.path(copy_dir, "app.R"), warn = FALSE)
  )
})
