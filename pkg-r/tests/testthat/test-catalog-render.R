test_that("the written JSON has the documented top-level fields", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = c("card_full_screen", "selectInput"),
    served = "never",
    quiet = TRUE
  )
  expect_true(file.exists(path))

  rec <- jsonlite::read_json(path)
  expect_identical(rec$schema, 1L)
  expect_identical(rec$language, "r")
  expect_true(is.character(rec$key) && length(rec$key) == 1)
  expect_match(rec$generated_at, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
  expect_identical(rec$generator$package, "bslibreact")
  expect_identical(
    rec$generator$version,
    as.character(utils::packageVersion("bslibreact"))
  )
  expect_setequal(
    names(rec$versions),
    c("bslib", "shiny", "htmltools", "runtime")
  )
  expect_setequal(names(rec$samples), c("card_full_screen", "selectInput"))
})

test_that("samples serializes as a JSON object, not an array", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE
  )
  raw <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_match(raw, '"samples":\\s*\\{')
  expect_no_match(raw, '"samples":\\s*\\[')
})

test_that("a tag-kind sample has the tag-kind field shape", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "card_full_screen",
    served = "never",
    quiet = TRUE
  )
  s <- jsonlite::read_json(path)$samples$card_full_screen

  expect_identical(s$kind, "tag")
  expect_false(s$served)
  expect_true(is.character(s$call) && nzchar(s$call))
  expect_true(is.character(s$html) && grepl("card", s$html))
  expect_null(s$html_attrs)
  expect_null(s$skipped)
  expect_true(is.list(s$deps))
})

test_that("an installed extra-kind sample renders like a tag", {
  skip_if_not_installed("reactable")
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "reactableOutput",
    served = "never",
    quiet = TRUE
  )
  s <- jsonlite::read_json(path)$samples$reactableOutput

  expect_identical(s$kind, "extra")
  expect_null(s$skipped)
  expect_true(is.character(s$html) && nzchar(s$html))
})

test_that("a missing extra-kind package is skipped, not an error", {
  path <- withr::local_tempfile(fileext = ".json")
  local_mocked_bindings(.pkg_available = function(pkg) FALSE)
  render_markup_catalog(
    path = path,
    components = "reactableOutput",
    served = "never",
    quiet = TRUE
  )
  s <- jsonlite::read_json(path)$samples$reactableOutput

  expect_identical(s$kind, "extra")
  expect_null(s$html)
  expect_identical(s$deps, list())
  expect_match(s$skipped, "not installed")
})

test_that("a page-kind sample without serving falls back with served: false", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "page_fillable",
    served = "never",
    quiet = TRUE
  )
  s <- jsonlite::read_json(path)$samples$page_fillable

  expect_identical(s$kind, "page")
  expect_false(s$served)
  expect_true(is.character(s$html) && nzchar(s$html))
  expect_null(s$html_attrs)
})

test_that("shinyOptions(bootstrapTheme=) is restored to its prior value after rendering", {
  expect_null(shiny::getShinyOption("bootstrapTheme"))
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE
  )
  expect_null(shiny::getShinyOption("bootstrapTheme"))
})

test_that("cache = TRUE skips re-rendering when the key has not changed", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE
  )
  mtime1 <- file.info(path)$mtime

  Sys.sleep(1.1)
  result <- render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE,
    cache = TRUE
  )
  mtime2 <- file.info(path)$mtime

  expect_equal(mtime1, mtime2)
  expect_identical(result$key, markup_catalog_key())
})

test_that("cache = FALSE always re-renders, even with an unchanged key", {
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE
  )
  mtime1 <- file.info(path)$mtime

  Sys.sleep(1.1)
  render_markup_catalog(
    path = path,
    components = "selectInput",
    served = "never",
    quiet = TRUE,
    cache = FALSE
  )
  mtime2 <- file.info(path)$mtime

  expect_false(identical(mtime1, mtime2))
})

test_that("a fast, unserved nav sample already carries real Bootstrap 5 nav markup", {
  # navset_pill is kind = "tag": no server needed, and the same
  # shinyOptions(bootstrapTheme=) wrap that "tag" kind samples get is
  # enough on its own to avoid the Bootstrap 3 branch for plain nav
  # strips. The full page_navbar regression below additionally proves the
  # SERVED path (this package's documented, default behavior for "page"
  # kind samples) gets it right too.
  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "navset_pill",
    served = "never",
    quiet = TRUE
  )
  html <- jsonlite::read_json(path)$samples$navset_pill$html

  expect_match(html, "nav-item")
  expect_match(html, "nav-link", fixed = TRUE)
  expect_no_match(html, '<li[^>]*class="active"')
})

test_that("regression: the served page_navbar sample has real Bootstrap 5 nav markup", {
  # This is the single most important test in the package: it is the
  # reason this repository's live-catalog design exists (see
  # docs/decisions/0001-no-fixtures-live-ground-truth.md). Rendered
  # outside a real running Shiny session, bslib's nav-building code
  # silently takes its Bootstrap 3 branch and the active tab comes out as
  # `<li class="active"><a>` instead of the real
  # `<li class="nav-item"><a class="nav-link active">`.
  skip_if_not_installed(c("callr", "httpuv", "curl", "xml2"))
  skip_on_cran()

  path <- withr::local_tempfile(fileext = ".json")
  render_markup_catalog(
    path = path,
    components = "page_navbar",
    served = "always",
    quiet = TRUE
  )
  s <- jsonlite::read_json(path)$samples$page_navbar

  expect_true(s$served)
  expect_match(s$html, "nav-item")
  expect_match(s$html, "nav-link active", fixed = TRUE)
  # The old, wrong Bootstrap 3 branch put "active" directly on the <li>
  # itself; the correct markup puts "nav-item" on the <li> and moves
  # "active" onto the nested <a class="nav-link active">.
  expect_no_match(s$html, '<li[^>]*class="active"')
  expect_true(is.list(s$html_attrs))
})
