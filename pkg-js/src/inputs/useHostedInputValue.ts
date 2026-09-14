import { useEffect, useState } from "react";
import { useNs } from "../module/Module";

type InputChangedEvent = { name?: string; value?: unknown };

/**
 * Read a hosted input's current value on the client. This is the port's
 * equivalent of a conditionalPanel reading input.x in the parent app: some
 * piece of React needs to know what a hosted <SliderInput> or
 * <SelectInput> currently holds, without going through the server.
 *
 * Shiny fires shiny:inputchanged as a jQuery custom event on document
 * whenever any bound input changes, carrying {name, value}. It is a jQuery
 * event, not a native DOM CustomEvent, so this has to go through
 * window.$(document), not addEventListener.
 *
 * Checked against a running app (the gallery's slider-input example, whose
 * hosted sliderInput was driven through ionRangeSlider): Shiny puts
 * {name, value} on the event object itself and passes no second argument.
 * The second-argument read below is kept as a cheap guard, since Shiny has
 * carried the payload that way in the past and it costs nothing here.
 */
export function useHostedInputValue<T>(id: string): T | undefined {
  const fullId = useNs(id);
  const [value, setValue] = useState<T | undefined>(undefined);

  useEffect(() => {
    const $ = window.$;
    if (!$) return;
    const handler = (event: unknown, payload?: unknown) => {
      const e = event as InputChangedEvent | undefined;
      const p = payload as InputChangedEvent | undefined;
      const name = p?.name ?? e?.name;
      const next = p?.value ?? e?.value;
      if (name === fullId) {
        setValue(next as T);
      }
    };
    $(document).on("shiny:inputchanged", handler);
    return () => {
      $(document).off("shiny:inputchanged", handler);
    };
  }, [fullId]);

  return value;
}
