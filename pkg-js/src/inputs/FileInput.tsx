import { HostedInput } from "./HostedInput";

/**
 * shiny::fileInput(). Hosted through the app's own
 * `output$<id> <- renderUI({ fileInput(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No label/accept props here:
 * those live only in the R call, copied verbatim from the parent.
 *
 * Not yet re-verified against a running app since migrating off the
 * hand-written ShinyInput host (unlike SliderInput/SelectizeInput,
 * checked directly): fileInput()'s own binding does more than read an
 * input value, it posts the file's bytes to a dedicated upload
 * endpoint. Re-check this specifically the next time a port hosts one.
 */
export const FileInput = HostedInput;
