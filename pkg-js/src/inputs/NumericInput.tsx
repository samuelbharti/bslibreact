import { HostedInput } from "./HostedInput";

/**
 * shiny::numericInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ numericInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No min/max/step/value props
 * here: those live only in the R call, copied verbatim from the parent.
 */
export const NumericInput = HostedInput;
