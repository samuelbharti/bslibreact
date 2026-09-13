# Runner for this app's own tests, in the layout shiny::runTests() and
# shinytest2::test_app() expect. Run from the app directory:
#
#   Rscript --% -e "shiny::runTests('.', assert = TRUE)"
library(testthat)

test_dir("testthat")
