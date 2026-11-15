test_that("page_deps() returns a list of htmlDependency objects", {
  deps <- page_deps(bslib::bs_theme(version = 5))
  expect_type(deps, "list")
  expect_true(length(deps) > 0)
  for (d in deps) {
    expect_s3_class(d, "html_dependency")
  }
})

test_that("no dependency is named bootstrap", {
  deps <- page_deps(bslib::bs_theme(version = 5))
  names <- vapply(deps, function(d) d$name, character(1))
  expect_false("bootstrap" %in% names)
})

test_that("theme = NULL still returns dependencies, with no error", {
  deps <- page_deps(theme = NULL)
  expect_true(length(deps) > 0)
  names <- vapply(deps, function(d) d$name, character(1))
  # sliderInput's ionRangeSlider skin is one of the default "tag"/"page"
  # samples, so it should show up even with no theme active.
  expect_true(any(grepl("ion", names, ignore.case = TRUE)))
})

test_that("a customized theme produces resolvable Sass-compiled dependencies", {
  skip_on_cran()
  # A plain bs_theme(version = 5), with no customization, IS bslib's own
  # default, so bslib skips recompiling it and points bslib-component-css
  # at its pre-built static "components/dist/components.css" instead
  # (confirmed directly: only a theme that actually differs from the
  # default forces a real Sass compile). A customized color is enough to
  # force a real compile, landing in a fresh, absolute temp path this test
  # can confirm exists. Scoped to one sample instead of the full default
  # catalog for the same reason: many components in one render can attach
  # more than one bslib-component-css entry, only some of which the theme
  # actually forced a recompile for.
  deps <- page_deps(
    bslib::bs_theme(version = 5, primary = "#123456"),
    components = "card_full_screen"
  )
  component_css <- Filter(
    function(d) identical(d$name, "bslib-component-css"),
    deps
  )
  expect_true(length(component_css) > 0)
  f <- file.path(component_css[[1]]$src$file, component_css[[1]]$stylesheet)
  expect_true(file.exists(f), info = f)
})

test_that("the global theme is restored after the call", {
  expect_null(bslib::bs_global_get())
  page_deps(bslib::bs_theme(version = 5))
  expect_null(bslib::bs_global_get())

  prior <- bslib::bs_theme(version = 5, primary = "#000000")
  bslib::bs_global_set(prior)
  withr::defer(bslib::bs_global_clear())

  # A minimal, version-agnostic component here: most of the default
  # catalog (accordion, tooltip, popover, input_switch, ...) requires
  # Bootstrap 5 or higher and would error under a version = 4 theme,
  # which is beside the point of this test (restoring the prior global
  # theme works the same regardless of which theme was passed in).
  page_deps(bslib::bs_theme(version = 4), components = "selectInput")
  expect_identical(bslib::bs_global_get(), prior)
})

test_that("components = character() plus one extra tag returns only that tag's dependencies", {
  extra <- shiny::plotOutput("x")
  deps <- page_deps(theme = NULL, extra, components = character())
  expect_identical(deps, htmltools::findDependencies(extra))
})

test_that("an unknown component name produces a clear error naming it", {
  expect_error(
    page_deps(
      theme = NULL,
      components = c("selectInput", "not_a_real_component")
    ),
    "not_a_real_component"
  )
})

test_that("dots must be unnamed", {
  expect_error(page_deps(theme = NULL, extra = shiny::plotOutput("x")))
})

test_that("theme must be a bs_theme object or NULL", {
  expect_error(page_deps(theme = "not a theme"), class = "rlang_error")
})

test_that("regression: bs_global_set(), not bs_global_theme(), decides the resolved CSS", {
  # bs_global_theme()'s first argument is `version` (a Bootstrap version
  # NUMBER), not a theme object, so bs_global_theme(theme) silently builds
  # and sets a brand new stock theme instead of the one passed in. A
  # custom heading font survives the correct call and is dropped by the
  # buggy one.
  skip_on_cran()

  old <- bslib::bs_global_get()
  withr::defer({
    bslib::bs_global_clear()
    if (!is.null(old)) bslib::bs_global_set(old)
  })

  custom_theme <- bslib::bs_theme(
    heading_font = bslib::font_google("Fira Sans")
  )

  # Correct: page_deps() itself, which uses bs_global_set() internally.
  deps_correct <- page_deps(custom_theme, components = "card_full_screen")
  css_correct <- Filter(
    function(d) identical(d$name, "bslib-component-css"),
    deps_correct
  )
  expect_true(length(css_correct) > 0)
  file_correct <- file.path(
    css_correct[[1]]$src$file,
    css_correct[[1]]$stylesheet
  )
  expect_true(file.exists(file_correct))
  content_correct <- paste(
    readLines(file_correct, warn = FALSE),
    collapse = "\n"
  )

  # Buggy: simulate the old, wrong call directly (a theme object passed
  # where a Bootstrap version number belongs), bypassing page_deps()
  # entirely, since page_deps() itself does not have this bug.
  bslib::bs_global_set(custom_theme)
  bslib::bs_global_theme(5)
  tag <- bslib::card(bslib::card_header("Title"), bslib::card_body("Body"))
  deps_buggy <- htmltools::findDependencies(tag)
  bslib::bs_global_clear()
  css_buggy <- Filter(
    function(d) identical(d$name, "bslib-component-css"),
    deps_buggy
  )
  expect_true(length(css_buggy) > 0)
  file_buggy <- file.path(css_buggy[[1]]$src$file, css_buggy[[1]]$stylesheet)
  content_buggy <- if (file.exists(file_buggy)) {
    paste(readLines(file_buggy, warn = FALSE), collapse = "\n")
  } else {
    ""
  }

  # The two resolved files differ (different stylesheet file names, and
  # different content), and only the correctly-themed one contains the
  # custom font.
  expect_false(identical(
    css_correct[[1]]$stylesheet,
    css_buggy[[1]]$stylesheet
  ))
  expect_true(grepl("Fira Sans", content_correct, fixed = TRUE))
  expect_false(grepl("Fira Sans", content_buggy, fixed = TRUE))
})

test_that("the shiny baseline is excluded and each dependency appears once", {
  deps <- page_deps(bslib::bs_theme(version = 5))
  nms <- vapply(deps, function(d) d$name, character(1))

  # jquery used to come back 14 times here while the Python sibling
  # dropped it, which is the divergence this guards against.
  expect_false("jquery" %in% nms)
  expect_false("bootstrap" %in% nms)
  expect_identical(anyDuplicated(nms), 0L)
})

test_that("dedupe_by_name keeps the highest version of a repeated name", {
  a <- htmltools::htmlDependency("x", "1.0.0", src = c(href = "."))
  b <- htmltools::htmlDependency("x", "2.0.0", src = c(href = "."))
  other <- htmltools::htmlDependency("y", "1.0.0", src = c(href = "."))

  kept <- dedupe_by_name(list(a, b, other))
  expect_length(kept, 2L)
  expect_identical(kept[[1]]$version, "2.0.0")
  expect_identical(kept[[2]]$name, "y")
})

test_that("dedupe_by_name falls back to first seen when a version is unparsable", {
  a <- htmltools::htmlDependency("x", "not-a-version", src = c(href = "."))
  b <- htmltools::htmlDependency("x", "2.0.0", src = c(href = "."))

  kept <- dedupe_by_name(list(a, b))
  expect_length(kept, 1L)
  expect_identical(kept[[1]]$version, "not-a-version")
})
