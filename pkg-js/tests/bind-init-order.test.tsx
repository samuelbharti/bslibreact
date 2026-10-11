import { render, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { NavbarTabStrip, NavItem } from "../src/nav/NavbarTabStrip";
import { createFakeShiny } from "./fake-shiny";

// Its own file: shinyreact's useShinyInitialized() reads a page-wide store
// that stays "initialized" for the rest of a test file once any test has
// set it, and this test needs it not initialized yet at mount. vitest gives
// each file a fresh store.

afterEach(() => {
  delete (window as { Shiny?: unknown }).Shiny;
});

const panels = [{ value: "one", label: "One" }];

describe("useBoundScope: Shiny initializes after mount", () => {
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
