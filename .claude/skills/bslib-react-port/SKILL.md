---
name: bslib-react-port
description: |
  Port a Shiny app (R or Python) to the shinyreact ui.tsx pattern using the
  bslibreact component kit, and check the port against its parent at fixed
  points. Use when the user asks to port, convert, or migrate a Shiny app
  that uses bslib, when a port looks wrong next to its parent (wrong widget
  colors, a gray or washed-out page, a select stuck on Loading, a card that
  clips, an output that never updates), or when bslibreact needs a new
  component. Sits on top of the shinyreact-convert-app skill and this
  package's docs/porting.md, which holds the rules and the symptom table.
  It adds the checkpoints that come from building this kit.
license: MIT
compatibility: claude-code
metadata:
  version: "2.0.0"
  repo: samuelbharti/bslibreact
---

# Porting with parity checks

Read this package's `docs/porting.md` first. It holds the rules: the
ui.tsx pattern (never call it an SPA), Level H for hosted widgets, Level R
for plain values, no Tailwind, no shadcn, no react-bootstrap, no em dashes,
plain writing. This skill adds the order of work and the checks. The
general phases come from the `shinyreact-convert-app` skill.

bslibreact ships only `page_deps()`, `host_input()`, and
`bslibreact_dep()` at runtime. There is no built-in triage, dependency
diff, or screenshot tool: those checks below are manual, done with the
browser's own devtools and a plain side by side comparison against the
running parent app. That is deliberate (see
`docs/decisions/0001-no-fixtures-live-ground-truth.md`): a check run once
per port does not justify a permanent runtime or CI dependency.

## Checkpoints, in order

1. Before writing PORT.md, read the parent app by hand and note:
   - Its `bs_theme()` call (or `_brand.yml`) and its page function
     (`page_navbar`, `page_sidebar`, `page_fillable`, or none). No bslib
     theme and no bslib page function means the page shell is built by
     hand, and `page_react()` attaches no Bootstrap at all unless it is
     given a `theme`. Such a parent runs on Bootstrap 3, which this kit
     does not target, so give the port `bslib::bs_theme(version = 5)` on
     purpose and record that in PORT.md as a divergence.
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
     or Elements tab, or `curl -s <url> | grep -o '<link[^>]*>\|<script[^>]*>'`):
     every CSS and JS file the parent's theme and widgets pull in should
     also appear on the port. A missing one renders a widget unstyled; an
     extra, unrelated one is usually harmless, but find out why it is there.
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
   `pkg-py/src/bslibreact/_catalog.py` in this repository, not the app
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

The full table is in this repository's `docs/porting.md`, under "Checks"
(https://github.com/samuelbharti/bslibreact/blob/main/docs/porting.md). Use it at
checkpoint 2, and whenever the port looks different from its parent.

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
