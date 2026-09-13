import { HostedInput } from "./HostedInput";

/**
 * shiny::actionButton(). Hosted through the app's own
 * `output$<id> <- renderUI({ actionButton(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No label/icon/class props
 * here: those live only in the R call, copied verbatim from the parent.
 */
export const ActionButton = HostedInput;
