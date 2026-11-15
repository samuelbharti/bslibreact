# The frozen name list from docs/markup-catalog.md's "Sample names"
# section, copied here literally (not computed from the catalog) so that
# renaming, adding, or dropping a sample in R/catalog-samples.R is caught
# by this test, on purpose, instead of silently passing because the test
# recomputed its expectation from the same source it is meant to check.
#
# This package's own catalog ships only "tag" and "page" samples; the
# "extra" samples (DTOutput, reactableOutput, htmlwidget_output,
# plotOutput_with_spinner) live only in the markup catalog renderer's own
# dev-time list (tools/markup/render-r.R), not here.
frozen_names <- c(
  "selectInput",
  "selectizeInput",
  "radioButtons",
  "checkboxInput",
  "sliderInput",
  "actionButton",
  "plotOutput",
  "card_full_screen",
  "sidebar_layout",
  "selectizeInput_server_placeholder",
  "textAreaInput",
  "textOutput",
  "verbatimTextOutput",
  "details_summary",
  "card_bare_children",
  "actionButton_class_override",
  "fileInput",
  "helpText_hr",
  "layout_columns_value_box",
  "plotOutput_click",
  "card_footer",
  "sidebar_layout_titled",
  "sidebar_layout_right_closed",
  "accordion_checkbox_groups",
  "textInput",
  "actionLink",
  "downloadButton",
  "sliderInput_no_ticks",
  "selectizeInput_remove_button",
  "selectizeInput_max_options",
  "radioButtons_inline",
  "numericInput",
  "passwordInput",
  "uiOutput",
  "uiOutput_fill",
  "page_fillable",
  "layout_columns_fill",
  "page_navbar",
  "page_navbar_icon",
  "page_navbar_sidebar",
  "sidebar_custom_class",
  # Replaces the earlier hand corrected page_navbar_dropdown fixture.
  "page_navbar_dropdown",
  # Added for coverage this kit did not have before.
  "page_navbar_not_fillable",
  "sidebar_layout_gap_padding",
  "layout_columns_single_child",
  "card_id",
  "card_height",
  "card_no_fill",
  "tooltip",
  "popover",
  "value_box",
  "uiOutput_inline",
  "input_dark_mode",
  "input_switch",
  "input_task_button",
  "accordion",
  "navset_card_tab",
  "navset_pill",
  "checkboxGroupInput",
  "dateInput",
  "dateRangeInput",
  "icon"
)

test_that("the catalog's names exactly match the frozen list", {
  expect_setequal(catalog_names(), frozen_names)
  expect_length(catalog_names(), length(frozen_names))
})

test_that("every sample name is unique", {
  names <- catalog_names()
  expect_equal(anyDuplicated(names), 0L)
})

test_that("kind and group are always one of the documented values", {
  for (s in markup_catalog()) {
    expect_true(s$kind %in% c("tag", "page", "extra"), info = s$name)
    expect_true(
      s$group %in%
        c(
          "page",
          "nav",
          "layout",
          "card",
          "tooltip",
          "output",
          "input",
          "misc"
        ),
      info = s$name
    )
  }
})

test_that("this package's own catalog ships no extra-kind samples", {
  expect_length(markup_catalog(kind = "extra"), 0)
})

test_that("every tag and page sample evaluates without erroring", {
  for (s in markup_catalog(kind = c("tag", "page"))) {
    result <- tryCatch(eval(s$call, envir = baseenv()), error = function(e) e)
    expect_false(
      inherits(result, "error"),
      info = paste(
        s$name,
        ":",
        conditionMessage(
          if (inherits(result, "error")) result else simpleError("")
        )
      )
    )
  }
})

test_that("catalog_eval() errors clearly on an unknown name", {
  expect_error(catalog_eval("not_a_real_sample"), "not_a_real_sample")
})
