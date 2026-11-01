# 0005: the gallery deploys as three server apps, not a WebAssembly bundle

Date: 2026-09-13
Status: proposed (not built yet: `gallery/app.R` still runs every variant
as its own local process)

## Context

`gallery/` compares 42 components built three ways: classic bslib and
Shiny, bslibreact installed from npm, and bslibreact taken from the R
package's vendored bundle. Locally the shell launches each variant as its
own background R process and shows it in an iframe, so browsing the whole
gallery would mean 126 processes. No host will run that, which leaves the
question of what to deploy instead.

GitHub Pages was the first candidate, since the repository is already
public and Pages costs nothing. Pages serves static files and cannot run
R, so live demos there would have to go through `shinylive`, which
compiles R to WebAssembly and runs it in the browser.

An earlier attempt at exactly that failed, and the reason was misread at
the time as "shinyreact and bslibreact have no WebAssembly builds, so
this is impossible." The real cause is narrower. `remotes::install_github()`
records `RemoteType: github` in a package's DESCRIPTION. Reading that
field, r-shinylive's resolver goes looking for a GitHub release tagged
`HEAD` carrying prebuilt wasm assets. No such release exists, and the
export stops there. The same resolver has a second branch for
packages whose DESCRIPTION names an r-universe repository, and that
branch fetches wasm binaries that r-universe builds automatically. Both
packages are pure R with no compiled code. Publishing them to
r-universe would therefore produce working builds, and every heavy
dependency the gallery uses (leaflet, plotly, reactable, gt, DT, ggplot2)
is already on `repo.r-wasm.org`.

Shinylive is available after all, and two measurements decide against
it anyway. The runtime a shinylive app ships is about 60 MB, and a real
exported example measured 66.8 MB. Posit's own FDA Pilot 4 case study
reports load times of one to three minutes, cut to roughly 15 seconds
after the 0.8.0 bundling work. Exported apps placed under one site share
their static assets, and a browser downloads that payload once. Each
iframe still starts its own webR worker with its own WebAssembly heap.
Three columns means three R instances booting on every page.

A separate detail rules shinylive out for this design regardless of
speed. Query strings never reach a shinylive app, which
`posit-dev/r-shinylive` tracks as an open issue, and the parameter is
what collapses 126 apps into three.

## Decision

Three Shiny apps run on Posit Connect Cloud, one per variant, and a
static shell on GitHub Pages lists the components, shows the source, and
embeds the three apps in iframes.

Each app reads `?component=<slug>` and renders that component. Shiny
calls a `ui` function that takes one argument once per HTTP request, with
the query string available on `req$QUERY_STRING`. The page can
therefore choose its own script tag before anything is sent.
`session$clientData$url_search` cannot do this, because it arrives after
the page is built. A throwaway
app confirmed the mechanism: `?component=slider-input` and
`?component=value-box` each emitted the script tag they should.

Connect Cloud's free plan allows five applications at 4 GB and one CPU
each, which fits three with room to spare. It lists a monthly active-hour
allowance and then states on the same page that the limit is not
currently enforced, which is what separates it from shinyapps.io's hard
25 hours. Publishing points at a public GitHub repository and a primary
file, so a subdirectory such as `gallery/deploy/classic/app.R` works
directly, and a push to the connected branch redeploys by default.
Dependencies come from `manifest.json` written by
`rsconnect::writeManifest()`; renv is explicitly unsupported there.

shinyapps.io was rejected. Its free plan caps five applications at 25
active hours a month, and Posit is folding the service into Connect Cloud
with automatic migration beginning in 2027.

## Consequences

The gallery keeps real R, so a component behaves exactly as it does
locally and nothing waits on a WebAssembly runtime. The cost is that the
live demos no longer live on Pages, and the site spans two services.

One assumption is still unverified. Connect Cloud documents packages
from *private* GitHub repositories as a paid feature and never states
plainly whether *public* GitHub sources work on the free plan. Both
`shinyreact` and `bslibreact` install from GitHub. A single throwaway
deployment should settle the question before the three real apps are
built.

Two properties of the hosting shape how the deploy apps should be
written. Workers shut down five seconds after the last connection by
default, and 60 seconds is the maximum, which leaves a quiet gallery
cold starting often. Folding 42 components into one app also gives that
app the union of every component's dependencies. Calling `pkg::fn()`
instead of `library(pkg)` keeps a namespace unloaded until the requested
component needs it, which holds a cold start near plain shiny and bslib.

Publishing `bslibreact` to r-universe remains worth doing on its own
merits, and it would reopen the shinylive route if a fully static gallery
ever becomes more valuable than a fast one.
