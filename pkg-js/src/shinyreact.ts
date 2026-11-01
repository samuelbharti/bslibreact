// Typed accessors for window.shinyreact, window.Shiny, and window.bslib.
// React and Shiny both come from globals on the page (see
// examples/01-hello/vite.config.ts), so every hook in the kit goes through here
// instead of touching `window` directly.

export type InputOpts = {
  debounceMs?: number;
  priority?: "immediate" | "deferred" | "event";
  type?: string;
};

export type OutputStatus = "pending" | "ready" | "recalculating" | "error";

// Matches @posit-dev/shinyreact's own ErrorsMessageValue exactly (call/type
// are string ARRAYS, not plain strings: R's condition class chain, or null
// for both on py-shiny). tests/shinyreact-surface.test.ts and tests/setup.ts
// (which assigns the real package's exports into window.shinyreact, typed
// as ShinyReactGlobal below) both fail to type-check the moment this drifts
// from the real shape, which is what caught the mismatch this comment now
// documents: an earlier version of this type had call/type as plain
// optional strings, which is not what the real package ever sends.
export type OutputError = { message: string; call: string[] | null; type?: string[] | null };

export interface ShinyReactGlobal {
  React: typeof import("react");
  ReactDOM: typeof import("react-dom/client");
  useShinyInput: <T>(id: string, def: T, opts?: InputOpts) => [T, (v: T) => void];
  useSetShinyInput: <T>(id: string, def: T, opts?: InputOpts) => (v: T) => void;
  useShinyInputValue: <T>(id: string) => T | undefined;
  useShinyOutputValue: <T>(id: string, def?: T) => T | undefined;
  useShinyOutputStatus: (id: string) => OutputStatus;
  useShinyOutputError: (id: string) => OutputError | null;
  useShinyInitialized: () => boolean;
  useShinyBusy: () => boolean;
  useShinyMessageHandler: (type: string, handler: (data: unknown) => void) => void;
  ShinyOutput: (props: {
    id: string;
    tagName?: string;
    className?: string;
    [attr: string]: unknown;
  }) => import("react").ReactElement;
  // Mirrors @posit-dev/shinyreact's real ImageOutput props exactly (width
  // and height are plain strings there, not number|string as an earlier,
  // looser version of this type guessed - tests/setup.ts's assignment of
  // the real module into window.shinyreact, typed as ShinyReactGlobal,
  // fails to compile the moment this drifts from the real shape again).
  ImageOutput: (props: {
    id: string;
    className?: string;
    width?: string;
    height?: string;
    debounceMs?: number;
    onRecalculating?: (isRecalculating: boolean) => void;
    namespace?: string | null;
    // The real component returns null before its image dimensions are
    // known (nothing to size an <img> to yet), so this cannot be typed as
    // always returning a ReactElement.
  }) => import("react").ReactElement | null;
  ShinyModuleProvider: (props: {
    namespace: string;
    children: import("react").ReactNode;
  }) => import("react").ReactElement;
}

// window.Shiny is the real Shiny.js runtime, loaded because page_react()
// always attaches shiny's own JS dependency to the page (shinyreact is a
// bridge, not a replacement for Shiny). useBoundScope.ts calls its bind
// methods directly for the two components that bind their own markup.
export interface ShinyGlobal {
  initializeInputs: (scope: Document | Element) => void;
  bindAll: (scope: Document | Element) => Promise<void> | void;
  unbindAll: (scope: Document | Element, includeSelf?: boolean) => void;
  setInputValue: (name: string, value: unknown, opts?: InputOpts) => void;
  /** Shiny.addCustomMessageHandler(type, handler): the client half of
   *  session$sendCustomMessage(type, ...) on the server. A port reaches
   *  for this when the parent's own UI had an inline
   *  tags$script(HTML("Shiny.addCustomMessageHandler(...)")) driving a
   *  plain DOM effect (opening an offcanvas, say) that isn't itself a
   *  hosted input or output. */
  addCustomMessageHandler: (type: string, handler: (message: unknown) => void) => void;
  initializedPromise?: Promise<void>;
}

// bslib's own component runtime. Its input/output-owning components attach
// this global and read it from an inline <script> in R-rendered HTML; TSX
// calls the same functions from a useLayoutEffect instead.
export interface BslibGlobal {
  Card?: { initializeAllCards: () => void };
  Sidebar?: { initCollapsibleAll: () => void };
}

// A minimal jQuery surface. Shiny dispatches its custom events
// (shiny:inputchanged, shiny:busy, shiny:idle, ...) through jQuery's own
// event system, not as native DOM CustomEvents, so a plain
// addEventListener never sees them: this has to go through $(document).
export interface JQueryLite {
  (selector: Document | string): {
    on: (event: string, handler: (event: unknown, ...args: unknown[]) => void) => void;
    off: (event: string, handler: (event: unknown, ...args: unknown[]) => void) => void;
  };
}

declare global {
  interface Window {
    shinyreact: ShinyReactGlobal;
    // Optional, not required: @posit-dev/shinyreact's own ambient
    // declaration (shiny-react/index.ts) augments the same global Window
    // interface with `Shiny?: ShinyClassExtended`, and TypeScript requires
    // every merged declaration of one property to share the exact same
    // optionality (TS2687, "All declarations of 'Shiny' must have
    // identical modifiers"). Any file in this package's own test suite
    // that imports @posit-dev/shinyreact (tests/setup.ts does, to install
    // the real hooks onto this same global) pulls that declaration into
    // the program, so this one has to match it - which also happens to be
    // the more honest shape anyway: a page can genuinely have no Shiny at
    // all (see useBoundScope.ts and the markup tests, both of which render
    // this kit with window.Shiny absent on purpose).
    Shiny?: ShinyGlobal;
    bslib?: BslibGlobal;
    $: JQueryLite;
  }
}

let providedShinyReact: ShinyReactGlobal | undefined;

/**
 * Hand this module a `@posit-dev/shinyreact` instance directly, instead of
 * relying on `window.shinyreact`.
 *
 * The server-tier IIFE build (see vite.config.ts) externalizes react and
 * react-dom to `window.shinyreact.React` / `.ReactDOM`, so every hook here
 * reads the one React instance the page's shinyreact.js dependency already
 * installed. An npm-tier app is different: it bundles `@posit-dev/shinyreact`
 * itself (a real dependency, resolved by its own bundler) rather than
 * loading shinyreact.js as a page dependency, so there is no global to read.
 * Such an app calls this once, at startup, with the module it already
 * imported, and every hook and component in this kit resolves against that
 * instance instead of a `window.shinyreact` that build may never populate.
 *
 * Deliberately NOT auto-detected with a static `import * as shinyreact from
 * "@posit-dev/shinyreact"` in this file: that would force EVERY consumer of
 * this package, including the server-tier IIFE build, to also resolve
 * "@posit-dev/shinyreact" as a real dependency and bundle whatever React
 * copy IT resolves to. That is exactly the "two React instances on one
 * page" failure mode the externalization above exists to prevent (every
 * hook silently returns nothing, or throws about hooks being called
 * outside a component, once two React copies disagree about which one is
 * "the" dispatcher). Requiring an explicit call instead keeps this file
 * import-free of "@posit-dev/shinyreact", so only an app that opts in by
 * calling provideShinyReact() pays for that dependency at all.
 */
export function provideShinyReact(mod: ShinyReactGlobal): void {
  providedShinyReact = mod;
}

function sr(): ShinyReactGlobal {
  const g = providedShinyReact ?? window.shinyreact;
  if (!g) {
    throw new Error(
      "window.shinyreact is not available, and no module was passed to " +
        "provideShinyReact(). Is the shinyreact page dependency loaded, or " +
        "did an npm-tier app forget to call provideShinyReact() at startup?",
    );
  }
  return g;
}

export function useShinyInput<T>(id: string, def: T, opts?: InputOpts) {
  return sr().useShinyInput<T>(id, def, opts);
}

export function useSetShinyInput<T>(id: string, def: T, opts?: InputOpts) {
  return sr().useSetShinyInput<T>(id, def, opts);
}

export function useShinyInputValue<T>(id: string) {
  return sr().useShinyInputValue<T>(id);
}

export function useShinyOutputValue<T>(id: string, def?: T) {
  return sr().useShinyOutputValue<T>(id, def);
}

export function useShinyOutputStatus(id: string) {
  return sr().useShinyOutputStatus(id);
}

export function useShinyOutputError(id: string) {
  return sr().useShinyOutputError(id);
}

export function useShinyInitialized() {
  return sr().useShinyInitialized();
}

export function useShinyBusy() {
  return sr().useShinyBusy();
}

export function useShinyMessageHandler(type: string, handler: (data: unknown) => void) {
  return sr().useShinyMessageHandler(type, handler);
}

export const ShinyOutput = (props: Parameters<ShinyReactGlobal["ShinyOutput"]>[0]) =>
  sr().ShinyOutput(props);

export const ImageOutput = (props: Parameters<ShinyReactGlobal["ImageOutput"]>[0]) =>
  sr().ImageOutput(props);

export const ShinyModuleProvider = (
  props: Parameters<ShinyReactGlobal["ShinyModuleProvider"]>[0],
) => sr().ShinyModuleProvider(props);
