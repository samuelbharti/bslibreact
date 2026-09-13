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
  bslib's own markup, rendered live from an installed bslib rather than
  hand typed, so it cannot silently drift from what a real app serves.

## Steps

bslib-react ships no port-checking tools: no triage, no dependency diff,
no screenshot helper. The checks below are manual, done against the
parent app running in one browser tab and the port running in another.
That is deliberate: a check run once per port is not worth a permanent
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

5. Server first. Build the page with `page_deps()` and `bslib_react_dep()`
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
today, open an issue or a pull request against bslib-react, and switch the
port to the new component once it lands. Adding the component itself, in
this package's own repository, has no fixture file to update:

1. Add a sample call with the same name to `pkg-r/R/catalog-samples.R` and
   `pkg-py/src/bslib_react/_catalog.py`.
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

| What you see | Run | Usual cause |
| --- | --- | --- |
| Widget colors are stock, the parent is branded | Compare `<head>` dependencies | A theme deferred dependency resolved with no theme. Use `bslib::bs_global_set()`, not `bslib::bs_global_theme()`, inside `page_deps()`. |
| Whole page washed out | Compare `<head>` dependencies | Bootstrap 3 from a themeless page function. |
| A hosted select never leaves Loading | Browser console | A JS error before Shiny connected. |
| A card or plot clips, the page does not fill | View source | Check `page_fillable()`, `layout_columns()`, and `uiOutput(fill = )` classes. |
| An output never updates | Browser devtools, `window.Shiny.shinyapp.$bindings` | A top level output was wrapped in `<Module>` by mistake. |
| An `update*Input()` at session start has no effect | none, it is silent | The update arrived before the dynamic UI rendered that input. Put the value in the widget's own constructor instead. |

See `.claude/skills/bslib-react-port/SKILL.md` for the full symptom table
and the checkpoints in more detail.

## What bit earlier ports, and where the fix lives now

**Theme deferred widget CSS resolved unthemed.** `page_deps()` sets the
global theme with `bslib::bs_global_set(theme)` before collecting
dependencies, and restores the previous global theme afterward. The bug
this avoids: `bslib::bs_global_theme(theme)` takes a Bootstrap version
number as its first argument, not a theme object, so passing a theme
there silently builds a different, unbranded theme instead.

**A themeless `page_react()` served Bootstrap 3.** Fixed upstream in
shinyreact; still visible in a `<head>` dependency comparison if it
recurs, since a Bootstrap 3 file appearing on the port and not the parent
is exactly the kind of difference that check is meant to catch.

**The navbar's active tab had no underline.** bslib's nav item builder
decides between Bootstrap 3 and 5 markup based on
`shiny::getCurrentThemeVersion()`, which reads a Shiny option set by a
running session, not by `bslib::bs_global_set()` alone. This package's own
markup catalog renders every sample with that option set for exactly this
reason, so `NavbarTabStrip` is pinned against correct markup rather than a
stale dump.

**A full screen card made the page taller than the viewport.**
`usePageBody()` injects `html { height: 100% }` into the page, matching
what `bslib::page_fillable()` itself does server side.
