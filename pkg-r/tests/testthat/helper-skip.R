# Shared skip helpers. testthat sources every helper-*.R file before
# running tests, so these are available in every test file with no
# explicit source() call.

# Skip a test when no Chrome or Chromium binary can be found. chromote
# itself only errors about this the first time it actually tries to
# launch a browser, which is a confusing place to discover it in a test
# run; this checks up front instead. find_chrome() itself throws when it
# cannot locate a browser (rather than returning NULL), so both an error
# and a NULL result are treated as "no chrome available".
skip_if_no_chrome <- function() {
  testthat::skip_if_not_installed("chromote")
  chrome <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
  if (is.null(chrome)) {
    testthat::skip("no Chrome or Chromium binary found")
  }
  invisible(TRUE)
}
