import { HostedInput } from "./HostedInput";

/**
 * shiny::checkboxInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ checkboxInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No value/label props here:
 * those live only in the R call, copied verbatim from the parent.
 */
export const CheckboxInput = HostedInput;
