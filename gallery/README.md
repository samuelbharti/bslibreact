# bslib-react component gallery

A side by side gallery, matching [shiny.posit.co/r/components](https://shiny.posit.co/r/components/):
a sidebar lists every example, grouped by category; selecting one shows it
large on the right, switchable between classic bslib + Shiny and
bslib-react + shinyreact, with a button to show the code for both. R only
for now; Python follows once this pattern is proven.

This is a real, single Shiny app (`app.R`), meant to be run with plain R
and eventually deployed to Posit Connect Cloud. It replaced an earlier
version built on `shinylive` (R compiled to WebAssembly, running fully in
the browser, deployed as a static site to GitHub Pages): that version was
slow to cold start, and could not run the react half live at all, since
neither `shinyreact` nor `bslibreact` has a WebAssembly build. See git
history for that version if it's ever worth revisiting once those
packages are more widely distributed.

## Layout

```
gallery/
  app.R          the shell: sidebar, mode switch, code panel, lazy app launcher
  examples.R     the registry: slug, category, title, and note per example
  apps/<slug>/
    classic/app.R      plain bslib + Shiny
    react/             bslib-react + shinyreact: app.R, src/App.tsx, src/ui.tsx, www/ (built, committed)
  scripts/
    build-apps.mjs      builds every react/src/ui.tsx into react/www/ui.js
```

## Running it

```
npm install                        # once, for the react client build tooling
npm run build                      # from gallery/: builds every react/www/ui.js
Rscript -e "shiny::runApp('gallery')"
```

Every example is a genuine, independent Shiny app under
`apps/<slug>/{classic,react}/`. `app.R` starts one lazily, in the
background, the first time it is selected (or its pill is switched to),
and reuses the same running process after that; switching to an example
you have already viewed is instant, the first view of a new one takes a
couple of seconds while its process boots. Nothing here uses `shinylive`
or `webR`: this is plain `shiny::runApp()` all the way down, once per
example, proxied through an `<iframe>`.

## Adding an example

1. `apps/<slug>/classic/app.R` and `apps/<slug>/react/{app.R,src/App.tsx}`.
   Give the react client's `src/ui.tsx` the same two lines every other
   example's has (mount `<App />` via `window.shinyreact.ReactDOM`).
2. Any hosted input's client-side `id` must carry the `_ui` suffix
   (`host_input(output, "bins", ...)` on the server means
   `id="bins_ui"` on the client) -- this is the one mistake every example
   in this gallery hit at least once while it was being built.
3. Run `npm run build` (from `gallery/`) to produce that example's
   `react/www/ui.js`, and commit it: unlike a typical build artifact,
   this one ships, the same way `examples/*/www/ui.js` does elsewhere in
   this repo, since there is no build step at deploy time.
4. Add one entry to `examples.R`. The code panel and the live apps
   themselves are always read from the real files, nothing to keep in
   sync by hand beyond that one registry entry.

## Deploying

Not yet automated. The plan is Posit Connect Cloud, which expects one
self-contained Shiny app; `app.R`'s lazy-launcher approach (each example
as a separate background R process, proxied through an iframe) works
locally but needs a decision before it can ship there: whether Connect
Cloud can host the sidebar shell and all 42+ backing apps as one
deployment, or whether the backing apps need their own separate Connect
deployments with the shell iframing their public URLs instead of
`127.0.0.1`. Worth resolving with a small end to end test (two or three
examples deployed for real) before committing either way for the full
gallery.
