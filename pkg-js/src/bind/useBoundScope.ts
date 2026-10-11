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
 * tab strip passes its parent). Cleanup unbinds `target`, the element
 * captured when the effect ran, and everything inside it; content that
 * stays mounted after `enabled` turns off binds again only on remount.
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

  // When the hook turns off, forget the old bind during this render, so that
  // turning it back on withholds content from its very first commit.
  const [wasActive, setWasActive] = useState(active);
  if (active !== wasActive) {
    setWasActive(active);
    if (!active) setBound(false);
  }

  useEffect(() => {
    if (!active || !initialized) return;
    const el = target.current;
    const Shiny = window.Shiny;
    if (!el || !Shiny) return;

    let cancelled = false;
    const sc = scope(el) ?? el;
    // If binding fails, show the content anyway (a hidden page helps no
    // one) and report the error. bindAll() is typed Promise<void> | void,
    // and either call can also throw synchronously.
    const done = () => {
      if (!cancelled) setBound(true);
    };
    const fail = (error: unknown) => {
      done();
      // eslint-disable-next-line no-console
      console.error("bslib-react: binding to Shiny failed", error);
    };
    try {
      Shiny.initializeInputs(sc);
      void Promise.resolve(Shiny.bindAll(sc)).then(done, fail);
    } catch (error) {
      fail(error);
    }

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
