import { useEffect, useState } from "react";
import { useNs } from "../module/Module";

type InputChangedEvent = { name?: string; value?: unknown };

// The value Shiny last sent for this input, if any. Shiny keys some inputs
// as "<id>:<type>" (a date input, say), so a suffixed key counts too.
function currentValue(id: string): unknown {
  if (typeof window === "undefined") return undefined;
  const values = window.Shiny?.shinyapp?.$inputValues;
  if (!values) return undefined;
  if (Object.prototype.hasOwnProperty.call(values, id)) return values[id];
  const key = Object.keys(values).find((k) => k.startsWith(`${id}:`));
  return key === undefined ? undefined : values[key];
}

/**
 * Read a hosted input's current value on the client, the port's version of
 * a conditionalPanel reading input.x. Starts from the value Shiny last sent,
 * then follows shiny:inputchanged, a jQuery event on document with
 * {name, value} on the event object, so this listens through
 * window.$(document), not addEventListener. Undefined until Shiny has the
 * input at all.
 */
export function useHostedInputValue<T>(id: string): T | undefined {
  const fullId = useNs(id);
  const [state, setState] = useState(() => ({ id: fullId, value: currentValue(fullId) }));
  // A new id starts from that input's own value in the same render, so the
  // previous input's value never shows for even one commit.
  let current = state;
  if (state.id !== fullId) {
    current = { id: fullId, value: currentValue(fullId) };
    setState(current);
  }

  useEffect(() => {
    const $ = window.$;
    if (!$) return;
    const handler = (event: unknown) => {
      const e = event as InputChangedEvent | undefined;
      if (e?.name === fullId) setState({ id: fullId, value: e.value });
    };
    $(document).on("shiny:inputchanged", handler);
    return () => {
      $(document).off("shiny:inputchanged", handler);
    };
  }, [fullId]);

  return current.value as T | undefined;
}
