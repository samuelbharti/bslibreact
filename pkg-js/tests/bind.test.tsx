import { render, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NavbarTabStrip, NavItem } from "../src/nav/NavbarTabStrip";
import { LayoutSidebar } from "../src/layout/Sidebar";
import { ShinyOutput } from "../src/shinyreact";
import { createFakeShiny } from "./fake-shiny";

/**
 * useBoundScope keeps hosted content out of a scope until its own manual
 * bindAll() has settled, so the hosted output's own bind pass and the
 * manual one never scan the same element at once, which Shiny reports as
 * "Duplicate output IDs". The fake Shiny in fake-shiny.ts reproduces that
 * race. The "Shiny initializes after mount" case is in
 * bind-init-order.test.tsx.
 */

afterEach(() => {
  delete (window as { Shiny?: unknown }).Shiny;
});

const panels = [{ value: "one", label: "One" }];

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

describe("useBoundScope: failure and re-binding", () => {
  it("shows the content and reports the error when bindAll() fails", async () => {
    const { Shiny } = createFakeShiny();
    (window as unknown as { Shiny: unknown }).Shiny = {
      ...Shiny,
      bindAll: vi.fn(() => Promise.reject(new Error("boom"))),
    };
    const error = vi.spyOn(console, "error").mockImplementation(() => {});

    const { container } = render(
      <LayoutSidebar id="s" sidebar={<div data-testid="side" />}>
        <div />
      </LayoutSidebar>,
    );

    await waitFor(() => {
      expect(container.querySelector('[data-testid="side"]')).not.toBeNull();
    });
    expect(error).toHaveBeenCalled();
    error.mockRestore();
  });

  it("withholds the content again while it re-binds", async () => {
    const { Shiny } = createFakeShiny();
    (window as unknown as { Shiny: unknown }).Shiny = Shiny;
    const ui = (id?: string) => (
      <LayoutSidebar id={id} sidebar={<div data-testid="side" />}>
        <div />
      </LayoutSidebar>
    );

    const { container, rerender } = render(ui("s"));
    await waitFor(() => {
      expect(container.querySelector('[data-testid="side"]')).not.toBeNull();
    });

    rerender(ui(undefined));
    rerender(ui("s"));
    expect(container.querySelector('[data-testid="side"]')).toBeNull();
    await waitFor(() => {
      expect(container.querySelector('[data-testid="side"]')).not.toBeNull();
    });
  });
});
