import { useEffect, useState, type RefObject } from "react";
import { useShinyInitialized } from "../shinyreact";

/**
 * Bind a hand-written scope to Shiny exactly once, after Shiny has
 * initialized, and report when it is safe to mount anything hosted inside
 * that scope. Both `NavbarTabStrip` and `LayoutSidebar` are built on this.
 *
 * THE BUG THIS FIXES
 *
 * `NavbarTabStrip` and `LayoutSidebar` both write their own markup by hand
 * instead of going through `renderUI()` + `HostedInput` (see
 * `NavbarTabStrip`'s own file comment for why: each one mixes a hosted,
 * Shiny-bound element, the tab strip's own `<ul>`, the sidebar's own
 * `<aside>`, with ordinary React-owned siblings in one DOM subtree that
 * `renderUI()` cannot express as a single output). Both used to call
 * `Shiny.initializeInputs()` and `Shiny.bindAll()` themselves, directly, in
 * a plain `useEffect`, over a scope that could ALSO hold whatever the
 * caller passed as `children` (or, for the sidebar, `sidebar`) - ordinary
 * React content that can itself contain a hosted output built on
 * shinyreact's `ShinyOutput` (a `PlotOutput`, any `HostedInput`, ...).
 *
 * `Shiny.bindAll()` is async, and shiny.js's own output binding pass
 * (`bindOutputs()`) checks whether a candidate element already carries
 * `.shiny-bound-output` SYNCHRONOUSLY, before its first `await`, and only
 * adds that class AFTER the await resolves. `ShinyOutput` (from
 * `@posit-dev/shinyreact`) already coordinates its OWN concurrent mounts
 * against each other for exactly this reason: a `ShinyOutput` sibling
 * mounting in the same commit as another one reuses the in-flight
 * `bindAll()` call for their shared (or overlapping) scope rather than
 * starting a second, racing one. What that bookkeeping cannot see is a
 * call it does not know about, made by code outside it, such as the old
 * `NavbarTabStrip` / `LayoutSidebar` effects calling `window.Shiny.bindAll()`
 * straight from a `useEffect`. When React mounts a hosted output INSIDE
 * that manually-bound scope in the same commit as the manual call, both
 * scans can start before either has marked anything bound, both find the
 * same DOM element "unbound", and both register it: Shiny logs "Duplicate
 * output IDs" once per extra registration, even though there is only one
 * element.
 *
 * THE FIX
 *
 * Not to make the manual call aware of `ShinyOutput`'s in-flight passes:
 * that bookkeeping is private to the other package, and reimplementing it
 * here would just be a second copy to keep in sync. Instead: never let a
 * hosted output exist inside the scope while the manual call is in
 * flight. This hook runs `initializeInputs()` / `bindAll()` FIRST, on a
 * scope that cannot yet contain anything hosted, and only reports "ready"
 * once that settles. The caller withholds whatever content might contain
 * a hosted output (see `NavbarTabStrip`'s `children` and `LayoutSidebar`'s
 * `sidebar` and `children`) until this hook says ready, so by
 * construction a `ShinyOutput` never mounts, and never runs its own
 * `bindAll()` pass, while this hook's pass is still scanning. The two
 * never overlap in time, so there is nothing left for either to race.
 *
 * A second, independent bug this also fixes, for `NavbarTabStrip`
 * specifically: every Shiny binding's `find(scope)` (including the
 * tab-input binding that looks for `ul.shiny-tab-input`) is
 * `$(scope).find(selector)`, which is descendants-only and therefore
 * EXCLUDES `scope` itself. The old code passed the `<ul>` itself as
 * `bindAll`'s scope, so the strip's own `<ul>` was never actually found
 * and bound as an input, no matter how many times bindAll ran - clicking
 * a tab never produced an `input$<id>` update server-side. This hook
 * takes a `scope` callback instead of assuming `target` itself is the
 * right element to scan, so a caller whose bound element needs an
 * ancestor for descendants-only `find()` to reach it (the tab strip,
 * which hands back its own parent) and a caller whose bound element is
 * already reachable from an existing ancestor (the sidebar's outer layout
 * div, relative to its `<aside>`) can both use this one hook correctly.
 *
 * BEHAVIOR
 *
 * - `!enabled`, no `window` (server-side rendering, and some non-DOM test
 *   renderers), or no `window.Shiny` at all: returns `true` immediately
 *   and does nothing else. The markup tests in this package render every
 *   component with no Shiny on the page at all, and must see their
 *   content right away - there is nothing to bind against, so nothing to
 *   wait for.
 * - Otherwise: starts at `false`. Once `useShinyInitialized()` (shinyreact's
 *   own hook, backed by `Shiny.initializedPromise` / the `"shiny:connected"`
 *   DOM event) reports Shiny is up, this hook runs
 *   `Shiny.initializeInputs(sc)` then `await Shiny.bindAll(sc)`, where
 *   `sc` is `scope(target.current) ?? target.current`, and only then flips
 *   to `true`. Shiny finishing initialization after this component has
 *   already mounted is handled the same way, since the effect re-runs the
 *   moment `useShinyInitialized()` flips, the same dependency the two
 *   effects this replaces already keyed off (as `ready`).
 * - Cleanup calls `Shiny.unbindAll(el, true)`, where `el` is the element
 *   captured when the effect ran, `includeSelf` true, unbinding only the
 *   one element this hook bound, never the whole scope (which may hold
 *   plenty of other bindings this hook did not create and has no business
 *   tearing down). Reading `target.current` again at cleanup time, which
 *   is what this did originally and what both components did before this
 *   hook existed, is wrong: the deps below deliberately exclude `target`,
 *   so React can swap the node out from under the ref without re-running
 *   the effect, and cleanup would then unbind whatever is there now while
 *   the element actually bound keeps its bindings forever.
 *
 * @param target The element this hook is responsible for binding and
 * unbinding. Passed to `scope()` to compute the actual scan scope, and
 * used by itself as the unbind target on cleanup.
 * @param scope Given `target.current`, returns the element to run
 * `initializeInputs()` / `bindAll()` over. Falls back to `target.current`
 * itself when this returns `null`.
 * @param enabled Set to `false` to skip binding entirely (LayoutSidebar
 * does this when it has no `id`, matching the old code's `if (!id) return`
 * early exit: a sidebar with no id is not a Shiny input, so there is
 * nothing to bind).
 * @returns Whether it is safe to mount content that might contain a
 * hosted Shiny output inside `scope`.
 */
export function useBoundScope(
  target: RefObject<HTMLElement | null>,
  scope: (target: HTMLElement) => HTMLElement | null,
  enabled = true,
): boolean {
  // Called unconditionally, on every render, regardless of `enabled`: React
  // requires a given component instance to call the same hooks in the same
  // order on every render, and the simplest way to guarantee that here is
  // to never let a hook call sit behind an early return.
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
    // Wrapped in Promise.resolve() because ShinyGlobal#bindAll is typed
    // Promise<void> | void: real Shiny always returns a promise, but
    // nothing here should rely on that if a future fake or shim does not.
    void Promise.resolve(Shiny.bindAll(sc)).then(() => {
      if (!cancelled) setBound(true);
    });

    return () => {
      cancelled = true;
      // Unbind `el`, captured when this effect ran, not target.current as
      // read at cleanup time. React can swap the node out from under the
      // ref between the two, and unbinding a different element than the
      // one bound above leaves Shiny holding the original's bindings.
      Shiny.unbindAll(el, true);
    };
    // `scope` is passed as a fresh inline arrow function at every call site
    // (see NavbarTabStrip and LayoutSidebar) with no identity of its own
    // across renders, and `target` is a ref object, stable for the life of
    // the component - including either in the dependency list would re-run
    // this effect every render for no reason. Same tradeoff the two effects
    // this hook replaces already made for `id` / `ready`.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active, initialized]);

  return active ? bound : true;
}
