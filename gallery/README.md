# bslib-react component gallery

A side by side gallery, matching [shiny.posit.co/r/components](https://shiny.posit.co/r/components/):
a sidebar lists every example, grouped by category; selecting one shows
three live versions of it next to each other, each with the complete
source below it. R only for now; Python follows once this pattern is
proven.

The three columns are the point of the thing:

| Column | What it is | Needs Node? |
| --- | --- | --- |
| `classic` | plain bslib + Shiny, the usual R stack | no |
| `react` | bslib-react installed from npm, UI written in TSX, bundled by Vite | yes |
| `rpkg` | bslib-react from the R package's own vendored bundle, UI hand written in plain JS | no |

`react` and `rpkg` are the two tiers described in [docs/build.md](../docs/build.md).
Their `app.R` is byte identical, deliberately: `bslibreact` is the server
half of both, and the only thing that differs is where the client comes
from. The `react` column builds it from TSX; the `rpkg` column writes it
by hand against `window.bslibReact`, the global that
`bslib_react_dep()`'s vendored bundle publishes, so it needs no npm and
no build step at all.

This is a real, single Shiny app (`app.R`), meant to be run with plain R
and eventually deployed to Posit Connect Cloud. It replaced an earlier
version built on `shinylive` (R compiled to WebAssembly, running fully in
the browser, deployed as a static site to GitHub Pages): that version was
slow to cold start, and could not run the react half live at all, since
neither `shinyreact` nor `bslibreact` has a WebAssembly build. See git
history for that version if it's ever worth revisiting once those
packages are more widely distributed.

## Layout

```text
gallery/
  app.R          the shell: sidebar, three demo columns, code panels, app launcher
  examples.R     the registry: slug, category, title, and note per example
  apps/<slug>/
    classic/app.R      plain bslib + Shiny
    react/             app.R, src/App.tsx, src/ui.tsx, www/ui.js (built, committed)
    rpkg/              app.R, www/ui.js (hand written, no build)
  scripts/
    build-apps.mjs      builds every react/src/ui.tsx into react/www/ui.js
```

## Running it

```bash
Rscript -e "shiny::runApp('gallery')"
```

Every `react/www/ui.js` is committed. After changing a react client's
`src/`, or `pkg-js`, rebuild them from the repository root with `npm ci`
and `make bundles`. The rpkg column reads the R package's vendored bundle,
so a `pkg-js` change also needs `make update-dist` and a reinstall of
`bslibreact` before that column shows it.

Every example is a genuine, independent Shiny app under
`apps/<slug>/{classic,react,rpkg}/`. `app.R` starts the three belonging
to whichever example you select, in the background, and keeps the nine
most recently used alive after that, so going back to an example you have
already opened is instant and a new one takes a second or two while its
processes boot. An earlier version started all of them at once; with
three variants apiece that is 126 R processes each loading shiny, bslib
and sometimes plotly or leaflet, which pins the CPU hard enough that none
of them finish booting. Start them on demand.

Nothing here uses `shinylive` or `webR`: this is plain `shiny::runApp()`
all the way down, once per example per variant, proxied through an
`<iframe>`.

## Adding an example

1. Write `apps/<slug>/classic/app.R` and
   `apps/<slug>/react/{app.R,src/App.tsx}`. Give the react client's
   `src/ui.tsx` the same file every other example has (it mounts
   `<App />` via `window.shinyreact.ReactDOM`); all 42 copies are
   identical.
2. Any hosted input's client-side `id` must carry the `_ui` suffix
   (`host_input(output, "bins", ...)` on the server means
   `id="bins_ui"` on the client). This is the one mistake every example
   in this gallery hit at least once while it was being built.
3. Run `make bundles` (from the repository root) to produce that example's
   `react/www/ui.js`, and commit it: unlike a typical build artifact,
   this one ships, the same way `examples/*/www/ui.js` does elsewhere in
   this repo, since there is no build step at deploy time.
4. Copy `react/app.R` to `rpkg/app.R` unchanged, and hand write
   `rpkg/www/ui.js` as the `React.createElement` form of `App.tsx`. Wrap
   it in a `window.addEventListener("load", ...)` and read the globals
   inside that listener: `page_react()` emits the app's own `ui.js`
   script tag *before* `bslib_react_dep()`'s, so `window.bslibReact` is
   still undefined while the file is first evaluated, and a page that
   reads it at the top level renders blank with no console error.
5. Add one entry to `examples.R`. The code panels and the live apps are
   always read from the real files, so there is nothing to keep in sync
   by hand beyond that one registry entry.

## Deploying

Not yet automated. The plan is Posit Connect Cloud, which expects one
self-contained Shiny app; `app.R`'s launcher approach (each example
variant as a separate background R process, proxied through an iframe)
works locally but needs a decision before it can ship there: whether
Connect Cloud can host the sidebar shell and all 126 backing apps as one
deployment, or whether the backing apps need their own separate Connect
deployments with the shell iframing their public URLs instead of
`127.0.0.1`. Worth resolving with a small end to end test (two or three
examples deployed for real) before committing either way for the full
gallery.
