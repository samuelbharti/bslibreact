import { createContext, useContext, type ReactNode } from "react";
import { ShinyModuleProvider } from "../shinyreact";

// shinyreact does not expose a hook to read the current module namespace
// (there is no useShinyModuleNamespace on window.shinyreact), so the kit
// keeps its own React context for it. A hosted input's markup carries a
// plain HTML id, not a shinyreact channel, so it needs the namespace at
// render time to build that id itself.
const NamespaceContext = createContext<string | undefined>(undefined);

type ModuleProps = { namespace: string; children: ReactNode };

// Wraps a subtree in both the kit's own namespace context (for hosted
// inputs and outputs, which build a plain id) and shinyreact's own
// ShinyModuleProvider (for useShinyInput / reactive_output-backed Level R
// hooks used inside the same subtree). One <Module> covers both levels.
export function Module({ namespace, children }: ModuleProps) {
  return (
    <NamespaceContext.Provider value={namespace}>
      <ShinyModuleProvider namespace={namespace}>{children}</ShinyModuleProvider>
    </NamespaceContext.Provider>
  );
}

// Build the wire id a hosted input or output uses: "<ns>-<id>" inside a
// Module, or the bare id at the top level. Matches Shiny's own ns()
// (single hyphen, matching moduleServer's default).
export function useNs(id: string): string {
  const namespace = useContext(NamespaceContext);
  return namespace ? `${namespace}-${id}` : id;
}
