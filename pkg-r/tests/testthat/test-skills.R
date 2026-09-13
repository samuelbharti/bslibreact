# Guards inst/skills/bslib-react-port/ (copied from the repository root's
# .claude/skills/bslib-react-port/ by `make update-skills`) against drift,
# the same way shinyreact's own test suite checks its shipped skill. The
# skill is written in a later phase of this repository's setup; this
# activates automatically once it exists.
test_that("inst/skills/bslib-react-port matches the repository's own skill source", {
  source_dir <- testthat::test_path(
    "..",
    "..",
    "..",
    ".claude",
    "skills",
    "bslib-react-port"
  )
  copy_dir <- system.file("skills", "bslib-react-port", package = "bslibreact")
  skip_if_not(
    file.exists(file.path(source_dir, "SKILL.md")),
    ".claude/skills/bslib-react-port does not exist yet"
  )
  skip_if_not(
    nzchar(copy_dir),
    "inst/skills/bslib-react-port has not been vendored yet"
  )

  expect_identical(
    readLines(file.path(source_dir, "SKILL.md"), warn = FALSE),
    readLines(file.path(copy_dir, "SKILL.md"), warn = FALSE)
  )
})
