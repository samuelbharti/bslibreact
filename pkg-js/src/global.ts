// The IIFE entry point (see vite.config.ts): built as dist/bslib-react.js,
// the file pkg-r and pkg-py vendor and a served page's own htmlDependency
// attaches as a classic <script defer>. Loaded after shinyreact's own
// dependency (see shinyreact.ts's own comment on why this file never
// imports "@posit-dev/shinyreact" directly), so every component in this
// kit reads React and the shinyreact hooks off window.shinyreact by the
// time this script runs.
import * as api from "./index";

declare global {
  interface Window {
    bslibReact: typeof api;
  }
}

window.bslibReact = api;
