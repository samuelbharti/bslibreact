import { useEffect, useState } from "react";
import { useNs } from "../module/Module";

type InputChangedEvent = { name?: string; value?: unknown };

// The input's current value, if Shiny already has it. Shiny keys some
// inputs as "<id>:<type>" (a date input, say), so a suffixed key counts too.
function currentValue(id: string): unknown {
  const values = window.Shiny?.shinyapp?.$inputValues;
  if (!values) return undefined;
  if (id in values) return values[id];
  const key = Object.keys(values).find((k) => k.startsWith(`${id}:`));
  return key === undefined ? undefined : values[key];
}

/**
 * Read a hosted input's current value on the client, the port's version of
 * a conditionalPanel reading input.x. Starts from the value Shiny already
 * has, then follows shiny:inputchanged, a jQuery event on document with
 * {name, value} on the event object, so this listens through
 * window.$(document), not addEventListener. Undefined until Shiny has the
 * input at all.
 */
export function useHostedInputValue<T>(id: string): T | undefined {
  const fullId = useNs(id);
  const [value, setValue] = useState<T | undefined>(() => currentValue(fullId) as T | undefined);

  useEffect(() => {
    // A new id starts from that input's own value, not the previous one's.
    setValue(currentValue(fullId) as T | undefined);
    const $ = window.$;
    if (!$) return;
    const handler = (event: unknown) => {
      const e = event as InputChangedEvent | undefined;
      if (e?.name === fullId) setValue(e.value as T);
    };
    $(document).on("shiny:inputchanged", handler);
    return () => {
      $(document).off("shiny:inputchanged", handler);
    };
  }, [fullId]);

  return value;
}
