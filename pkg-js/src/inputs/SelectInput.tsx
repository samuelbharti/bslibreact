import { HostedInput } from "./HostedInput";

/**
 * shiny::selectInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ selectInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No choices/selected props
 * here: those live only in the R call, copied verbatim from the parent.
 */
export const SelectInput = HostedInput;
