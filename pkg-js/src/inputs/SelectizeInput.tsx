import { HostedInput } from "./HostedInput";

/**
 * shiny::selectizeInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ selectizeInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No choices/multiple/options
 * props here: those live only in the R call, copied verbatim from the
 * parent, including a server-side selectize's `choices = NULL`.
 */
export const SelectizeInput = HostedInput;
