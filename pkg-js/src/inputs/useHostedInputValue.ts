import { useEffect, useState } from "react";
import { useNs } from "../module/Module";

type InputChangedEvent = { name?: string; value?: unknown };

/**
 * Read a hosted input's current value on the client, the port's version of
 * a conditionalPanel reading input.x. Shiny fires shiny:inputchanged as a
 * jQuery event on document, with {name, value} on the event object, so this
 * listens through window.$(document), not addEventListener. Starts as
 * undefined, until the input next changes.
 */
export function useHostedInputValue<T>(id: string): T | undefined {
  const fullId = useNs(id);
  const [value, setValue] = useState<T | undefined>(undefined);

  useEffect(() => {
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
