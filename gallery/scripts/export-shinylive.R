# Exports every gallery example's classic/ app (plain bslib + Shiny, no
# shinyreact or bslib-react) via shinylive, so it runs fully client-side in
# the published static site. The react/ half of each example cannot be
# exported this way: shinyreact and bslibreact have no WebAssembly binary
# distribution (neither is on CRAN or r-universe with a wasm build, and
# neither has a tagged GitHub release for shinylive to build one from), so
# shinylive::export() fails at dependency resolution before it ever reaches
# the browser-compatibility question. Confirmed by hand while planning this
# gallery: a plain bslib + Shiny app exports and runs correctly; a shinyreact
# app does not export at all. See docs/decisions/ for the write-up once one
# exists; for now this comment is the record.
#
# Run from gallery/ (this is what `npm run build`/`npm run
# export:shinylive` does, npm's own cwd convention for a workspace
# script), after `npm run build:site` has already written the shell to
# dist/ (this script only adds to that directory; it never empties it):
#   Rscript scripts/export-shinylive.R [--out dist]

args <- commandArgs(trailingOnly = TRUE)
out_flag <- which(args == "--out")
site_root <- if (length(out_flag) == 1 && out_flag < length(args)) {
  args[out_flag + 1]
} else {
  "dist"
}

apps_dir <- "apps"
slugs <- list.dirs(apps_dir, full.names = FALSE, recursive = FALSE)
slugs <- slugs[file.exists(file.path(apps_dir, slugs, "classic", "app.R"))]

if (length(slugs) == 0) {
  stop("no gallery/apps/*/classic/app.R found, nothing to export")
}

for (slug in slugs) {
  classic_dir <- file.path(apps_dir, slug, "classic")
  cat(sprintf("[gallery] exporting %s (classic)\n", slug))
  # Every app shares one destdir (site_root, the same dist/ the shell was
  # built into) via subdir=, so the ~66 MB shinylive/webR runtime is
  # written once at dist/shinylive/ and referenced by relative path from
  # each app's own dist/apps/<slug>/classic/, not duplicated per app.
  # ExampleCard's iframe src ("apps/<slug>/classic/index.html") is relative
  # to the shell's own index.html, which is why subdir starts with "apps/".
  shinylive::export(
    classic_dir,
    site_root,
    subdir = file.path("apps", slug, "classic"),
    quiet = FALSE
  )
}

cat(sprintf(
  "[gallery] exported %d classic app%s into %s\n",
  length(slugs),
  if (length(slugs) == 1) "" else "s",
  site_root
))
