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
  against the parent app with `port_peek()`; never assume it matches.
- No Tailwind, no shadcn, no react-bootstrap. This kit's components copy
  bslib's own markup, rendered live from an installed bslib rather than
  hand typed, so it cannot silently drift from what a real app serves.

## Steps

1. Triage the parent before writing anything.

   ```r
   bslibreact::port_triage("../parent")
   ```
   ```bash
   python -m bslib_react triage ../parent
   ```

   Paste the result into `PORT.md`.

2. Run the parent and screenshot it.

   ```r
   bslibreact::port_peek("../parent", out = "docs/local/peek")
   ```

3. Write `PORT.md` before any code: a behavior tree, a per-page checklist,
   a status line, and a list of any deliberate divergences from the
   parent.

4. Scaffold the port.

   ```r
   bslibreact::create_app("myport", title = "...")
   ```

   Copy the parent's `R/`, `data/`, and `_brand.yml` unchanged.

5. Server first. Attach the theme and `page_deps()`, then wrap every
   widget the parent renders verbatim in `renderUI()` or `@render.ui`
   under an `_ui` suffixed name. Keep module server signatures unchanged.
   Use `reactive_output()` only for genuine Level R values.

6. Client, one vertical slice, then stop and check.

   ```r
   bslibreact::port_deps_diff("../parent", ".")
   bslibreact::port_peek(".", parent = "../parent", out = "docs/local/peek")
   ```
   ```bash
   python -m bslib_react deps-diff ../parent .
   python -m bslib_react peek . --parent ../parent --out docs/local/peek
   ```

   `deps_diff` must come back clean and `peek` must show the port
   connected with no new console errors before writing the rest of the
   client. Both functions also accept `parent_url`/`port_url` to attach to
   apps already running, including comparing an R parent against a Python
   port or the reverse.

7. Verify: run the app's own test suite, `deps_diff` again, `peek` with
   `parent` set, update `PORT.md`, run the project's pre-commit checks,
   commit.

Screenshots default to a temporary directory and the function prints where
it wrote them; pass `out = "docs/local/peek"` in a repository that ignores
that directory, so nothing lands in a commit by accident.

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
7. Run `port_deps_diff()` on the app again. If a dependency is missing,
   add that call to the app's own `page_deps()` extras.

No dump script, no fixture files, and nothing to revert after a
regeneration rewrote a random id. Deleting `.cache/` and running
`make markup` again always gives a clean slate.

## Checks

| What you see | Run | Usual cause |
| --- | --- | --- |
| Widget colors are stock, the parent is branded | `port_deps_diff` | A theme deferred dependency resolved with no theme. Use `bslib::bs_global_set()`, not `bslib::bs_global_theme()`, inside `page_deps()`. |
| Whole page washed out | `port_deps_diff` | Bootstrap 3 from a themeless page function. |
| A hosted select never leaves Loading | `port_peek` console output | A JS error before Shiny connected. |
| A card or plot clips, the page does not fill | `port_peek(select = ...)` | Check `page_fillable()`, `layout_columns()`, and `uiOutput(fill = )` classes. |
| An output never updates | `port_peek` bound outputs count | A top level output was wrapped in `<Module>` by mistake. |
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
shinyreact; `port_deps_diff()` still flags it if it recurs, since a
Bootstrap 3 file appearing on the port and not the parent is exactly the
kind of difference it is built to catch.

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
