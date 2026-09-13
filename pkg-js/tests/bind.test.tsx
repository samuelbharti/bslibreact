import { render, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NavbarTabStrip, NavItem } from "../src/nav/NavbarTabStrip";
import { LayoutSidebar } from "../src/layout/Sidebar";
import { ShinyOutput } from "../src/shinyreact";

/**
 * The bind defect (see useBoundScope.ts's own file comment for the full
 * "why"): NavbarTabStrip and LayoutSidebar used to call
 * Shiny.initializeInputs()/bindAll() directly, on a scope that could also
 * contain a hosted ShinyOutput mounting in the same commit. shiny.js's own
 * bindOutputs() checks `.shiny-bound-output` synchronously, then marks it
 * only after an internal await, so two overlapping scans both see the same
 * element "unbound" and both register it - Shiny's "Duplicate output IDs"
 * warning, once per extra registration. This file proves the fix
 * (useBoundScope withholding hosted content until its own manual bind has
 * settled) actually closes that window.
 *
 * The fake window.Shiny below reproduces that specific hazard shape - a
 * synchronous candidate scan followed by an async mark - rather than just
 * counting calls, because a call counter alone cannot tell "one call bound
 * two elements" apart from "two calls each (wrongly) bound the same
 * element once".
 *
 * ORDERING CONSTRAINT, READ BEFORE ADDING A TEST ABOVE THE FIRST ONE:
 * @posit-dev/shinyreact's useShinyInitialized() is backed by a page-wide
 * singleton store (lifecycle-store.ts) with no per-test reset exported for
 * consumers to use: `initialized` is a module-level boolean that, once
 * true, stays true for every later test in this FILE (vitest gives each
 * test FILE a fresh module registry, but tests within one file share it).
 * The very first test below relies on `initialized` still being false at
 * mount, which is only true if nothing earlier in this file has already
 * given the store a window.Shiny to observe. Every test AFTER it is
 * written to be correct either way (see each test's own comment), so it is
 * only ever safe to ADD tests below the first one, never above it.
 */

afterEach(() => {
  delete (window as { Shiny?: unknown }).Shiny;
});

const panels = [{ value: "one", label: "One" }];

/** Matches every element kind this kit's hand-written bind scopes register:
 *  a hosted output's own wrapper (.shiny-html-output), the tab strip's own
 *  <ul> (ul.shiny-tab-input), and a sidebar with an id (.bslib-sidebar-input). */
const BINDABLE_SELECTOR = ".shiny-html-output, ul.shiny-tab-input, .bslib-sidebar-input";

function createFakeShiny() {
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

describe("useBoundScope: Shiny initializes after mount", () => {
  // MUST stay the first test in this file - see the file-level comment.
  it("delays binding, and withholds children, until initializedPromise resolves", async () => {
    let resolveInit: () => void = () => {};
    const initializedPromise = new Promise<void>((resolve) => {
      resolveInit = resolve;
    });
    const { Shiny, calls } = createFakeShiny();
    (window as unknown as { Shiny: unknown }).Shiny = { ...Shiny, initializedPromise };

    const { container } = render(
      <NavbarTabStrip id="nav" panels={panels}>
        <NavItem>
          <span data-testid="marker">extra</span>
        </NavItem>
      </NavbarTabStrip>,
    );

    // Shiny exists, but has not initialized yet: nothing bound, marker
    // withheld.
    expect(container.querySelector('[data-testid="marker"]')).toBeNull();
    expect(calls).toHaveLength(0);

    resolveInit();

    await waitFor(() => {
      expect(container.querySelector('[data-testid="marker"]')).not.toBeNull();
    });
    expect(calls.length).toBeGreaterThan(0);
  });
});

describe("useBoundScope: NavbarTabStrip with hosted outputs among its extra children", () => {
  let bound: Set<Element>;
  let calls: { scope: Element; unboundOutputsSeen: Element[] }[];
  let container: HTMLElement;

  beforeEach(async () => {
    const fake = createFakeShiny();
    bound = fake.bound;
    calls = fake.calls;
    (window as unknown as { Shiny: unknown }).Shiny = fake.Shiny;

    const rendered = render(
      <NavbarTabStrip id="nav" panels={panels}>
        <NavItem>
          <ShinyOutput id="a" className="shiny-html-output" />
        </NavItem>
        <NavItem>
          <ShinyOutput id="b" className="shiny-html-output" />
        </NavItem>
      </NavbarTabStrip>,
    );
    container = rendered.container;

    await waitFor(() => {
      expect(container.querySelector("#a")).not.toBeNull();
      expect(container.querySelector("#b")).not.toBeNull();
    });
    await waitFor(() => {
      expect(bound.has(container.querySelector("#a")!)).toBe(true);
      expect(bound.has(container.querySelector("#b")!)).toBe(true);
    });
  });

  it("never scans a scope that still contains an unbound hosted output", () => {
    // calls[0] is, by construction, the manual useBoundScope call: it is
    // the only bindAll call that can possibly run before childrenReady
    // flips true, and the hosted outputs above do not exist in the DOM
    // until childrenReady is true. If withholding ever regressed, this
    // call's scope (the <ul>'s parent, which contains both outputs once
    // they exist) would see them here instead of an empty list.
    expect(calls[0]!.unboundOutputsSeen).toEqual([]);
  });

  it("registers each hosted output exactly once", () => {
    const seenCounts = new Map<Element, number>();
    for (const call of calls) {
      for (const el of call.unboundOutputsSeen) {
        seenCounts.set(el, (seenCounts.get(el) ?? 0) + 1);
      }
    }
    // Sanity check that this test is actually exercising something: both
    // outputs must show up as a candidate in exactly one call each once
    // ShinyOutput's own mount effects run.
    expect(seenCounts.size).toBe(2);
    for (const [el, count] of seenCounts) {
      expect(
        count,
        `#${el.id} was seen as an unbound candidate by ${count} bindAll call(s), want exactly 1`,
      ).toBe(1);
    }
  });

  it("registers the tab strip's own <ul> as a bound input", () => {
    expect(bound.has(container.querySelector("ul")!)).toBe(true);
  });
});

describe("useBoundScope: LayoutSidebar", () => {
  it("withholds sidebar and children, then binds the <aside> as an input, when id is set", async () => {
    const { Shiny, bound, calls } = createFakeShiny();
    (window as unknown as { Shiny: unknown }).Shiny = Shiny;

    const { container } = render(
      <LayoutSidebar id="filters" sidebar={<ShinyOutput id="side" className="shiny-html-output" />}>
        <ShinyOutput id="main" className="shiny-html-output" />
      </LayoutSidebar>,
    );

    // Withheld on the first render: the manual bind has not settled yet.
    expect(container.querySelector("#side")).toBeNull();
    expect(container.querySelector("#main")).toBeNull();

    await waitFor(() => {
      expect(container.querySelector("#side")).not.toBeNull();
      expect(container.querySelector("#main")).not.toBeNull();
    });

    // Same guarantee as NavbarTabStrip's: the manual call (scope = the
    // outer layout div) ran before either hosted output existed.
    expect(calls[0]!.unboundOutputsSeen).toEqual([]);

    const aside = container.querySelector("aside")!;
    await waitFor(() => expect(bound.has(aside)).toBe(true));
  });

  it("renders sidebar and children immediately, with no binding at all, when id is absent", () => {
    const { Shiny } = createFakeShiny();
    (window as unknown as { Shiny: unknown }).Shiny = Shiny;

    const { container } = render(
      <LayoutSidebar sidebar={<div data-testid="side-content" />}>
        <div data-testid="main-content" />
      </LayoutSidebar>,
    );

    // No id means useBoundScope's `enabled` is false, so it returns true
    // synchronously and never touches Shiny at all - matching the old
    // code's plain `if (!id) return`. This is true regardless of whatever
    // the shared lifecycle store remembers from earlier tests, since
    // `enabled` short-circuits before `initialized` is even consulted.
    expect(container.querySelector('[data-testid="side-content"]')).not.toBeNull();
    expect(container.querySelector('[data-testid="main-content"]')).not.toBeNull();
    expect(Shiny.bindAll).not.toHaveBeenCalled();
    expect(Shiny.initializeInputs).not.toHaveBeenCalled();
  });
});
