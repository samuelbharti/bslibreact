import { useEffect, useState, type RefObject } from "react";
import { useShinyInitialized } from "../shinyreact";

/**
 * Bind a hand-written scope to Shiny once Shiny has initialized, and report
 * when it is safe to mount hosted content inside it. NavbarTabStrip and
 * LayoutSidebar use this: each writes Shiny-bound markup by hand (the tab
 * strip's <ul>, a sidebar's <aside>) next to React content that can hold
 * hosted outputs.
 *
 * Why the content waits: Shiny.bindAll() checks for `.shiny-bound-output`
 * synchronously, but marks elements bound only after an await. A manual
 * bindAll() and a hosted ShinyOutput's own bind pass, running at the same
 * time over the same element, can both find it unbound and both register
 * it, which Shiny reports as "Duplicate output IDs". So this binds first,
 * on a scope with nothing hosted in it yet, and only then returns true;
 * callers withhold their hosted content until it does.
 *
 * `scope(target)` gives the element to bind over. Shiny's find() is
 * descendants-only, so a bound element needs an ancestor as its scope (the
 * tab strip passes its parent). Cleanup unbinds only `target`, the element
 * captured when the effect ran.
 *
 * Returns true at once, binding nothing, when `enabled` is false or the
 * page has no window.Shiny (the markup tests render without one).
 */
export function useBoundScope(
  target: RefObject<HTMLElement | null>,
  scope: (target: HTMLElement) => HTMLElement | null,
  enabled = true,
): boolean {
  const initialized = useShinyInitialized();
  const [bound, setBound] = useState(false);

  const hasShiny = typeof window !== "undefined" && Boolean(window.Shiny);
  const active = enabled && hasShiny;

  useEffect(() => {
    if (!active || !initialized) return;
    const el = target.current;
    const Shiny = window.Shiny;
    if (!el || !Shiny) return;

    let cancelled = false;
    const sc = scope(el) ?? el;
    Shiny.initializeInputs(sc);
    // bindAll() is typed Promise<void> | void.
    void Promise.resolve(Shiny.bindAll(sc)).then(() => {
      if (!cancelled) setBound(true);
    });

    return () => {
      cancelled = true;
      // `el`, not target.current: React can swap the node out meanwhile.
      Shiny.unbindAll(el, true);
    };
    // `scope` is a new arrow function every render and `target` a stable ref,
    // so neither belongs in the deps.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active, initialized]);

  return active ? bound : true;
}
