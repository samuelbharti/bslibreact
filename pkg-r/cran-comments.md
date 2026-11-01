## Submission

This is a new release.

## Notes for reviewers

`inst/lib/bslibreact/bslibreact.js` is a vendored bundle built by this
project's sibling `pkg-js` package (npm `bslibreact`). It reads its React
and ReactDOM instances from a page-level global (`window.shinyreact`) set
up by the `shinyreact` package, and bundles neither React nor ReactDOM
itself.

## R CMD check results

0 errors | 0 warnings | 1 note

* "Found the following files/directories: ''NULL''" appears on Windows
  only and comes from the check tooling rather than this package.
