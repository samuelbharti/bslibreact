import { render } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { NavbarTabStrip, NavItem } from "../src/nav/NavbarTabStrip";
import { LayoutSidebar } from "../src/layout/Sidebar";

/**
 * useBoundScope with no window.Shiny on the page at all: the markup tests
 * render NavbarTabStrip and LayoutSidebar that way and rely on the withheld
 * content showing on the first synchronous read. bind-late-init.test.tsx
 * covers Shiny arriving after mount; bind.test.tsx the rest.
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
