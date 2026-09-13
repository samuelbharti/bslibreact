import { HostedInput } from "./HostedInput";

/**
 * shiny::radioButtons(). Hosted through the app's own
 * `output$<id> <- renderUI({ radioButtons(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No choices/selected/inline
 * props here: those live only in the R call, copied verbatim from the
 * parent.
 */
export const RadioButtons = HostedInput;
