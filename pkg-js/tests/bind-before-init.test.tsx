import { render } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { NavbarTabStrip, NavItem } from "../src/nav/NavbarTabStrip";
import { LayoutSidebar } from "../src/layout/Sidebar";

/**
 * useBoundScope's "there is no Shiny on this page at all" behavior, kept in
 * its own file rather than folded into bind.test.tsx.
 *
 * Every markup test in this package (tests/markup.test.tsx and friends)
 * renders NavbarTabStrip and LayoutSidebar with no window.Shiny present, and
 * relies on useBoundScope returning `true` immediately so the withheld
 * `children`/`sidebar` content still shows up in a plain render() with no
 * waitFor. These two tests are the guarantee that reliance is not
 * accidental: they render both components with window.Shiny absent and
 * check the withheld content is there on the very first synchronous read,
 * no `await` needed.
 *
 * This is safe to run in any order, alongside anything else that might also
 * touch window.Shiny in the same file: unlike useShinyInitialized() (backed
 * by a page-wide singleton store with no per-test reset - see bind.test.tsx's
 * own file comment for why THAT forces an ordering constraint there),
 * useBoundScope's own `hasShiny` check reads `window.Shiny` directly, fresh,
 * every render, so it is unaffected by whatever the shared lifecycle store
 * remembers from an earlier test.
 */

afterEach(() => {
  delete (window as { Shiny?: unknown }).Shiny;
});

const panels = [{ value: "one", label: "One" }];

describe("useBoundScope: no window.Shiny on the page", () => {
  it("NavbarTabStrip renders its extra children immediately, with nothing to bind against", () => {
    const { container } = render(
      <NavbarTabStrip id="nav" panels={panels}>
        <NavItem>
          <span data-testid="marker">extra</span>
        </NavItem>
      </NavbarTabStrip>,
    );

    expect(container.querySelector('[data-testid="marker"]')).not.toBeNull();
  });

  it("LayoutSidebar renders sidebar and children immediately, even with an id set", () => {
    // The id matters here: it is what makes useBoundScope's `enabled` true,
    // so this specifically exercises the "enabled, but no window.Shiny at
    // all" branch, not the (also-immediate, but for the unrelated reason
    // that enabled is false) no-id case bind.test.tsx covers.
    const { container } = render(
      <LayoutSidebar id="filters" sidebar={<div data-testid="side-content" />}>
        <div data-testid="main-content" />
      </LayoutSidebar>,
    );

    expect(container.querySelector('[data-testid="side-content"]')).not.toBeNull();
    expect(container.querySelector('[data-testid="main-content"]')).not.toBeNull();
  });
});
