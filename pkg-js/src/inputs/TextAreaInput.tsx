import { HostedInput } from "./HostedInput";

/**
 * shiny::textAreaInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ textAreaInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No rows/placeholder props
 * here: those live only in the R call, copied verbatim from the parent.
 */
export const TextAreaInput = HostedInput;
