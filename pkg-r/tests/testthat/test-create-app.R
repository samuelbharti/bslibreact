test_that("create_app() copies every template file with placeholders substituted", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", title = "My App", open = FALSE)

  template_dir <- system.file("templates", "app-r", package = "bslibreact")
  template_files <- sort(list.files(
    template_dir,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  ))
  created_files <- sort(list.files(
    path,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  ))
  expect_identical(created_files, template_files)

  all_text <- vapply(
    file.path(path, created_files),
    function(f) {
      paste(readLines(f, warn = FALSE), collapse = "\n")
    },
    character(1)
  )
  expect_false(any(grepl("APP_NAME", all_text, fixed = TRUE)))
  expect_false(any(grepl("APP_TITLE", all_text, fixed = TRUE)))
  expect_false(any(grepl("BSLIB_REACT_VERSION", all_text, fixed = TRUE)))
})

test_that("the scaffolded app.R parses without error", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", open = FALSE)
  expect_no_error(parse(file.path(path, "app.R")))
})

test_that("the scaffolded package.json is valid JSON naming bslib-react", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", open = FALSE)
  pkg <- jsonlite::fromJSON(file.path(path, "package.json"))
  expect_true("bslib-react" %in% names(pkg$dependencies))
  expect_identical(pkg$name, "myapp")
})

test_that("the substituted version matches the installed package version", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", open = FALSE)
  pkg <- jsonlite::fromJSON(file.path(path, "package.json"))
  expected <- paste0("^", as.character(utils::packageVersion("bslibreact")))
  expect_true(startsWith(pkg$dependencies[["bslib-react"]], expected))
})

test_that("brand = TRUE adds brand = TRUE to the theme call", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", brand = TRUE, open = FALSE)
  app_r_text <- paste(readLines(file.path(path, "app.R")), collapse = "\n")
  expect_match(app_r_text, "brand = TRUE", fixed = TRUE)
})

test_that("brand = FALSE (the default) leaves the theme call plain", {
  path <- file.path(withr::local_tempdir(), "myapp")
  create_app(path, name = "myapp", open = FALSE)
  app_r_text <- paste(readLines(file.path(path, "app.R")), collapse = "\n")
  expect_false(grepl("brand = TRUE", app_r_text, fixed = TRUE))
})

test_that("scaffolding into a non-empty directory errors clearly", {
  path <- withr::local_tempdir()
  writeLines("something", file.path(path, "existing.txt"))
  expect_error(create_app(path, open = FALSE), "not empty")
})

test_that("scaffolding into a new or empty directory succeeds", {
  path <- withr::local_tempdir()
  expect_no_error(create_app(path, name = "myapp", open = FALSE))
})
