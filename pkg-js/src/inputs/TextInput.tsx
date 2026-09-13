import { HostedInput } from "./HostedInput";

/**
 * shiny::textInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ textInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No placeholder/width props
 * here: those live only in the R call, copied verbatim from the parent.
 */
export const TextInput = HostedInput;
