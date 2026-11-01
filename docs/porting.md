# Porting an existing app

## The parity rule

A port must look like its parent app. That comes from building the port
the right way, not from copying the look afterward:

- The port loads the parent's own `bs_theme()` call and `_brand.yml`
  file, through `page_react(theme = ...)`. The same Bootstrap build and
  brand colors load.
- Every widget with a Shiny binding stays a real Shiny widget: sliders,
  selects, date pickers, buttons, task buttons, the top tab bar, plots,
  tables, file inputs, download links, and chat widgets. This package
  calls that Level H, for hosted.
- Plain text, value boxes, small conditional panels, and small `renderUI`
  or `@render.ui` blocks that only format data become real React state.
  This package calls that Level R, for React. Check every Level R choice
  against the parent app by running both side by side; never assume it
  matches.
- No Tailwind, no shadcn, no react-bootstrap. This kit's components copy
  bslib's own markup, rendered live from an installed bslib, not
  hand typed, so it cannot silently drift from what a real app serves.

## Steps

bslibreact ships no port-checking tools: no triage, no dependency diff,
no screenshot helper. The checks below are manual, done against the
parent app running in one browser tab and the port running in another.
That is deliberate: a check run once per port does not justify a permanent
runtime or CI dependency (see
`docs/decisions/0001-no-fixtures-live-ground-truth.md`).

1. Triage the parent before writing anything: read its `app.R`/`app.py`,
   note its `bs_theme()`/`_brand.yml` and page function, and list every
   `renderUI`/`@render.ui` block with a first guess at Level H or Level R.
   Paste this into `PORT.md`.

2. Run the parent and look at it. Screenshot it by hand if the port's
   later look needs a reference to compare against.

3. Write `PORT.md` before any code: a behavior tree, a per-page checklist,
   a status line, and a list of any deliberate divergences from the
   parent.

4. Start the port from `examples/01-hello` (see `docs/build.md`, "Start
   from the example"). Copy the parent's `R/`, `data/`, and `_brand.yml`
   unchanged.

5. Server first. Build the page with `page_deps()`
   (see `docs/build.md`, "The page"), then wrap every widget the parent
   renders verbatim in `renderUI()` or `@render.ui` under an `_ui`
   suffixed name (or use `host_input()`). Keep module server signatures
   unchanged. Use real React state only for genuine Level R values.

6. Client, one vertical slice, then stop and check. Run the parent and
   the port side by side and compare:
   - The `<head>` dependencies each one loads (browser devtools, or
     `curl -s <url> | grep -o '<link[^>]*>\|<script[^>]*>'`).
   - The rendered page, by eye.
   - The browser console on the port: no errors, no "Duplicate output
     IDs" warnings.

   Fix any difference before writing the rest of the client.

7. Verify: run the app's own test suite, repeat the side by side
   comparison above, update `PORT.md`, run the project's pre-commit
   checks, commit.

## When the kit lacks a component

The port does not block on this. Host the piece whole through `UiOutput`
today, open an issue or a pull request against bslibreact, and switch the
port to the new component once it lands. Adding the component itself, in
this package's own repository, has no fixture file to update:

1. Add a sample call with the same name to `pkg-r/R/catalog-samples.R` and
   `pkg-py/src/bslibreact/_catalog.py`.
2. Run `make markup`.
3. Read the rendered shape in `.cache/markup/r.json`.
4. Write the TSX component against that shape, and note in its doc
   comment which catalog sample it is pinned to.
5. Add a test in `pkg-js/tests/markup.test.tsx` comparing the component's
   rendered shape against the catalog sample.
6. Add a row to `docs/markup.md`.
7. Compare the app's `<head>` dependencies again. If one is missing, add
   that call to the app's own `page_deps()` extras.

No dump script, no fixture files, and nothing to revert after a
regeneration rewrote a random id. Deleting `.cache/` and running
`make markup` again always gives a clean slate.

## Checks

| What you see on the port | Check | Usual cause |
| --- | --- | --- |
| Widget colors are stock blue or gray, the parent is branded | Compare `<head>` dependencies by hand | A theme deferred dependency resolved with no theme. `page_deps(theme)` must set the global theme with `bslib::bs_global_set(theme)`, not `bslib::bs_global_theme(theme)`. That function's first argument is `version`, a Bootstrap version number, so it silently builds a different theme instead. |
| Whole page washed out, fonts or spacing wrong | Compare `<head>` dependencies by hand | No Bootstrap at all: `page_react()` was given no `theme`. Or a stylesheet only the parent loads. |
| A hosted select shows Loading forever, outputs stay empty | Browser console | A JS error before Shiny connected. Usually a library clash. |
| An icon renders as nothing | Compare `<head>` dependencies by hand | Font Awesome only on the parent. Add an `icon()` call, or the icon library's dependency helper, to the app's extra `page_deps()` arguments. |
| A hosted `reactR`-based widget (`reactable` and others built the same way) throws `Cannot read properties of undefined (reading 'useLayoutEffect')` and never renders | Browser console, compare `<head>` dependencies by hand | The app's folder is named `react`. `page_react()` names the app's client dependency after its folder, Shiny loads one dependency per name, and reactR ships React as `"react"`. Never name an app folder after a dependency the page loads (`react`, `shinyreact`, `bslibreact`, a widget package). |
| A card or plot clips, the page does not fill | View source, check classes | `page_fillable()` sets `html { height: 100% }`, `page_navbar(fillable = )` is per panel, `layout_columns()` fills by default, `uiOutput(fill = )` matters. |
| An output never updates but the parent's does | Browser devtools, `window.Shiny.shinyapp.$bindings` | Namespace. Top level outputs never sit inside `<Module>`. Kit components pass `namespace={null}` when they read `window.Shiny` directly. |
| A slider or select moves but `input$x` never changes server side | Browser devtools, `window.Shiny.shinyapp.$inputValues` | The output holding it needs `renderUI()`/`@render.ui`, not a plain `ShinyOutput`. Only `renderUI`'s own client binding calls `initializeInputs()`. Or two elements share an id: check the `_ui` suffix on the output name is actually different from the widget's own input id. |
| Navbar or tab markup looks right in a plain render dump but is visibly wrong live, missing the active tab underline or the wrong classes | View source against a real running app | bslib's nav item builder branches on `shiny::getCurrentThemeVersion()`, which reads the Shiny option `bootstrapTheme`, set only by a running app or by `shiny::shinyOptions(bootstrapTheme = <theme>)`, not by `bslib::bs_global_set()` alone. This package's own markup catalog renders with that option set for exactly this reason; a one off script written outside it needs the same care. |
| An `update*Input()` call at session start has no visible effect | none, it is silent | An update sent before the dynamic UI has rendered that input is dropped, since Shiny has no such input yet. Put the value in the widget's own constructor argument where possible, or gate the update on the same reactive the holder waits for. |
| `shiny::runApp()` crashes on startup with a "could not find function" error that did not happen in the original app | none | `loadSupport()` auto-sources every file under `R/` before `app.R`'s own top level `library()` calls run, when `app.R` is the entry point. If any `R/` file calls a function from a package only `app.R` attaches, this crashes. Fix with an `R/00-bootstrap.R`, sourced first alphabetically, that calls the needed `library()`s itself. Add the same fix to `tests/testthat/setup.R`, which sources `R/` directly and bypasses `loadSupport()`. |
| The console logs an error for a Level R `reactive_output()` around the first reactive flush, but the app behaves fine | Browser console | Likely noise from a `req()`/`validate()` gate. The server suppresses the error correctly, but some client bindings log every error unconditionally. Verify with `useShinyOutputError()` reading a null value and `useShinyOutputStatus()` reading ready before assuming a real bug. Do not wrap it in a blanket error handler by reflex, since that also swallows genuine errors. |
| A shinyreact hook that reads ambient module context resolves the wrong channel, or never resolves, inside a `<Module>` | View source, check the namespace prefix | shinyreact's own hooks already prefix with the ambient module namespace. Wrapping the id in this kit's own namespace helper on top double prefixes it. That helper is for kit components that read `window.Shiny` directly, and the two mechanisms are not interchangeable. It also only resolves inside a descendant of `<Module>`, never in the component that renders the `<Module>` itself. |

## What bit earlier ports, and where the fix lives now

**Theme deferred widget CSS resolved unthemed.** `page_deps()` sets the
global theme with `bslib::bs_global_set(theme)` before collecting
dependencies, and restores the previous global theme afterward. The bug
this avoids: `bslib::bs_global_theme(theme)` takes a Bootstrap version
number as its first argument, not a theme object, so passing a theme
there silently builds a different, unbranded theme instead.

**A themeless `page_react()` served Bootstrap 3.** Fixed upstream in
shinyreact: without a `theme`, `page_react()` now attaches no Bootstrap at
all, which a `<head>` dependency comparison shows as Bootstrap missing on
the port. Give `page_react()` the parent's theme.

**The navbar's active tab had no underline.** bslib's nav item builder
decides between Bootstrap 3 and 5 markup based on
`shiny::getCurrentThemeVersion()`, which reads a Shiny option set by a
running session, not by `bslib::bs_global_set()` alone. This package's own
markup catalog renders every sample with that option set for exactly this
reason, so `NavbarTabStrip` is pinned against correct markup, not a
stale dump.

**A full screen card made the page taller than the viewport.**
`usePageBody()` injects `html { height: 100% }` into the page, matching
what `bslib::page_fillable()` itself does server side.

**A hosted `reactable` table never rendered, with `Cannot read
properties of undefined (reading 'useLayoutEffect')` in the console.**
`page_react()` names the app's own client dependency after the app's
folder, and Shiny loads only one dependency per name: one already on the
page wins, and a later one with the same name is skipped. `reactR`, which
`reactable` and similar widgets are built on, ships React as a dependency
named `"react"`, so in an app whose folder was called `react`, reactable's
React never loaded. Found while building this repository's gallery, whose
client folders were named `react/` then (they are `vite/` now). The same
goes for any dependency name: do not name an app folder after something
the page loads, such as `react`, `shinyreact`, `bslibreact`, or a widget
package like `leaflet`.
