# Cross-package version drift guard, like shinyreact's own test suite.
# Skips outside a full checkout of this repository (R CMD check, an
# installed package), where pkg-js and the root pyproject.toml are absent.
test_that("this package's version matches pkg-js and the root pyproject.toml", {
  pkg_js_path <- testthat::test_path("..", "..", "..", "pkg-js", "package.json")
  pyproject_path <- testthat::test_path("..", "..", "..", "pyproject.toml")
  skip_if_not(
    file.exists(pkg_js_path) && file.exists(pyproject_path),
    "pkg-js/package.json or pyproject.toml is missing (not a repository checkout)"
  )

  r_version <- as.character(utils::packageVersion("bslibreact"))

  js_pkg <- jsonlite::fromJSON(pkg_js_path)
  expect_identical(js_pkg$version, r_version)

  # A simple regex read of `version = "x.y.z"` instead of a full TOML
  # parser: this package does not otherwise need a TOML dependency, and a
  # top-level `[project]` version field is a simple, stable enough shape
  # to read this way.
  py_lines <- readLines(pyproject_path, warn = FALSE)
  py_version_line <- grep('^version\\s*=\\s*"', py_lines, value = TRUE)[1]
  expect_false(is.na(py_version_line))
  py_version <- sub('^version\\s*=\\s*"([^"]+)".*$', "\\1", py_version_line)
  expect_identical(py_version, r_version)
})
