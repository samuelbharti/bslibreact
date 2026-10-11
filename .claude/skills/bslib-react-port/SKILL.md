---
name: bslib-react-port
description: |
  Port a Shiny app (R or Python) to the shinyreact ui.tsx pattern using the
  bslib-react component kit, and check the port against its parent at fixed
  points. Use when the user asks to port, convert, or migrate a Shiny app
  that uses bslib, when a port looks wrong next to its parent (wrong widget
  colors, a gray or washed-out page, a select stuck on Loading, a card that
  clips, an output that never updates), or when bslib-react needs a new
  component. Sits on top of the shinyreact-convert-app skill and this
  package's docs/porting.md. It adds the checkpoints and the symptom table
  that come from building this kit.
license: MIT
compatibility: claude-code
metadata:
  version: "2.0.0"
  repo: samuelbharti/bslib-react
---

# Porting with parity checks

Read this package's `docs/porting.md` first. It holds the rules: the
ui.tsx pattern (never call it an SPA), Level H for hosted widgets, Level R
for plain values, no Tailwind, no shadcn, no react-bootstrap, no em dashes,
plain writing. This skill adds the order of work and the checks. The
general phases come from the `shinyreact-convert-app` skill.

bslib-react ships only `page_deps()`, `host_input()`, and
`bslib_react_dep()` at runtime. There is no built-in triage, dependency
diff, or screenshot tool: those checks below are manual, done with the
browser's own devtools and a plain side by side comparison against the
running parent app. That is deliberate (see
`docs/decisions/0001-no-fixtures-live-ground-truth.md`): a check run once
per port is not worth a permanent runtime or CI dependency.

## Checkpoints, in order

1. Before writing PORT.md, read the parent app by hand and note:
   - Its `bs_theme()` call (or `_brand.yml`) and its page function
     (`page_navbar`, `page_sidebar`, `page_fillable`, or none). No bslib
     theme and no bslib page function means the page shell is built by
     hand, and `page_react()` attaches no Bootstrap at all unless it is
     given a `theme`. Pass the parent's theme, or
     `bslib::bs_theme(version = 5)` when it has none, before writing the
     client.
   - Every `renderUI`/`@render.ui` block. Each is a decision: Level R when
     it only formats data, a hosted widget (`host_input()`) when it holds
     a real Shiny-bound control.
   - Whether the app looks like a skeleton (a stub with no real logic).
     Stop and ask the owner before porting one of those.

   Paste these notes into PORT.md.

2. Build one vertical slice, then stop and check. One page, one hosted
   input, one hosted output. Do not write the rest of the client yet.

   Run the parent and the port side by side (two ports, two browser tabs).
   Compare:
   - The `<head>` dependencies each one loads (browser devtools' Network
     or Elements tab, or `curl -s <url> | grep -o '<link[^>]*>|<script[^>]*>'`):
     every CSS and JS file the parent's theme and widgets pull in should
     also appear on the port. A missing one renders a widget unstyled; an
     extra, unrelated one is usually harmless but worth understanding.
   - The rendered page by eye, side by side. Take a screenshot of each if
     the difference is subtle.
   - The browser console on the port: zero errors, and zero "Duplicate
     output IDs" warnings (the defect this kit's hosting pattern exists to
     avoid).

   Fix any difference before writing more client code. Skipping this step
   is the most common way to lose an afternoon to screenshot forensics
   later.

3. After adding a catalog sample, or any change to `page_deps()`'s extra
   arguments, repeat the dependency comparison above. The dependency
   sampler drifts silently otherwise.

4. Before each commit, compare the port and the parent once more by eye.
   Then run the project's own pre-commit checks, then commit in small
   batches.

## When the kit is missing a component

There is no fixture file to add. Instead:

1. Add a sample call with the same name to `pkg-r/R/catalog-samples.R` and
   `pkg-py/src/bslib_react/_catalog.py` in this repository, not the app
   you are porting.
2. Run `make markup`.
3. Read the rendered shape in `.cache/markup/r.json`.
4. Write the TSX component against that shape.
5. Add a markup test comparing the component's rendered shape against the
   catalog sample.
6. Add a row to `docs/markup.md`.

While waiting for that, host the piece whole through `UiOutput` in the app
you are porting, and switch to the new component once it lands.

## Symptom table

| What you see on the port | Check | Usual cause |
| --- | --- | --- |
| Widget colors are stock blue or gray, the parent is branded | Compare `<head>` dependencies by hand | A theme deferred dependency resolved with no theme. `page_deps(theme)` must set the global theme with `bslib::bs_global_set(theme)`, not `bslib::bs_global_theme(theme)`. That function's first argument is `version`, a Bootstrap version number, so it silently builds a different theme instead. |
| Whole page washed out, fonts or spacing wrong | Compare `<head>` dependencies by hand | Bootstrap 3 from a themeless page function on a bslib-free app, or a stylesheet only the parent loads. |
| A hosted select shows Loading forever, outputs stay empty | Browser console | A JS error before Shiny connected. Usually a library clash. |
| An icon renders as nothing | Compare `<head>` dependencies by hand | Font Awesome only on the parent. Add an `icon()` call, or the icon library's dependency helper, to the app's extra `page_deps()` arguments. |
| A hosted `reactR`-based widget (`reactable` and others built the same way) throws `Cannot read properties of undefined (reading 'useLayoutEffect')` and never renders | Browser console, compare `<head>` dependencies by hand | `reactR` ships its own React copy as a dependency named `"react"`, the same name `page_react()` uses for the app's own client bundle. htmltools keeps whichever same-named dependency reports the higher version, and `page_react()`'s cache-busting build number always wins, so the real React script never loads. Pull `reactR::html_dependency_react()` in the app's own `page_deps()`/`...` call, rename it, and list it first. |
| A card or plot clips, the page does not fill | View source, check classes | `page_fillable()` sets `html { height: 100% }`, `page_navbar(fillable = )` is per panel, `layout_columns()` fills by default, `uiOutput(fill = )` matters. |
| An output never updates but the parent's does | Browser devtools, `window.Shiny.shinyapp.$bindings` | Namespace. Top level outputs never sit inside `<Module>`. Kit components pass `namespace={null}` when they read `window.Shiny` directly. |
| A slider or select moves but `input$x` never changes server side | Browser devtools, `window.Shiny.shinyapp.$inputValues` | The output holding it needs `renderUI()`/`@render.ui`, not a plain `ShinyOutput`. Only `renderUI`'s own client binding calls `initializeInputs()`. Or two elements share an id: check the `_ui` suffix on the output name is actually different from the widget's own input id. |
| Navbar or tab markup looks right in a plain render dump but is visibly wrong live, missing the active tab underline or the wrong classes | View source against a real running app | bslib's nav item builder branches on `shiny::getCurrentThemeVersion()`, which reads the Shiny option `bootstrapTheme`, set only by a running app or by `shiny::shinyOptions(bootstrapTheme = <theme>)`, not by `bslib::bs_global_set()` alone. This package's own markup catalog renders with that option set for exactly this reason; a one off script written outside it needs the same care. |
| An `update*Input()` call at session start has no visible effect | none, it is silent | An update sent before the dynamic UI has rendered that input is dropped, since Shiny has no such input yet. Put the value in the widget's own constructor argument where possible, or gate the update on the same reactive the holder waits for. |
| `shiny::runApp()` crashes on startup with a "could not find function" error that did not happen in the original app | none | `loadSupport()` auto-sources every file under `R/` before `app.R`'s own top level `library()` calls run, when `app.R` is the entry point. If any `R/` file calls a function from a package only `app.R` attaches, this crashes. Fix with an `R/00-bootstrap.R`, sourced first alphabetically, that calls the needed `library()`s itself. Add the same fix to `tests/testthat/setup.R`, which sources `R/` directly and bypasses `loadSupport()`. |
| The console logs an error for a Level R `reactive_output()` around the first reactive flush, but the app behaves fine | Browser console | Likely noise from a `req()`/`validate()` gate. The server suppresses the error correctly, but some client bindings log every error unconditionally. Verify with `useShinyOutputError()` reading a null value and `useShinyOutputStatus()` reading ready before assuming a real bug. Do not wrap it in a blanket error handler by reflex, since that also swallows genuine errors. |
| A shinyreact hook that reads ambient module context resolves the wrong channel, or never resolves, inside a `<Module>` | View source, check the namespace prefix | shinyreact's own hooks already prefix with the ambient module namespace. Wrapping the id in this kit's own namespace helper on top double prefixes it. That helper is for kit components that read `window.Shiny` directly, and the two mechanisms are not interchangeable. It also only resolves inside a descendant of `<Module>`, never in the component that renders the `<Module>` itself. |

## Rules that bit previous ports

- One slice, then checkpoint 2, then the rest. Never build the whole
  client before the first side by side check.
- Top level outputs are never wrapped in `<Module>`.
- Copy the parent's tests verbatim where they exist. A failing test is a
  port bug until proven otherwise.
- The parent app is never modified. Not even a comment.
- A local plans and notes directory should be git ignored in a properly
  set up project. Screenshots and working notes go there, never in a
  commit.
- Never commit an environment file or a key. Read a file before staging it
  if it might hold one.
- Write down the symptom actually seen, and mark the cause as a guess
  until it is isolated by turning it on and off in a minimal case. A cause
  that merely sounds right is not yet verified.
- When a minimal repro does not reproduce, suspect the repro before
  concluding the bug is not real. A negative result is only as good as the
  harness that produced it.
- Every app composing shared component modules needs its own
  `moduleServer` block per module, hosting that module's own widgets,
  placed next to, never inside, the module's own existing server call.
- Check this package's exported component list before assuming something
  needs building from scratch. The kit grows with each release.
