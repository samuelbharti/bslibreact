# Tests the pure data layer (R/_shared/volcano-data.R) directly: no shiny
# session needed, since none of this reads input$ or output$. The server
# wiring itself (app.R) is exercised by port_peek() in a real browser, not
# duplicated here as a unit test; see docs/porting.md on why a component's
# own markup and bind mechanics belong to pkg-js, not to an example app.

app_dir <- normalizePath(file.path(testthat::test_path(), "..", ".."))
for (f in list.files(
  file.path(app_dir, "R", "_shared"),
  pattern = "[.][Rr]$",
  full.names = TRUE
)) {
  source(f)
}

de_results <- utils::read.csv(
  file.path(app_dir, "data", "de_results.csv"),
  stringsAsFactors = FALSE
)

test_that("volcano_data classifies status from logFC and p together", {
  vd <- volcano_data(
    de_results,
    lfc_threshold = 1,
    p_threshold = 0.05,
    p_col = "padj"
  )
  expect_setequal(levels(vd$status), c("Down", "NS", "Up"))
  expect_true(all(vd$status[vd$logFC >= 1 & vd$p < 0.05] == "Up"))
  expect_true(all(vd$status[vd$logFC <= -1 & vd$p < 0.05] == "Down"))
})

test_that("volcano_data labels at most label_top_n genes, by smallest p", {
  vd <- volcano_data(de_results, label_top_n = 5)
  labelled <- vd[!is.na(vd$label), ]
  expect_equal(nrow(labelled), 5)
  expect_true(all(labelled$status != "NS"))
  expect_true(max(labelled$p) <= min(vd$p[is.na(vd$label) & vd$status != "NS"]))
})

test_that("volcano_data errors clearly on a missing required column", {
  bad <- de_results[, setdiff(names(de_results), "logFC")]
  expect_error(volcano_data(bad), "logFC")
})

test_that("volcano_status_counts always reports all three levels", {
  vd <- volcano_data(de_results, lfc_threshold = 100)
  counts <- volcano_status_counts(vd)
  expect_equal(names(counts), c("Down", "NS", "Up"))
  expect_equal(unname(counts[["Up"]]), 0L)
})
