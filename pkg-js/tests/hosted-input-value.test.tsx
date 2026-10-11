import { act, render } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { useHostedInputValue } from "../src/inputs/useHostedInputValue";
import type { JQueryLite } from "../src/shinyreact";

type Handler = (event: unknown) => void;
let handlers: Set<Handler>;

beforeEach(() => {
  handlers = new Set();
  window.$ = ((_target: unknown) => ({
    on: (_event: string, handler: Handler) => handlers.add(handler),
    off: (_event: string, handler: Handler) => handlers.delete(handler),
  })) as unknown as JQueryLite;
});

afterEach(() => {
  delete (window as { Shiny?: unknown }).Shiny;
});

function setInputValues(values: Record<string, unknown>) {
  (window as unknown as { Shiny: unknown }).Shiny = { shinyapp: { $inputValues: values } };
}

function fire(name: string, value: unknown) {
  act(() => handlers.forEach((handler) => handler({ name, value })));
}

function Show({ id }: { id: string }) {
  const value = useHostedInputValue<unknown>(id);
  return <span data-testid="v">{value === undefined ? "none" : String(value)}</span>;
}

describe("useHostedInputValue", () => {
  it("starts from the value Shiny already has, a typed key included", () => {
    setInputValues({ bins: 30, "when:shiny.date": "2026-01-01" });
    const { getByTestId, rerender } = render(<Show id="bins" />);
    expect(getByTestId("v").textContent).toBe("30");
    rerender(<Show id="when" />);
    expect(getByTestId("v").textContent).toBe("2026-01-01");
  });

  it("follows shiny:inputchanged for its own input only", () => {
    const { getByTestId } = render(<Show id="bins" />);
    expect(getByTestId("v").textContent).toBe("none");
    fire("other", 1);
    expect(getByTestId("v").textContent).toBe("none");
    fire("bins", 12);
    expect(getByTestId("v").textContent).toBe("12");
  });

  it("does not keep the previous input's value when its id changes", () => {
    const { getByTestId, rerender } = render(<Show id="a" />);
    fire("a", "from a");
    expect(getByTestId("v").textContent).toBe("from a");
    rerender(<Show id="b" />);
    expect(getByTestId("v").textContent).toBe("none");
  });
});
