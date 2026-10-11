import { vi } from "vitest";

// A fake window.Shiny that reproduces the hazard useBoundScope guards
// against: bindAll() scans for unbound elements synchronously and marks
// them bound only after an await, as shiny.js's bindOutputs() does.

/** Matches every element kind this kit's hand-written bind scopes register:
 *  a hosted output's own wrapper (.shiny-html-output), the tab strip's own
 *  <ul> (ul.shiny-tab-input), and a sidebar with an id (.bslib-sidebar-input). */
export const BINDABLE_SELECTOR = ".shiny-html-output, ul.shiny-tab-input, .bslib-sidebar-input";

export function createFakeShiny() {
  const bound = new Set<Element>();
  const calls: { scope: Element; unboundOutputsSeen: Element[] }[] = [];

  const bindAll = vi.fn((scope: Element) => {
    // The synchronous phase: capture what's unbound right now, exactly
    // like shiny.js's own bindOutputs() does before its first await.
    const candidates = Array.from(scope.querySelectorAll<Element>(BINDABLE_SELECTOR)).filter(
      (el) => !bound.has(el),
    );
    // Only .shiny-html-output candidates count as "hosted outputs" for the
    // race this reproduces (the tab <ul> and a sidebar's <aside> are hosted
    // INPUTS - bound through the same pass, but a different bug: the
    // descendants-only find(), not the concurrent-mount race).
    const unboundOutputsSeen = candidates.filter((el) =>
      el.classList.contains("shiny-html-output"),
    );
    calls.push({ scope, unboundOutputsSeen });

    // The async phase: mark everything actually bound only after a real
    // await, the exact gap that lets two overlapping calls both see the
    // same element as unbound.
    return Promise.resolve().then(() => {
      for (const el of candidates) bound.add(el);
    });
  });

  const unbindAll = vi.fn((scope: Element) => {
    bound.delete(scope);
  });

  return {
    Shiny: { initializeInputs: vi.fn(), bindAll, unbindAll, initializedPromise: Promise.resolve() },
    bound,
    calls,
  };
}
