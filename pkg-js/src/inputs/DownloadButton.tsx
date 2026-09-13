import { HostedInput } from "./HostedInput";

/**
 * shiny::downloadButton(). Hosted through the app's own
 * `output$<id> <- renderUI({ downloadButton(id, ...) })`; see
 * `HostedInput.tsx`'s own comment for why. No label/class props here:
 * those live only in the R call, copied verbatim from the parent.
 */
export const DownloadButton = HostedInput;
