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

// Matches @posit-dev/shinyreact's ErrorsMessageValue: call and type are R's
// condition call and class chain, null on py-shiny. tests/setup.ts assigns
// the real package to a ShinyReactGlobal, so drift fails to type-check.
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
  // Mirrors @posit-dev/shinyreact's ImageOutput props.
  ImageOutput: (props: {
    id: string;
    className?: string;
    width?: string;
    height?: string;
    debounceMs?: number;
    onRecalculating?: (isRecalculating: boolean) => void;
    namespace?: string | null;
    // null until the image's size is known.
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
  /** The last value of every bound input, keyed by id (sometimes with a
   *  ":<type>" suffix). Read by useHostedInputValue for its first value. */
  shinyapp?: { $inputValues: Record<string, unknown> };
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
    // Optional, to match @posit-dev/shinyreact's own declaration of the same
    // property (TS2687 otherwise), and because a page can have no Shiny.
    Shiny?: ShinyGlobal;
    bslib?: BslibGlobal;
    $: JQueryLite;
  }
}

let providedShinyReact: ShinyReactGlobal | undefined;

/**
 * Hand this kit a `@posit-dev/shinyreact` module instead of relying on
 * `window.shinyreact`. The served page's shinyreact.js sets that global; an
 * app that bundles `@posit-dev/shinyreact` itself instead calls this once at
 * startup with the module it imported.
 *
 * Not done with a static import here: that would make every consumer,
 * including the IIFE build, bundle shinyreact and its own React copy, and
 * two React copies on one page break every hook.
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
