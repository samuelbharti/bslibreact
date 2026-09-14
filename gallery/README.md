# bslib-react component gallery

A side by side gallery, matching [shiny.posit.co/r/components](https://shiny.posit.co/r/components/):
every example runs both as classic bslib + Shiny and as bslib-react +
shinyreact, with a switch to compare them and a button to show the code
for both. R only for now; Python follows once this pattern is proven.

## Layout

```
gallery/
  src/                 the gallery shell (a plain React SPA, not a shinyreact client)
  apps/<slug>/
    classic/app.R      plain bslib + Shiny
    react/             bslib-react + shinyreact: app.R, src/App.tsx, src/ui.tsx
      screenshot.png    committed; see "Why react mode is a screenshot" below
      www/              build output, gitignored, dev-only (see below)
  scripts/
    build-apps.mjs      builds every react/src/ui.tsx into react/www/ui.js (dev only)
    export-shinylive.R  exports every classic/ app via shinylive into dist/
  dist/                 build output, gitignored, this is what gets published
```

## Building

```
npm run build     # from gallery/: builds the shell, then exports every classic app
npm run dev       # the shell's own dev server
npm run build:apps  # rebuilds every react/ client, for taking new screenshots (see below)
```

`npm run build` is what CI runs (`.github/workflows/gallery-deploy.yaml`),
publishing `gallery/dist/` to GitHub Pages.

## Why react mode is a screenshot, not a live iframe

Every classic app really does run live, client-side, no server, via
[shinylive](https://posit-dev.github.io/r-shinylive/). The react half
cannot, today: `shinylive::export()` needs a WebAssembly-compiled binary
for every R package an app uses, and neither `shinyreact` nor
`bslibreact` has one (neither is on CRAN or r-universe with a wasm build,
and neither has a tagged GitHub release for shinylive to build one from
as a fallback). Confirmed by hand while building this gallery: a plain
bslib + Shiny app exports and runs correctly under shinylive; a
shinyreact app fails at the dependency-resolution step, before it ever
reaches a browser.

So react mode shows a screenshot of the real, running app instead, next
to its real source code. If `shinyreact`/`bslibreact` ever ship a wasm
build, or a hosted R server becomes available for this site, this is the
one thing to revisit; nothing else about the gallery's design depends on
it staying this way.

To refresh a screenshot after changing an example: run
`npm run build:apps` (builds every `react/src/ui.tsx`), start that
example's `react/app.R` with `shiny::runApp()`, and capture
`document.body` with a headless browser (chromote in R, Playwright in
Node, whichever is at hand). The committed PNG is the only thing the
published site reads; `react/www/` itself is gitignored, dev-only
output.

## Adding an example (Phase 2)

1. `apps/<slug>/classic/app.R` and `apps/<slug>/react/{app.R,src/App.tsx}`.
   Give the react client's `src/ui.tsx` the same two lines every other
   example's has (mount `<App />` via `window.shinyreact.ReactDOM`).
2. Any hosted input's client-side `id` must carry the `_ui` suffix
   (`host_input(output, "bins", ...)` on the server means
   `id="bins_ui"` on the client) -- this is the one mistake every example
   in this gallery hit at least once while it was being built.
3. Build that example's client and take its screenshot (see above).
4. Add one entry to `src/data/examples.ts`'s `REGISTRY`. Everything else
   (code panel content, the classic iframe's `src`) is read from the real
   files automatically.
5. `npm run build` and open `dist/index.html` to check it.

## Deploying

Push to `main` (this repository's pre-push hook means that is always a
manual, by-hand step); `gallery-deploy.yaml` builds and publishes to
GitHub Pages automatically from there. GitHub Pages itself needs to be
turned on once, in the repository's own Settings > Pages, with the
source set to "GitHub Actions" -- that is a repository setting, not
something this workflow file can turn on by itself.
