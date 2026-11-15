# 0003: hosted widgets by default, React state as the exception

Date: 2026-09-13
Status: accepted

## Context

A React client sitting in front of a Shiny server can either rebuild each
input widget from scratch in React and wire it to `useShinyInput()`, or
host the server's own widget markup through `renderUI()` and read it back
with a thin wrapper. Measurements against 20 ported apps in
`samuelbharti/shinyreact-apps` found that no port used React state for a
real Shiny-bound widget: every slider, select box, date picker, file
input, and action button was hosted, and the client was a layout shell
around server-rendered pieces.

## Decision

Every component in `pkg-js/src/inputs/` is `HostedInput`: it renders one
`ShinyOutput` with class `shiny-html-output` and no markup of its own. The
matching server side calls `output$<id>_ui <- renderUI(<the widget call,
unchanged>)`, or `host_input(output, "<id>", <widget call>)`, which does
the same thing and catches an id collision at render time. The `_ui`
suffix on the output name is mandatory: the widget's own call puts its
input id on its own markup, and the output wrapper puts the output id on
its own element, so reusing one string for both puts two elements under
one DOM id.

The one exception is `NavbarTabStrip`: a tab strip mixes hosted tab links
with plain React siblings (`nav_spacer()`, a value chip, a dark mode
toggle) in one list, so it cannot be swapped in as a single `renderUI()`
output. It writes its own markup and binds itself as a Shiny input, using
`useBoundScope()` to avoid double-registering the hosted outputs inside it
(see the `NavbarTabStrip.tsx` and `Sidebar.tsx` source comments for the
mechanism).

Plain text, value boxes, `conditionalPanel`-style show/hide, and small
`renderUI()` blocks that only format data are the cases where real React
state is the better fit. This kit calls the first style Level H, for hosted, and
the second Level R, for React.

No Tailwind, no shadcn, no react-bootstrap. This kit exists because those
give a good looking app that does not look like the bslib original; the
components here copy bslib's own markup so a themed app renders with no
extra styling at all.

## Consequences

The kit does not need to be a state management library, and most of its
surface (`pkg-js/src/inputs/`) carries no version risk from a bslib
release, because it renders no bslib markup itself. A component with a
real reason to bind its own scope should use `useBoundScope()` instead of
calling `Shiny.bindAll()` directly, so its bind pass cannot race
`ShinyOutput`'s own deduplicated bind.
