import { HostedInput } from "./HostedInput";

/**
 * shiny::passwordInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ passwordInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No placeholder prop here: it
 * lives only in the R call, copied verbatim from the parent.
 */
export const PasswordInput = HostedInput;
