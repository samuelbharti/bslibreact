---
title: Building the client
---

# Building the client

A bslibreact app has two halves. A Shiny server, in R or Python, does the
reactive work. A React client owns the page and lays it out with this
package's components. This guide covers the client half. The
[R](https://www.samuelbharti.com/bslibreact/r/articles/get-started.html) and
[Python](https://www.samuelbharti.com/bslibreact/py/get-started.html) Get
started articles build a whole app from the same example.

## The files

The example app `examples/01-hello` in the repository is the starting point
for a new client. Its client is three files:

| File | Role |
| --- | --- |
| `src/App.tsx` | The page, written with bslibreact components. |
| `src/ui.tsx` | Mounts `App` on the page. It is the same in every app. |
| `vite.config.ts` | Builds `src/` into `www/ui.js`, the one script the server sends. |

## Install

```
npm install bslibreact @posit-dev/shinyreact react react-dom
```

`react` and `react-dom` are peer dependencies, version 19.

## One copy of React

shinyreact's own script puts React on the page as `window.shinyreact`. The
client must use that copy and not bundle a second one. Two copies of React on
one page fail in a confusing way: every hook returns nothing. The Vite config
therefore marks React as external and points it at the global:

```ts
rollupOptions: {
  external: ["react", "react-dom", "react-dom/client"],
  output: {
    globals: {
      react: "window.shinyreact.React",
      "react-dom": "window.shinyreact.ReactDOM",
      "react-dom/client": "window.shinyreact.ReactDOM",
    },
  },
},
```

`src/ui.tsx` mounts the app with the same shared copy:

```tsx
import App from "./App";

const { ReactDOM } = window.shinyreact;

const container = document.body.appendChild(document.createElement("div"));
container.className = "html-fill-item html-fill-container";

ReactDOM.createRoot(container).render(<App />);
```

The two fill classes keep bslib's fill layout working between `<body>` and
the page component.

## Layout components

Page shells, cards, sidebars, value boxes and navbars reproduce bslib's
markup directly, so they need nothing from the server:

```tsx
import { PageSidebar, Card, CardHeader, CardBody } from "bslibreact";

<PageSidebar title="My app" sidebar={<Controls />}>
  <Card fullScreen>
    <CardHeader>Histogram</CardHeader>
    <CardBody>...</CardBody>
  </Card>
</PageSidebar>;
```

## Hosted inputs and outputs

Inputs such as `SliderInput` and `SelectInput` are hosted. The server renders
the real Shiny widget and the component displays it, so the widget keeps the
look and behaviour Shiny gives it. The server side is one call:

```r
bslibreact::host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
```

```python
host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))
```

The client mounts it with the `_ui` suffix:

```tsx
<SliderInput id="bins_ui" />
```

`bins` is the widget's own input id, so the element that hosts it needs a
different id. Outputs work the same way without the suffix:
`<PlotOutput id="plot" />` displays `output$plot`.

## Plain values as React state

A value that is only data, such as a count shown in a value box, does not
need a hosted widget. Read it as React state:

```tsx
import { useShinyOutputValue } from "bslibreact";

const status = useShinyOutputValue<string>("status");
```

Host a widget by default, and read a plain value this way only when it is
data and not an interactive control.

## Shiny modules

A component inside `<Module namespace="volcano">` has its ids prefixed the
way `moduleServer("volcano", ...)` prefixes them on the server, so
`<PlotOutput id="plot" />` resolves to `volcano-plot`:

```tsx
import { Module, PlotOutput } from "bslibreact";

<Module namespace="volcano">
  <PlotOutput id="plot" />
</Module>;
```

## Build

```
npm run build
```

The build writes `www/ui.js`. `npm run dev` rebuilds on every change. If the
deployment target has no Node step, commit `www/ui.js`.

## A client with no build step

A small page can skip npm and Vite. The R and Python packages ship a prebuilt
bundle, attached with `bslibreact_dep()`, that registers every component on
`window.bslibreact`. A hand-written `www/ui.js` then calls
`React.createElement(window.bslibreact.Card, ...)`. Most apps should use the
Vite build.

## More

- [Building a new app](https://github.com/samuelbharti/bslibreact/blob/main/docs/build.md)
  has the full guide, including the page setup and deployment.
- [The component map](https://github.com/samuelbharti/bslibreact/blob/main/docs/markup.md)
  lists each R call, its Python call, and the matching component.
