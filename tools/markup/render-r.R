#!/usr/bin/env Rscript
# Thin CLI wrapper around bslibreact::render_markup_catalog(), the R half
# of the markup catalog contract in docs/markup-catalog.md. Run from the
# repository root:
#
#   Rscript tools/markup/render-r.R --key
#   Rscript tools/markup/render-r.R --out .cache/markup/r.json
#
# --key prints bslibreact::markup_catalog_key() and exits 0, rendering
# nothing: pkg-js's vitest global setup calls this on every test run and
# only re-renders when the key differs from the cached file's own key.
# --out <path> renders the full catalog to that path and exits 0, or exits
# non-zero with a message on stderr if rendering fails.
#
# This script tries library(bslibreact) first, so it works the same way
# once the package is actually installed (from r-universe, or a local
# install). It falls back to pkgload::load_all("pkg-r") when the package
# is not installed, which is the common case for a plain checkout of this
# repository: pkgload is used only here, as a dev-time convenience, and is
# deliberately not a dependency of pkg-r itself (a script that loads a
# package from source has no business being one of that package's own
# runtime dependencies).

args <- commandArgs(trailingOnly = TRUE)

if (requireNamespace("bslibreact", quietly = TRUE)) {
  library(bslibreact)
} else {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    cat(
      "bslibreact is not installed and pkgload is not available to load it from source.\n",
      "Install pkgload (install.packages(\"pkgload\")) or install bslibreact itself.\n",
      file = stderr()
    )
    quit(status = 1)
  }
  # This script lives at tools/markup/render-r.R, two levels below the
  # repository root; pkg-r sits alongside tools/ at that same root.
  root <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "..", ".."), winslash = "/")
  pkg_dir <- file.path(root, "pkg-r")
  if (!file.exists(file.path(pkg_dir, "DESCRIPTION"))) {
    # Fall back to a path relative to the current working directory, for
    # the case where this script is invoked in some other way than
    # `Rscript tools/markup/render-r.R` from the repo root (commandArgs()
    # cannot always recover --file= reliably, for example when the script
    # is sourced rather than run directly).
    pkg_dir <- "pkg-r"
  }
  pkgload::load_all(pkg_dir, quiet = TRUE)
}

if ("--key" %in% args) {
  cat(markup_catalog_key(), "\n", sep = "")
  quit(status = 0)
}

out_flag <- which(args == "--out")
if (length(out_flag) == 1 && out_flag < length(args)) {
  out_path <- args[out_flag + 1]
  result <- tryCatch(
    {
      render_markup_catalog(path = out_path)
      TRUE
    },
    error = function(e) {
      cat("render_markup_catalog() failed: ", conditionMessage(e), "\n", sep = "", file = stderr())
      FALSE
    }
  )
  quit(status = if (isTRUE(result)) 0 else 1)
}

cat(
  "usage: Rscript tools/markup/render-r.R --key\n",
  "       Rscript tools/markup/render-r.R --out <path>\n",
  file = stderr()
)
quit(status = 1)
