## Submission

This is a new release.

## Notes for reviewers

`inst/lib/bslib-react/bslib-react.js` is a vendored bundle built by this
project's sibling `pkg-js` package (npm `bslib-react`). It reads its React
and ReactDOM instances from a page-level global (`window.shinyreact`) set
up by the `shinyreact` package, and bundles neither React nor ReactDOM
itself.

## R CMD check results

0 errors | 0 warnings | 0 notes
